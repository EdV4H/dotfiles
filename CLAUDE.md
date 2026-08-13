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
  - Session variables (Google Cloud project, etc.)
  - mise (node / npm グローバルツール管理)
  
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
- Terminal: wezterm, herdr (terminal multiplexer)
- Editor: neovim
- Search: ripgrep
- Utilities: curl, jq, docker
- AI tools: claude-code, gemini-cli, amazon-q-cli
- Node.js: mise (node / ni / ccusage をグローバル管理)
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

### herdr (ターミナルマルチプレクサ)

zellij から移行済み。 スクリプトから触るときの要点だけ:

- **タブ/ペインの操作は必ず ID 指定。** `herdr tab close <tab_id>` / `herdr pane close <pane_id>` は
  ID 必須なので、 zellij 時代の「裸の `close-tab` がフォーカス中のタブを巻き込む」事故は起きない。
  自分のタブ/ペインは `$HERDR_TAB_ID` / `$HERDR_PANE_ID` で分かる。
- **CLI の出力は socket API のエンベロープ付き JSON。** 配列は `.result.tabs[]` / `.result.panes[]` に
  入っている (`.[]` ではない)。 エラー時は `{"error":{...}}` を出して exit 1。
- **`tab create` は新タブの root pane まで返す** (`.result.root_pane.pane_id`)。 pane を引き直さなくてよい。
- **コマンド付きでタブ/ペインを生やす形は無い。** `tab create` → `pane run <pane_id> "<cmd>"` の 2 段。
  `pane run` はペインのシェルに打ち込んで Enter まで送るので、 引数は `printf %q` でクォートする。
  Enter を送りたくない (旧 `start_suspended` 相当) なら `pane send-text`。
- **タブ/ペインはコマンドが終了しても消えない** (`--close-on-exit` 相当が無い)。 後片付けは明示的に。
- socket は `~/.config/herdr/[sessions/<name>/]herdr.sock` の固定パス。 `$TMPDIR` に依存しないので
  launchd からも Claude Code の Bash サンドボックスからも同じサーバーに届く。

専用ヘルパー (使えるなら必ずこっちを優先):

- `herdr-tab-id <label>` → label 一致のタブ ID を引く (無ければ空 + exit 1)
- `close-conflict-tab <repo> <num>` → `Conflict: <repo>#<num>` タブを閉じる (pr-conflict-check 用)
- `close-merged-review-tab <num> <repo>` → `Review: <repo>#<num>` タブを閉じる (gh-review-watcher 用)
- `open-review-tab <url> <num> <repo>` → `Review: <repo>#<num>` タブを開いて review-pr を走らせる
- `herdr-bootstrap <work|cockpit>` → 旧 zellij KDL レイアウト相当の workspace を組み直す

参考実装: `nix/home-manager/programs/herdr/`, `nix/home-manager/programs/claude-code/close-conflict-tab.sh`

## PC 移行手順

新しい Mac に乗り換えるときの手順。 dotfiles (nix) で OS / dotfile / launchd / skills は再現できるので、 ここでは **nix 管理外の state** (gitignored な `.env` / `.npmrc` / SSH 鍵 / cache 等) と **クローン済み repo** の引き継ぎだけを扱う。

実装は `nix/home-manager/programs/claude-code/migration/` に 3 スクリプトあり、 `~/.local/bin/` に登録済み:

- `migration-export` — gitignored secret + `~/.ssh` 等を tar.gz に固める
- `migration-list-repos` — `~/Projects/` 配下の repo path と remote URL を TSV 化
- `migration-restore` — 新 PC で展開 + 再 clone

### 旧 PC 側

```bash
# dry-run でまず中身を確認
MIGRATION_DRY_RUN=1 ~/.local/bin/migration-export

# 実行
~/.local/bin/migration-export
~/.local/bin/migration-list-repos

# 生成物 (~/migration-bundle-<ts>.{tar.gz,sha256,repos.txt}) を AirDrop / scp で新 PC へ
```

### 新 PC 側

```bash
# 1. nix セットアップ
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# 2. dotfiles を clone (gh CLI 未認証段階なので https 経由)
git clone https://github.com/EdV4H/dotfiles ~/dotfiles
cd ~/dotfiles

# 2.5. 会社端末で Netskope (SWG) が常駐している場合、 cache.nixos.org の HTTPS を
# MITM するため nix-daemon が cache から binary を取れない → local build 嵐になる。
# Netskope CA を nix の信頼バンドルに追加してから nix run .#update する。
#   (Netskope クライアントが無い PC ではこの step はスキップ可)
if pgrep -f "Netskope Client.app" >/dev/null; then
  security find-certificate -a -p -c "ca.atrae.goskope.com" \
    /Library/Keychains/System.keychain | sudo tee /etc/ssl/atrae-netskope-ca.pem
  # nix-darwin の security.pki.certificateFiles で永続化される。 ただし初回 bootstrap は
  # まだ反映前なので、 nix-daemon 用のバンドルに手動 append:
  sudo bash -c '
    cp /etc/static/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt.tmp
    cat /etc/ssl/atrae-netskope-ca.pem >> /etc/ssl/certs/ca-certificates.crt.tmp
    mv /etc/ssl/certs/ca-certificates.crt.tmp /etc/ssl/certs/ca-certificates.crt
  '
  sudo launchctl kickstart -k system/org.nixos.nix-daemon
fi

nix run .#update

# 3. bundle を展開して repo を再 clone (gh auth は先に通すこと)
gh auth login
~/.local/bin/migration-restore ~/Downloads/migration-bundle-*.tar.gz ~/Downloads/migration-bundle-*.repos.txt

# 4. 他の認証
aws sso login   # profile ごとに
gcloud auth login && gcloud auth application-default login
docker login

# 5. node 環境 (mise が global=latest で自動管理。特定バージョンが要る時のみ)
mise use -g node@<version>

# 6. Kiro CLI を使う場合 (退避された zprofile を戻す)
[ -f ~/.zprofile.kiro.bak ] && mv ~/.zprofile ~/.zprofile.hm.bak && mv ~/.zprofile.kiro.bak ~/.zprofile

# 7. poke-mate を使う場合: skill の symlink を貼る
#    (poke-mate repo 内に skill 本体があり、 ~/.claude/skills から symlink で参照する設計)
if [ -d ~/Projects/poke-mate ]; then
  ln -sfn ~/Projects/poke-mate/skills/build-party-with-me ~/.claude/skills/poke-mate-build-party-with-me
  ln -sfn ~/Projects/poke-mate/skills/review-party ~/.claude/skills/poke-mate-review-party
fi

# 8. herdr: Claude Code 連携を入れる (~/.claude/settings.json に hook を書き込む。
#    nix 管理外なので新 PC で 1 回だけ手動実行が要る)
herdr integration install claude
herdr integration status

# 9. herdr のワークスペースを組み直す (旧 zellij の work.kdl / cockpit.kdl 相当)
#    herdr を起動してから、 別ペイン or 起動後のシェルで:
herdr-bootstrap work
# herdr-bootstrap cockpit   # 必要なら
```

### 引き継がないもの

`node_modules` / build 成果物 / `~/.local/share/mise/` (ランタイム実体) / Claude Desktop の state / aws/gcloud の認証 SQLite — すべて新 PC で再構築 (token 失効リスクと keychain 結合の複雑さを避けるため)。