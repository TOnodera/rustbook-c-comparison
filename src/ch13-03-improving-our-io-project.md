

## 入出力プロジェクトを改善する

このイテレータに関する新しい知識があれば、イテレータを使用してコードのいろんな場所をより明確で簡潔にすることで、
第12章の入出力プロジェクトを改善することができます。イテレータが`Config::build`関数と`search`関数の実装を改善する方法に目を向けましょう。

### イテレータを使用して`clone`を取り除く

リスト12-6において、スライスに添え字アクセスして値をクローンすることで、`Config`構造体に値を所有させながら、
`String`値のスライスを取り、`Config`構造体のインスタンスを作るコードを追記しました。リスト13-17では、
リスト12-23のような`Config::build`の実装を再現しました:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch13-functional-features/listing-12-23-reproduced/src/main.rs:ch13}}
```

<span class="caption">リスト13-17: リスト12-23から`Config::build`関数の再現</span>

その際、将来的に除去する予定なので、非効率的な`clone`呼び出しを憂慮するなと述べました。
えっと、その時は今です！

引数`args`に`String`要素のスライスがあるためにここで`clone`が必要だったのですが、
`build`関数は`args`を所有していません。`Config`インスタンスの所有権を返すためには、
`Config`インスタンスがその値を所有できるように、`Config`の`query`と`file_path`フィールドから値をクローンしなければなりませんでした。

イテレータについての新しい知識があれば、`build`関数をスライスを借用する代わりに、
引数としてイテレータの所有権を奪うように変更することができます。スライスの長さを確認し、
特定の場所に添え字アクセスするコードの代わりにイテレータの機能を使います。これにより、
イテレータは値にアクセスするので、`Config::build`関数がすることが明確化します。

ひとたび、`Config::build`がイテレータの所有権を奪い、借用する添え字アクセス処理をやめたら、
`clone`を呼び出して新しくメモリ確保するのではなく、イテレータからの`String`値を`Config`にムーブできます。

#### 返却されるイテレータを直接使う

入出力プロジェクトの*src/main.rs*ファイルを開いてください。こんな見た目のはずです。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch13-functional-features/listing-12-24-reproduced/src/main.rs:ch13}}
```

まずはリスト12-24のような`main`関数の冒頭を、今回はイテレータを使用するリスト13-18のコードに変更します。
これは、`Config::build`も更新するまでコンパイルできません。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch13-functional-features/listing-13-18/src/main.rs:here}}
```

<span class="caption">リスト13-18: `env::args`の戻り値を`Config::build`に渡す</span>

`env::args`関数は、イテレータを返します！イテレータの値をベクタに集結させ、それからスライスを`Config::build`に渡すのではなく、
今では`env::args`から返ってくるイテレータの所有権を直接`Config::build`に渡しています。

次に、`Config::build`の定義を更新する必要があります。入出力プロジェクトの*src/lib.rs*ファイルで、
`Config::build`のシグニチャをリスト13-19のように変えましょう。関数本体を更新する必要があるので、
それでもコンパイルはできません。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch13-functional-features/listing-13-19/src/main.rs:here}}
```

<span class="caption">リスト13-19: `Config::build`のシグニチャをイテレータを期待するように更新する</span>

`env::args`関数の標準ライブラリドキュメントは、この関数が返すイテレータの型は`std::env::Args`であること、
そしてこの型は`String`値を返す`Iterator`トレイトを実装していることを示しています。

引数`args`の型が`&[String]`ではなく、トレイト境界`impl Iterator<Item = String>`を持つジェネリック型を持つように、
`Config::build`関数のシグニチャを更新しています。第10章の[「引数としてのトレイト」][impl-trait]節で説明した`impl Trait`構文のここでの使用は、
`args`は`Iterator`型を実装し`String`要素を返す任意の型でよいことを意味します。

`args`の所有権を奪い、繰り返しを行うことで`args`を可変化する予定なので、
`args`引数の仕様に`mut`キーワードを追記でき、可変にします。

#### 添え字の代わりに`Iterator`トレイトのメソッドを使用する

次に、`Config::build`の本体を修正しましょう。`args`は`Iterator`トレイトを実装しているので、
それに対して`next`メソッドを呼び出せることがわかります！リスト13-20は、
リスト12-23のコードを`next`メソッドを使用するように更新したものです。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,noplayground
{{#rustdoc_include ../listings/ch13-functional-features/listing-13-20/src/main.rs:here}}
```

<span class="caption">リスト13-20: `Config::build`の本体をイテレータメソッドを使うように変更する</span>

`env::args`の戻り値の1番目の値は、プログラム名であることを思い出してください。それは無視し、
次の値を取得したいので、まず`next`を呼び出し、戻り値に対して何もしません。2番目に、
`next`を呼び出して`Config`の`query`フィールドに置きたい値を得ます。`next`が`Some`を返したら、
`match`を使用してその値を抜き出します。`None`を返したら、十分な引数が与えられなかったということなので、
`Err`値で早期リターンします。`file_path`値に対しても同じことをします。

### イテレータアダプタでコードをより明確にする

入出力プロジェクトの`search`関数でも、イテレータを活用することができます。その関数はリスト12-19に示していますが、以下のリスト13-28に再掲します。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-19/src/lib.rs:ch13}}
```

<span class="caption">リスト13-21: リスト12-19の`search`関数の実装</span>

イテレータアダプタメソッドを使用して、このコードをもっと簡潔に書くことができます。そうすれば、
可変な中間の`results`ベクタをなくすこともできます。関数型プログラミングスタイルは、可変な状態の量を最小化することを好み、
コードを明瞭化します。可変な状態を除去すると、検索を同時並行に行うという将来的な改善をするのが、
可能になる可能性があります。なぜなら、`results`ベクタへの同時アクセスを管理する必要がなくなるからです。
リスト13-22は、この変更を示しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch13-functional-features/listing-13-22/src/lib.rs:here}}
```

<span class="caption">リスト13-22: `search`関数の実装でイテレータアダプタのメソッドを使用する</span>

`search`関数の目的は、`query`を含む`contents`の行すべてを返すことであることを思い出してください。
リスト13-16の`filter`例に酷似して、このコードは`filter`アダプタを使用して`line.contains(query)`が`true`を返す行だけを残すことができます。
それから、合致した行を別のベクタに`collect`で集結させます。ずっと単純です！ご自由に、
同じ変更を行い、`search_case_insensitive`関数でもイテレータメソッドを使うようにしてください。

### ループかイテレータかの選択

次の論理的な疑問は、自身のコードでどちらのスタイルを選ぶかと理由です。 リスト13-21の元の実装とリスト13-22のイテレータを使用するバージョンです。
多くのRustプログラマは、イテレータスタイルを好みます。とっかかりが少し困難ですが、
いろんなイテレータアダプタとそれがすることの感覚を一度掴めれば、イテレータの方が理解しやすいこともあります。
いろんなループを少しずつもてあそんだり、新しいベクタを構築する代わりに、コードは、ループの高難度の目的に集中できるのです。
これは、ありふれたコードの一部を抽象化するので、イテレータの各要素が通過しなければならないふるい条件など、
このコードに独特の概念を理解しやすくなります。

ですが、本当に2つの実装は等価なのでしょうか？直観的な仮説は、より低レベルのループの方がより高速ということかもしれません。
パフォーマンスに触れましょう。

[impl-trait]: ch10-02-traits.html#traits-as-parameters
