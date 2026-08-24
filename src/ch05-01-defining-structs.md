## 構造体を定義し、インスタンス化する

構造体は、[「タプル型」][tuples]の節で議論したタプルと、どちらも関係する複数の値を抱えるという点で似ています。
タプル同様、構造体の一部を異なる型にできます。
一方タプルとは違って、構造体では各データ片には名前をつけるので、値の意味が明確になります。
これらの名前が付いていることで、構造体はタプルに比して、より柔軟になるわけです: データの順番に頼って、
インスタンスの値を指定したり、アクセスしたりする必要がないのです。

構造体の定義は、`struct`キーワードを入れ、構造体全体に名前を付けます。構造体名は、
一つにグループ化されるデータ片の意義を表すものであるべきです。そして、波かっこ内に、
データ片の名前と型を定義し、これは*フィールド*と呼ばれます。例えば、リスト5-1では、
ユーザアカウントに関する情報を保持する構造体を示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-01/src/main.rs:here}}
```

<span class="caption">リスト5-1: `User`構造体定義</span>

構造体を定義した後に使用するには、各フィールドに対して具体的な値を指定して構造体の*インスタンス*を生成します。
インスタンスは、構造体名を記述し、*key: value*ペアを含む波かっこを付け加えることで生成します。
ここで、キーはフィールド名、値はそのフィールドに格納したいデータになります。フィールドは、
構造体で宣言した通りの順番に指定する必要はありません。換言すると、構造体定義とは、
型に対する一般的な雛形のようなものであり、インスタンスは、その雛形を特定のデータで埋め、その型の値を生成するわけです。
例えば、リスト5-2で示されたように特定のユーザを宣言することができます。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-02/src/main.rs:here}}
```

<span class="caption">リスト5-2: `User`構造体のインスタンスを生成する</span>

構造体から特定の値を得るには、ドット記法を使います。例えば、
このユーザのEメールアドレスにアクセスするには、`user1.email`を使います。
インスタンスが可変であれば、ドット記法を使い特定のフィールドに代入することで値を変更できます。
リスト5-3では、可変な`User`インスタンスの`email`フィールド値を変更する方法を示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-03/src/main.rs:here}}
```

<span class="caption">リスト5-3: ある`User`インスタンスの`email`フィールド値を変更する</span>

インスタンス全体が可変でなければならないことに注意してください; Rustでは、一部のフィールドのみを可変にすることはできないのです。
また、あらゆる式同様、構造体の新規インスタンスを関数本体の最後の式として生成して、
そのインスタンスを返すことを暗示できます。

リスト5-4は、与えられたemailとusernameで`User`インスタンスを生成する`build_user`関数を示しています。
`active`フィールドには`true`値が入り、`sign_in_count`には値`1`が入ります。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-04/src/main.rs:here}}
```

<span class="caption">リスト5-4: Eメールとユーザ名を取り、`User`インスタンスを返す`build_user`関数</span>

構造体のフィールドと同じ名前を関数の引数にもつけることは筋が通っていますが、
`email`と`username`というフィールド名と変数を繰り返さなきゃいけないのは、ちょっと面倒です。
構造体にもっとフィールドがあれば、名前を繰り返すことはさらに煩わしくなるでしょう。
幸運なことに、便利な省略記法があります！

### フィールド初期化省略記法を使う

仮引数名と構造体のフィールド名がリスト5-4では、全く一緒なので、*フィールド初期化省略*記法を使って`build_user`を書き換えても、
振る舞いは全く同じにしつつ、リスト5-5に示したように`username`と`email`を繰り返さなくてもよくなります。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-05/src/main.rs:here}}
```

<span class="caption">リスト5-5: `username`と`email`引数が構造体のフィールドと同名なので、
フィールド初期化省略法を使用する`build_user`関数</span>

ここで、`email`というフィールドを持つ`User`構造体の新規インスタンスを生成しています。
`email`フィールドを`build_user`関数の`email`引数の値にセットしたいわけです。
`email`フィールドと`email`引数は同じ名前なので、`email: email`と書くのではなく、
`email`と書くだけで済むのです。

### 構造体更新記法で他のインスタンスからインスタンスを生成する

他のインスタンスからの値の多くの部分を含みつつ、一部を変更する形で新しいインスタンスを生成できるとしばしば有用です。
*構造体更新記法*でそうすることができます。

まず、リスト5-6では、更新記法なしで普通に`user2`に新しい`User`インスタンスを生成する方法を示しています。
`email`には新しい値をセットしていますが、それ以外にはリスト5-2で生成した`user1`の値を使用しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-06/src/main.rs:here}}
```

<span class="caption">リスト5-6: `user1`の一部の値を使用しつつ、新しい`User`インスタンスを生成する</span>

構造体更新記法を使用すると、リスト5-7に示したように、コード量を減らしつつ、同じ効果を達成できます。`..`という記法により、
明示的にセットされていない残りのフィールドが、与えられたインスタンスのフィールドと同じ値になるように指定します。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/listing-05-07/src/main.rs:here}}
```

<span class="caption">リスト5-7: 構造体更新記法を使用して、新しい`User`インスタンス用の値に新しい`email`をセットしつつ、
残りの値は`user1`を使う</span>

リスト5-7のコードも、`email`については`user1`とは異なる値、`username`、`active`と`sign_in_count`フィールドについては、
`user1`と同じ値になるインスタンスを`user2`に生成します。
`..user1`は、残りのフィールドについては`user1`の対応するフィールドから値を取る、ということを示すために最後に来る必要がありますが、
フィールドについては好きなだけ多く、構造体定義中のフィールドの順序とは無関係に好きな順で、値を指定してかまいません。

構造体更新記法は代入と同様に`=`を使います; これは、[「ムーブによる変数とデータの相互作用」][move]の節で見たのと同じように、
データをムーブするからです。この例で言うと、`user2`を作成した後は、もう`user1`をそっくりそのまま使うことはできません。
`user1`の`username`フィールド中の`String`が`user2`の中にムーブされてしまったからです。
もし`user2`に、`email`と`username`のために新しい`String`値を与えていたなら、つまり、
`user1`からは`active`と`sign_in_count`の値だけを使用していたなら、`user2`を作成した後も`user1`はまだ有効だったでしょう。
`active`と`sign_in_count`はどちらも`Copy`トレイトを実装した型なので、[「スタックのみのデータ: コピー」][copy]節で議論した振る舞いが適用されるからです。

### 異なる型を生成する名前付きフィールドのないタプル構造体を使用する

Rustは、構造体名により追加の意味を含むものの、フィールドに紐づけられた名前がなく、むしろフィールドの型だけの*タプル構造体*と呼ばれる、
タプルに似た構造体もサポートしています。タプル構造体は、構造体名が提供する追加の意味は含むものの、
フィールドに紐付けられた名前はありません; むしろ、フィールドの型だけが存在します。タプル構造体は、タプル全体に名前をつけ、
そのタプルを他のタプルとは異なる型にしたいが、普通の構造体のように各フィールド名を与えるのは、
冗長、または余計という場合に有用です。

タプル構造体を定義するには、`struct`キーワードの後に構造体名、さらにタプルに含まれる型を続けてください。
例えば、ここでは、`Color`と`Point`という2種類のタプル構造体の定義して使用します:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/no-listing-01-tuple-structs/src/main.rs}}
```

`black`と`origin`の値は、違う型であることに注目してください。これらは、異なるタプル構造体のインスタンスだからですね。
定義された各構造体は、構造体内のフィールドが同じ型であっても、それ自身が独自の型になります。
例えば、`Color`型を引数に取る関数は、`Point`を引数に取ることはできません。たとえ、両者の型が、
3つの`i32`値からできていてもです。それ以外については、タプル構造体のインスタンスは、
分配して個々の部品にしたり、`.`と添え字を使用して個々の値にアクセスできるという点で、タプルと似ています。

### フィールドのないユニット<ruby>様<rp>(</rp><rt>よう</rt><rp>)</rp></ruby>構造体

また、一切フィールドのない構造体を定義することもできます！これらは、`()`、
[「タプル型」][tuples]の節で言及したユニット型と似たような振る舞いをすることから、
*ユニット様構造体*と呼ばれます。ユニット様構造体は、ある型にトレイトを実装するけれども、
型自体に保持させるデータは一切ない場面に有効になります。トレイトについては第10章で議論します。
以下は、`AlwaysEqual`という名前のユニット様構造体を宣言し、インスタンス化する例です:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch05-using-structs-to-structure-related-data/no-listing-04-unit-like-structs/src/main.rs}}
```

`AlwaysEqual`を定義するためには、`struct`キーワード、付けたい名前、そしてセミコロンを使います。
波括弧や丸括弧は不要です！
次に、同じようにして、`subject`変数に`AlwaysEqual`のインスタンスを得られます: 波括弧や丸括弧を付けずに、定義した名前を使います。
後でこの型の振る舞いを、おそらくはテスト目的で既知の結果を得るために、`AlwaysEqual`のすべてのインスタンスが常に他の任意の型と等価であるように実装することを想像してください。
この挙動を実装するためにデータはまったく必要ないですね！
トレイトを定義して、ユニット様構造体も含めた任意の型にそれを実装する方法については10章で触れます。

> ### 構造体データの所有権
>
> リスト5-1の`User`構造体定義において、`&str`文字列スライス型ではなく、所有権のある`String`型を使用しました。
> これは意図的な選択です。というのも、この構造体の各インスタンスには自身の全データを所有してもらう必要があり、
> このデータは、構造体全体が有効な間はずっと有効である必要があるのです。
>
> 構造体に、他の何かに所有されたデータへの参照を保持させることもできますが、
> そうするには*ライフタイム*という第10章で議論するRustの機能を使用しなければなりません。
> ライフタイムのおかげで構造体に参照されたデータが、構造体自体が有効な間、ずっと有効であることを保証してくれるのです。
> 次のように、ライフタイムを指定せずに構造体に参照を保持させようとしたとしましょう。これは動きません:
>
> <span class="filename">ファイル名: src/main.rs</span>
>
> ```rust,ignore,does_not_compile
> struct User {
>     active: bool,
>     username: &str,
>     email: &str,
>     sign_in_count: u64,
> }
>
> fn main() {
>     let user1 = User {
>         active: true,
>         username: "someusername123",
>         email: "someone@example.com",
>         sign_in_count: 1,
>     };
> }
> ```
>
> コンパイラは、ライフタイム指定子が必要だと怒るでしょう:
>
> ```console
> $ cargo run
>    Compiling structs v0.1.0 (file:///projects/structs)
> error[E0106]: missing lifetime specifier
> (エラー: ライフタイム指定子がありません)
>  --> src/main.rs:3:15
>   |
> 3 |     username: &str,
>   |               ^ expected named lifetime parameter
>   |                (ライフタイム引数を予期しました)
>   |
> help: consider introducing a named lifetime parameter
>   |
> 1 ~ struct User<'a> {
> 2 |     active: bool,
> 3 ~     username: &'a str,
>   |
>
> error[E0106]: missing lifetime specifier
>  --> src/main.rs:4:12
>   |
> 4 |     email: &str,
>   |            ^ expected named lifetime parameter
>   |
> help: consider introducing a named lifetime parameter
>   |
> 1 ~ struct User<'a> {
> 2 |     active: bool,
> 3 |     username: &str,
> 4 ~     email: &'a str,
>   |
>
> For more information about this error, try `rustc --explain E0106`.
> error: could not compile `structs` (bin "structs") due to 2 previous errors
> ```
>
> 第10章で、これらのエラーを解消して構造体に参照を保持する方法について議論しますが、
> 当面、今回のようなエラーは、`&str`のような参照の代わりに、`String`のような所有された型を使うことで修正します。

[tuples]: ch03-02-data-types.html#タプル型
[move]: ch04-01-what-is-ownership.html#ムーブによる変数とデータの相互作用
[copy]: ch04-01-what-is-ownership.html#スタックのみのデータ-コピー


