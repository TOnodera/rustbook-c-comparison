## Hello, Cargo!

CargoはRustのビルドシステム兼パッケージマネージャです。
ほとんどのRustaceanはこのツールを使ってRustプロジェクトを管理しています。
なぜなら、Cargoは多くの仕事、たとえばコードのビルド、コードが依存するライブラリのダウンロード、それらのライブラリのビルドなどを扱ってくれるからです。
（コードが必要とするライブラリのことを*依存*（dependencies）と呼びます）

いままでに書いたようなごく単純なRustプログラムには依存がありません。
「Hello, world!」プロジェクトをCargoでビルドしても、Cargoの中のコードをビルドする部分しか使わないでしょう。
より複雑なRustプログラムを書くようになると依存を追加することになりますが、Cargoを使ってプロジェクトを開始したなら、依存の追加もずっと簡単になります。

Rustプロジェクトの大多数がCargoを使用しているので、これ以降、この本では、あなたもCargoを使用していると想定します。
もし[「インストール」][installation]節で紹介した公式のインストーラを使用したなら、CargoはRustと共にインストールされています。
Rustを他の方法でインストールした場合は、以下のコマンドをターミナルに入れて、Cargoがインストールされているか確認してください。

```console
$ cargo --version
```

バージョンナンバーが表示されたならインストールされています！
`command not found`などのエラーが表示された場合は、自分がインストールした方法についてのドキュメントを参照して、Cargoを個別にインストールする方法を調べてください。

### Cargoでプロジェクトを作成する

Cargoを使って新しいプロジェクトを作成し、元の「Hello, world!」プロジェクトとの違いを見ていきましょう。
*projects*ディレクトリ（または自分がコードを保存すると決めた場所）に戻ってください。
それから、OSに関係なく、以下を実行してください。

```console
$ cargo new hello_cargo
$ cd hello_cargo
```

最初のコマンドは*hello_cargo*という名の新しいディレクトリとプロジェクトを作成します。
プロジェクトを*hello_cargo*と名付けたので、Cargoはそれに関連するいくつかのファイルを同名のディレクトリに作成します。

*hello_cargo*ディレクトリに行き、ファイルの一覧を取得してください。
Cargoが2つのファイルと1つのディレクトリを生成してくれたことがわかるでしょう。
*Cargo.toml*ファイルと*src*ディレクトリがあり、*src*の中には*main.rs*ファイルがあります。

また、*.gitignore*ファイルと共に新しいGitリポジトリも初期化されています。
もし、すでに存在するGitリポジトリの中で`cargo new`を実行したなら、Git関連のファイルは作られません。
`cargo new --vcs=git`とすることで、この振る舞いを変更できます。

> 補足：Gitは一般的なバージョン管理システムです。
> `cargo new`コマンドに`--vcs`フラグを与えることで、別のバージョン管理システムを使用したり、何も使用しないようにもできます。
> 利用可能なオプションを確認するには`cargo new --help`を実行します。

お気に入りのテキストエディタで*Cargo.toml*を開いてください。
リスト1-2のコードのようになっているはずです。

<span class="filename">ファイル名：Cargo.toml</span>

```toml
[package]
name = "hello_cargo"
version = "0.1.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
```

<span class="caption">リスト1-2：`cargo new`で生成された*Cargo.toml*の内容</span>

このファイルは[*TOML*][toml]（*Tom's Obvious, Minimal Language*、トムの明確な最小限の言語）形式で、Cargoの設定フォーマットです。

最初の行の`[package]`はセクションヘッダーで、それ以降の文がパッケージを設定することを示します。
このファイルに情報を追加してく中で、他のセクションも追加していくことになります。

次の3行はCargoがプログラムをコンパイルするのに必要となる設定情報を指定します。
ここでは、名前、バージョン、使用するRustのエディションを指定しています。
`edition`キーについては[付録E][appendix-e]で説明されています。

最後の行の`[dependencies]`は、プロジェクトの依存を列挙するためのセクションの始まりです。
Rustではコードのパッケージのことを*クレート*と呼びます。
このプロジェクトでは他のクレートは必要ありませんが、第2章の最初のプロジェクトでは必要になるので、そのときにこの依存セクションを使用します。

では、*src/main.rs*を開いて見てみましょう。

<span class="filename">ファイル名: src/main.rs</span>

```rust
fn main() {
    println!("Hello, world!");
}
```

Cargoはリスト1-1で書いたような「Hello, world!」プログラムを生成してくれています。
これまでのところ、私たちのプロジェクトとCargoが生成したプロジェクトの違いは、Cargoがコードを*src*ディレクトリに配置したことと、
最上位のディレクトリに*Cargo.toml*設定ファイルがあることです。

Cargoはソースファイルが*src*ディレクトリにあることを期待します。
プロジェクトの最上位のディレクトリは、READMEファイル、ライセンス情報、設定ファイル、その他のコードに関係しないものだけを置きます。
Cargoを使うとプロジェクトを整理することができます。
すべてのものに決まった場所があり、すべてがその場所にあるのです。

「Hello, world!」プロジェクトのようにCargoを使用しないプロジェクトを開始したときでも、Cargoを使用するプロジェクトへと変換できます。
プロジェクトのコードを*src*ディレクトリに移動し、適切な*Cargo.toml*ファイルを作成すればいいのです。

### Cargoプロジェクトをビルドし、実行する

では「Hello, world!」プログラムをCargoでビルドして実行すると、何が違うのかを見てみましょう！
*hello_cargo*ディレクトリから以下のコマンドを入力して、プロジェクトをビルドします。

```console
$ cargo build
   Compiling hello_cargo v0.1.0 (file:///projects/hello_cargo)
    Finished dev [unoptimized + debuginfo] target(s) in 2.85 secs
```

このコマンドは実行ファイルを現在のディレクトリではなく、*target/debug/hello_cargo*（Windowsでは*target/debug/hello_cargo.exe*）に作成します。
デフォルトのビルドはデバッグビルドなので、Cargoはバイナリを*debug*という名前のディレクトリの中に入れます。
以下のコマンドで実行ファイルを実行できます。

```console
$ ./target/debug/hello_cargo # or .\target\debug\hello_cargo.exe on Windows
                             # Windowsでは .\target\debug\hello_cargo.exe
Hello, world!
```

すべてがうまくいけば、ターミナルに`Hello, world!`と表示されるはずです。
`cargo build`を初めて実行したとき、Cargoは最上位に*Cargo.lock*という新しいファイルを作成します。
このファイルはプロジェクト内の依存関係の正確なバージョンを記録しています。
このプロジェクトには依存がないので、このファイルの中は少しまばらです。
このファイルは手動で変更する必要はありません。
Cargoがその内容を管理してくれます。

先ほどは`cargo build`でプロジェクトをビルドし、`./target/debug/hello_cargo`で実行しました。
`cargo run`を使うと、コードのコンパイルから、できた実行ファイルの実行までの全体を一つのコマンドで行えます。

```console
$ cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.0 secs
     Running `target/debug/hello_cargo`
Hello, world!
```

`cargo build`を実行してから、バイナリへのパス全体を使って実行する、という手順をいちいち踏むより、
`cargo run`を使う方が便利なので、ほとんどの開発者は`cargo run`を使います。

今回はCargoが`hello_cargo`をコンパイルしていることを示す出力がないことに注目してください。
Cargoはファイルが変更されていないことに気づいたので、再ビルドせずに単にバイナリを実行したのです。
もしソースコードを変更していたら、Cargoは実行前にプロジェクトを再ビルドし、以下のような出力が表示されたことでしょう。

```console
$ cargo run
   Compiling hello_cargo v0.1.0 (file:///projects/hello_cargo)
    Finished dev [unoptimized + debuginfo] target(s) in 0.33 secs
     Running `target/debug/hello_cargo`
Hello, world!
```

Cargoは`cargo check`というコマンドも提供しています。
このコマンドはコードがコンパイルできるか素早くチェックしますが、実行ファイルは生成しません。

```console
$ cargo check
   Checking hello_cargo v0.1.0 (file:///projects/hello_cargo)
    Finished dev [unoptimized + debuginfo] target(s) in 0.32 secs
```

なぜ実行可能ファイルが欲しくないのでしょうか？
`cargo check`は実行ファイルを生成するステップを省くことができるので、多くの場合、`cargo build`よりもずっと高速です。
もし、あなたがコードを書きながら継続的にチェックするのなら、`cargo check`を使えば、プロジェクトがまだコンパイルできるか確認するプロセスを高速化できます！
そのため多くのRustaceanはプログラムを書きながら定期的に`cargo check`を実行し、コンパイルできるか確かめます。
そして、実行ファイルを使う準備ができたときに`cargo build`を走らせるのです。

ここまでにCargoについて学んだことをおさらいしておきましょう。

* `cargo new`を使ってプロジェクトを作成できる
* `cargo build`を使ってプロジェクトをビルドできる
* `cargo run`を使うとプロジェクトのビルドと実行を1ステップで行える
* `cargo check`を使うとバイナリを生成せずにプロジェクトをビルドして、エラーがないか確認できる
* Cargoは、ビルドの成果物をコードと同じディレクトリに保存するのではなく、*target/debug*ディレクトリに格納する

Cargoを使用するもう一つの利点は、どのOSで作業していてもコマンドが同じであることです。
そのため、これ以降はLinuxやmacOS向けの手順と、Windows向けの手順を分けて説明することはありません。

### リリースに向けたビルド

プロジェクトが最終的にリリースできるようになったら、`cargo build --release`を使い、最適化した状態でコンパイルできます。
このコマンドは実行ファイルを、*target/debug*ではなく、*target/release*に作成します。
最適化によってRustコードの実行速度が上がりますが、それを有効にすることでプログラムのコンパイルにかかる時間が長くなります。
このため二つの異なるプロファイルがあるのです。
一つは開発用で、素早く頻繁に再ビルドしたいときのもの。
もう一つはユーザに渡す最終的なプログラムをビルドするためのもので、繰り返し再ビルドすることはなく、可能な限り高速に動作するようにします。
コードの実行時間をベンチマークするなら、必ず`cargo build --release`を実行し、*target/release*の実行ファイルを使ってベンチマークを取ってください。

### 習慣としてのCargo

単純なプロジェクトでは、Cargoは単に`rustc`を使うことに対してあまり多くの価値を生みません。
しかし、プログラムが複雑になるにつれて、その価値を証明することになるでしょう。
プログラムが複数のファイルに分かれるほど大きくなったり、依存が必要になってくると、
Cargoにビルドを調整させるほうがずっと簡単です。

`hello_cargo`プロジェクトは単純ではありますが、Rustのキャリアを通じて使うことになる本物のツールの多くを使用しています。
実際、既存のどんなプロジェクトで作業するときも、以下のコマンドを使えば、Gitでコードをチェックアウトし、そのプロジェクトのディレクトリに移動し、ビルドすることができます。

```console
$ git clone example.org/someproject
$ cd someproject
$ cargo build
```

Cargoの詳細については、[ドキュメント][cargo]を参照してください。

## まとめ

既にRustの旅の素晴らしいスタートを切っています！
この章では以下を行う方法について学びました。

* `rustup`で最新の安定版のRustをインストールする
* 新しいRustのバージョンに更新する
* ローカルにインストールされたドキュメントを開く
* 「Hello, world!」プログラムを書き、`rustc`を直接使って実行する
* Cargoにおける習慣に従った新しいプロジェクトを作成し、実行する

いまは、より中身のあるプログラムを構築し、Rustコードの読み書きに慣れるのに良いタイミングでしょう。
そこで第2章では、数当てゲームプログラムを構築します。
もし、一般的なプログラミングの概念がRustでどう実現されるか学ぶことから始めたいのであれば、第3章を読んで、それから第2章に戻ってください。

[installation]: ch01-01-installation.html#インストール
[toml]: https://toml.io
[appendix-e]: appendix-05-editions.html
[cargo]: https://doc.rust-lang.org/cargo/


