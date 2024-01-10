# AtCoder用Rust開発環境
## 概要
- vscodeのdevcontainerを使用してAtCoder向けRust環境を構築するツール群
- Pythonもインストールされる
    - [ahc_tester](https://github.com/r3yohei/ahc_tester) を使用できるようにするため
## 使い方
### 環境構築
- リポジトリをクローンする
- vscodeで開く
```bash
code atcoder-rust-devcontainer
```
- reopen in containerする
    - 初回やDockerfileを編集した後はビルドされるので遅い(約40~50分．．．)
### コンテスト参加
- コンテストディレクトリを作成 
```bash
cargo_compete_new.sh ahcXXX
```
- 提出など
```bash
cd ./src/contest/ahcXXX
cargo compete s a --no-test
```