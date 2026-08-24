## `if let`と`let...else`による簡潔な制御フロー

`if let`構文を使うと、`if`と`let`を組み合わせ、ある1つのパターンに一致する値だけを処理し、それ以外を無視するコードを簡潔に書けます。リスト6-6のプログラムを考えてみましょう。このプログラムは、変数`config_max`に入っている`Option<u8>`の値を照合しますが、値が`Some`バリアントだった場合にだけコードを実行します。

<Listing number="6-6" caption="値が`Some`の場合にだけコードを実行する`match`">

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/listing-06-06/src/main.rs:here}}
```

</Listing>

値が`Some`なら、パターンの中で値を変数`max`へ束縛し、`Some`バリアントに入っている値を表示します。`None`の値に対しては何もしたくありません。しかし、`match`式を成立させるには、1つのバリアントを処理した後に`_ => ()`を追加しなければなりません。これは、わずらわしい定型コードです。

代わりに、`if let`を使ってもっと短く書けます。次のコードは、リスト6-6の`match`と同じように動作します。

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/no-listing-12-if-let/src/main.rs:here}}
```

`if let`構文では、パターンと式を等号で区切ります。動作は`match`と同じで、式が`match`へ渡す値に相当し、パターンが最初のアームに相当します。ここではパターンが`Some(max)`であり、`max`には`Some`の中の値が束縛されます。そのため、対応する`match`アームで行ったのと同じように、`if let`ブロックの本体で`max`を使えます。`if let`ブロック内のコードは、値がパターンに一致した場合にだけ実行されます。

`if let`を使うと、入力する量、インデント、定型コードを減らせます。ただし、`match`が強制する網羅性の検査は失われます。網羅性の検査は、処理すべきケースを忘れていないことを保証するものです。`match`と`if let`のどちらを選ぶかは、その場面で何をしたいか、そして網羅性の検査と引き換えに簡潔さを得ることが適切かどうかによって決まります。

言い換えると、`if let`は「値が1つのパターンに一致したときにコードを実行し、それ以外の値はすべて無視する`match`」の糖衣構文だと考えられます。

`if let`には`else`も付けられます。`else`に対応するコードブロックは、同等の`match`式における`_`ケースのコードブロックと同じです。リスト6-4で定義した`Coin`列挙型を思い出してください。`Quarter`バリアントには`UsState`の値も格納されていました。25セント硬貨については州名を知らせ、それ以外の硬貨については枚数を数えたい場合、次のような`match`式を使えます。

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/no-listing-13-count-and-announce-match/src/main.rs:here}}
```

同じ処理を、次のように`if let`と`else`を使って書くこともできます。

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/no-listing-14-count-and-announce-if-let-else/src/main.rs:here}}
```

## `let...else`で「正常系」をまっすぐに保つ

よくあるパターンとして、値が存在する場合には何らかの計算を行い、存在しなければ既定値を返す処理があります。`UsState`の値を持つ硬貨の例を続けましょう。25セント硬貨に刻まれた州がどれほど古いかに応じて面白いことを言いたいなら、次のように州の古さを調べるメソッドを`UsState`へ追加できます。

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/listing-06-07/src/main.rs:state}}
```

次にリスト6-7のように、`if let`を使って硬貨の種類を照合し、条件の本体で`state`変数を導入できます。

<Listing number="6-7" caption="`if let`の中に条件式を入れ子にして、州が1900年に存在していたかを確認する">

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/listing-06-07/src/main.rs:describe}}
```

</Listing>

これで目的は達成できますが、処理が`if let`文の本体へ押し込まれています。行う処理がもっと複雑になると、最上位の分岐がどのように関係しているのかを追いにくくなるかもしれません。また、式が値を生成するという性質を利用し、リスト6-8のように、`if let`から`state`を生成するか、早期リターンすることもできます（`match`でも同じようなことができます）。

<Listing number="6-8" caption="`if let`を使って値を生成するか、早期リターンする">

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/listing-06-08/src/main.rs:describe}}
```

</Listing>

ただし、これも別の意味で少し追いにくいコードです。`if let`の一方の分岐は値を生成し、もう一方の分岐は関数全体から戻っています。

このよくあるパターンを表現しやすくするため、Rustには`let...else`があります。`let...else`構文では、`if let`とよく似た形で、左辺にパターン、右辺に式を置きます。ただし、`if`側の分岐はなく、`else`側の分岐だけがあります。パターンが一致すると、パターンから得た値が外側のスコープに束縛されます。パターンが一致しなければ、プログラムは`else`アームへ進みます。このアームは関数から戻らなければなりません。

リスト6-9では、リスト6-8の`if let`を`let...else`へ置き換えたコードを確認できます。

<Listing number="6-9" caption="`let...else`を使って関数内の流れを明確にする">

```rust
{{#rustdoc_include ../listings/ch06-enums-and-pattern-matching/listing-06-09/src/main.rs:describe}}
```

</Listing>

この書き方では、`if let`の2つの分岐のように制御フローが大きく分かれることなく、関数本体の主要な流れ、すなわち「正常系」をまっすぐに保てることに注目してください。

`match`を使うとプログラムのロジックが冗長になりすぎる場面では、Rustの道具箱には`if let`と`let...else`もあることを思い出してください。

## まとめ

ここまでで、列挙された複数の値のうち、いずれか1つになり得る独自の型を列挙型によって作る方法を説明しました。標準ライブラリの`Option<T>`型が、型システムを利用してエラーを防ぐのにどう役立つかも示しました。列挙型の値が内部にデータを持つ場合は、処理する必要のあるケースの数に応じて、`match`または`if let`を使ってその値を取り出し、利用できます。

これで、Rustプログラムから構造体と列挙型を使い、対象領域の概念を表現できるようになりました。APIで使う独自の型を作成すると、型安全性が保証されます。コンパイラは、各関数が期待する型の値だけを受け取るように確認してくれます。

利用者にとって整理され、分かりやすく、必要なものだけを公開するAPIを提供するため、次はRustのモジュールについて見ていきましょう。

