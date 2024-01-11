# AtCoder用Rust開発環境
## 概要
- vscodeのdevcontainerを使用してAtCoder向けRust環境を構築するツール群
- Pythonもインストールされる
    - [ahc_tester](https://github.com/r3yohei/ahc_tester) を使用できるようにするため
## 使い方
### 環境構築
- リポジトリをクローンする
- docker imageをビルドする
```bash
cd ./docker
./build.sh
```
- `.env`を作成する
    - `.env.example`を編集し，ログインに必要な情報を環境変数化する
- vscodeで開く
```bash
code atcoder-rust-devcontainer
```
- reopen in containerする
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
- 自動テスト等は [ahc_tester](https://github.com/r3yohei/ahc_tester) を参照