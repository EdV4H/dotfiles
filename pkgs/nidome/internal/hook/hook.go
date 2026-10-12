// Package hook holds the shell integration scripts printed by `nidome init`.
package hook

import (
	_ "embed"
	"fmt"
)

//go:embed zsh.zsh
var zsh string

// Script returns the hook script for the given shell.
func Script(shell string) (string, error) {
	switch shell {
	case "zsh":
		return zsh, nil
	default:
		return "", fmt.Errorf("unsupported shell %q (M0 supports zsh only)", shell)
	}
}
