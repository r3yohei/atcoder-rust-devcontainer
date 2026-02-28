#!/bin/bash
#
# 新規コンテスト参加用 Rust プロジェクト作成スクリプト
#
# 使用法: ./new-contest.sh <contest_id>
# 例: ./new-contest.sh ahcXXX
#
# 更新対象: ワークスペースの .vscode/settings.json
# ワークスペースルートは未指定時 ~/work。別のルート: WORKSPACE_ROOT=/path/to/workspace ./new-contest.sh ahcXXX

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
# ワークスペースの .vscode/settings.json を更新対象に
# WORKSPACE_ROOT 未指定時はホームディレクトリ直下の work
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$HOME/work}"
WORKSPACE_SETTINGS_JSON="$WORKSPACE_ROOT/.vscode/settings.json"

if [ "$#" -ne 1 ]; then
    echo "使用法: $0 <contest_id>"
    echo "例: $0 ahcXXX"
    exit 1
fi

CONTEST="$1"
CONTEST_DIR="$PROJECT_ROOT/src/contest/$CONTEST"

# compete.toml [template] src および [template.new] dependencies と同等の埋め込みテンプレート
# heredoc でクォート問題を回避
SRC_TEMPLATE=$(cat << 'SRC_EOF'
#![allow(non_snake_case, unused)]

use itertools::Itertools;
use proconio::{marker::*, source::line::LineSource, *};
use rand::prelude::*;
use rand::seq::SliceRandom;
use rand_pcg::Pcg64Mcg;
use rustc_hash::FxHashSet;
use std::io::*;
use std::{cmp::*, vec};
use std::{collections::*, fmt::format};
use superslice::Ext;

const INF: i64 = 1 << 60;
const SEED: u128 = 8_192;
const DIJ: [(usize, usize); 4] = [(0, !0), (0, 1), (!0, 0), (1, 0)];
const DIR: [char; 4] = ['L', 'R', 'U', 'D'];
const TL: f64 = 1.989;

pub fn get_time() -> f64 {
    static mut STIME: f64 = -1.0;
    let t = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap();
    let ms = t.as_secs() as f64 + t.subsec_nanos() as f64 * 1e-9;
    unsafe {
        if STIME < 0.0 {
            STIME = ms;
        }
        #[cfg(feature = "local")]
        {
            (ms - STIME) * 1.5
        }
        #[cfg(not(feature = "local"))]
        {
            ms - STIME
        }
    }
}

pub trait ChangeMinMax {
    fn chmin(&mut self, x: Self) -> bool;
    fn chmax(&mut self, x: Self) -> bool;
}
impl<T: PartialOrd> ChangeMinMax for T {
    fn chmin(&mut self, x: Self) -> bool {
        *self > x && {
            *self = x;
            true
        }
    }
    fn chmax(&mut self, x: Self) -> bool {
        *self < x && {
            *self = x;
            true
        }
    }
}

#[derive(Clone, Debug)]
struct Input {}
impl Input {
    fn new() -> Self {
        todo!();
    }
}

#[derive(Clone, Debug)]
struct State {}
impl State {
    fn new(input: &Input) -> Self {
        todo!();
    }
}

fn main() {
    get_time();
}
SRC_EOF
)

DEPS_TEMPLATE='ac-library-rs = "=0.1.1"
once_cell = "=1.18.0"
pathfinding = "=4.3.0"
num = "=0.4.1"
num-integer = "=0.1.45"
num-iter = "=0.1.43"
num-traits = "=0.2.15"
ndarray = "=0.15.6"
nalgebra = "=0.32.3"
libm = "=0.2.7"
rand = { version = "=0.8.5", features = ["small_rng", "min_const_gen"] }
rand_pcg = "=0.3.1"
rand_distr = "=0.4.3"
superslice = "=1.0.0"
itertools = "=0.11.0"
itertools-num = "=0.1.3"
proconio = { version = "=0.4.5", features = ["derive"] }
rustc-hash = "=1.1.0"
smallvec = { version = "=1.11.0", features = ["const_generics", "const_new", "write", "union", "serde", "arbitrary"] }
'

if [ -d "$CONTEST_DIR" ]; then
    echo "プロジェクトが既に存在します: $CONTEST_DIR (settings.json の同期のみ実行)"
else
    echo "コンテスト '$CONTEST' のプロジェクトを作成しています..."

    # ディレクトリ作成
    mkdir -p "$CONTEST_DIR/src/bin"

    # src/bin/a.rs を作成
    echo "$SRC_TEMPLATE" > "$CONTEST_DIR/src/bin/a.rs"
    echo "  作成: $CONTEST_DIR/src/bin/a.rs"

    # -----------------------------------------------------------------------------
    # Cargo.toml を作成
    # -----------------------------------------------------------------------------
    BIN_NAME="${CONTEST}-a"
    ATCODER_URL="https://atcoder.jp/contests/${CONTEST}/tasks/${CONTEST}_a"

    cat > "$CONTEST_DIR/Cargo.toml" << CARGO_EOF
[profile.dev]
opt-level = 3

[package]
name = "$CONTEST"
version = "0.1.0"
edition = "2021"

[features]
local = []

[package.metadata.cargo-compete.bin]
$BIN_NAME = { alias = "a", problem = "$ATCODER_URL" }

[[bin]]
name = "$BIN_NAME"
path = "src/bin/a.rs"

[dependencies]
$DEPS_TEMPLATE

[dev-dependencies]
CARGO_EOF
    echo "  作成: $CONTEST_DIR/Cargo.toml"

    # -----------------------------------------------------------------------------
    # Cargo.lock をコピー（テンプレートがあれば）
    # -----------------------------------------------------------------------------
    if [ -f "$PROJECT_ROOT/template-cargo-lock.toml" ]; then
        cp "$PROJECT_ROOT/template-cargo-lock.toml" "$CONTEST_DIR/Cargo.lock"
        echo "  作成: $CONTEST_DIR/Cargo.lock"
    fi
fi

# -----------------------------------------------------------------------------
# settings.json の同期
# ワークスペースの .vscode/settings.json に rust-analyzer.linkedProjects を追加
# -----------------------------------------------------------------------------
# rust-analyzer.linkedProjects を追加（絶対パスで環境非依存）
# -----------------------------------------------------------------------------
CARGO_TOML_ABS="$PROJECT_ROOT/src/contest/$CONTEST/Cargo.toml"
LIB_CARGO_ABS="$PROJECT_ROOT/src/lib/Cargo.toml"

mkdir -p "$WORKSPACE_ROOT/.vscode"
TARGET_JSON="$WORKSPACE_SETTINGS_JSON"

if command -v jq &>/dev/null; then
    if [ ! -f "$TARGET_JSON" ]; then
        # ファイルが存在しない: 作成し、lib + src/contest 内の全 Cargo.toml を登録
        PATHS_JSON="[\"$LIB_CARGO_ABS\""
        while IFS= read -r p; do
            [ -n "$p" ] && PATHS_JSON="$PATHS_JSON, \"$p\""
        done < <(find "$PROJECT_ROOT/src/contest" -maxdepth 2 -name "Cargo.toml" 2>/dev/null | sort)
        PATHS_JSON="$PATHS_JSON]"
        if ! jq -n --argjson arr "$PATHS_JSON" '{"rust-analyzer.linkedProjects": $arr}' > "$TARGET_JSON.tmp"; then
            echo "エラー: settings.json の作成に失敗しました。"
            rm -f "$TARGET_JSON.tmp"
            exit 1
        fi
        mv "$TARGET_JSON.tmp" "$TARGET_JSON"
        echo "  作成: $TARGET_JSON (rust-analyzer.linkedProjects に既存プロジェクトを登録)"
    else
        # ファイルが存在する: JSON を検証し、今回のプロジェクトがなければ追加
        if ! jq empty "$TARGET_JSON" 2>/dev/null; then
            echo "エラー: $TARGET_JSON の JSON が不正です。手動で修正してください。"
            exit 1
        fi
        if jq -e --arg path "$CARGO_TOML_ABS" '(.["rust-analyzer.linkedProjects"] // [] | index($path)) != null' "$TARGET_JSON" &>/dev/null; then
            echo "  (既に rust-analyzer.linkedProjects に登録済み)"
        else
            if ! jq --arg path "$CARGO_TOML_ABS" '.["rust-analyzer.linkedProjects"] = (.["rust-analyzer.linkedProjects"] // []) + [$path]' "$TARGET_JSON" > "$TARGET_JSON.tmp"; then
                echo "エラー: $TARGET_JSON の書き込みに失敗しました。"
                rm -f "$TARGET_JSON.tmp"
                exit 1
            fi
            mv "$TARGET_JSON.tmp" "$TARGET_JSON"
            echo "  更新: $TARGET_JSON に $CARGO_TOML_ABS を追加"
        fi
    fi
else
    echo "  警告: jq がインストールされていません。手動で rust-analyzer.linkedProjects に以下を追加してください:"
    echo "    対象: $TARGET_JSON"
    echo "    追加: \"$CARGO_TOML_ABS\""
fi

echo ""
echo "完了: $CONTEST_DIR"
