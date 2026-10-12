package capture

import (
	"reflect"
	"testing"
)

func feed(f *Filter, chunks ...string) string {
	var out []byte
	for _, c := range chunks {
		out = append(out, f.Write([]byte(c))...)
	}
	return string(out)
}

func TestFilterCapturesFailedCommand(t *testing.T) {
	var got []Result
	f := &Filter{OnDone: func(r Result) { got = append(got, r) }}

	out := feed(f,
		"\x1b]7771;nidome;cwd=/tmp/x\a\x1b]7771;nidome;cmd=pnpm install\a",
		"\x1b]133;C\a",
		"\x1b[31m ERR_PNPM",                  // split mid-line…
		"_LOCKFILE\x1b[0m boom\r\nlast line", // …and mid-colour
		"\r\n\x1b]133;D;1\a\x1b]133;A\a$ ",
	)

	if len(got) != 1 {
		t.Fatalf("got %d results", len(got))
	}
	want := Result{Cmd: "pnpm install", Cwd: "/tmp/x", Exit: 1,
		Tail: []string{" ERR_PNPM_LOCKFILE boom", "last line"}}
	if !reflect.DeepEqual(got[0], want) {
		t.Fatalf("got %#v\nwant %#v", got[0], want)
	}
	// Private OSC is stripped; everything else passes through untouched.
	wantOut := "\x1b]133;C\a\x1b[31m ERR_PNPM_LOCKFILE\x1b[0m boom\r\nlast line\r\n\x1b]133;D;1\a\x1b]133;A\a$ "
	if out != wantOut {
		t.Fatalf("passthrough mismatch:\n got %q\nwant %q", out, wantOut)
	}
}

func TestFilterSplitsOSCAcrossWrites(t *testing.T) {
	var got []Result
	f := &Filter{OnDone: func(r Result) { got = append(got, r) }}
	feed(f, "\x1b]77", "71;nidome;cmd=false\x1b", "\\\x1b]13", "3;C\x1b\\", "\x1b]133;D;", "1\a")
	if len(got) != 1 || got[0].Cmd != "false" || got[0].Exit != 1 {
		t.Fatalf("got %#v", got)
	}
}

func TestFilterCarriageReturnOverwrites(t *testing.T) {
	var got []Result
	f := &Filter{OnDone: func(r Result) { got = append(got, r) }}
	feed(f, "\x1b]133;C\a", "10%\r50%\r100%\r\nError: x\r\n", "\x1b]133;D;2\a")
	if want := []string{"100%", "Error: x"}; !reflect.DeepEqual(got[0].Tail, want) {
		t.Fatalf("got %q want %q", got[0].Tail, want)
	}
}

func TestFilterSkipsAltScreen(t *testing.T) {
	var got []Result
	f := &Filter{OnDone: func(r Result) { got = append(got, r) }}
	feed(f, "\x1b]133;C\a", "before\r\n", "\x1b[?1049hVIM SCREEN\r\n\x1b[?1049l", "after\r\n", "\x1b]133;D;1\a")
	if want := []string{"before", "after"}; !reflect.DeepEqual(got[0].Tail, want) {
		t.Fatalf("got %q want %q", got[0].Tail, want)
	}
	if !got[0].AltScreen {
		t.Fatal("AltScreen not set")
	}
}

func TestFilterKeepsLastLines(t *testing.T) {
	var got []Result
	f := &Filter{OnDone: func(r Result) { got = append(got, r) }}
	feed(f, "\x1b]133;C\a")
	for i := 0; i < maxLines+50; i++ {
		feed(f, "x\n")
	}
	feed(f, "\x1b]133;D;1\a")
	if len(got[0].Tail) != maxLines || !got[0].Truncated {
		t.Fatalf("len=%d truncated=%v", len(got[0].Tail), got[0].Truncated)
	}
}
