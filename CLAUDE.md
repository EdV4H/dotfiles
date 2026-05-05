# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Nix-based dotfiles configuration repository that manages system configuration for macOS (aarch64-darwin) using:
- **Nix Flakes** for reproducible system configuration
- **Home Manager** for user-level package and configuration management
- **nix-darwin** for macOS system-level configuration
- **Homebrew** integration for GUI applications

## Essential Commands

### System Updates
```bash
# Update entire system configuration (flake + home-manager + nix-darwin)
nix run .#update

# Update only home-manager configuration
nix run nixpkgs#home-manager -- switch --flake .#myHomeConfig

# Update only nix-darwin configuration
sudo darwin-rebuild switch --flake .#ATR-LAP-OSX-YUSUKE-MARUYAMA

# Update flake inputs
nix flake update
```

### Development Commands
```bash
# Format Nix files
nix fmt

# Check flake configuration
nix flake check

# Build without switching
nix build .#homeConfigurations.myHomeConfig.activationPackage
nix build .#darwinConfigurations.ATR-LAP-OSX-YUSUKE-MARUYAMA.system
```

## Architecture

### Flake Structure
- **flake.nix**: Main entry point defining:
  - Home Manager configuration: `myHomeConfig`
  - Darwin configuration: `ATR-LAP-OSX-YUSUKE-MARUYAMA`
  - Update script app: `.#update`
  - Formatter using treefmt-nix

### Configuration Modules
- **nix/home-manager/default.nix**: User-level configuration
  - Shell configuration (zsh with aliases)
  - Development tools (git, gh, tmux, neovim, etc.)
  - Session variables (VOLTA_HOME, Google Cloud project)
  
- **nix/nix-darwin/default.nix**: System-level macOS configuration
  - Nix daemon settings
  - macOS defaults (Finder, Dock)
  - Homebrew casks for GUI applications
  - Font packages

### Program Configurations
- **nix/home-manager/programs/wezterm/**: Terminal emulator configuration
  - Lua-based configuration with custom keybindings
  - Everforest Dark color scheme
  
- **nix/home-manager/programs/neovim/**: Neovim configuration (currently minimal)

## Key Configuration Details

### User Information
- Username: `yusukemaruyama`
- Home directory: `/Users/yusukemaruyama`
- System: `aarch64-darwin`
- Machine name: `ATR-LAP-OSX-YUSUKE-MARUYAMA`

### Installed Development Tools
- Version control: git, gh, lazygit
- Terminal: wezterm, tmux
- Editor: neovim
- Search: ripgrep
- Utilities: curl, jq, docker
- AI tools: claude-code, gemini-cli, amazon-q-cli
- Node.js: volta
- Cloud: google-cloud-sdk

### Shell Aliases
- `lg` → `lazygit`
- `la` → `ls -a`
- `ccd` → `claude --dangerously-skip-permissions`
- `cl` → `clear`

## Working with this Configuration

When modifying configurations:
1. Edit the appropriate `.nix` file
2. Run `nix fmt` to ensure proper formatting
3. Test changes with `nix flake check`
4. Apply changes using the update commands above

Note: The configuration uses experimental Nix features (flakes) which must be enabled in the Nix settings.

## Common Tasks

### Adding new packages
- For user packages: Edit `home.packages` in `nix/home-manager/default.nix`
- For GUI apps: Add to `homebrew.casks` in `nix/nix-darwin/default.nix`
- After adding, run `nix run .#update` to apply

### Modifying shell aliases
- Edit `programs.zsh.shellAliases` in `nix/home-manager/default.nix`
- Changes take effect after running the update command

### Adding new program configurations
- Create a new file in `nix/home-manager/programs/<program>/default.nix`
- Import it in `nix/home-manager/default.nix`
- See wezterm configuration as an example

## Compact Instructions

When compacting, preserve the following:
- Current task context and goals
- File paths being edited and their purpose
- Test results and error messages
- Decisions already made and their rationale
- Key variable names and function signatures being worked on

## Important Notes

- The Neovim configuration references a symlink to `${pwd}/conf` which points to `~/dotfiles-nix/home-manager/console/neovim/conf` - this path may need adjustment
- WezTerm is installed via Homebrew's nightly cask, not Nix
- The configuration includes both Nix packages and Homebrew casks for different types of applications

### Zellij タブ閉じる時の注意

**重要**: zellij タブを閉じる時は必ず `close-tab-by-id` を使うこと。`go-to-tab-name` + `close-tab` の組み合わせは事故の元。

理由: `go-to-tab-name "<name>"` は対象タブが存在しないと**フォーカスを移動せず黙って失敗** (exit code 2)。続けて `close-tab` を実行すると**現在フォーカスのタブが閉じてしまう**。 `2>/dev/null` でエラーを潰していると気付かず、別のタブを破壊する事故が起きる。

```bash
# ❌ 危険: tab name が存在しないと、フォーカスのある別のタブを閉じてしまう
zellij action go-to-tab-name "$TAB_NAME" 2>/dev/null
zellij action close-tab

# ✅ 安全: ID で明示的に指定 (なければ noop)
TAB_ID=$(zellij action list-tabs --json | jq -r --arg n "$TAB_NAME" '.[] | select(.name == $n) | .tab_id')
[ -n "$TAB_ID" ] && zellij action close-tab-by-id "$TAB_ID"
```

参考実装: `nix/home-manager/programs/claude-code/close-merged-review-tab.sh`