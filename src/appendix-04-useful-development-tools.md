## 付録D：便利な開発ツール

この付録では、Rustプロジェクトの提供する便利な開発ツールについていくつかお話します。
自動フォーマット、警告に対する修正をすばやく適用する方法、lintツール、そしてIDEとの統合について見ていきます。

### `rustfmt`を使った自動フォーマット


`rustfmt`というツールは、コミュニティのコードスタイルに合わせてあなたのコードをフォーマットしてくれます。
Rustを書くときにどのスタイルを使うかで揉めないように、多くの共同で行われるプロジェクトが`rustfmt`を使っています：全員がこのツールでコードをフォーマットするのです。

`rustfmt`をインストールするには、以下を入力してください：

```console
$ rustup component add rustfmt
```

これで`rustfmt`と`cargo-fmt`が使えるようになります。これは`rustc`と`cargo`の両方のコマンドがあるのと似たようなものです。
どんなCargoのプロジェクトも、次を入力するとフォーマットできます：

```console
$ cargo fmt
```

このコマンドを実行すると、現在のクレートのあらゆるRustコードをフォーマットし直します。
これを行うと、コードのスタイルのみが変わり、コードの意味は変わりません。
`rustfmt`についてより詳しく知るには[ドキュメント][rustfmt]を読んでください。

[rustfmt]: https://github.com/rust-lang/rustfmt

### `rustfix`でコードを修正する

rustfixというツールはRustをインストールすると同梱されており、コンパイラの警告 (warning) を自動で直してくれます。
Rustでコードを書いたことがある人なら、コンパイラの警告を見たことがあるでしょう。
たとえば、下のコードを考えます：

<span class="filename">Filename: src/main.rs</span>

```rust
fn do_something() {}

fn main() {
    for i in 0..100 {
        do_something();
    }
}
```

ここで、`do_something`関数を100回呼んでいますが、`for`ループの内部で変数`i`を一度も使っていません。
Rustはこれについて警告します：

```console
$ cargo build
   Compiling myprogram v0.1.0 (file:///projects/myprogram)
warning: unused variable: `i`
 --> src/main.rs:4:9
  |
4 |     for i in 1..100 {
  |         ^ help: consider using `_i` instead
  |
  = note: #[warn(unused_variables)] on by default

    Finished dev [unoptimized + debuginfo] target(s) in 0.50s
```

警告は、変数名に`_i`を使ってはどうかと提案しています：アンダーバーはその変数を使わないという意図を示すのです。
`cargo fix`というコマンドを実行することで、この提案を`rustfix`ツールで自動で適用できます。

```console
$ cargo fix
    Checking myprogram v0.1.0 (file:///projects/myprogram)
      Fixing src/main.rs (1 fix)
    Finished dev [unoptimized + debuginfo] target(s) in 0.59s
```

*src/main.rs*をもう一度見てみると、`cargo fix`によってコードが変更されていることがわかります。

<span class="filename">Filename: src/main.rs</span>

```rust
fn do_something() {}

fn main() {
    for _i in 0..100 {
        do_something();
    }
}
```

`for`ループの変数は`_i`という名前になったので、警告はもう現れません。

`cargo fix`コマンドを使うと、異なるRust editionの間でコードを変換することもできます。
editionについては付録Eに書いています。

### Clippyでもっとlintを

Clippyというツールは、コードを分析することで、よくある間違いを見つけ、Rustのコードを改善させてくれるlintを集めたものです（訳注：いわゆる静的解析ツール）。

Clippyをインストールするには、次を入力してください：

```console
$ rustup component add clippy
```

Clippyのlintは、次のコマンドでどんなCargoプロジェクトに対しても実行できます：

```console
$ cargo clippy
```

たとえば、下のように、円周率などの数学定数の近似を使ったプログラムを書いているとします。

<span class="filename">ファイル名: src/main.rs</span>

```rust
fn main() {
    let x = 3.1415;
    let r = 8.0;
    println!("the area of the circle is {}", x * r * r);
}
```

`cargo clippy`をこのプロジェクトに実行すると次のエラーを得ます：

```text
error: approximate value of `f{32, 64}::consts::PI` found. Consider using it directly
 --> src/main.rs:2:13
  |
2 |     let x = 3.1415;
  |             ^^^^^^
  |
  = note: #[deny(clippy::approx_constant)] on by default
  = help: for further information visit https://rust-lang-nursery.github.io/rust-clippy/master/index.html#approx_constant
```

あなたは、このエラーのおかげで、Rustにはより正確に定義された定数がすでにあり、これを代わりに使うとプログラムがより正しくなるかもしれないと気づくことができます。
なので、あなたはコードを定数`PI`を使うように変更するでしょう。
以下のコードはもうClippyからエラーや警告は受けません。

<span class="filename">ファイル名: src/main.rs</span>

```rust
fn main() {
    let x = std::f64::consts::PI;
    let r = 8.0;
    println!("the area of the circle is {}", x * r * r);
}
```

Clippyについてより詳しく知るには、[ドキュメント][clippy]を読んでください。

[clippy]: https://github.com/rust-lang/rust-clippy

### `rust-analyzer`を使ってIDEと統合する

IDEとの統合には、Rustコミュニティが推奨する[`rust-analyzer`][rust-analyzer]を利用できます。このツールは、IDEとプログラミング言語が通信するための仕様である[Language Server Protocol][lsp]に対応した、コンパイラを中心とするユーティリティ群です。[Visual Studio Code用のrust-analyzer拡張][vscode]など、さまざまなクライアントから利用できます。

インストール方法は`rust-analyzer`プロジェクトの[ホームページ][rust-analyzer]を確認し、使用するIDEへ言語サーバのサポートを追加してください。自動補完、定義へのジャンプ、インラインでのエラー表示などが利用できるようになります。

[rust-analyzer]: https://rust-analyzer.github.io
[lsp]: http://langserver.org/
[vscode]: https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer
