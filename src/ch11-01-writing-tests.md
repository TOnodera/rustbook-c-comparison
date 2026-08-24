

## テストの記述法

テストは、テスト以外のコードが想定された方法で機能していることを実証するRustの関数です。
テスト関数の本体は、典型的には以下の3つの動作を行います。

1. 必要なデータや状態をセットアップする。
2. テスト対象のコードを実行する。
3. 結果が想定通りであることを断定（以下、アサーションという）する。

Rustが、特にこれらの動作を行うテストを書くために用意している機能を見ていきましょう。
これには、`test`属性、いくつかのマクロ、`should_panic`属性が含まれます。

### テスト関数の構成

最も単純には、Rustにおけるテストは`test`属性で注釈された関数のことです。属性とは、
Rustコードの部品に関するメタデータです。 一例を挙げれば、構造体とともに第5章で使用した`derive`属性です。
関数をテスト関数に変えるには、`fn`の前に`#[test]`を付け加えてください。
`cargo test`コマンドでテストを実行したら、コンパイラは注釈された関数を実行するテスト用バイナリをビルドし、
各テスト関数が通過したか失敗したかを報告します。

新しいライブラリプロジェクトをCargoで作ると、テスト関数付きのテストモジュールが自動的に生成されます。
このモジュールがテストを書くためのテンプレートを提供してくれるので、
新しいプロジェクトを始めるたびに正しい構造とか文法をいちいち検索しなくてすみます。
ここに好きな数だけテスト関数やテストモジュールを追加すればいいというわけです！

まずは実際にコードをテストする前に、自動生成されたテンプレートのテストで実験して、テストの動作の性質をいくらか学びましょう。
その後で、以前書いたコードを呼び出し、振る舞いが正しいことをアサーションする、ホンモノのテストを書きましょう。

2つの数を足す、`adder`という新しいライブラリプロジェクトを生成しましょう:

```console
$ cargo new adder --lib
     Created library `adder` project
$ cd adder
```

`adder`ライブラリの*src/lib.rs*ファイルの中身は、リスト11-1のような見た目のはずです。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/listing-11-01/src/lib.rs}}
```

<span class="caption">リスト11-1: `cargo new`で自動生成されたテストモジュールと関数</span>

とりあえず、最初の2行は無視し、関数に集中しましょう。
`#[test]`注釈に注目してください。 この属性は、これがテスト関数であることを示すので、
テスト実行機はこの関数をテストとして扱うとわかるのです。さらに、`tests`モジュール内にはテスト関数以外の関数を入れ、
一般的なシナリオをセットアップしたり、共通の処理を行う手助けをしたりもできるので、
必ずどの関数がテストかを示す必要があるのです。

例の関数本体は、`assert_eq!`マクロを使用して、2と2を足した結果を含む`result`が、4に等しいことをアサーションしています。
このアサーションは、典型的なテストのフォーマット例をなしているわけです。実行してこのテストが通る（訳注：テストが成功する、の意味。英語でpassということから、このように表現される）ことを確かめましょう。

`cargo test`コマンドでプロジェクトにあるテストがすべて実行されます。リスト11-2に示したようにですね。

```console
{{#include ../listings/ch11-writing-automated-tests/listing-11-01/output.txt}}
```

<span class="caption">リスト11-2: 自動生成されたテストを実行した出力</span>

Cargoがテストをコンパイルし、実行しました。`running 1 test`という行が見えます。
その次の行は、生成されたテスト関数の`it_works`という名前と、このテストの実行結果が`ok`であることを示しています。
テスト全体のまとめである`test result:ok.`は、全テストが通ったことを意味し、
`1 passed; 0 failed`と読める部分は、通過または失敗したテストの数を合計しているのです。

特定の場合にテスト実行しないように、テストを無視するように指定することができます。
これについては後でこの章の[「特に要望のない限りテストを無視する」][ignoring]節で扱います。
ここではそれを行っていないので、まとめは`0 ignored`と示しています。
`cargo test` コマンドに引数を渡すことで、名前が文字列にマッチするテストのみを実行することもできます。
*フィルタリング*と呼ばれますが、これについては[「名前でテストの一部を実行する」][subset]節で扱います。
また、実行するテストにフィルタをかけもしなかったので、まとめの最後に`0 filtered out`と表示されています。

`0 measured`という統計は、パフォーマンスを測定するベンチマークテスト用です。
ベンチマークテストは、本書記述の時点では、nightly版のRustでのみ利用可能です。
詳しくは、[ベンチマークテストのドキュメンテーション][bench]を参照してください。

テスト出力の次の部分、つまり`Doc-tests adder`で始まる部分は、ドキュメンテーションテストの結果用のものです。
まだドキュメンテーションテストは何もないものの、コンパイラは、APIドキュメントに現れるどんなコード例もコンパイルできます。
この機能により、ドキュメントとコードを同期することができるわけです。ドキュメンテーションテストの書き方については、
第14章の[テストとしてのドキュメンテーションコメント][doc-comments]節で説明しましょう。今は、`Doc-tests`出力は無視します。

それでは必要に応じてテストをカスタマイズしていきましょう。
まずは`it_works`関数の名前を違う名前に、例えば以下の`exploration`のように変更してください。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-01-changing-test-name/src/lib.rs}}
```

そして、`cargo test`を再度実行します。これで出力が`it_works`の代わりに`exploration`と表示しています。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-01-changing-test-name/output.txt}}
```

それでは別のテストを追加していきます。ただし、今回は失敗するテストにしましょう！
テスト関数内の何かがパニックすると、テストは失敗します。
各テストは、新規スレッドで実行され、メインスレッドが、テストスレッドが死んだと確認した時、テストは失敗と印づけられます。
第9章で、パニックを引き起こす最も単純な方法は`panic!`マクロを呼び出すことだと語りました。
*src/lib.rs*ファイルがリスト11-3のような見た目になるよう、`another`という名前の関数として新しいテストを入力してください。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,panics,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/listing-11-03/src/lib.rs}}
```

<span class="caption">リスト11-3: `panic!`マクロを呼び出したために失敗する2番目のテストを追加する</span>

`cargo test`で再度テストを実行してください。出力はリスト11-4のようになるはずであり、
`exploration`テストは通り、`another`は失敗したと表示されます。

```console
{{#include ../listings/ch11-writing-automated-tests/listing-11-03/output.txt}}
```

<span class="caption">リスト11-4: 一つのテストが通り、一つが失敗するときのテスト結果</span>

`ok`の代わりに`test test::another`の行は、`FAILED`を表示しています。個々の結果とまとめの間に、
2つ新たな区域ができました: 最初の区域は、失敗したテスト各々の具体的な理由を表示しています。
今回の場合、`another`は*src/lib.rs*ファイルの10行目で`'Make this test fail'でパニックした`ために失敗した、という詳細が得られました。
次の区域は失敗したテストの名前だけを列挙しています。
これは、テストがたくさんあり、失敗したテストの詳細がたくさん表示されるときに有用になります。
失敗したテストの名前を使用してそのテストだけを実行し、より簡単にデバッグすることができます。
テストの実行方法については、[テストの実行され方を制御する][controlling-how-tests-are-run]節でもっと語りましょう。

サマリー行が最後に出力されています。 総合的に言うと、テスト結果は`FAILED`でした。
一つのテストが通り、一つが失敗したわけです。

様々な状況でのテスト結果がどんな風になるか見てきたので、テストを行う際に有用になる`panic!`以外のマクロに目を向けましょう。

### `assert!`マクロで結果を確認する

`assert!`マクロは、標準ライブラリで提供されていますが、テスト内の何らかの条件が`true`と評価されることを確かめたいときに有効です。
`assert!`マクロには、論理値に評価される引数を与えます。その値が`true`なら、
何も起こらずにテストは通ります。その値が`false`なら、`assert!`マクロは`panic!`を呼び出し、
テストは失敗します。`assert!`マクロを使用することで、コードが意図した通りに機能していることを確認する助けになるわけです。

第5章のリスト5-15で、`Rectangle`構造体と`can_hold`メソッドを使用しました。リスト11-5でもそれを繰り返しています。
このコードを*src/lib.rs*ファイルに放り込み、`assert!`マクロでそれ用のテストを何か書いてみましょう。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/listing-11-05/src/lib.rs}}
```

<span class="caption">リスト11-5: 第5章から`Rectangle`構造体とその`can_hold`メソッドを使用する</span>

`can_hold`メソッドは論理値を返すので、`assert!`マクロの完璧なユースケースになるわけです。
リスト11-6で、幅が8、高さが7の`Rectangle`インスタンスを生成し、これが幅5、
高さ1の別の`Rectangle`インスタンスを保持できるとアサーションすることで`can_hold`を用いるテストを書きます。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/listing-11-06/src/lib.rs:here}}
```

<span class="caption">リスト11-6: より大きな長方形がより小さな長方形を確かに保持できるかを確認する`can_hold`用のテスト</span>

`tests`モジュール内に新しい行を加えたことに注目してください。 `use super::*`です。
`tests`モジュールは、第7章の[モジュールツリーの要素を示すためのパス][paths-for-referring-to-an-item-in-the-module-tree]節で説明した通常の公開ルールに従う普通のモジュールです。
`tests`モジュールは、内部モジュールなので、外部モジュール内のテスト配下にあるコードを内部モジュールのスコープに持っていく必要があります。
ここではglobを使用して、外部モジュールで定義したものすべてがこの`tests`モジュールでも使用可能になるようにしています。

テストは`larger_can_hold_smaller`と名付け、必要な`Rectangle`インスタンスを2つ生成しています。
そして、`assert!`マクロを呼び出し、`larger.can_hold(&smaller)`の呼び出し結果を渡しました。
この式は、`true`を返すと考えられるので、テストは通るはずです。確かめましょう！

```console
{{#include ../listings/ch11-writing-automated-tests/listing-11-06/output.txt}}
```

通ります！別のテストを追加しましょう。今回は、小さい長方形は、より大きな長方形を保持できないことをアサーションします。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-02-adding-another-rectangle-test/src/lib.rs:here}}
```

今回の場合、`can_hold`関数の正しい結果は`false`なので、その結果を`assert!`マクロに渡す前に反転させる必要があります。
結果として、`can_hold`が`false`を返せば、テストは通ります。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-02-adding-another-rectangle-test/output.txt}}
```

通るテストが2つ！さて、コードにバグを導入したらテスト結果がどうなるか確認してみましょう。
幅を比較する大なり記号を小なり記号で置き換えて`can_hold`メソッドの実装を変更しましょう:

```rust,not_desired_behavior,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-03-introducing-a-bug/src/lib.rs:here}}
```

テストを実行すると、以下のような出力をします。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-03-introducing-a-bug/output.txt}}
```

テストによりバグが捕捉されました！`larger.width`が8、`smaller.width`が5なので、
`can_hold`内の幅の比較が今は`false`を返すようになったのです。 8は5より小さくないですからね。

### `assert_eq!`と`assert_ne!`マクロで等値性をテストする

機能性を検証する一般的な方法は、テスト下にあるコードの結果と、コードが返すと期待される値との、等値性を確かめることです。
これを`assert`マクロを使用して`==`演算子を使用した式を渡すことで行うこともできます。
しかしながら、これはありふれたテストなので、標準ライブラリには1組のマクロ(`assert_eq!`と`assert_ne!`)が提供され、
このテストをより便利に行うことができます。これらのマクロはそれぞれ、二つの引数を比べ、等しいかと等しくないかを確かめます。
また、アサーションが失敗したら二つの値の出力もし、テストが失敗した*原因*を確認しやすくなります。
一方で`assert!`マクロは、`==`式の値が`false`になったことしか示さず、`false`になった原因の値は出力しません。

リスト11-7では、引数に`2`を加える`add_two`という名前の関数を書いて、
この関数を`assert_eq!`マクロでテストしています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/listing-11-07/src/lib.rs}}
```

<span class="caption">リスト11-7: `assert_eq!`マクロで`add_two`関数をテストする</span>

これが通ることを確認しましょう！

```console
{{#include ../listings/ch11-writing-automated-tests/listing-11-07/output.txt}}
```

`assert_eq!`マクロに引数として`4`を渡していますが、これは`add_two(2)`の呼び出し結果と等しいです。
このテストの行は`test tests::it_adds_two ... ok`であり、`ok`というテキストはテストが通ったことを示しています！

コードにバグを仕込んで、`assert_eq!`が失敗した時にそれがどうなるのか確認してみましょう。
`add_two`関数の実装を代わりに`3`を足すように変えてください。

```rust,not_desired_behavior,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-04-bug-in-add-two/src/lib.rs:here}}
```

テストを再度実行します。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-04-bug-in-add-two/output.txt}}
```

テストがバグを捕捉しました！
`it_adds_two`のテストは失敗し、そのメッセージは、
失敗したアサーションが`` assertion failed: `(left == right)` ``であったこと、
そして`left`と`right`の値が何だったかを示しています。
このメッセージはデバッグを開始する助けになります。
`left`引数は`4`だったが、`add_two(2)`がある`right`引数は`5`でした。
実行中のテストが多数あるときは特に、この出力は役に立つだろうと想像できるでしょう。

言語やテストフレームワークによっては、等値性アサーション関数の引数を`expected`と`actual`と呼び、
引数を指定する順序が重要であることに注意してください。
ですがRustでは、これらは`left`と`right`と呼ばれ、期待する値とコードが生成する値を指定する順序は重要ではありません。
今回のテストのアサーションを`assert_eq!(add_two(2), 4)`と書くこともでき、
そうすると失敗メッセージは、同じく`` assertion failed: `(left == right)` ``を表示するでしょう。

`assert_ne!`マクロは、与えた2つの値が等しくなければ通り、等しければ失敗します。
このマクロは、値が何になる*だろう*か確信が持てないけれども、
確実にこの値にはなる*べきでない*とわかっているような場合に最も有用になります。例えば、
入力を何らかの手段で変え（て出力す）ることが保証されているけれども、入力の変え方がテストを実行する曜日に依存する関数をテストしているなら、
アサーションすべき最善の事柄は、関数の出力が入力と等しくないことかもしれません。

内部的には、`assert_eq!`と`assert_ne!`マクロは、それぞれ`==`と`!=`演算子を使用しています。
アサーションが失敗すると、これらのマクロは引数をデバッグフォーマットを使用してプリントするので、
比較対象の値は`PartialEq`と`Debug`トレイトを実装していなければなりません。
すべての組み込み型と、ほぼすべての標準ライブラリの型はこれらのトレイトを実装しています。
自分で定義した構造体やenumについては、
その型の値の等値性をアサーションするために、`PartialEq`を実装する必要があるでしょう。
それが失敗した時にその値をプリントできるように、`Debug`も実装する必要もあるでしょう。
第5章のリスト5-12で触れたように、どちらのトレイトも導出可能なトレイトなので、
これは通常、単純に構造体やenum定義に`#[derive(PartialEq, Debug)]`という注釈を追加するだけですみます。
これらやその他の導出可能なトレイトに関する詳細については、付録C、[導出可能なトレイト][derivable-traits]をご覧ください。

### カスタムの失敗メッセージを追加する

さらに、`assert!`、`assert_eq!`、`assert_ne!`の追加引数として、失敗メッセージと共にカスタムのメッセージが表示されるよう、
追加することもできます。必須引数の後に指定された引数はすべて`format!`マクロに渡されるので、
（format!マクロについては第8章の[`+`演算子、または`format!`マクロで連結][concatenation-with-the--operator-or-the-format-macro]節で議論しました）、
`{}`プレースホルダーを含むフォーマット文字列とこのプレースホルダーに置き換えられる値を渡すことができます。
カスタムメッセージは、アサーションがどんな意味を持つかドキュメント化するのに役に立ちます。
もしテストが失敗した時、コードにどんな問題があるのかをよりしっかり把握できるはずです。

例として、人々に名前で挨拶をする関数があり、関数に渡した名前が出力に出現することをテストしたいとしましょう:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-05-greeter/src/lib.rs}}
```

このプログラムの要件はまだ取り決められておらず、挨拶の先頭の`Hello`というテキストはおそらく変わります。
要件が変わった時にテストを更新しなくてもよいようにしたいと考え、
`greeting`関数から返る値と正確な等値性を確認するのではなく、出力が入力引数のテキストを含むことをアサーションするだけにします。

それでは`greeting`が`name`を含まないように変更してこのコードにバグを仕込み、テストの失敗がデフォルトでどんな風になるのか確かめましょう:

```rust,not_desired_behavior,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-06-greeter-with-bug/src/lib.rs:here}}
```

このテストを実行すると、以下のように出力されます。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-06-greeter-with-bug/output.txt}}
```

この結果は、アサーションが失敗し、どの行にアサーションがあるかを示しているだけです。
失敗メッセージが`greeting`関数からの値を出力していればより有用でしょう。
`greeting`関数から得た実際の値で埋められるプレースホルダーを含むフォーマット文字列からなるカスタムの失敗メッセージを追加してみましょう:

```rust,ignore
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-07-custom-failure-message/src/lib.rs:here}}
```

これでテストを実行したら、より有益なエラーメッセージが得られるでしょう。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-07-custom-failure-message/output.txt}}
```

実際に得られた値がテスト出力に表示されているので、起こると想定していたものではなく、
起こったものをデバッグするのに役に立ちます。

### `should_panic`でパニックを確認する

戻り値を確認することに加えて、想定通りにコードがエラー状態を扱っていることを確認することが重要です。
例えば、第9章のリスト9-10で生成した`Guess`型を考えてください。`Guess`を使用する他のコードは、
`Guess`のインスタンスは1から100の範囲の値しか含まないという保証に依存しています。
その範囲外の値で`Guess`インスタンスを生成しようとするとパニックすることを確認するテストを書くことができます。

これは、テスト関数に`should_panic`という属性を追加することで達成できます。
このテストは、関数内のコードがパニックする場合に通過します。つまり、
関数内のコードがパニックしなかったら、テストは失敗するわけです。

リスト11-8は、予想どおりに`Guess::new`のエラー条件が発生していることを確認するテストを示しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/listing-11-08/src/lib.rs}}
```

<span class="caption">リスト11-8: 状況が`panic!`を引き起こすとテストする</span>

`#[test]`属性の後、適用するテスト関数の前に`#[should_panic]`属性を配置しています。
このテストが通るときの結果を見ましょう:

```console
{{#include ../listings/ch11-writing-automated-tests/listing-11-08/output.txt}}
```

よさそうですね！では、値が100より大きいときに`new`関数がパニックするという条件を除去することでコードにバグを導入しましょう:

```rust,not_desired_behavior,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-08-guess-with-bug/src/lib.rs:here}}
```

リスト11-8のテストを実行すると、失敗するでしょう。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-08-guess-with-bug/output.txt}}
```

この場合、それほど役に立つメッセージは得られませんが、テスト関数に目を向ければ、
`#[should_panic]`で注釈されていることがわかります。得られた失敗は、
テスト関数のコードがパニックを引き起こさなかったことを意味するのです。

`should_panic`を使用するテストは不正確なこともあります。
`should_panic`のテストは、想定していたもの以外の理由でテストがパニックしても通ってしまうのです。
`should_panic`のテストの正確を期すために、`should_panic`属性に`expected`引数を追加することもできます。
このテストハーネスは、失敗メッセージに与えられたテキストが含まれていることを確かめてくれます。
例えば、リスト11-9の修正された`Guess`のコードを考えてください。ここでは、
`new`関数は、値が大きすぎるか小さすぎるかによって異なるメッセージでパニックします。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/listing-11-09/src/lib.rs:here}}
```

<span class="caption">リスト11-9: 指定された部分文字列を含むパニックメッセージで`panic!`することをテストする</span>

`should_panic`属性の`expected`引数に置いた値が`Guess::new`関数がパニックしたメッセージの一部になっているので、
このテストは通ります。予想されるパニックメッセージ全体を指定することもでき、今回の場合、
`Guess value must be less than or equal to 100, got 200.`となります。
何を指定するかは、パニックメッセージのどこが固有でどこが動的か、
またテストをどの程度正確に行いたいかによります。今回の場合、パニックメッセージの一部でも、テスト関数内のコードが、
`else if value > 100`の場合を実行していると確認するのに事足りるのです。

`expected`メッセージありの`should_panic`テストが失敗すると何が起きるのが確かめるために、
`if value < 1`と`else if value > 100`ブロックの本体を入れ替えることで再度コードにバグを仕込みましょう:

```rust,ignore,not_desired_behavior
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-09-guess-with-panic-msg-bug/src/lib.rs:here}}
```

`should_panic`テストを実行すると、今回は失敗するでしょう。

```console
{{#include ../listings/ch11-writing-automated-tests/no-listing-09-guess-with-panic-msg-bug/output.txt}}
```

この失敗メッセージは、このテストが確かに予想通りパニックしたことを示していますが、
パニックメッセージは、予想される文字列の`'Guess value must be less than or equal to 100'`を含んでいませんでした。
実際に得られたパニックメッセージは今回の場合、`Guess value must be greater than or equal to 1, got 200.`でした。
そうしてバグの所在地を割り出し始めることができるわけです！

### `Result<T, E>`をテストで使う

これまで書いてきたテストは失敗するとパニックしていましたが、
`Result<T, E>`を使うようなテストを書くこともできます！
以下は、リスト11-1のテストを、`Result<T, E>`を使い、パニックする代わりに`Err`を返すように書き直したものです：

```rust,noplayground
{{#rustdoc_include ../listings/ch11-writing-automated-tests/no-listing-10-result-in-tests/src/lib.rs:here}}
```

`it_works`関数の戻り値の型は`Result<(), String>`になりました。
関数内で`assert_eq!`マクロを呼び出す代わりに、テストが成功すれば`Ok(())`を、失敗すれば`Err`に`String`を入れて返すようにします。

`Result<T, E>` を返すようなテストを書くと、`?`演算子をテストの中で使えるようになります。
これは、テスト内で何らかの工程が`Err`ヴァリアントを返したときに失敗するべきテストを書くのに便利です。

`Result<T, E>`を使うテストに`#[should_panic]`注釈を使うことはできません。
操作が`Err`列挙子を返すことをアサーションするためには、`Result<T, E>`値に対して`?`演算子を使用*しないでください*。
代わりに、`assert!(value.is_err())`を使用してください。

今やテスト記法を複数知ったので、テストを実行する際に起きていることに目を向け、
`cargo test`で使用できるいろんなオプションを探究しましょう。

[concatenation-with-the--operator-or-the-format-macro]:
ch08-02-strings.html#演算子またはformatマクロで連結
[bench]: https://doc.rust-lang.org/unstable-book/library-features/test.html
[ignoring]: ch11-02-running-tests.html#ignoring-tests-unless-specifically-requested
[subset]: ch11-02-running-tests.html#running-a-subset-of-tests-by-name
[controlling-how-tests-are-run]: ch11-02-running-tests.html#controlling-how-tests-are-run
[derivable-traits]: https://doc.rust-lang.org/book/appendix-03-derivable-traits.html
[doc-comments]: ch14-02-publishing-to-crates-io.html#documentation-comments-as-tests
[paths-for-referring-to-an-item-in-the-module-tree]: ch07-03-paths-for-referring-to-an-item-in-the-module-tree.html
