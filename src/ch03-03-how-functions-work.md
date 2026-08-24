## 関数

関数は、Rustのコードにおいてよく見かける存在です。既に、言語において最も重要な関数のうちの一つを目撃していますね:
そう、`main`関数です。これは、多くのプログラムで実行を開始するエントリーポイントになります。
`fn`キーワードもすでに見かけましたね。これによって新しい関数を宣言することができます。

Rustの関数と変数の命名規則には、`some_variable`のような*スネークケース*を使うのが慣例です。
スネークケースとは、全文字を小文字にし、単語区切りにアンダースコアを使うことです。
以下のプログラムで、サンプルの関数定義をご覧ください:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-16-functions/src/main.rs}}
```

Rustでは、`fn`に続けて関数名と丸かっこの組を入力して関数を定義します。
波かっこが、コンパイラに関数本体の開始と終了の位置を伝えます。

定義した関数は、名前に丸かっこの組を続けることで呼び出すことができます。
`another_function`関数がプログラム内で定義されているので、`main`関数内から呼び出すことができるわけです。
ソースコード中で`another_function`を`main`関数の*後*に定義していることに注目してください;
勿論、main関数の前に定義することもできます。コンパイラは、関数がどこで定義されているかは気にしません。
呼び出し元から見えるスコープ内のどこかで定義されていることのみ気にします。

*functions*という名前の新しいバイナリ生成プロジェクトを始めて、関数についてさらに深く探究していきましょう。
`another_function`の例を*src/main.rs*ファイルに配置して、走らせてください。
以下のような出力が得られるはずです:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-16-functions/output.txt}}
```

行出力は、`main`関数内に書かれた順序で実行されています。最初に"Hello, world"メッセージが出て、
それから`another_function`が呼ばれて、こちらのメッセージが出力されています。

### 引数

関数は、*仮引数 (parameter)* を持つよう定義することもできます。仮引数とは、関数シグニチャの一部になる特別な変数のことです。
関数に仮引数があると、仮引数に対して具体的な値を与えることができます。
厳密にはこの具体的な値は*実引数 (argument)* と呼ばれますが、普段の会話では、関数定義内の変数と関数呼び出し時に渡す実際の値の両方の意味で、
*parameter*と*argument*を区別なく使う傾向にあります。日本語でも、特に区別する必要がない場合は、どちらも単に*引数*と呼ぶことがあります。

次の版の`another_function`では、仮引数を追加しています:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-17-functions-with-parameters/src/main.rs}}
```

このプログラムを走らせてみてください; 以下のような出力が得られるはずです:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-17-functions-with-parameters/output.txt}}
```

`another_function`の宣言には、`x`という名前の仮引数があります。`x`の型は、
`i32`と指定されています。値`5`を`another_function`に渡すと、`println!`マクロにより、
フォーマット文字列中の`x`を含む1組の波かっこがあった位置に値`5`が出力されます。

関数シグニチャにおいて、各仮引数の型を宣言しなければ*なりません*。これは、Rustの設計において、
意図的な判断です: 関数定義で型注釈が必要不可欠ということは、コンパイラがその意図する型を推し量るのに、
プログラマがコードの他の箇所で使用する必要がないということを意味します。
コンパイラも、関数が期待する型を知っていれば、より役に立つエラーメッセージを与えることができます。

関数に複数の仮引数を定義したいときは、仮引数定義をカンマで区切ってください。
こんな感じです:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-18-functions-with-multiple-parameters/src/main.rs}}
```

この例では、`print_labeled_measurement`という名前の2引数の関数を生成しています。
第1引数は`value`という名前で`i32`です。第2引数は`unit_label`という名前で`char`型です。
この関数は`value`と`unit_label`の両方を含むテキストを出力します。

このコードを走らせてみましょう。今、*function*プロジェクトの*src/main.rs*ファイルに記載されているプログラムを先ほどの例と置き換えて、
`cargo run`で走らせてください:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-18-functions-with-multiple-parameters/output.txt}}
```

`value`に対して値`5`、`unit_label`に対して値`'h'`を渡して関数を呼び出したので、
プログラムの出力にはこれらの値が含まれます。

### 文と式

関数本体は、文が並び、最後に式を置くか文を置くという形で形成されます。今のところ、
私たちが見てきた関数は式で終わることはありませんでしたが、式が文の一部になっているものなら見かけましたね。Rustは、式指向言語なので、
これは理解しておくべき重要な差異になります。他の言語にこの差異はありませんので、文と式がなんなのかと、
その違いが関数本体にどんな影響を与えるかを見ていきましょう。

* *文 (statement)* はなんらかの動作をして値を返さない命令です。
* *式 (expression)* は結果値に評価されます。ちょっと例を眺めてみましょう。

実のところ、もう文と式は使っています。
`let`キーワードを使用して変数を生成し、値を代入することは文になります。
リスト3-1で`let y = 6;`は文です。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/listing-03-01/src/main.rs}}
```

<span class="caption">リスト3-1: 1文を含む`main`関数宣言</span>

関数定義も文になります。つまり、先の例は全体としても文になるわけです。

文は値を返しません。故に、`let`文を他の変数に代入することはできません。
以下のコードではそれを試みていますが、エラーになります:

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-19-statements-vs-expressions/src/main.rs}}
```

このプログラムを実行すると、以下のようなエラーが出るでしょう:


```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-19-statements-vs-expressions/output.txt}}
```

この`let y = 6`という文は値を返さないので、`x`に束縛するものがないわけです。これは、
CやRubyなどの言語とは異なる動作です。CやRubyでは、代入は代入値を返します。これらの言語では、
`x = y = 6`と書いて、`x`も`y`も値6になるようにできるのですが、Rustにおいては、
そうは問屋が卸さないわけです。

式は値に評価され、これからあなたが書くRustコードの多くを構成します。
数学演算(`5 + 6`など)を思い浮かべましょう。この例は、値`11`に評価される式です。式は文の一部になりえます:
リスト3-1において、`let y = 6`という文の`6`は値`6`に評価される式です。関数呼び出しも式です。マクロ呼び出しも式です。
波括弧で作られる新しいスコープも式です:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-20-blocks-are-expressions/src/main.rs}}
```

以下の式:

```rust,ignore
{
    let x = 3;
    x + 1
}
```

は今回の場合、`4`に評価されるブロックです。その値が、`let`文の一部として`y`に束縛されます。
今まで見かけてきた行と異なり、`x + 1`の行には文末にセミコロンがついていないことに気をつけてください。
式は終端にセミコロンを含みません。式の終端にセミコロンを付けたら、文に変えてしまいます。そして、文は値を返しません。
次に関数の戻り値や式を見ていく際にこのことを肝に銘じておいてください。

### 戻り値のある関数

関数は、それを呼び出したコードに値を返すことができます。戻り値に名前を付けはしませんが、
矢印(`->`)の後に型を書いて宣言する必要があります。Rustでは、関数の戻り値は、関数本体ブロックの最後の式の値と同義です。
`return`キーワードで関数から早期リターンし、値を指定することもできますが、多くの関数は最後の式を暗黙的に返します。
こちらが、値を返す関数の例です:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-21-function-return-values/src/main.rs}}
```

`five`関数内には、関数呼び出しもマクロ呼び出しも、`let`文でさえ存在しません。数字の5が単独であるだけです。
これは、Rustにおいて、完璧に問題ない関数です。関数の戻り値型が`-> i32`と指定されていることにも注目してください。
このコードを実行してみましょう; 出力はこんな感じになるはずです:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-21-function-return-values/output.txt}}
```

`five`内の`5`が関数の戻り値です。だから、戻り値型が`i32`なのです。これについてもっと深く考察しましょう。
重要な箇所は2つあります: まず、`let x = five()`という行は、関数の戻り値を使って変数を初期化していることを示しています。
関数`five`は`5`を返すので、この行は以下のように書くのと同義です:

```rust
let x = 5;
```

2番目に、`five`関数は仮引数をもたず、戻り値型を定義していますが、関数本体はセミコロンなしの`5`単独です。
なぜなら、これが返したい値になる式だからです。

もう一つ別の例を見ましょう:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-22-function-parameter-and-return/src/main.rs}}
```

このコードを走らせると、`The value of x is: 6`と出力されるでしょう。しかし、
`x + 1`を含む行の終端にセミコロンを付けて、式から文に変えたら、エラーになるでしょう:

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-23-statements-dont-return-values/src/main.rs}}
```

このコードをコンパイルすると、以下のようにエラーが出ます:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-23-statements-dont-return-values/output.txt}}
```

メインのエラーメッセージである`mismatched types (型が合いません)`でこのコードの根本的な問題が明らかになるでしょう。
関数`plus_one`の定義では、`i32`型を返すと言っているのに、文は値に評価されないからです。このことは、
`()`、つまりユニット型として表現されています。それゆえに、何も戻り値がなく、これが関数定義と矛盾するので、
結果としてエラーになるわけです。この出力内で、コンパイラは問題を修正する手助けになりそうなメッセージも出していますね: 
セミコロンを削除するよう提言しています。そして、そうすれば、エラーは直るわけです。

