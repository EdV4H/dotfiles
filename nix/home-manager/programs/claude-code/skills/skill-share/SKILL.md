---
name: skill-share
version: 1.0.0
description: "Share your Claude Code Skills with the team via Notion. Discover and install Skills others have shared, and your own Skills are auto-published in return."
---

# skill-share

Notion 上の共有データベースを介して、チームでSkillsのナレッジを共有するSkill。

- `recommend`: Notion から他人の Skills を取得し、あなたの作業文脈に合うものをおすすめ → 選択でインストール
- `publish`: 自分の Skills を Notion にアップロード（ギブ・アンド・テイク）
- `sync`: publish + recommend を順に実行

## 前提条件

### 1. Notion DB の用意（チームで1度だけ）

下記スキーマで Notion データベースを作成し、その DB ID をチームに共有する。

| プロパティ | 型 | 内容 |
|-----------|-----|------|
| `Name` | Title | Skill 名 |
| `Owner` | Rich text | アップロード者 |
| `OwnerEmail` | Email | 識別用 |
| `Type` | Select | `skill` / `agent` |
| `Scope` | Select | `user` / `project` |
| `Description` | Rich text | frontmatter の `description` |
| `Tags` | Multi-select | LLM が抽出 |
| `Version` | Rich text | frontmatter の `version` |
| `SourcePath` | Rich text | アップロード元のローカルパス |
| `UpdatedAt` | Date | 最終更新 |

ページ本文には SKILL.md 全文をコードブロックで貼る。

### 2. ローカル設定ファイルの配置

`~/.config/claude-skill-share/.env` に DB の識別子を書く（git 管理外、各自手動）:

```env
NOTION_DATABASE_ID=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NOTION_DATA_SOURCE_URL=collection://xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

`NOTION_DATABASE_ID` はページ参照用、`NOTION_DATA_SOURCE_URL` は MCP のクエリ用（`notion-query-data-sources` の `data_source_url`）。サンプルは dotfiles の `.env.sample` を参照。

### 3. Notion MCP の認証

Notion MCP (`plugin:Notion:notion`) が `Connected` になっていること。`claude mcp list` で確認し、`Needs authentication` の場合は Claude Code 側で再認証してから実行する。

## 引数

```
/skill-share [recommend|publish|sync] [--scope=user|project|both] [--dry-run]
```

- 第1引数（サブコマンド、省略時は `recommend`）: `recommend` / `publish` / `sync`
- `--scope`: `publish` / `sync` 時のアップロード対象範囲（既定: `user`）
  - `user`: `~/.claude/skills/` 配下
  - `project`: 現在のリポジトリの `.claude/skills/` 配下
  - `both`: 両方
- `--dry-run`: Notion への書き込みを行わず、対象一覧と差分のみ表示

## Behavior

### Step 0: 共通の前処理

```bash
ENV_FILE="$HOME/.config/claude-skill-share/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "未設定: $ENV_FILE を作って NOTION_DATABASE_ID と NOTION_DATA_SOURCE_URL を書いてください（dotfiles の .env.sample を参照）"
  exit 1
fi
set -a; . "$ENV_FILE"; set +a

OWNER_EMAIL=$(git config user.email)
OWNER_NAME=$(git config user.name)
```

`NOTION_DATABASE_ID` または `NOTION_DATA_SOURCE_URL` が空なら同様にエラー終了。

Notion MCP が利用可能か（`mcp__plugin_Notion_notion__*` ツールが見えるか）を確認。利用できない場合は「Notion MCP に再認証してから再実行してください」と案内して終了。

---

### Subcommand: `publish`

#### Step P1: スコープ決定と走査

```bash
SCOPE="${SCOPE:-user}"  # 引数 --scope から
case "$SCOPE" in
  user) ROOTS=("$HOME/.claude/skills") ;;
  project) ROOTS=("$(pwd)/.claude/skills") ;;
  both) ROOTS=("$HOME/.claude/skills" "$(pwd)/.claude/skills") ;;
esac

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  find "$root" -maxdepth 2 -name SKILL.md
done
```

検出したパス一覧を表示。

#### Step P2: 各 SKILL.md のパースと前処理

各 SKILL.md について:

1. frontmatter を抽出（`name`, `version`, `description`）
2. 本文を読み込む
3. **個人情報チェック**: 本文に以下のパターンが含まれるかチェックし、見つかればユーザーに表示して確認
   - 絶対パス（`/Users/<name>/...`, `/home/<name>/...`）
   - メールアドレス
   - API トークン風の長い英数字

   見つかった場合は AskUserQuestion で「マスク」「そのまま公開」「このSkillだけスキップ」を選ばせる。
4. **Tags 抽出**: SKILL.md 本文を見て、用途・言語・依存MCP などを 3〜7 個のタグとして LLM が抽出する（例: `["nix", "git", "worktree"]`）

#### Step P3: Notion DB に upsert

各 Skill について Notion DB を `OwnerEmail`+`Name`+`Scope` でクエリ:

```
mcp__plugin_Notion_notion__notion-query-data-sources
  data_source_url: $NOTION_DATA_SOURCE_URL
  filter: OwnerEmail = $OWNER_EMAIL AND Name = $name AND Scope = $scope
```

- ヒット → `notion-update-page` でプロパティと本文を上書き
- 0件 → `notion-create-pages` で新規作成

`--dry-run` の場合は実際の書き込みをスキップして「+追加 / ~更新」のみ表示。

#### Step P4: サマリー

```
[skill-share] publish 完了
  対象: 12件
  追加: 8 / 更新: 4 / スキップ: 0
  個人情報マスク: 2件
```

---

### Subcommand: `recommend`

#### Step R1: Notion から候補取得

```
mcp__plugin_Notion_notion__notion-query-data-sources
  data_source_url: $NOTION_DATA_SOURCE_URL
  filter: OwnerEmail != $OWNER_EMAIL  # 自分以外
```

取得件数を表示。

#### Step R2: ローカル既インストールを除外

```bash
INSTALLED=$(ls "$HOME/.claude/skills/" 2>/dev/null)
```

`Name` が一致するものは候補から除外（バージョン違いがあるかもしれないが、シンプル化のため一旦除外）。

#### Step R3: ユーザー文脈の収集

```bash
pwd
git log --oneline -10 2>/dev/null
ls CLAUDE.md flake.nix package.json pyproject.toml 2>/dev/null
```

加えて `~/.claude/skills/` の既存 Skill 名一覧（どんな分野を好むかの推定材料）。

#### Step R4: LLM による推薦

候補リスト（Name + Description + Tags + Owner）と、Step R3 で集めた文脈を見て、Claude が上位 5 件をピック。各候補について短い推薦理由を1文ずつ書く。

#### Step R5: ユーザーに提示してインストール選択

`AskUserQuestion`（multiSelect: true）で「インストールしたいものを選んでください」と聞く。1件も選ばれなければ終了。

#### Step R6: インストール

選択された各 Skill について:

1. Notion ページの本文（SKILL.md コードブロック）を取得
2. 配置先を確認:
   - **一時的に試す**: `~/.claude/skills/<name>/SKILL.md` に直接書く
   - **永続化（推奨）**: dotfilesの `nix/home-manager/programs/claude-code/skills/<name>/SKILL.md` に書く → 続けて `nix run .#update` を促す
3. ローカルに同名 Skill があれば「上書きしますか？」と確認

#### Step R7: サマリー

```
[skill-share] recommend 完了
  インストール: nix-flake-update (Alice), claude-skill-test (Bob)
  配置先: ~/dotfiles/nix/home-manager/programs/claude-code/skills/
  → `nix run .#update` を実行してください
```

---

### Subcommand: `sync`

`publish` を実行 → 続けて `recommend` を実行。各サブコマンドのフローをそのまま順に実行する。

---

## 注意事項

- **Notion MCP が未認証なら何もしない**: 認証エラーをユーザーに分かりやすく伝えて終了する。
- **個人情報の扱い**: `publish` 時に必ず本文をスキャンする。マスク処理はユーザー確認の上でのみ行う（自動マスクはしない）。
- **同名衝突**: `recommend` でのインストール時、ローカルに同名があれば必ず確認する。
- **dry-run の徹底**: 初めて使うときは `--dry-run` で何が公開されるかを確認することを強く推奨。
- **取り下げ**: 公開済みSkillの削除は本Skillの範囲外。Notion UI から手動で削除する。
