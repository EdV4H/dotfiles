// Package capture splits a PTY output stream into per-command chunks using
// OSC 133 shell-integration markers, while passing the stream through to the
// real terminal unchanged (except for nidome's private OSC sequences).
package capture

import (
	"strconv"
	"strings"
)

// PrivateOSC is the OSC number the hook uses to send metadata to the wrapper.
// The wrapper strips these sequences so the terminal never sees them.
const PrivateOSC = "7771;nidome;"

const (
	maxOSC     = 64 << 10 // give up on an OSC payload larger than this
	maxSeq     = 256      // give up on a CSI sequence longer than this
	maxLines   = 200      // output tail kept per command
	maxLineLen = 4 << 10
)

// Result is one finished command.
type Result struct {
	Cmd       string
	Cwd       string
	Exit      int
	Tail      []string // ANSI-stripped output lines, oldest first
	Truncated bool     // older lines were dropped
	AltScreen bool     // the command used the alternate screen (vim, less, …)
}

type state int

const (
	stNormal state = iota
	stEsc
	stCSI
	stOSC
	stOSCEsc
)

// Filter is a streaming parser. Feed it raw PTY output with Write; it returns
// the bytes to forward to the terminal and calls OnDone for each command that
// finishes.
type Filter struct {
	OnDone func(Result)

	st  state
	seq []byte // pending escape sequence (forwarded once complete)

	running bool
	alt     bool
	usedAlt bool
	cmd     string
	cwd     string

	lines     []string
	cur       []byte
	truncated bool
}

// Write consumes p and returns what should be written to the terminal.
func (f *Filter) Write(p []byte) []byte {
	out := make([]byte, 0, len(p))
	for _, b := range p {
		switch f.st {
		case stNormal:
			if b == 0x1b {
				f.st = stEsc
				f.seq = append(f.seq[:0], b)
				continue
			}
			out = append(out, b)
			f.text(b)
		case stEsc:
			f.seq = append(f.seq, b)
			switch b {
			case '[':
				f.st = stCSI
			case ']':
				f.st = stOSC
			default:
				out = append(out, f.seq...)
				f.st = stNormal
			}
		case stCSI:
			f.seq = append(f.seq, b)
			if b >= 0x40 && b <= 0x7e {
				f.csi(f.seq[2:])
				out = append(out, f.seq...)
				f.st = stNormal
			} else if len(f.seq) > maxSeq {
				out = append(out, f.seq...)
				f.st = stNormal
			}
		case stOSC:
			switch {
			case b == 0x07:
				out = f.osc(out, f.seq[2:], []byte{0x07})
				f.st = stNormal
			case b == 0x1b:
				f.st = stOSCEsc
			default:
				f.seq = append(f.seq, b)
				if len(f.seq) > maxOSC {
					out = append(out, f.seq...)
					f.st = stNormal
				}
			}
		case stOSCEsc:
			if b == '\\' {
				out = f.osc(out, f.seq[2:], []byte{0x1b, '\\'})
				f.st = stNormal
				continue
			}
			// Not ST: forward what we had and restart on this ESC.
			out = append(out, f.seq...)
			f.seq = append(f.seq[:0], 0x1b)
			f.st = stEsc
			// Re-run the byte in stEsc.
			out = append(out, f.Write([]byte{b})...)
		}
	}
	return out
}

func (f *Filter) text(b byte) {
	if !f.running || f.alt {
		return
	}
	switch {
	case b == '\n':
		f.pushLine()
	case b == '\r':
		// A bare CR means the next text overwrites the line (progress bars).
		// Keep a marker; the next printable byte clears the line, while an
		// LF (CRLF) just ends it.
		f.cur = append(f.cur, '\r')
	case b == '\t' || b >= 0x20 && b != 0x7f:
		if n := len(f.cur); n > 0 && f.cur[n-1] == '\r' {
			f.cur = f.cur[:0]
		}
		if len(f.cur) < maxLineLen {
			f.cur = append(f.cur, b)
		}
	case b == 0x08: // backspace
		if n := len(f.cur); n > 0 {
			f.cur = f.cur[:n-1]
		}
	}
}

func (f *Filter) pushLine() {
	line := strings.TrimRight(string(f.cur), "\r \t")
	f.cur = f.cur[:0]
	f.lines = append(f.lines, line)
	if len(f.lines) > maxLines {
		f.lines = f.lines[len(f.lines)-maxLines:]
		f.truncated = true
	}
}

func (f *Filter) csi(params []byte) {
	s := string(params)
	switch s {
	case "?1049h", "?1047h", "?47h":
		f.alt = true
		if f.running {
			f.usedAlt = true
		}
	case "?1049l", "?1047l", "?47l":
		f.alt = false
	}
}

func (f *Filter) osc(out, payload, term []byte) []byte {
	s := string(payload)
	if strings.HasPrefix(s, PrivateOSC) {
		kv := s[len(PrivateOSC):]
		switch {
		case strings.HasPrefix(kv, "cmd="):
			f.cmd = kv[len("cmd="):]
		case strings.HasPrefix(kv, "cwd="):
			f.cwd = kv[len("cwd="):]
		}
		return out // swallowed
	}
	switch {
	case s == "133;C" || strings.HasPrefix(s, "133;C;"):
		f.start()
	case s == "133;D" || strings.HasPrefix(s, "133;D;"):
		exit := 0
		if rest := strings.TrimPrefix(s, "133;D"); rest != "" {
			exit, _ = strconv.Atoi(strings.SplitN(rest[1:], ";", 2)[0])
		}
		f.finish(exit)
	}
	out = append(out, 0x1b, ']')
	out = append(out, payload...)
	return append(out, term...)
}

func (f *Filter) start() {
	f.running = true
	f.usedAlt = f.alt
	f.lines = f.lines[:0]
	f.cur = f.cur[:0]
	f.truncated = false
}

func (f *Filter) finish(exit int) {
	if !f.running {
		return
	}
	if len(f.cur) > 0 {
		f.pushLine()
	}
	// zsh's PROMPT_SP prints padding just before the prompt; drop blank tail lines.
	for len(f.lines) > 0 && f.lines[len(f.lines)-1] == "" {
		f.lines = f.lines[:len(f.lines)-1]
	}
	r := Result{
		Cmd:       f.cmd,
		Cwd:       f.cwd,
		Exit:      exit,
		Tail:      append([]string(nil), f.lines...),
		Truncated: f.truncated,
		AltScreen: f.usedAlt,
	}
	f.running = false
	f.cmd, f.cwd = "", ""
	if f.OnDone != nil {
		f.OnDone(r)
	}
}
