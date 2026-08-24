## 構造体を使ったプログラム例

構造体を使用したくなる可能性のあるケースを理解するために、長方形の面積を求めるプログラムを書きましょう。
単一の変数から始め、代わりに構造体を使うようにプログラムをリファクタリングします。

Cargoで*rectangles*という新規バイナリプロジェクトを作成しましょう。このプロジェクトは、
長方形の幅と高さをピクセルで指定し、その面積を求めます。リスト5-8に、プロジェクトの*src/main.rs*で、
正にそうする一例を短いプログラムとして示しました。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-08/src/main.rs:all}}
```

<span class="caption">リスト5-8: 個別の幅と高さ変数を指定して長方形の面積を求める</span>

では、`cargo run`でこのプログラムを走らせてください:

```console
{{#include ../listings/ch05-using-structs-to-structure-related-data/listing-05-08/output.txt}}
```

このコードは、各寸法を与えて`area`関数を呼び出すことで長方形の面積を割り出すことができますが、
このコードはもっと簡潔で読みやすくすることができます。

このコードの問題点は、`area`のシグニチャから明らかです:

```rust,ignore
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-08/src/main.rs:here}}
```

`area`関数は、1長方形の面積を求めるものと考えられますが、今書いた関数には引数が2つあり、
そしてこのプログラム内のどこを見ても、これらの引数に関連性があることが明確になっていません。
幅と高さを一緒にグループ化する方が、より読みやすく、扱いやすくなるでしょう。
それをする一つの方法については、第3章の[「タプル型」][the-tuple-type]節ですでに議論しました: タプルを使うのです。

### タプルでリファクタリングする

リスト5-9は、タプルを使う別バージョンのプログラムを示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-09/src/main.rs}}
```

<span class="caption">リスト5-9: タプルで長方形の幅と高さを指定する</span>

ある意味では、このプログラムはマシです。タプルのおかげで少し構造的になり、一引数を渡すだけになりました。
しかし別の意味では、このバージョンは明確性を失っています: タプルは要素に名前を付けないので、
タプルの要素に添え字でアクセスする必要があり、計算が不明瞭になったのです。

面積計算では幅と高さを混同しても問題ないですが、長方形を画面に描画したいとなると、これは問題になります！
タプルの添え字`0`が`幅`で、添え字`1`が`高さ`であることを肝に銘じておかなければなりません。
もし他人がこのコードを使用することになったら、彼らがこのことを見つけ出して肝に銘じておくのはより難しくなるでしょう。
データの意味をコードに載せていないことで、エラーを招きやすくなってしまいました。

### 構造体でリファクタリングする: より意味付けする

データのラベル付けで意味を付与するために構造体を使います。現在使用しているタプルを全体と一部に名前のある構造体に、
変形することができます。そう、リスト5-10に示したように。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-10/src/main.rs}}
```

<span class="caption">リスト5-10: `Rectangle`構造体を定義する</span>

ここでは、構造体を定義し、`Rectangle`という名前にしています。波括弧の中で`width`と`height`というフィールドを定義し、
`u32`という型にしました。それから`main`内で`Rectangle`の特定のインスタンスを生成し、
幅を`30`、高さを`50`にしました。

これで`area`関数は引数が一つになり、この引数は名前が`rectangle`、型は`Rectangle`構造体インスタンスへの不変借用になりました。
第4章で触れたように、構造体の所有権を奪うよりも借用する必要があります。こうすることで`main`は所有権を保って、
`rect1`を使用し続けることができ、そのために関数シグニチャと関数呼び出し時に`&`を使っているわけです。

`area`関数は、`Rectangle`インスタンスの`width`と`height`フィールドにアクセスしています。
（借用された構造体インスタンスのフィールドにアクセスしても、そのフィールドの値はムーブされないことに注意してください。
構造体の借用をよく使うのはこのためです）
これで、`area`の関数シグニチャは、我々の意図をズバリ示すようになりました: `width`と`height`フィールドを使って、
`Rectangle`の面積を計算します。これにより、幅と高さが相互に関係していることが伝わり、
タプルの`0`や`1`という添え字を使うよりも、これらの値に説明的な名前を与えられるのです。プログラムの意図が明瞭になりました。

### トレイトの導出で有用な機能を追加する

プログラムのデバッグをしている間に、`Rectangle`のインスタンスを出力し、フィールドの値を確認できると便利でしょう。
リスト5-11では、以前の章のように、[`println!`マクロ][println]を試しに使用しようとしています。
ですが、これは動きません。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-11/src/main.rs}}
```

<span class="caption">リスト5-11: `Rectangle`のインスタンスを出力しようとする</span>

このコードをコンパイルすると、こんな感じのエラーが出ます:

```text
{{#include ../listings/ch05-using-structs-to-structure-related-data/listing-05-11/output.txt:3:4}}
```

`println!`マクロには、様々な整形があり、標準では、波括弧は`Display`として知られる整形をするよう、
`println!`に指示するのです: 直接エンドユーザ向けの出力です。これまでに見てきた基本型は、
標準で`Display`を実装しています。というのも、`1`や他の基本型をユーザに見せる方法は一つしかないからです。
しかし構造体では、`println!`が出力を整形する方法は自明ではなくなります。出力方法がいくつもあるからです:
カンマは必要なの？波かっこを出力する必要はある？全フィールドが見えるべき？この曖昧性のため、
Rustは必要なものを推測しようとせず、構造体は`println!`と`{}`プレースホルダで使用される`Display`実装を提供しないのです。

エラーを読み下すと、こんな有益な注意書きがあります:

```text
{{#include ../listings/ch05-using-structs-to-structure-related-data/listing-05-11/output.txt:10:13}}
```

試してみましょう！`pritnln!`マクロ呼び出しは、`println!("rect1 is {:?}", rect1);`という見た目になるでしょう。
波括弧内に`:?`という指定子を書くと、`println!`に`Debug`と呼ばれる出力整形を使いたいと指示するのです。
`Debug`トレイトは、開発者にとって有用な方法で構造体を出力させてくれるので、
コードをデバッグしている最中に、値を確認することができます。

変更してコードをコンパイルしてください。なに！まだエラーが出ます:

```text
{{#include ../listings/ch05-using-structs-to-structure-related-data/output-only-01-debug/output.txt:3:4}}
```

しかし今回も、コンパイラは有益な注意書きを残してくれています:

```text
{{#include ../listings/ch05-using-structs-to-structure-related-data/output-only-01-debug/output.txt:10:13}}
```

*確かに*Rustにはデバッグ用の情報を出力する機能が備わっていますが、この機能を構造体で使えるようにするには、
明示的な選択をしなければならないのです。そうするには、構造体定義の直前に`#[derive(Debug)]`という外部属性を追加します。
そう、リスト5-12で示されている通りです。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-12/src/main.rs}}
```

<span class="caption">リスト5-12: `Debug`トレイトを導出する属性を追加し、
    `Rectangle`インスタンスをデバッグ用整形機で出力する</span>

これでプログラムを実行すれば、エラーは出ず、以下のような出力が得られるでしょう:

```console
{{#include ../listings/ch05-using-structs-to-structure-related-data/listing-05-12/output.txt}}
```

素晴らしい！最善の出力ではないものの、このインスタンスの全フィールドの値を出力しているので、
デバッグ中には間違いなく役に立つでしょう。より大きな構造体があるなら、もう少し読みやすい出力の方が有用です;
そのような場合には、`println!`文字列中の`{:?}`の代わりに`{:#?}`を使うことができます。
この例で`{:#?}`というスタイルを使用したら、出力は以下のようになるでしょう:

```console
{{#include ../listings/ch05-using-structs-to-structure-related-data/output-only-02-pretty-debug/output.txt}}
```

`Debug`整形を使用して値を出力するためのもう一つの方法は、[`dbg!`マクロ][dbg]を使用することです。
`dbg!`マクロは式の所有権を奪い（参照を取る`println!`とは対照的です）、その呼び出しが発生したコード内のファイル名と行番号とともに式を評価した結果を出力して、
その値の所有権を返します。

> 注釈: 標準出力コンソールストリーム（`stdout`）に出力する`println!`とは異なり、`dbg!`マクロの呼び出しは標準エラーコンソールストリーム（`stderr`）に出力します。
> `stderr`と`stdout`については[12章の「標準出力ではなく標準エラーにエラーメッセージを書き込む」節][err]でより詳しく触れます。

以下は、`width`フィールドに代入される値と、`rect1`の構造体全体の値に関心がある場合の例です:

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/no-listing-05-dbg-macro/src/main.rs}}
```

`dbg!`は式が評価された値の所有権を返すため、式`30 * scale`を囲うように`dbg!`を書くことで、`width`フィールドはここで`dbg!`の呼び出しをしなかった場合とまったく同じ値になります。
`rect1`の所有権は奪ってほしくないので、次の`dbg!`呼び出しでは`rect1`への参照を使用しています。
この例の出力は以下のようになります:

```console
{{#include ../listings/ch05-using-structs-to-structure-related-data/no-listing-05-dbg-macro/output.txt}}
```

出力の前半は*src/main.rs*の10行目からの出力です。
ここでは式`30 * scale`をデバッグ出力していて、その結果の値は`60`です（整数に実装されている`Debug`整形を使用して出力されています）。
*src/main.rs*の14行目の`dbg!`呼び出しは`&rect1`の値を出力し、これは`Rectangle`構造体です。
この出力は `Rectangle`型の pretty `Debug`整形を使用します。
`dbg!`マクロは、コードが何をしているのか理解しようとするときには非常に有用です！

`Debug`トレイトの他にも、Rustでは`derive`属性で使えるトレイトが多く提供されており、独自の型に有用な振る舞いを追加することができます。
そのようなトレイトとその振る舞いは、付録Cで一覧になっています。
これらのトレイトを独自の動作とともに実装する方法だけでなく、独自のトレイトを生成する方法については、第10章で解説します。
また、`derive`の他にも多数の属性が存在します; さらなる情報については[Rust Referenceの“Attributes”節][attributes]を参照してください。

`area`関数は、非常に特殊です: 長方形の面積を算出するだけです。`Rectangle`構造体とこの動作をより緊密に結び付けられると、
役に立つでしょう。なぜなら、他のどんな型でもうまく動作しなくなるからです。
`area`関数を`Rectangle`型に定義された`area`*メソッド*に変形することで、
このコードをリファクタリングし続けられる方法について見ていきましょう。

[the-tuple-type]: ch03-02-data-types.html#タプル型
[app-c]: appendix-03-derivable-traits.md
[println]: https://doc.rust-lang.org/std/macro.println.html
[dbg]: https://doc.rust-lang.org/std/macro.dbg.html
[err]: ch12-06-writing-to-stderr-instead-of-stdout.html
[attributes]: https://doc.rust-lang.org/reference/attributes.html


