// Command nidome records failed terminal commands with their output so the
// same error never has to be debugged twice. This is the M0 prototype: it
// only proves that the PTY wrapper can cut output per command without
// breaking the terminal.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/EdV4H/nidome/internal/capture"
	"github.com/EdV4H/nidome/internal/hook"
	"github.com/creack/pty"
	"golang.org/x/term"
)

func main() {
	if len(os.Args) < 2 {
		usage()
	}
	switch os.Args[1] {
	case "init":
		if len(os.Args) != 3 {
			usage()
		}
		s, err := hook.Script(os.Args[2])
		if err != nil {
			fatal(err)
		}
		fmt.Print(s)
	case "shell":
		os.Exit(runShell(os.Args[2:]))
	case "log":
		b, err := os.ReadFile(logPath())
		if err != nil {
			fatal(err)
		}
		os.Stdout.Write(b)
	default:
		usage()
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: nidome init zsh | nidome shell [shell args...] | nidome log")
	os.Exit(2)
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "nidome:", err)
	os.Exit(1)
}

func dataDir() string {
	if d := os.Getenv("NIDOME_DATA_DIR"); d != "" {
		return d
	}
	if d := os.Getenv("XDG_DATA_HOME"); d != "" {
		return filepath.Join(d, "nidome")
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".local", "share", "nidome")
}

func logPath() string { return filepath.Join(dataDir(), "m0.jsonl") }

type record struct {
	At        time.Time `json:"at"`
	Cmd       string    `json:"cmd"`
	Cwd       string    `json:"cwd"`
	Exit      int       `json:"exit"`
	Tail      []string  `json:"tail"`
	Truncated bool      `json:"truncated,omitempty"`
	AltScreen bool      `json:"alt_screen,omitempty"`
}

// runShell starts the user's shell on a PTY and relays I/O, recording the
// output tail of every command that exits non-zero.
func runShell(args []string) int {
	sh := os.Getenv("SHELL")
	if sh == "" {
		sh = "/bin/zsh"
	}
	c := exec.Command(sh, args...)
	c.Env = append(os.Environ(), "NIDOME_PTY=1")

	ptmx, err := pty.Start(c)
	if err != nil {
		fatal(err)
	}
	defer ptmx.Close()

	// Keep the inner terminal size in sync (SIGWINCH).
	winch := make(chan os.Signal, 1)
	signal.Notify(winch, syscall.SIGWINCH)
	go func() {
		for range winch {
			_ = pty.InheritSize(os.Stdin, ptmx)
		}
	}()
	winch <- syscall.SIGWINCH
	defer func() { signal.Stop(winch); close(winch) }()

	if term.IsTerminal(int(os.Stdin.Fd())) {
		old, err := term.MakeRaw(int(os.Stdin.Fd()))
		if err != nil {
			fatal(err)
		}
		defer term.Restore(int(os.Stdin.Fd()), old)
	}

	go func() {
		buf := make([]byte, 32<<10)
		for {
			n, err := os.Stdin.Read(buf)
			if n > 0 {
				if _, werr := ptmx.Write(buf[:n]); werr != nil {
					return
				}
			}
			if err != nil {
				return
			}
		}
	}()

	recs := make(chan record, 16)
	done := make(chan struct{})
	go writeRecords(recs, done)

	f := &capture.Filter{OnDone: func(r capture.Result) {
		if r.Exit == 0 {
			return
		}
		select {
		case recs <- record{At: time.Now(), Cmd: r.Cmd, Cwd: r.Cwd, Exit: r.Exit,
			Tail: r.Tail, Truncated: r.Truncated, AltScreen: r.AltScreen}:
		default: // never block the terminal on disk I/O
		}
	}}
	buf := make([]byte, 32<<10)
	for {
		n, err := ptmx.Read(buf)
		if n > 0 {
			os.Stdout.Write(f.Write(buf[:n]))
		}
		if err != nil {
			break
		}
	}
	close(recs)
	<-done

	if err := c.Wait(); err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return ee.ExitCode()
		}
		return 1
	}
	return 0
}

func writeRecords(recs <-chan record, done chan<- struct{}) {
	defer close(done)
	var fh *os.File
	for r := range recs {
		if fh == nil {
			if err := os.MkdirAll(dataDir(), 0o700); err != nil {
				continue
			}
			var err error
			fh, err = os.OpenFile(logPath(), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
			if err != nil {
				continue
			}
			defer fh.Close()
		}
		b, _ := json.Marshal(r)
		fh.Write(append(b, '\n'))
	}
}
