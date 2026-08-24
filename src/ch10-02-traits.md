## トレイト: 共通の振る舞いを定義する

*トレイト*は、特定の型に存在し、他の型と共有できる機能を定義します。
トレイトを使用すると、共通の振る舞いを抽象的に定義できます。*トレイト境界*を使用すると、
あるジェネリック型が、特定の振る舞いをもつあらゆる型になり得ることを指定できます。

> 注釈: 違いはあるものの、トレイトは他の言語でよくインターフェイスと呼ばれる機能に類似しています。

### トレイトを定義する

型の振る舞いは、その型に対して呼び出せるメソッドから構成されます。異なる型は、それらの型全てに対して同じメソッドを呼び出せるなら、
同じ振る舞いを共有することになります。トレイト定義は、メソッドシグニチャをあるグループにまとめ、なんらかの目的を達成するのに必要な一連の振る舞いを定義する手段です。

例えば、いろんな種類や量のテキストを保持する複数の構造体があるとしましょう: 特定の場所から送られる新しいニュースを保持する`NewsArticle`と、
新規ツイートか、リツイートか、はたまた他のツイートへのリプライなのかを示すメタデータを伴う最大で280文字までの`Tweet`です。

`NewsArticle` または `Tweet` インスタンスに保存されているデータのサマリーを表示できる`aggregator`という名前のメディア アグリゲータ ライブラリ クレートを作成します。
これをするには、各型のサマリーが必要で、インスタンスで `summarize` メソッドを呼び出してサマリーを要求することになるでしょう。
リスト10-12は、この振る舞いを表現する公開の`Summary`トレイトの定義を表示しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/listing-10-12/src/lib.rs}}
```

<span class="caption">リスト10-12: `summarize`メソッドで提供される振る舞いからなる`Summary`トレイト</span>

ここでは、`trait`キーワード、それからトレイト名を使用してトレイトを宣言していて、その名前は今回の場合、
`Summary`です。
また、いくつかの例で見ていきますが、このクレートに依存するクレートがこのトレイトを利用できるように、トレイトを`pub`として宣言しています。
波括弧の中にこのトレイトを実装する型の振る舞いを記述するメソッドシグニチャを定義し、
今回の場合は、`fn summarize(&self) -> String`です。

メソッドシグニチャの後に、波括弧内に実装を提供する代わりに、セミコロンを使用しています。
このトレイトを実装する型はそれぞれ、メソッドの本体に独自の振る舞いを提供しなければなりません。
コンパイラにより、`Summary`トレイトを保持するあらゆる型に、このシグニチャと全く同じメソッド`summarize`が定義されていることが
強制されます。

トレイトには、本体に複数のメソッドを含むことができます: メソッドシグニチャは行ごとに並べられ、
各行はセミコロンで終わります。

### トレイトを型に実装する

これで `Summary` トレイトのメソッドのシグネチャを希望通りに定義できたので、メディア アグリゲータ内の型に対してこれを実装できます。
リスト10-13は、 `Summary` トレイトを `NewsArticle` 構造体上に実装したもので、ヘッドライン、著者、そして地域情報を使って`summarize` の戻り値を作っています。
`Tweet` 構造体に関しては、ツイートの内容が既に280文字に制限されていると仮定して、ユーザー名の後にツイートのテキスト全体が続くものとして `summarize` を定義します。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/listing-10-13/src/lib.rs:here}}
```

<span class="caption">リスト10-13: `Summary`トレイトを`NewsArticle`と`Tweet`型に実装する</span>

型にトレイトを実装することは、普通のメソッドを実装することに似ています。違いは、`impl`の後に、
実装したいトレイトの名前を置き、それから`for`キーワード、さらにトレイトの実装対象の型の名前を指定することです。
`impl`ブロック内に、トレイト定義で定義したメソッドシグニチャを置きます。各シグニチャの後にセミコロンを追記するのではなく、
波括弧を使用し、メソッド本体に特定の型のトレイトのメソッドに欲しい特定の振る舞いを入れます。

これでライブラリは`NewsArticle`と`Tweet`に対して`Summary`トレイトを実装できたので、クレートの利用者は普通のメソッド同様に`NewsArticle`や`Tweet`のインスタンスに対してこのトレイトメソッドを呼び出せます。
唯一の違いは、ユーザは型だけではなくトレイトもスコープ内に持ち込まなくてはならないということです。
以下は、バイナリクレートが私たちの`aggregator`ライブラリクレートをどうやって使用できるかの例です:

```rust,ignore
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-01-calling-trait-method/src/main.rs}}
```

このコードは、`1 new tweet: horse_ebooks: of course, as you probably already know, people`と出力します。

`aggregator`クレートに依存する他のクレートも、自身の型に対して`Summary`を実装するために、`Summary`トレイトをスコープに持ち込むことができます。
注意すべき制限の1つは、トレイトか、対象の型のうち、少なくとも一方が自分のクレートに固有(local)である時のみ、
型に対してトレイトを実装できるということです。例えば、`Display`のような標準ライブラリのトレイトを`aggregator`クレートの機能の一部として、
`Tweet`のような独自の型に実装できます。型`Tweet`が`aggregator`クレートに固有だからです。
また、`Summary`を`aggregator`クレートで`Vec<T>`に対して実装することもできます。
トレイト`Summary`は、`aggregator`クレートに固有だからです。

しかし、外部のトレイトを外部の型に対して実装することはできません。例として、
`aggregator`クレート内で`Vec<T>`に対して`Display`トレイトを実装することはできません。
`Display`と`Vec<T>`はどちらも標準ライブラリで定義され、`aggregator`クレートに固有ではないからです。
この制限は、*コヒーレンス*(coherence)、特に*孤児のルール*(orphan rule)と呼ばれる特性の一部で、
親の型が存在しないためにそう命名されました。この規則により、他の人のコードが自分のコードを壊したり、
その逆が起きないことを保証してくれます。この規則がなければ、2つのクレートが同じ型に対して同じトレイトを実装できてしまい、
コンパイラはどちらの実装を使うべきかわからなくなってしまうでしょう。

### デフォルト実装

時として、全ての型の全メソッドに対して実装を要求するのではなく、トレイトの全てあるいは一部のメソッドに対してデフォルトの振る舞いがあると有用です。
そうすれば、特定の型にトレイトを実装する際、各メソッドのデフォルト実装を保持するかオーバーライドするか選べるわけです。

リスト10-14では、リスト10-12のように、メソッドシグニチャだけを定義するのではなく、
`Summary`トレイトの`summarize`メソッドにデフォルトの文字列を指定しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/listing-10-14/src/lib.rs:here}}
```

<span class="caption">リスト10-14: `summarize`メソッドのデフォルト実装がある`Summary`トレイトを定義する</span>

デフォルト実装を利用して`NewsArticle`のインスタンスをまとめるには、
`impl Summary for NewsArticle {}`と空の`impl`ブロックを指定します。

もはや`NewsArticle`に直接`summarize`メソッドを定義してはいませんが、私達はデフォルト実装を提供しており、
`NewsArticle`は`Summary`トレイトを実装すると指定しました。そのため、
`NewsArticle`のインスタンスに対して`summarize`メソッドを同じように呼び出すことができます。
このように:

```rust,ignore
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-02-calling-default-impl/src/main.rs:here}}
```

このコードは、`New article available! (Read more...)`（`新しい記事があります！（もっと読む）`）と出力します。

デフォルト実装を用意しても、リスト10-13の`Tweet`の`Summary`実装を変える必要はありません。
理由は、デフォルト実装をオーバーライドする記法はデフォルト実装のないトレイトメソッドを実装する記法と同じだからです。

デフォルト実装は、自らのトレイトのデフォルト実装を持たない他のメソッドを呼び出すことができます。
このようにすれば、トレイトは多くの有用な機能を提供しつつ、実装者は僅かな部分しか指定しなくて済むようになります。
例えば、`Summary`トレイトを、（実装者が）内容を実装しなければならない`summarize_author`メソッドを持つように定義し、
それから`summarize_author`メソッドを呼び出すデフォルト実装を持つ`summarize`メソッドを定義することもできます:

```rust,noplayground
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-03-default-impl-calls-other-methods/src/lib.rs:here}}
```

このバージョンの`Summary`を使用するために、型にトレイトを実装する際、実装する必要があるのは`summarize_author`だけです:

```rust,ignore
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-03-default-impl-calls-other-methods/src/lib.rs:impl}}
```

`summarize_author`定義後、`Tweet`構造体のインスタンスに対して`summarize`を呼び出せ、
`summarize`のデフォルト実装は、私達が提供した`summarize_author`の定義を呼び出すでしょう。
`summarize_author`を実装したので、追加のコードを書く必要なく、`Summary`トレイトは、
`summarize`メソッドの振る舞いを与えてくれました。

```rust,ignore
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-03-default-impl-calls-other-methods/src/main.rs:here}}
```

このコードは、`1 new tweet: (Read more from @horse_ebooks...)`（`1つの新しいツイート：（@horse_ebooksさんの文章をもっと読む）`）と出力します。

デフォルト実装を、そのメソッドをオーバーライドしている実装から呼び出すことはできないことに注意してください。

### 引数としてのトレイト

トレイトを定義し実装する方法はわかったので、トレイトを使っていろんな種類の型を受け付ける関数を定義する方法を学んでいきましょう。
リスト10-13で`NewsArticle`と`Tweet`に対して実装した`Summary`トレイトを使用して、`notify`関数を定義しましょう。
この関数は、`Summary`トレイトを実装する何らかの型を持つ引数`item`を持ち、それに対して`summarize`メソッドを呼び出します。
これを行うためには、このように`impl Trait`構文を使います:

```rust,ignore
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-04-traits-as-parameters/src/lib.rs:here}}
```

引数の`item`には、具体的な型の代わりに、`impl`キーワードとトレイト名を指定します。
この引数は、指定されたトレイトを実装しているあらゆる型を受け付けます。
`notify`の中身では、`summarize`のような、`Summary`トレイトに由来する`item`のあらゆるメソッドを呼び出すことができます。
私達は、`notify`を呼びだし、`NewsArticle`か`Tweet`のどんなインスタンスでも渡すことができます。
この関数を呼び出すときに、`String`や`i32`のような他の型を渡すようなコードはコンパイルできません。
なぜなら、これらの型は`Summary`を実装していないからです。

#### トレイト境界構文

`impl Trait`構文は単純なケースを解決しますが、実はより長い*トレイト境界 (trait bound)* として知られる姿の糖衣構文 (syntax sugar) なのです。
それは以下のようなものです：

```rust,ignore
pub fn notify<T: Summary>(item: &T) {
	// 速報！ {}
    println!("Breaking news! {}", item.summarize());
}
```

この「より長い」姿は前節の例と等価ですが、より冗長です。
山カッコの中にジェネリックな型引数の宣言を書き、型引数の後ろにコロンを挟んでトレイト境界を置いています。

簡単なケースでは`impl Trait`構文は便利で、コードを簡潔にしてくれます。
一方でそうでないケースでは、完全なトレイト境界構文を使えばより複雑な制約を表現できます。
たとえば、`Summary`を実装する2つのパラメータを持つような関数を考えることができます。
`impl Trait`構文を使ってそうするのはこのようになるでしょう：

```rust,ignore
pub fn notify(item1: &impl Summary, item2: &impl Summary) {
```

この関数が受け取る`item1`と`item2`の型が（どちらも`Summary`を実装する限り）異なっても良い場合、`impl Trait`の使用は適切です。
しかし、両方の引数が同じ型であることを強制したい場合は、次のようにトレイト境界を使用しなくてはなりません:

```rust,ignore
pub fn notify<T: Summary>(item1: &T, item2: &T) {
```

引数である`item1`と`item2`の型としてジェネリックな型`T`を指定しました。
これにより、`item1`と`item2`として関数に渡される値の具体的な型が同一でなければならない、という制約を与えています。

#### 複数のトレイト境界を`+`構文で指定する

複数のトレイト境界も指定できます。
たとえば、`notify`に、`item`に対する`summarize`に加えて画面出力形式（ディスプレイフォーマット）も使わせたいとします。
その場合は、`notify`の定義に`item`は`Display`と`Summary`の両方を実装していなくてはならないと指定することになります。
これは、以下のように`+`構文で行うことができます：

```rust,ignore
pub fn notify(item: &(impl Summary + Display)) {
```

`+`構文はジェネリック型につけたトレイト境界に対しても使えます：

```rust,ignore
pub fn notify<T: Summary + Display>(item: &T) {
```

これら2つのトレイト境界が指定されていれば、`notify`の中では`summarize`を呼び出すことと、`{}`を使って`item`をフォーマットすることの両方が行なえます。

#### `where`句を使ったより明確なトレイト境界

あまりたくさんのトレイト境界を使うことには欠点もあります。
それぞれのジェネリック（な型）がそれぞれのトレイト境界をもつので、複数のジェネリック型の引数をもつ関数は、関数名と引数リストの間に大量のトレイト境界に関する情報を含むことがあります。
これでは関数のシグネチャが読みにくくなってしまいます。
このため、Rustはトレイト境界を関数シグネチャの後の`where`句の中で指定するという別の構文を用意しています。
なので、このように書く：

```rust,ignore
fn some_function<T: Display + Clone, U: Clone + Debug>(t: &T, u: &U) -> i32 {
```

代わりに、`where`句を使い、このように書くことができます：

```rust,ignore
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-07-where-clause/src/lib.rs:here}}
```

この関数シグニチャは、よりさっぱりとしています。トレイト境界を多く持たない関数と同じように、関数名、引数リスト、戻り値の型が一緒になって近くにあるからですね。

### トレイトを実装している型を返す


以下のように、`impl Trait`構文を戻り値型のところで使うことにより、あるトレイトを実装する何らかの型を返すことができます。

```rust,ignore
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-05-returning-impl-trait/src/lib.rs:here}}
```

戻り値の型として`impl Summary`を使うことにより、具体的な型が何かを言うことなく、`returns_summarizable`関数は`Summary`トレイトを実装している何らかの型を返すのだ、と指定することができます。
今回`returns_summarizable`は`Tweet`を返しますが、この関数を呼び出すコードはそのことを知る必要はありません。

実装しているトレイトだけで戻り値型を指定できることは、13章で学ぶ、クロージャとイテレータを扱うときに特に便利です。
クロージャとイテレータの作り出す型は、コンパイラだけが知っているものであったり、指定するには長すぎるものであったりします。
`impl Trait`構文を使えば、非常に長い型を書くことなく、ある関数は`Iterator`トレイトを実装するある型を返すのだ、と簡潔に指定することができます。

ただし、`impl Trait`は一種類の型を返す場合にのみ使えます。
たとえば、以下のように、戻り値の型は`impl Summary`で指定しつつ、`NewsArticle`か`Tweet`を返すようなコードは失敗します：

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/no-listing-06-impl-trait-returns-one-type/src/lib.rs:here}}
```

`NewsArticle`か`Tweet`を返すというのは、コンパイラの`impl Trait`構文の実装まわりの制約により許されていません。
このような振る舞いをする関数を書く方法は、17章の[「トレイトオブジェクトで異なる型の値を許容する」][using-trait-objects-that-allow-for-values-of-different-types]節で学びます。

### トレイト境界を使用して、メソッド実装を条件分けする

ジェネリックな型引数を持つ`impl`ブロックにトレイト境界を与えることで、
特定のトレイトを実装する型に対するメソッド実装を条件分けできます。例えば、
リスト10-15の型`Pair<T>`は、`Pair<T>`の新しいインスタンスを返す`new`関数を常に実装します
（第5章の[「メソッドを定義する」][methods]節で学んだ、`Self`は`impl`ブロックの型に対する型エイリアスだということを思い出してください、今回は`Pair<T>`です）。しかし次の`impl`ブロック内では、`Pair<T>`は、
内部の型`T`が比較を可能にする`PartialOrd`トレイト*と*出力を可能にする`Display`トレイトを実装している時のみ、
`cmp_display`メソッドを実装します。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch10-generic-types-traits-and-lifetimes/listing-10-15/src/lib.rs}}
```

<span class="caption">リスト10-15: トレイト境界によってジェネリックな型に対するメソッド実装を条件分けする</span>

また、別のトレイトを実装するあらゆる型に対するトレイト実装を条件分けすることもできます。
トレイト境界を満たすあらゆる型にトレイトを実装することは、*ブランケット実装*(blanket implementation)と呼ばれ、
Rustの標準ライブラリで広く使用されています。例を挙げれば、標準ライブラリは、
`Display`トレイトを実装するあらゆる型に`ToString`トレイトを実装しています。
標準ライブラリの`impl`ブロックは以下のような見た目です:

```rust,ignore
impl<T: Display> ToString for T {
    // --snip--
}
```

標準ライブラリにはこのブランケット実装があるので、`Display`トレイトを実装する任意の型に対して、
`ToString`トレイトで定義された`to_string`メソッドを呼び出せるのです。
例えば、整数は`Display`を実装するので、このように整数値を対応する`String`値に変換できます:

```rust
let s = 3.to_string();
```

ブランケット実装は、トレイトのドキュメンテーションの「実装したもの」節に出現します。

トレイトとトレイト境界により、ジェネリックな型引数を使用して重複を減らしつつ、コンパイラに対して、
そのジェネリックな型に特定の振る舞いが欲しいことを指定するコードを書くことができます。
それからコンパイラは、トレイト境界の情報を活用してコードに使用された具体的な型が正しい振る舞いを提供しているか確認できます。
動的型付き言語では、その型に定義されていないメソッドを呼び出せば、実行時 (runtime) にエラーが出るでしょう。
しかし、Rustはこの種のエラーをコンパイル時に移したので、コードが動かせるようになる以前に問題を修正することを強制されるのです。
加えて、コンパイル時に既に確認したので、実行時の振る舞いを確認するコードを書かなくても済みます。
そうすることで、ジェネリクスの柔軟性を諦めることなくパフォーマンスを向上させます。

[using-trait-objects-that-allow-for-values-of-different-types]: ch18-02-trait-objects.html#トレイトオブジェクトで共通の振る舞いを抽象化する
[methods]: ch05-03-method-syntax.html#メソッドを定義する

