## 付録A: キーワード

以下のリストは、現在、あるいは将来Rust言語により使用されるために予約されているキーワードです。
そのため、識別子として使用することはできません。識別子には、関数名、変数名、引数名、構造体のフィールド名、モジュール名、クレート名、定数名、マクロ名、静的な値の名前、属性名、型名、トレイト名、ライフタイム名などがあります。
ただし、[生識別子][raw-identifiers]のところで議論する生識別子は例外です。

[raw-identifiers]: #raw-identifiers

### 現在使用されているキーワード

以下のキーワードは、解説された通りの機能が現状あります。

* `as` - 基礎的なキャストの実行、要素を含む特定のトレイトの明確化、`use`や`extern crate`文の要素名を変更する
* `async` - 現在のスレッドをブロックする代わりに`Future`を返す
* `await` - `Future`の結果が準備できるまで実行を停止する
* `break` - 即座にループを抜ける
* `const` - 定数要素か定数の生ポインタを定義する
* `continue` - 次のループの繰り返しに継続する
* `crate` - 外部のクレートかマクロが定義されているクレートを表すマクロ変数をリンクする
* `dyn` - トレイトオブジェクトへの動的ディスパッチを行う
* `else` - `if`と`if let`制御フロー構文の規定
* `enum` - 列挙型を定義する
* `extern` - 外部のクレート、関数、変数をリンクする
* `false` - bool型のfalseリテラル
* `fn` - 関数か関数ポインタ型を定義する
* `for` - イテレータの要素を繰り返す、トレイトの実装、高階ライフタイムの指定
* `if` - 条件式の結果によって条件分岐
* `impl` - 固有の機能やトレイトの機能を実装する
* `in` - `for`ループ記法の一部
* `let` - 変数を束縛する
* `loop` - 無条件にループする
* `match` - 値をパターンとマッチさせる
* `mod` - モジュールを定義する
* `move` - クロージャにキャプチャした変数全ての所有権を奪わせる
* `mut` - 参照、生ポインタ、パターン束縛で可変性に言及する
* `pub` - 構造体フィールド、`impl`ブロック、モジュールで公開性について言及する
* `ref` - 参照で束縛する
* `return` - 関数から帰る
* `Self` - 定義しようとしている・実装(implement)しようとしている型の型エイリアス
* `self` - メソッドの主題、または現在のモジュール
* `static` - グローバル変数、またはプログラム全体に渡るライフタイム
* `struct` - 構造体を定義する
* `super` - 現在のモジュールの親モジュール
* `trait` - トレイトを定義する
* `true` - bool型のtrueリテラル
* `type` - 型エイリアスか関連型を定義する
* `union` - [union][union]を定義する。union宣言内で使う場合にのみキーワードになる
* `unsafe` - unsafeなコード、関数、トレイト、実装に言及する
* `use` - スコープにシンボルを持ち込む
* `where` - 型を制限する節に言及する
* `while` - 式の結果に基づいて条件的にループする

[union]: https://doc.rust-lang.org/reference/items/unions.html

### 将来的な使用のために予約されているキーワード

以下のキーワードには機能が何もないものの、将来的に使用される可能性があるので、Rustにより予約されています。

* `abstract`
* `become`
* `box`
* `do`
* `final`
* `gen`
* `macro`
* `override`
* `priv`
* `try`
* `typeof`
* `unsized`
* `virtual`
* `yield`

### 生識別子

*生識別子* とは、普段は使うことが許されないキーワードを使わせてくれる構文です。
生識別子はキーワードの前に`r#`を置いて使うことができます。

たとえば、`match`はキーワードです。
次の、名前が`match`である関数をコンパイルしようとすると：

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
fn match(needle: &str, haystack: &str) -> bool {
    haystack.contains(needle)
}
// 訳注: 引数名は、"a needle in a haystack" すなわち「干し草の中の針」という、
// 「見つかりそうにない捜し物」を意味する成句からもじった命名。
// 検索をする関数でよく使われる。
```

次のエラーを得ます：

```text
error: expected identifier, found keyword `match`
 --> src/main.rs:4:4
  |
4 | fn match(needle: &str, haystack: &str) -> bool {
  |    ^^^^^ expected identifier, found keyword
```

このエラーは`match`というキーワードを関数の識別子としては使えないと示しています。
`match`を関数名として使うには、次のように、生識別子構文を使う必要があります。

<span class="filename">ファイル名: src/main.rs</span>

```rust
fn r#match(needle: &str, haystack: &str) -> bool {
    haystack.contains(needle)
}

fn main() {
    assert!(r#match("foo", "foobar"));
}
```

このコードはなんのエラーもなくコンパイルできます。
`r#`は、定義のときも、`main`内で呼ばれたときにも、関数名の前につけられていることに注意してください。

生識別子を使えば、予約済みのキーワードであっても、選んだ任意の単語を識別子として使えます。これにより識別子名をより自由に選べるだけでなく、その単語がキーワードではない別の言語で書かれたプログラムとも連携できます。さらに、自分のクレートとは異なるRust Editionで書かれたライブラリも利用できます。

たとえば、`try`は2015 Editionではキーワードではありませんが、2018、2021、2024 Editionではキーワードです。2015 Editionで書かれ、`try`関数を持つライブラリへ依存している場合、それ以降のEditionのコードから関数を呼ぶには、生識別子構文の`r#try`を使います。Editionについて詳しくは[付録E][appendix-e]を参照してください。

[appendix-e]: appendix-05-editions.html
