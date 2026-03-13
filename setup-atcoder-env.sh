#!/bin/bash
#
# AtCoder Heuristic 用ローカル環境セットアップスクリプト
# Docker コンテナと同等の開発環境を構築します。
#
# 使用法:
#   ./setup-atcoder-env.sh [ENV_DIR]
#
# ENV_DIR: 環境のインストール先（デフォルト: ~/.local/atcoder-heuristic-env）

set -e

# インストール先
ENV_DIR="${1:-$HOME/.local/atcoder-heuristic-env}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

# Rust バージョン（ユーザー指定）
RUST_VERSION="1.89.0"

echo "=========================================="
echo "AtCoder Heuristic 環境セットアップ"
echo "=========================================="
echo "インストール先: $ENV_DIR"
echo "プロジェクト: $PROJECT_ROOT"
echo "Rust バージョン: $RUST_VERSION"
echo "=========================================="

mkdir -p "$ENV_DIR"
cd "$ENV_DIR"

# -----------------------------------------------------------------------------
# 1. システムパッケージ（要 sudo）
# -----------------------------------------------------------------------------
echo ""
echo "[1/6] システムパッケージの確認..."

# cmdtest は Yarn パッケージマネージャと名前が衝突するため削除
if command -v yarn &>/dev/null && yarn --version 2>&1 | grep -q "scenarios"; then
    echo "  cmdtest を削除しています（Yarn との衝突を解消）..."
    sudo apt remove -y cmdtest 2>/dev/null || true
fi

REQUIRED_PACKAGES=(
    wget git unzip zip tar vim curl gcc fd-find libssl-dev pkg-config
    build-essential jq software-properties-common python3-pip xsel
    nodejs npm
)

MISSING_PACKAGES=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l "$pkg" &>/dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "以下のパッケージをインストールしてください:"
    echo "  sudo apt-get update && sudo apt-get install -y ${MISSING_PACKAGES[*]}"
    read -p "今すぐインストールしますか? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    else
        echo "スキップしました。後で手動でインストールしてください。"
    fi
else
    echo "  必要なシステムパッケージは揃っています。"
fi

# -----------------------------------------------------------------------------
# 2. Miniconda
# -----------------------------------------------------------------------------
echo ""
echo "[2/6] Miniconda のセットアップ..."

MINICONDA_PATH="$ENV_DIR/miniconda3"
if [ ! -d "$MINICONDA_PATH" ]; then
    echo "  Miniconda をダウンロード・インストール中..."
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-py311_23.11.0-2-Linux-x86_64.sh
    bash Miniconda3-py311_23.11.0-2-Linux-x86_64.sh -b -p "$MINICONDA_PATH"
    rm Miniconda3-py311_23.11.0-2-Linux-x86_64.sh
fi

# conda を有効化
eval "$("$MINICONDA_PATH/bin/conda" shell.bash hook)"

conda config --set solver classic 2>/dev/null || true

# Python パッケージ（conda）
echo "  conda パッケージをインストール中..."
conda install -n base ipykernel --update-deps --force-reinstall -y 2>/dev/null || true
conda install -c conda-forge -c plotly -y \
    seaborn plotly nbformat python-kaleido optuna statsmodels scikit-learn scipy \
    2>/dev/null || true

# pip パッケージ
echo "  pip パッケージをインストール中..."
"$MINICONDA_PATH/bin/pip" install --upgrade pip
"$MINICONDA_PATH/bin/pip" install pulp japanize-matplotlib 'ray[default]'
"$MINICONDA_PATH/bin/pip" install --user online-judge-tools 2>/dev/null || true
# online-judge-tools は --user の場合 ~/.local/bin にインストールされる

# -----------------------------------------------------------------------------
# 3. Node.js (n + LTS) と Yarn
# -----------------------------------------------------------------------------
echo ""
echo "[3/6] Node.js のセットアップ..."

export N_PREFIX="$ENV_DIR/n"
export PATH="$N_PREFIX/bin:$PATH"
mkdir -p "$N_PREFIX/bin"

# npm のグローバルインストール先を ENV_DIR 内に設定（sudo 不要にする）
"$N_PREFIX/bin/npm" config set prefix "$N_PREFIX" 2>/dev/null || npm config set prefix "$N_PREFIX"

# npm はカレントディレクトリに package.json があることを期待するため、
# 空の ENV_DIR で実行すると ENOENT になる。一時的に /tmp に移動して実行する
NPM_SAFE_DIR="$(mktemp -d)"
trap 'rm -rf "$NPM_SAFE_DIR"' EXIT
(
    cd "$NPM_SAFE_DIR"
    if ! command -v n &>/dev/null; then
        echo "  n をインストール中..."
        npm install -g n
    fi
)

node_major=$(node -v 2>/dev/null | cut -d. -f1 | tr -d v); node_major=${node_major:-0}
if ! command -v node &>/dev/null || [ "${node_major:-0}" -lt 20 ]; then
    echo "  Node.js LTS をインストール中..."
    n lts
fi

# hash -r で npm のパス解決を更新（n 導入後は N_PREFIX の npm を使う必要がある）
hash -r 2>/dev/null || true

# Yarn: cmdtest の yarn でないことを確認してからインストール
(
    cd "$NPM_SAFE_DIR"
    # N_PREFIX の npm を明示的に使用（システム npm との競合を避ける）
    NPM_CMD="$N_PREFIX/bin/npm"
    [ -x "$NPM_CMD" ] || NPM_CMD="npm"
    if ! command -v yarn &>/dev/null; then
        echo "  Yarn をインストール中..."
        "$NPM_CMD" install -g yarn
    elif yarn --version 2>&1 | grep -q "scenarios"; then
        echo "  cmdtest の yarn を検出。正しい Yarn をインストール中..."
        sudo apt remove -y cmdtest 2>/dev/null || true
        "$NPM_CMD" install -g yarn
    fi
)

# -----------------------------------------------------------------------------
# 4. Rust (1.89.0)
# -----------------------------------------------------------------------------
echo ""
echo "[4/6] Rust $RUST_VERSION のセットアップ..."

RUST_HOME="$ENV_DIR/rust"
RUSTUP_HOME="$RUST_HOME/rustup"
CARGO_HOME="$RUST_HOME/cargo"
export RUSTUP_HOME CARGO_HOME
export PATH="$CARGO_HOME/bin:$PATH"

mkdir -p "$RUST_HOME"

if [ ! -f "$CARGO_HOME/bin/cargo" ]; then
    echo "  rustup をインストール中..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain "$RUST_VERSION" --no-modify-path
else
    echo "  Rust は既にインストール済み。ツールチェーンを更新..."
    rustup default "$RUST_VERSION" 2>/dev/null || rustup toolchain install "$RUST_VERSION" && rustup default "$RUST_VERSION"
fi

# -----------------------------------------------------------------------------
# 5. wasm-pack
# -----------------------------------------------------------------------------
echo ""
echo "[5/6] wasm-pack のインストール..."

if ! command -v wasm-pack &>/dev/null; then
    curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
fi

# -----------------------------------------------------------------------------
# 6. Rust クレート
# -----------------------------------------------------------------------------
echo ""
echo "[6/6] Rust クレートのインストール..."

rustup component add rustfmt 2>/dev/null || true
cargo install eza bat cargo-compete cargo-edit cargo-snippet --features="binaries" 2>/dev/null || true

# -----------------------------------------------------------------------------
# activate スクリプトの生成
# -----------------------------------------------------------------------------
echo ""
echo "activate スクリプトを生成しています..."

cat > "$ENV_DIR/activate" << 'ACTIVATE_EOF'
# AtCoder Heuristic 環境を有効化
# 使用方法: source <ENV_DIR>/activate

export ENV_DIR="ENV_DIR_PLACEHOLDER"
export RUST_HOME="${ENV_DIR}/rust"
export RUSTUP_HOME="${RUST_HOME}/rustup"
export CARGO_HOME="${RUST_HOME}/cargo"
export N_PREFIX="${ENV_DIR}/n"
export PATH="${ENV_DIR}/miniconda3/bin:${N_PREFIX}/bin:${CARGO_HOME}/bin:${HOME}/.local/bin:${PATH}"
ACTIVATE_EOF

# プレースホルダーを実際のパスに置換
sed -i "s|ENV_DIR_PLACEHOLDER|$ENV_DIR|g" "$ENV_DIR/activate"

# -----------------------------------------------------------------------------
# 完了
# -----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "セットアップ完了"
echo "=========================================="
echo ""
echo "環境を有効化するには:"
echo "  source $ENV_DIR/activate"
echo ""
echo "または .bashrc に以下を追加:"
echo "  [[ -f \"$ENV_DIR/activate\" ]] && source \"$ENV_DIR/activate\""
echo ""
