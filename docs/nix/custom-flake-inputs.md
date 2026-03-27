# カスタム Flake Inputs

> 自作の Rust TUI ツールを Nix flake input として管理し、dotfiles と一緒にインストールする。

## 課題

自作の CLI ツール（Rust 製）を macOS にインストールする方法が煩雑だった。`cargo install` は Nix のエコシステムと統合できず、バージョン管理も手動。

## 解決策

各ツールのリポジトリに `flake.nix` を定義し、dotfiles の flake input として参照する。`nix run .#update` で他のパッケージと一緒にインストール・更新される。

## 管理しているツール

### gh-review-watcher

GitHub のレビューリクエストを監視する TUI ツール。

```
リポジトリ: github:EdV4H/gh-review-watcher
```

### port-patrol

ローカルで使用中のポートを一覧・管理する TUI ツール。

```
リポジトリ: github:EdV4H/port-patrol
```

### gws (Google Workspace CLI)

Google Workspace API を操作する CLI。

```
リポジトリ: github:googleworkspace/cli
```

## セットアップ

### 1. flake.nix に input を追加

```nix
{
  inputs = {
    # 既存の inputs...
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # カスタムツール
    gh-review-watcher = {
      url = "github:EdV4H/gh-review-watcher";
      inputs.nixpkgs.follows = "nixpkgs";  # nixpkgs を共有してビルドキャッシュを効率化
    };
    port-patrol = {
      url = "github:EdV4H/port-patrol";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gws = {
      url = "github:googleworkspace/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, gh-review-watcher, port-patrol, gws, ... }@inputs:
    # ...
  ;
}
```

### 2. Home Manager の packages に追加

```nix
# nix/home-manager/default.nix
home.packages = with pkgs; [
  # 通常の Nix パッケージ
  git
  gh
  # ...

  # カスタム flake inputs
  inputs.gws.packages.${pkgs.system}.default
  inputs.gh-review-watcher.packages.${pkgs.system}.default
  inputs.port-patrol.packages.${pkgs.system}.default
];
```

### 3. inputs を module に渡す

```nix
# flake.nix の outputs 内
homeConfigurations.myHomeConfig = home-manager.lib.homeManagerConfiguration {
  pkgs = pkgs;
  extraSpecialArgs = {
    inherit inputs;  # これで各モジュールから inputs にアクセスできる
  };
  modules = [ ./nix/home-manager/default.nix ];
};
```

## 自作ツールの flake.nix テンプレート

Rust 製ツールの場合:

```nix
{
  description = "My Rust TUI tool";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "my-tool";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
        }
      );
    };
}
```

## 主要ファイル

| ファイル | 役割 |
|---------|------|
| [`flake.nix`](../../flake.nix) | Flake inputs の定義 |
| [`nix/home-manager/default.nix`](../../nix/home-manager/default.nix) | パッケージのインストール設定 |

## カスタマイズ

### 自分のツールを追加する

1. ツールのリポジトリに `flake.nix` を作成（上記テンプレート参照）
2. dotfiles の `flake.nix` に input を追加
3. `nix/home-manager/default.nix` の `home.packages` に追加
4. `nix run .#update` を実行

### 特定バージョンを固定する

```nix
# 特定のコミットを参照
gh-review-watcher = {
  url = "github:EdV4H/gh-review-watcher/abc1234";
  inputs.nixpkgs.follows = "nixpkgs";
};

# 特定のタグを参照
gh-review-watcher = {
  url = "github:EdV4H/gh-review-watcher?ref=v1.0.0";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### nixpkgs.follows の意味

```nix
inputs.nixpkgs.follows = "nixpkgs";
```

これにより、ツールが使う nixpkgs を dotfiles と同じバージョンに揃える。ビルドキャッシュの共有が効率化され、ビルド時間が短縮される。

## Tips & 注意点

- **flake.lock**: `nix flake update` すると全 inputs が最新に更新される。特定の input のみ更新したい場合は `nix flake update gh-review-watcher`
- **ビルドキャッシュ**: 初回ビルドは時間がかかるが、2回目以降は差分のみビルドされる
- **クロスプラットフォーム**: `flake.nix` で複数の system を定義しておくと、Linux でも同じツールを使える
- **Cargo.lock のコミット**: Rust プロジェクトでは `Cargo.lock` をコミットしておく必要がある（`cargoLock.lockFile` で参照するため）
