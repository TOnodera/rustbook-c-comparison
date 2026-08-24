

## 高度なトレイト

最初にトレイトについて説明したのは、第10章の「トレイト: 共通の振る舞いを定義する」節でしたが、
ライフタイム同様、より高度な詳細は議論しませんでした。今や、Rustに詳しくなったので、核心に迫れるでしょう。

### 関連型でトレイト定義においてプレースホルダーの型を指定する

*関連型*は、トレイトのメソッド定義がシグニチャでプレースホルダーの型を使用できるように、トレイトと型のプレースホルダーを結び付けます。
トレイトを実装するものがこの特定の実装で型の位置に使用される具体的な型を指定します。そうすることで、
なんらかの型を使用するトレイトをトレイトを実装するまでその型が一体なんであるかを知る必要なく定義できます。

この章のほとんどの高度な機能は、稀にしか必要にならないと解説しました。関連型はその中間にあります。
本の他の部分で説明される機能よりは使用されるのが稀ですが、この章で議論される他の多くの機能よりは頻繁に使用されます。

関連型があるトレイトの一例は、標準ライブラリが提供する`Iterator`トレイトです。その関連型は`Item`と名付けられ、
`Iterator`トレイトを実装している型が走査している値の型の代役を務めます。第13章の「`Iterator`トレイトと`next`メソッド」節で、
`Iterator`トレイトの定義は、リスト20-20に示したようなものであることに触れました。

```rust,noplayground
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-13/src/lib.rs}}
```

<span class="caption">リスト20-20: 関連型`Item`がある`Iterator`トレイトの定義</span>

型`Item`はプレースホルダー型で`next`メソッドの定義は、型`Option<Self::Item>`の値を返すことを示しています。
`Iterator`トレイトを実装するものは、`Item`の具体的な型を指定し、`next`メソッドは、
その具体的な型の値を含む`Option`を返します。

関連型は、ジェネリクスにより扱う型を指定せずに関数を定義できるという点でジェネリクスに似た概念のように思える可能性があります。
では、何故関連型を使用するのでしょうか？

2つの概念の違いを第13章から`Counter`構造体に`Iterator`トレイトを実装する例で調査しましょう。
リスト13-21で、`Item`型は`u32`だと指定しました:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch20-advanced-features/no-listing-22-iterator-on-counter/src/lib.rs:ch19}}
```

この記法は、ジェネリクスと比較可能に思えます。では、何故単純にリスト20-21のように、
`Iterator`トレイトをジェネリクスで定義しないのでしょうか？

```rust,noplayground
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-14/src/lib.rs}}
```

<span class="caption">リスト20-21: ジェネリクスを使用した架空の`Iterator`トレイトの定義</span>

差異は、リスト20-21のようにジェネリクスを使用すると、各実装で型を注釈しなければならないことです。
`Iterator<String> for Counter`や他のどんな型にも実装することができるので、
`Counter`の`Iterator`の実装が複数できるでしょう。換言すれば、トレイトにジェネリックな引数があると、
毎回ジェネリックな型引数の具体的な型を変更してある型に対して複数回実装できるということです。
`Counter`に対して`next`メソッドを使用する際に、どの`Iterator`の実装を使用したいか型注釈をつけなければならないでしょう。

関連型なら、同じ型に対してトレイトを複数回実装できないので、型を注釈する必要はありません。
関連型を使用する定義があるリスト20-20では、`Item`の型は1回しか選択できませんでした。
1つしか`impl Iterator for Counter`がないからです。`Counter`に`next`を呼び出す度に、
`u32`値のイテレータが欲しいと指定しなくてもよいわけです。

### デフォルトのジェネリック型引数と演算子オーバーロード

ジェネリックな型引数を使用する際、ジェネリックな型に対して既定の具体的な型を指定できます。これにより、
既定の型が動くのなら、トレイトを実装する側が具体的な型を指定する必要を排除します。ジェネリックな型に既定の型を指定する記法は、
ジェネリックな型を宣言する際に`<PlaceholderType=ConcreteType>`です。

このテクニックが有用になる場面の好例が、演算子オーバーロードです。*演算子オーバーロード*とは、
特定の状況で演算子(`+`など)の振る舞いをカスタマイズすることです。

Rustでは、独自の演算子を作ったり、任意の演算子をオーバーロードすることはできません。しかし、
演算子に紐づいたトレイトを実装することで`std::ops`に列挙された処理と対応するトレイトをオーバーロードできます。
例えば、リスト20-22で`+`演算子をオーバーロードして2つの`Point`インスタンスを足し合わせています。
`Point`構造体に`Add`トレイトを実装することでこれを行なっています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-15/src/main.rs}}
```

<span class="caption">リスト20-22: `Add`トレイトを実装して`Point`インスタンス用に`+`演算子をオーバーロードする</span>

`add`メソッドは2つの`Point`インスタンスの`x`値と2つの`Point`インスタンスの`y`値を足します。
`Add`トレイトには、`add`メソッドから返却される型を決定する`Output`という関連型があります。

このコードの既定のジェネリック型は、`Add`トレイト内にあります。こちらがその定義です。

```rust
trait Add<Rhs=Self> {
    type Output;

    fn add(self, rhs: Rhs) -> Self::Output;
}
```

このコードは一般的に馴染みがあるはずです。 1つのメソッドと関連型が1つあるトレイトです。
新しい部分は、`RHS=Self`です。 この記法は、*デフォルト型引数*と呼ばれます。
RHSというジェネリックな型引数("right hand side": 右辺の省略形)が、`add`メソッドの`rhs`引数の型を定義しています。
`Add`トレイトを実装する際に`RHS`の具体的な型を指定しなければ、`RHS`の型は標準で`Self`になり、
これは`Add`を実装している型になります。

`Point`に`Add`を実装する際、2つの`Point`インスタンスを足したかったので、`RHS`の規定を使用しました。
既定を使用するのではなく、`RHS`の型をカスタマイズしたくなる`Add`トレイトの実装例に目を向けましょう。

異なる単位で値を保持する構造体、`Millimeters`と`Meters`(それぞれ`ミリメートル`と`メートル`)が2つあります。
ミリメートルの値をメートルの値に足し、`Add`の実装に変換を正しくしてほしいです。
`Add`を`RHS`に`Meters`のある`Millimeters`に実装することができます。リスト20-23のように:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-16/src/lib.rs}}
```

<span class="caption">リスト20-23: `Millimeters`に`Add`トレイトを実装して、`Meters`に`Millimeters`を足す</span>

`Millimeters`を`Meters`に足すため、`Self`という既定を使う代わりに`impl Add<Meters>`を指定して、
`RHS`型引数の値をセットしています。

主に2通りの方法でデフォルト型引数を使用します。

* 既存のコードを破壊せずに型を拡張する
* ほとんどのユーザーは必要としない特定の場合でカスタマイズを可能にする

標準ライブラリの`Add`トレイトは、2番目の目的の例です。 通常、2つの似た型を足しますが、
`Add`トレイトはそれ以上にカスタマイズする能力を提供します。`Add`トレイト定義でデフォルト型引数を使用することは、
ほとんどの場合、追加の引数を指定しなくてもよいことを意味します。つまり、トレイトを使いやすくして、
ちょっとだけ実装の定型コードが必要なくなるのです。

最初の目的は2番目に似ていますが、逆です。 既存のトレイトに型引数を追加したいなら、既定を与えて、
既存の実装コードを破壊せずにトレイトの機能を拡張できるのです。

### 明確化のためのフルパス記法: 同じ名前のメソッドを呼ぶ

Rustにおいて、別のトレイトのメソッドと同じ名前のメソッドがトレイトにあったり、両方のトレイトを1つの型に実装することを妨げるものは何もありません。
トレイトのメソッドと同じ名前のメソッドを直接型に実装することも可能です。

同じ名前のメソッドを呼ぶ際、コンパイラにどれを使用したいのか教える必要があるでしょう。両方とも`fly`というメソッドがある2つのトレイト、
`Pilot`と`Wizard`(`訳注`: パイロットと魔法使い)を定義したリスト20-24のコードを考えてください。
それから両方のトレイトを既に`fly`というメソッドが実装されている型`Human`(`訳注`: 人間)に実装します。
各`fly`メソッドは異なることをします。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-17/src/main.rs:here}}
```

<span class="caption">リスト20-24: 2つのトレイトに`fly`があるように定義され、`Human`に実装されつつ、
    `fly`メソッドは`Human`に直接にも実装されている</span>

`Human`のインスタンスに対して`fly`を呼び出すと、コンパイラは型に直接実装されたメソッドを標準で呼び出します。
リスト20-25のようにですね:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-18/src/main.rs:here}}
```

<span class="caption">リスト20-25: `Human`のインスタンスに対して`fly`を呼び出す</span>

このコードを実行すると、`*waving arms furiously*`と出力され、コンパイラが`Human`に直接実装された`fly`メソッドを呼んでいることを示しています。

`Pilot`トレイトか、`Wizard`トレイトの`fly`メソッドを呼ぶためには、
より明示的な記法を使用して、どの`fly`メソッドを意図しているか指定する必要があります。
リスト20-26は、この記法をデモしています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-19/src/main.rs:here}}
```

<span class="caption">リスト20-26: どのトレイトの`fly`メソッドを呼び出したいか指定する</span>

メソッド名の前にトレイト名を指定すると、コンパイラにどの`fly`の実装を呼び出したいか明確化できます。
また、`Human::fly(&person)`と書くこともでき、リスト20-26で使用した`person.fly()`と等価ですが、
こちらの方は明確化する必要がないなら、ちょっと記述量が増えます。

このコードを実行すると、こんな出力がされます。

```console
{{#include ../listings/ch20-advanced-features/listing-20-19/output.txt}}
```

`fly`メソッドは`self`引数を取るので、1つの*トレイト*を両方実装する*型*が2つあれば、
コンパイラには、`self`の型に基づいてどのトレイトの実装を使うべきかわかるでしょう。

しかしながら、トレイトの一部になる関連関数には`self`引数がありません。同じスコープの2つの型がそのトレイトを実装する場合、
*フルパス記法*(fully qualified syntax)を使用しない限り、どの型を意図しているかコンパイラは推論できません。例えば、
リスト20-27の`Animal`トレイトには、関連関数`baby_name`、構造体`Dog`の`Animal`の実装、
`Dog`に直接定義された関連関数`baby_name`があります。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-20/src/main.rs}}
```

<span class="caption">リスト20-27: 関連関数のあるトレイトとそのトレイトも実装し、同じ名前の関連関数がある型</span>

このコードは、すべての子犬をスポットと名付けたいアニマル・シェルター(`訳注`: 身寄りのないペットを保護する保健所みたいなところ)用で、
`Dog`に定義された`baby_name`関連関数で実装されています。`Dog`型は、トレイト`Animal`も実装し、
このトレイトはすべての動物が持つ特徴を記述します。赤ちゃん犬は子犬と呼ばれ、
それが`Dog`の`Animal`トレイトの実装の`Animal`トレイトと紐づいた`base_name`関数で表現されています。

`main`で、`Dog::baby_name`関数を呼び出し、直接`Dog`に定義された関連関数を呼び出しています。
このコードは以下のような出力をします。

```console
{{#include ../listings/ch20-advanced-features/listing-20-20/output.txt}}
```

この出力は、欲しかったものではありません。`Dog`に実装した`Animal`トレイトの一部の`baby_name`関数を呼び出したいので、
コードは`A baby dog is called a puppy`と出力します。リスト20-26で使用したトレイト名を指定するテクニックは、
ここでは役に立ちません; `main`をリスト20-28のようなコードに変更したら、コンパイルエラーになるでしょう。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-21/src/main.rs:here}}
```

<span class="caption">リスト20-28: `Animal`トレイトの`baby_name`関数を呼び出そうとするも、コンパイラにはどの実装を使うべきかわからない</span>

`Animal::baby_name`はメソッドではなく関連関数であり、故に`self`引数がないので、どの`Animal::baby_name`が欲しいのか、
コンパイラには推論できません。こんなコンパイルエラーが出るでしょう。

```console
{{#include ../listings/ch20-advanced-features/listing-20-21/output.txt}}
```

`Dog`に対して`Animal`実装を使用したいと明確化し、コンパイラに指示するには、フルパス記法を使う必要があります。
リスト20-29は、フルパス記法を使用する方法をデモしています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-22/src/main.rs:here}}
```

<span class="caption">リスト20-29: フルパス記法を使って`Dog`に実装されているように、
    `Animal`トレイトからの`baby_name`関数を呼び出したいと指定する</span>

コンパイラに山カッコ内で型注釈を提供し、これは、この関数呼び出しでは`Dog`型を`Animal`として扱いたいと宣言することで、
`Dog`に実装されたように、`Animal`トレイトの`baby_name`メソッドを呼び出したいと示唆しています。
もうこのコードは、望み通りの出力をします。

```console
{{#include ../listings/ch20-advanced-features/listing-20-22/output.txt}}
```

一般的に、フルパス記法は、以下のように定義されています。

```rust,ignore
<Type as Trait>::function(receiver_if_method, next_arg, ...);
```

関連関数では、`receiver`がないでしょう。 他の引数のリストがあるだけでしょう。関数やメソッドを呼び出す箇所全部で、
フルパス記法を使用することもできるでしょうが、プログラムの他の情報からコンパイラが推論できるこの記法のどの部分も省略することが許容されています。
同じ名前を使用する実装が複数あり、どの実装を呼び出したいかコンパイラが特定するのに助けが必要な場合だけにこのより冗長な記法を使用する必要があるのです。

### スーパートレイトを使用して別のトレイト内で、あるトレイトの機能を必要とする

時として、あるトレイトに別のトレイトの機能を使用させる必要がある可能性があります。この場合、
依存するトレイトも実装されることを信用する必要があります。信用するトレイトは、実装しているトレイトの*スーパートレイト*です。

例えば、アスタリスクをフレームにする値を出力する`outline_print`メソッドがある`OutlinePrint`トレイトを作りたくなったとしましょう。
つまり、`Display`を実装し、`(x, y)`という結果になる`Point`構造体が与えられて、
`x`が`1`、`y`が`3`の`Point`インスタンスに対して`outline_print`を呼び出すと、以下のような出力をするはずです。

```text
**********
*        *
* (1, 3) *
*        *
**********
```

`outline_print`の実装では、`Display`トレイトの機能を使用したいです。故に、`Display`も実装する型に対してだけ`OutlinePrint`が動くと指定し、
`OutlinePrint`が必要とする機能を提供する必要があるわけです。トレイト定義で`OutlinePrint: Display`と指定することで、
そうすることができます。このテクニックは、トレイトにトレイト境界を追加することに似ています。
リスト20-30は、`OutlinePrint`トレイトの実装を示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-23/src/main.rs:here}}
```

<span class="caption">リスト20-30: `Display`からの機能を必要とする`OutlinePrint`トレイトを実装する</span>

`OutlinePrint`は`Display`トレイトを必要とすると指定したので、`Display`を実装するどんな型にも自動的に実装される`to_string`関数を使えます。
トレイト名の後にコロンと`Display`トレイトを追加せずに`to_string`を使おうとしたら、
現在のスコープで型`&Self`に`to_string`というメソッドは存在しないというエラーが出るでしょう。

`Display`を実装しない型、`Point`構造体などに`OutlinePrint`を実装しようとしたら、何が起きるか確認しましょう:

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch20-advanced-features/no-listing-02-impl-outlineprint-for-point/src/main.rs:here}}
```

`Display`が必要だけれども、実装されていないというエラーが出ます。

```console
{{#include ../listings/ch20-advanced-features/no-listing-02-impl-outlineprint-for-point/output.txt}}
```

これを修正するために、`Point`に`Display`を実装し、`OutlinePrint`が必要とする制限を満たします。
こんな感じで:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/no-listing-03-impl-display-for-point/src/main.rs:here}}
```

そうすれば、`Point`に`OutlinePrint`トレイトを実装してもコンパイルは成功し、
`Point`インスタンスに対して`outline_print`を呼び出し、アスタリスクのふちの中に表示することができます。

### ニュータイプパターンを使用して外部の型に外部のトレイトを実装する

第10章の「型にトレイトを実装する」節で、トレイトか型がクレートにローカルな限り、型にトレイトを実装できると述べるオーファンルールについて触れました。
*ニュータイプパターン*を使用してこの制限を回避することができ、タプル構造体に新しい型を作成することになります。
(タプル構造体については、第5章の「異なる型を生成する名前付きフィールドのないタプル構造体を使用する」節で説明しました。)
タプル構造体は1つのフィールドを持ち、トレイトを実装したい型の薄いラッパになるでしょう。そして、
ラッパの型はクレートにローカルなので、トレイトをラッパに実装できます。*ニュータイプ*という用語は、
Haskellプログラミング言語に端を発しています。このパターンを使用するのに実行時のパフォーマンスを犠牲にすることはなく、
ラッパ型はコンパイル時に省かれます。

例として、`Vec<T>`に`Display`を実装したいとしましょう。`Display`トレイトも`Vec<T>`型もクレートの外で定義されているので、
直接それを行うことはオーファンルールにより妨げられます。`Vec<T>`のインスタンスを保持する`Wrapper`構造体を作成できます。
そして、`Wrapper`に`Display`を実装し、`Vec<T>`値を使用できます。リスト20-31のように。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-24/src/main.rs}}
```

<span class="caption">リスト20-31: `Vec<String>`の周りに`Wrapper`を作成して`Display`を実装する</span>

`Display`の実装は、`self.0`で中身の`Vec<T>`にアクセスしています。`Wrapper`はタプル構造体で、
`Vec<T>`がタプルの添え字0の要素だからです。それから、`Wrapper`に対して`Display`型の機能を使用できます。

このテクニックを使用する欠点は、`Wrapper`が新しい型なので、保持している値のメソッドがないことです。
`self.0`に委譲して、`Wrapper`を`Vec<T>`と全く同様に扱えるように、`Wrapper`に直接`Vec<T>`のすべてのメソッドを実装しなければならないでしょう。
内部の型が持つすべてのメソッドを新しい型に持たせたいなら、
`Deref`トレイト(第15章の「`Deref`トレイトでスマートポインタを普通の参照のように扱う」節で議論しました)を`Wrapper`に実装して、
内部の型を返すことは解決策の1つでしょう。内部の型のメソッド全部を`Wrapper`型に持たせたくない(例えば、`Wrapper`型の機能を制限するなど)なら、
本当に欲しいメソッドだけを手動で実装しなければならないでしょう。

もう、トレイトに関してニュータイプパターンが使用される方法を知りました; トレイトが関連しなくても、
有用なパターンでもあります。焦点を変更して、Rustの型システムと相互作用する一部の高度な方法を見ましょう。
