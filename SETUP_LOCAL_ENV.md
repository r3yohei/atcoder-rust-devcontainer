# AtCoder Heuristic ローカル環境セットアップガイド

Docker を使用せずに、`docker/Dockerfile` と同等の開発環境を構築する手順です。

## 前提条件

- **OS**: Ubuntu 24.04 および互換ディストリビューション（Debian 等）
- **Rust**: バージョン **1.89.0** を使用

## クイックスタート

```bash
# プロジェクトルートで実行
cd /path/to/atcoder-heuristic
chmod +x setup-atcoder-env.sh
./setup-atcoder-env.sh

# 環境を有効化（毎回または .bashrc に追記）
source ~/.local/atcoder-heuristic-env/activate
```

## 詳細手順

### 1. セットアップスクリプトの実行

```bash
./setup-atcoder-env.sh [ENV_DIR]
```

- `ENV_DIR`: 環境のインストール先（省略時: `~/.local/atcoder-heuristic-env`）
- 例: `./setup-atcoder-env.sh ./venv` でプロジェクト直下に作成

### 2. システムパッケージ

最初の実行時に、以下のパッケージが不足している場合はインストールを促されます。

```bash
sudo apt-get update
sudo apt-get install -y \
  wget git unzip zip tar vim curl gcc fd-find libssl-dev pkg-config \
  build-essential jq software-properties-common python3-pip xsel nodejs npm
```

### 3. 環境の有効化

作業前に毎回実行するか、`.bashrc` に追記してください。

```bash
# 毎回
source ~/.local/atcoder-heuristic-env/activate

# .bashrc に追記（永続化）
echo '[[ -f "$HOME/.local/atcoder-heuristic-env/activate" ]] && source "$HOME/.local/atcoder-heuristic-env/activate"' >> ~/.bashrc
```

## インストールされる主な構成要素

| 項目 | 内容 |
|------|------|
| **Miniconda** | Python 3.11 + ipykernel, seaborn, plotly, optuna, scikit-learn, scipy, pulp, ray 等 |
| **Node.js** | n 経由で LTS + Yarn（ビジュアライザ用） |
| **Rust** | 1.89.0 + rustfmt, wasm-pack |
| **Rust クレート** | eza, bat, cargo-compete, cargo-edit, cargo-snippet |

## 使用方法

### cargo compete

```bash
# コンテスト作成（プロジェクトルートで）
cargo compete new <contest_id>

# 提出（コンテストディレクトリで）
cd src/contest/<contest_id>
cargo compete submit a --no-test
```

### online-judge-tools

`pip install --user online-judge-tools` により `~/.local/bin` にインストールされます。  
環境有効化時に PATH に含まれるため、`oj` コマンドが利用できます。

## entrypoint.sh 相当の処理について

Docker の `entrypoint.sh` では以下を行っていますが、ローカル環境では手動対応が必要です。

1. **VSCode 設定**: `.vscode/settings.json` は `.devcontainer/settings.example.json` を参考に手動で作成
2. **cargo compete login**: 初回に `cargo compete login atcoder` と `cargo compete login yukicoder` を実行
3. **git safe.directory**: 必要に応じて `git config --global --add safe.directory <path>` を実行

## トラブルシューティング

### Rust 1.89.0 がインストールできない

`rustup toolchain list` で利用可能なバージョンを確認してください。  
別バージョンを使う場合は、`setup-atcoder-env.sh` 先頭の `RUST_VERSION` を変更して再実行してください。

### conda パッケージでエラーが出る

`solver classic` を有効にした上で、問題のパッケージだけ別途インストールしてください。

```bash
source "$ENV_DIR/activate"
conda config --set solver classic
conda install -c conda-forge <パッケージ名>
```

### システムに既存の Node / Rust がある場合

環境有効化後は、`ENV_DIR` 内の Node / Rust が PATH の先に来るため、この環境のツールが優先されます。
