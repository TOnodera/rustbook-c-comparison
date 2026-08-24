## 制御フロー

条件が`true`かどうかによってコードを走らせたり、
条件が`true`の間繰り返しコードを走らせたりできることは、多くのプログラミング言語において、基本的な構成ブロックです。
Rustコードの実行フローを制御する最も一般的な文法要素は、`if`式とループです。

### `if`式

if式によって、条件に依存して枝分かれをさせることができます。条件を与え、以下のように宣言します。
「もし条件が合ったら、この一連のコードを実行しろ。条件に合わなければ、この一連のコードは実行するな」と。

*projects*ディレクトリに*branches*という名のプロジェクトを作って`if`式について掘り下げていきましょう。
*src/main.rs*ファイルに、以下のように入力してください:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-26-if-true/src/main.rs}}
```

`if`式は全て、キーワードの`if`から始め、条件式を続けます。今回の場合、
条件式は変数`number`が5未満の値になっているかどうかをチェックします。
条件が`true`の時に実行する一連のコードを条件式の直後に波かっこで包んで配置します。`if`式の条件式と紐付けられる一連のコードは、
時として*アーム*と呼ばれることがあります。
第2章の[「予想と秘密の数字を比較する」][comparing-the-guess-to-the-secret-number]の節で議論した`match`式のアームと同じです。

オプションとして、`else`式を含むこともでき(ここではそうしています)、これによりプログラムは、
条件式が偽になった時に実行するコードを与えられることになります。仮に、`else`式を与えずに条件式が偽になったら、
プログラムは単に`if`ブロックを飛ばして次のコードを実行しにいきます。

このコードを走らせてみましょう; 以下のような出力を目の当たりにするはずです:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-26-if-true/output.txt}}
```

`number`の値を条件が`false`になるような値に変更してどうなるか確かめてみましょう:

```rust,ignore
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-27-if-false/src/main.rs:here}}
```

再度プログラムを実行して、出力に注目してください:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-27-if-false/output.txt}}
```

このコード内の条件式は、`bool`型で*なければならない*ことにも触れる価値があります。
条件式が、`bool`型でない時は、エラーになります。例えば、試しに以下のコードを実行してみてください:

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-28-if-condition-must-be-bool/src/main.rs}}
```

今回、`if`の条件式は`3`という値に評価され、コンパイラがエラーを投げます:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-28-if-condition-must-be-bool/output.txt}}
```

このエラーは、コンパイラは`bool`型を予期していたのに、整数だったことを示唆しています。
RubyやJavaScriptなどの言語とは異なり、Rustでは、論理値以外の値が、自動的に論理値に変換されることはありません。
明示し、必ず`if`には条件式として、`論理値`を与えなければなりません。
例えば、数値が`0`以外の時だけ`if`のコードを走らせたいなら、以下のように`if`式を変更することができます:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-29-if-not-equal-0/src/main.rs}}
```

このコードを実行したら、`number was something other than zero`と表示されるでしょう。

#### `else if`で複数の条件を扱う

`if`と`else`を組み合わせて`else if`式にすることで複数の条件を使うこともできます。例です:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-30-else-if/src/main.rs}}
```

このプログラムには、通り道が4つあります。実行後、以下のような出力を目の当たりにするはずです:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-30-else-if/output.txt}}
```

このプログラムを実行すると、`if`式が順番に吟味され、最初に条件が`true`に評価された本体が実行されます。
6は2で割り切れるものの、`number is divisible by 2`や、
`else`ブロックの`number is not divisible by 4, 3, or 2`という出力はされないことに注目してください。
それは、Rustが最初の`true`な条件のブロックのみを実行し、
条件に合ったものが見つかったら、残りはチェックすらしないからです。

`else if`式を使いすぎると、コードがめちゃくちゃになってしまうので、1つ以上あるなら、
コードをリファクタリングしたくなるかもしれません。これらのケースに有用な`match`と呼ばれる、
強力なRustの枝分かれ文法要素については第6章で解説します。

#### `let`文内で`if`式を使う

`if`は式なので、`let`文の右辺に持ってきて結果を変数に代入することができます。リスト3-2のようにですね。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/listing-03-02/src/main.rs}}
```

<span class="caption">リスト3-2: `if`式の結果を変数に代入する</span>

この`number`変数は、`if`式の結果に基づいた値に束縛されます。このコードを走らせてどうなるか確かめてください:

```console
{{#include ../listings/ch03-common-programming-concepts/listing-03-02/output.txt}}
```

一連のコードは、そのうちの最後の式に評価され、数値はそれ単独でも式になることを思い出してください。
今回の場合、この`if`式全体の値は、どのブロックのコードが実行されるかに基づきます。これはつまり、
`if`の各アームの結果になる可能性がある値は、同じ型でなければならないということになります;
リスト3-2で、`if`アームも`else`アームも結果は、`i32`の整数でした。以下の例のように、
型が合わない時には、エラーになるでしょう:

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-31-arms-must-return-same-type/src/main.rs}}
```

このコードをコンパイルしようとすると、エラーになります。`if`と`else`アームは互換性のない値の型になり、
コンパイラがプログラム内で問題の見つかった箇所をズバリ指摘してくれます:

```console
{{#include ../listings/ch03-common-programming-concepts/no-listing-31-arms-must-return-same-type/output.txt}}
```

`if`ブロックの式は整数に評価され、`else`ブロックの式は文字列に評価されます。これでは動作しません。
変数は単独の型でなければならず、コンパイラは、コンパイル時に`number`変数の型を確実に把握する必要があるからです。
`number`の型を把握していることで、コンパイラは、コンパイル時に`number`が使われている箇所全部で型が有効であるか検証できるのです。
`number`の型が実行時にしか決まらないのであれば、コンパイラはそれを実行することができなくなってしまいます;
どの変数に対しても、架空の複数の型があることを追いかけなければならないのであれば、コンパイラはより複雑になり、
コードに対して行える保証が少なくなってしまうでしょう。

### ループでの繰り返し

一連のコードを1回以上実行できると、しばしば役に立ちます。この作業用に、
Rustにはいくつかの*ループ*が用意されています。ループは、本体内のコードを最後まで実行し、
直後にまた最初から処理を開始します。
ループを試してみるのに、*loops*という名の新プロジェクトを作りましょう。

Rustには3種類のループが存在します: `loop`と`while`と`for`です。それぞれ試してみましょう。

#### `loop`でコードを繰り返す

`loop`キーワードを使用すると、同じコードを何回も何回も永遠に、明示的にやめさせるまで実行します。

例として、*loops*ディレクトリの*src/main.rs*ファイルを以下のような感じに書き換えてください:

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-32-loop/src/main.rs}}
```

このプログラムを実行すると、プログラムを手動で止めるまで、何度も何度も続けて`again!`と出力するでしょう。
ほとんどの端末で<span class="keystroke">ctrl-c</span>というショートカットが使え、
永久ループに囚われてしまったプログラムに割り込むことができます。試しにやってみましょう:

```console
$ cargo run
   Compiling loops v0.1.0 (file:///projects/loops)
    Finished dev [unoptimized + debuginfo] target(s) in 0.29s
     Running `target/debug/loops`
again!
again!
again!
again!
^Cagain!
```

`^C`という記号が出た場所が、<span class="keystroke">ctrl-c</span>を押した場所です。`^C`の後には`again!`と表示されたり、
されなかったりします。割り込みシグナルをコードが受け取った時にループのどこにいたかによります。

幸いなことに、Rustにはコードによってループを抜け出す手段もあります。
ループ内に`break`キーワードを配置することで、プログラムに実行を終了すべきタイミングを教えることができます。
第2章の[「正しい予想をした後に終了する」][quitting-after-a-correct-guess]節の数当てゲーム内でこれをして、ユーザが予想を的中させ、
ゲームに勝った時にプログラムを終了させたことを思い出してください。

数当てゲームで`continue`を使用しました。`continue`はループの中で残っているコードをスキップして次のループに移るためのものです。

#### ループから値を返す

`loop`の使用法のひとつとして、失敗するかもしれないと分かっている操作、
例えばスレッドがそのジョブを完了したかを確認する操作などを、リトライするというのがあります。
さらに、コードの他の部分で使うために、ループの外に操作の結果を渡す必要があるかもしれません。
これを行うには、ループを止めるために使っている`break`式の後ろに、返したい値を付け加えてください;
その値はループを抜けて返され、使うことができます。このように:

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-33-return-value-from-loop/src/main.rs}}
```

ループの前で`counter`という変数を宣言し、`0`に初期化しています。
次に、ループから返された値を保持するために、`result`という変数を宣言しています。
ループの繰り返しごとに、`counter`変数に`1`を追加し、`counter`が`10`に等しいかチェックします。
等しい場合は、値`counter * 2`とともに`break`キーワードを使用しています。
ループの後には、値を`result`に代入する文を終了するためのセミコロンが使われています。
最後に、`result`の値を出力していて、この場合は`20`です。

#### 複数のループを区別するループラベル

ループ内にループがある場合、`break`と`continue`は最も内側のループに適用されます。
*ループラベル*を使用することで、`break`や`continue`が適用されるループを指定することができます。
ループラベルはシングルクオートで始める必要があります。
以下に例を示します。


```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-32-5-loop-labels/src/main.rs}}
```

外側のループには`'counting_up`というラベルがついていて、0から2まで数え上げます。
内側のラベルのないループは10から9までカウントダウンします。最初のラベルの無い`break`は内側のループを終了させます。
`break 'counting_up;`は外側のループを終了させます。
このコードは以下のような出力をします。

```console
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-32-5-loop-labels/output.txt}}
```



#### `while`で条件付きループ

プログラムは、ループ内で条件式を評価することがよく必要になるでしょう。条件が`true`の間、
ループが走るわけです。条件が`true`でなくなった時にプログラムは`break`を呼び出し、ループを終了します。
このような挙動は、`loop`、`if`、`else`、`break`を組み合わせることでも実装できます;
お望みなら、プログラムで今、試してみるのもいいでしょう。
しかし、このパターンは頻出するので、Rustにはそれ用の文法要素が用意されていて、`while`ループと呼ばれます。
リスト3-3では、プログラムを3回ループさせるために`while`を使用しています。
繰り返しごとにカウントダウンして、ループ後にメッセージを表示して終了します。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/listing-03-03/src/main.rs}}
```

<span class="caption">リスト3-3: 条件が真の間、コードを走らせる`while`ループを使用する</span>

この文法要素により、`loop`、`if`、`else`、`break`を使った時に必要になるネストがなくなり、
より明確になります。条件が`true`に評価される間、コードは実行されます; そうでなければ、ループを抜けます.

#### `for`でコレクションを覗き見る

配列などのコレクションの要素を覗き見るために、`while`要素を使うこともできます。
例えば、リスト3-4のループは配列`a`の各要素を出力します。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/listing-03-04/src/main.rs}}
```

<span class="caption">リスト3-4: `while`ループでコレクションの各要素を覗き見る</span>

ここで、コードは配列の要素を順番にカウントアップして覗いています。番号0から始まり、
配列の最終番号に到達するまでループします(つまり、`index < 5`が`true`でなくなる時です)。
このコードを走らせると、配列内の全要素が出力されます:

```console
{{#include ../listings/ch03-common-programming-concepts/listing-03-04/output.txt}}
```

予想通り、配列の5つの要素が全てターミナルに出力されています。`index`変数の値はどこかで`5`という値になるものの、
配列から6番目の値を拾おうとする前にループは実行を終了します。

しかし、このアプローチは間違いが発生しやすいです; 添え字の値や判定条件が間違っていれば、
プログラムはパニックしてしまいます。例えば、`a`配列の定義を4要素を持つように変更したのに、
条件を`while index < 4`に更新し忘れた場合、コードはパニックするでしょう。また遅いです。
実行時にループの各回ごとに添字が配列の境界内にあるかチェックするコードを、コンパイラが追加するからです。

より簡潔な対立案として、`for`ループを使ってコレクションの各アイテムに対してコードを実行することができます。
`for`ループはリスト3-5のコードのようになります。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/listing-03-05/src/main.rs}}
```

<span class="caption">リスト3-5: `for`ループを使ってコレクションの各要素を覗き見る</span>

このコードを走らせたら、リスト3-4と同じ出力が得られるでしょう。より重要なのは、
コードの安全性を向上させ、配列の終端を超えてアクセスしたり、
終端に届く前にループを終えてアイテムを見逃してしまったりするバグの可能性を完全に排除したことです。

`for`ループを使っていれば、配列の要素数を変えても、
リスト3-4で使った方法のように他のコードをいじることを覚えておく必要はなくなるわけです。

`for`ループのこの安全性と簡潔性により、Rustで使用頻度の最も高いループになっています。
リスト3-3で`while`ループを使ったカウントダウンサンプルのように、一定の回数、同じコードを実行したいような状況であっても、
多くのRustaceanは、`for`ループを使うでしょう。どうやってやるかといえば、
標準ライブラリで提供される`Range`型を使うのです。`Range`型は、片方の数字から始まって、
もう片方の数字未満の数値を順番に生成する型です。

`for`ループと、まだ話していない別のメソッド`rev`を使って範囲を逆順にしたカウントダウンはこうなります:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch03-common-programming-concepts/no-listing-34-for-range/src/main.rs}}
```

こちらのコードの方が少しいいでしょう？

## まとめ

やりましたね！結構長い章でした: 変数、スカラー値と複合データ型、関数、コメント、`if`式、そして、ループについて学びました！
この章で議論した概念について経験を積むために、以下のことをするプログラムを組んでみてください:

* 温度を華氏と摂氏で変換する。
* フィボナッチ数列の*n*番目を生成する。
* クリスマスキャロルの定番、"The Twelve Days of Christmas"の歌詞を、
  曲の反復性を利用して出力する。

次に進む準備ができたら、他の言語にはあまり存在*しない*Rustの概念について話しましょう: 所有権です。

[comparing-the-guess-to-the-secret-number]:
ch02-00-guessing-game-tutorial.html#予想と秘密の数字を比較する
[quitting-after-a-correct-guess]:
ch02-00-guessing-game-tutorial.html#正しい予想をした後に終了する


