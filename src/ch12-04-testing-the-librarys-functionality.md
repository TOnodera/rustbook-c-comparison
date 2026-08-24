

## テスト駆動開発でライブラリの機能を開発する

今や、ロジックを*src/lib.rs*に抜き出し、引数集めとエラー処理を*src/main.rs*に残したので、
コードの核となる機能のテストを書くのが非常に容易になりました。いろんな引数で関数を直接呼び出し、
コマンドラインからバイナリを呼び出す必要なく戻り値を確認できます。

この節では、以下の手順に従ってテスト駆動開発(TDD)プロセスを活用して、`minigrep`プログラムに検索ロジックを追加します。

1. 失敗するテストを書き、実行して想定通りの理由で失敗することを確かめる。
2. 十分な量のコードを書くか変更して新しいテストを通過するようにする。
3. 追加または変更したばかりのコードをリファクタリングし、テストが通り続けることを確認する。
4. 手順1から繰り返す！

TDDはソフトウェアを書く多くの方法のうちの一つに過ぎませんが、コードデザインを駆動するために役立てることができます。
テストを通過させるコードを書く前にテストを書くことで、過程を通して高いテストカバー率を保つ助けになります。

実際にクエリ文字列の検索を行う機能の実装をテスト駆動し、クエリに合致する行のリストを生成します。
この機能を`search`という関数に追加しましょう。

### 失敗するテストを記述する

もう必要ないので、プログラムの振る舞いを確認していた`println!`文を*src/lib.rs*と*src/main.rs*から削除しましょう。
それから*src/lib.rs*で、テスト関数のある`tests`モジュールを追加してください。[第11章][ch11-anatomy]のようにですね。
このテスト関数が`search`関数に欲しい振る舞いを指定します。 クエリと検索対象のテキストを受け取り、
クエリを含む行だけをテキストから返します。リスト12-15にこのテストを示していますが、まだコンパイルは通りません。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-15/src/lib.rs:here}}
```

<span class="caption">リスト12-15: こうだったらいいなという`search`関数の失敗するテストを作成する</span>

このテストは、`"duct"`という文字列を検索します。検索対象の文字列は3行で、うち1行だけが`"duct"`を含みます
(開き二重引用符の後のバックスラッシュは、この文字列リテラルの内容の先頭に改行文字を置かないように、
コンパイラに指示しているということに注意してください)。
`search`関数から返る値が想定している行だけを含むことをアサーションします。

このテストを実行し、失敗するところを観察することは、まだできません。このテストはコンパイルもできないからです。
まだ`search`関数が存在していません！TDDの原則に従って、空のベクタを常に返す`search`関数の定義を追加することで、
テストをコンパイルし実行するだけのコードを追記します。リスト12-16に示したようにですね。そうすれば、
テストはコンパイルでき、失敗するはずです。なぜなら、空のベクタは、
`"safe, fast, productive."`という行を含むベクタとは合致しないからです。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-16/src/lib.rs:here}}
```

<span class="caption">リスト12-16: テストがコンパイルできるのに十分なだけ`search`関数を定義する</span>

`search`のシグニチャ内で、明示的なライフタイム`'a`を定義し、そのライフタイムを`contents`引数と戻り値で使用していることに注目してください。
[第10章][ch10-lifetimes]からライフタイム仮引数は、どの実引数のライフタイムが戻り値のライフタイムに関連づけられているかを指定することを思い出してください。
この場合、返却されるベクタは、
(`query`引数ではなく)`contents`引数のスライスを参照する文字列スライスを含むべきと示唆しています。

言い換えると、コンパイラに`search`関数に返されるデータは、
`search`関数に`contents`引数で渡されているデータと同期間生きることを教えています。
これは重要なことです！スライス*に*参照されるデータは、参照が有効になるために有効である必要があるのです。
コンパイラが`contents`ではなく`query`の文字列スライスを生成すると想定してしまったら、
安全性チェックを間違って行うことになってしまいます。

ライフタイム注釈を忘れてこの関数をコンパイルしようとすると、こんなエラーが出ます。

```console
{{#include ../listings/ch12-an-io-project/output-only-02-missing-lifetimes/output.txt}}
```

コンパイラには、二つの引数のどちらが必要なのか知る由がないので、明示的に教えてあげる必要があるのです。
`contents`がテキストをすべて含む引数で、合致するそのテキストの一部を返したいので、
`contents`がライフタイム記法で戻り値に関連づくはずの引数であることをプログラマは知っています。

他のプログラミング言語では、シグニチャで引数と戻り値を関連づける必要はありませんが、この実践は時間とともに楽になっていくでしょう。
この例を第10章の[「ライフタイムで参照を検証する」][validating-references-with-lifetimes]節と比較してみるといいかもしれません。

さあ、テストを実行しましょう:

```console
{{#include ../listings/ch12-an-io-project/listing-12-16/output.txt}}
```

素晴らしい。テストは全く想定通りに失敗しています。テストが通るようにしましょう！

### テストを通過させるコードを書く

空のベクタを常に返しているために、現状テストは失敗しています。それを修正し、`search`を実装するには、
プログラムは以下の手順に従う必要があります。

* 中身を各行ごとに繰り返す。
* 行にクエリ文字列が含まれるか確認する。
* するなら、それを返却する値のリストに追加する。
* しないなら、何もしない。
* 一致する結果のリストを返す。

各行を繰り返す作業から、この手順に順に取り掛かりましょう。

#### `lines`メソッドで各行を繰り返す

Rustには、文字列を行ごとに繰り返す役立つメソッドがあり、利便性のために`lines`と名付けられ、
リスト12-17のように動作します。まだ、これはコンパイルできないことに注意してください。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-17/src/lib.rs:here}}
```

<span class="caption">リスト12-17: `contents`の各行を繰り返す</span>

`lines`メソッドはイテレータを返します。イテレータについて詳しくは、[第13章][ch13-iterators]で話しますが、
[リスト3-5][ch3-iter]でこのようなイテレータの使用法は見かけたことを思い出してください。
そこでは、イテレータに`for`ループを使用してコレクションの各要素に対して何らかのコードを実行していました。

#### クエリを求めて各行を検索する

次に現在の行がクエリ文字列を含むか確認します。幸運なことに、
文字列にはこれを行ってくれる`contains`という役に立つメソッドがあります！`search`関数に、
`contains`メソッドの呼び出しを追加してください。リスト12-18のようにですね。
それでもまだコンパイルできないことに注意してください。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-18/src/lib.rs:here}}
```

<span class="caption">リスト12-18: 行が`query`の文字列を含むか確認する機能を追加する</span>

ここまでで機能を組み上げてきました。これをコンパイルできるようにするためには、
関数のシグネチャでそうすると示したように、本体から値を返す必要があります。

#### 合致した行を保存する

この関数を完成させるには、返そうとしている、合致した行を保存する方法が必要です。そのために、`for`ループの前に可変なベクタを生成し、
`push`メソッドを呼び出して`line`をベクタに保存することができます。`for`ループの後でベクタを返却します。
リスト12-19のようにですね。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-19/src/lib.rs:here}}
```

<span class="caption">リスト12-19: 合致する行を保存したので、返すことができる</span>

これで`search`関数は、`query`を含む行だけを返すはずであり、テストも通るはずです。
テストを実行しましょう:

```console
{{#include ../listings/ch12-an-io-project/listing-12-19/output.txt}}
```

テストが通り、動いていることがわかりました！

ここで、テストが通過するよう保ったまま、同じ機能を保持しながら、検索関数の実装をリファクタリングする機会を考えることもできます。
検索関数のコードは悪すぎるわけではありませんが、イテレータの有用な機能の一部を活用していません。
この例には[第13章][ch13-iterators]で再度触れ、そこでは、イテレータをより深く探究し、さらに改善する方法に目を向けます。

#### `run`関数内で`search`関数を使用する

`search`関数が動きテストできたので、`run`関数から`search`を呼び出す必要があります。`config.query`の値と、
ファイルから`run`が読み込む`contents`の値を`search`関数に渡す必要があります。
それから`run`は、`search`から返ってきた各行を出力するでしょう。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch12-an-io-project/no-listing-02-using-search-in-run/src/lib.rs:here}}
```

それでも`for`ループで`search`から各行を返し、出力しています。

さて、プログラム全体が動くはずです！試してみましょう。まずはエミリー・ディキンソンの詩から、
ちょうど1行だけを返すはずの言葉から。"frog"です。

```console
{{#include ../listings/ch12-an-io-project/no-listing-02-using-search-in-run/output.txt}}
```

かっこいい！今度は、複数行にマッチするであろう言葉を試しましょう。"body"とかね:

```console
{{#include ../listings/ch12-an-io-project/output-only-03-multiple-matches/output.txt}}
```

そして最後に、詩のどこにも現れない単語を探したときに、何も出力がないことを確かめましょう。
"monomorphization"などね:

```console
{{#include ../listings/ch12-an-io-project/output-only-04-no-matches/output.txt}}
```

最高です！古典的なツールの独自のミニバージョンを構築し、アプリケーションを構造化する方法を多く学びました。
また、ファイル入出力、ライフタイム、テスト、コマンドライン引数の解析についても、少し学びました。

このプロジェクトをまとめ上げるために、環境変数を扱う方法と標準エラー出力に出力する方法を少しだけデモします。
これらはどちらも、コマンドラインプログラムを書く際に有用です。

[validating-references-with-lifetimes]: ch10-03-lifetime-syntax.html#validating-references-with-lifetimes
[ch11-anatomy]: ch11-01-writing-tests.html#the-anatomy-of-a-test-function
[ch10-lifetimes]: ch10-03-lifetime-syntax.html
[ch3-iter]: ch03-05-control-flow.html#looping-through-a-collection-with-for
[ch13-iterators]: ch13-02-iterators.html
