<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="concurrency-with-async"></a>

## Asyncで並行処理を行う

この節では、第16章でスレッドを使って取り組んだ並行処理の課題のいくつかに、asyncを適用します。重要な考え方の多くはすでに説明したので、ここではスレッドとFutureの違いに焦点を当てます。

多くの場合、asyncで並行処理を扱うAPIは、スレッドを使うAPIとよく似ています。一方で、大きく異なる場合もあります。スレッドとasyncのAPIが同じように*見えて*も、その振る舞いは異なることが多く、性能特性はほぼ必ず異なります。

<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="counting"></a>

### `spawn_task`で新しいタスクを生成する

第16章の[「`spawn`で新しいスレッドを生成する」][thread-spawn]<!-- ignore -->で最初に行ったのは、2つの別々のスレッドで数を数える処理でした。asyncでも同じことをしてみましょう。`trpl`クレートは、`thread::spawn` APIによく似た`spawn_task`関数と、`thread::sleep` APIの非同期版である`sleep`関数を提供します。リスト17-6のように、この2つを組み合わせて数を数える例を実装できます。

<Listing number="17-6" caption="メインタスクがある内容を表示する間に、別の内容を表示する新しいタスクを生成する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-06/src/main.rs:all}}
```

</Listing>

最初に`main`関数で`trpl::block_on`を使い、最上位の処理を非同期にできるよう準備します。

> 注：この章では、ここから先のすべての例で、`main`内にまったく同じ`trpl::block_on`のラッパーコードを含めます。そのため、`main`と同じように省略することがよくあります。自分のコードには含めることを忘れないでください。

次に、そのブロック内へ2つのループを書きます。どちらにも`trpl::sleep`の呼び出しを含め、次のメッセージを送るまで0.5秒（500ミリ秒）待ちます。一方のループは`trpl::spawn_task`の本体へ置き、もう一方は最上位の`for`ループとして置きます。`sleep`呼び出しの後には`await`も追加します。

このコードの動作はスレッド版の実装と似ています。実行時には、自分のターミナルでメッセージの順番が異なることがある点も同じです。

<!-- 出力の違いは重要ではなく、コンパイラの変更よりスレッドの実行順による可能性が高いため抽出しない -->

```text
hi number 1 from the second task!
hi number 1 from the first task!
hi number 2 from the first task!
hi number 2 from the second task!
hi number 3 from the first task!
hi number 3 from the second task!
hi number 4 from the first task!
hi number 4 from the second task!
hi number 5 from the first task!
```

この版は、メインのasyncブロック本体にある`for`ループが終わるとすぐ停止します。`main`関数が終了すると、`spawn_task`が生成したタスクも終了させられるからです。そのタスクを最後まで実行するには、JoinHandleを使って最初のタスクが完了するのを待つ必要があります。スレッドでは、スレッドの終了まで「ブロック」するため`join`メソッドを使いました。タスクのHandle自体がFutureなので、リスト17-7では同じことを`await`で行えます。その`Output`型は`Result`なので、待機した後に`unwrap`も呼び出します。

<Listing number="17-7" caption="JoinHandleに`await`を使い、タスクを完了まで実行する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-07/src/main.rs:handle}}
```

</Listing>

更新した版は、*両方*のループが完了するまで実行されます。

<!-- 出力の違いは重要ではなく、コンパイラの変更よりスレッドの実行順による可能性が高いため抽出しない -->

```text
hi number 1 from the second task!
hi number 1 from the first task!
hi number 2 from the first task!
hi number 2 from the second task!
hi number 3 from the first task!
hi number 3 from the second task!
hi number 4 from the first task!
hi number 4 from the second task!
hi number 5 from the first task!
hi number 6 from the first task!
hi number 7 from the first task!
hi number 8 from the first task!
hi number 9 from the first task!
```

ここまでは、asyncとスレッドは、構文が異なるだけで似た結果をもたらすように見えます。JoinHandleの`join`を呼び出す代わりに`await`を使い、`sleep`呼び出しも待機しました。

さらに大きな違いは、この処理のために別のOSスレッドを生成する必要がなかったことです。実は、ここではタスクさえ生成する必要がありません。asyncブロックは無名のFutureへコンパイルされるので、それぞれのループをasyncブロックに入れ、`trpl::join`関数を使って両方を完了までランタイムに実行させられます。

第16章の[「すべてのスレッドが終了するのを待つ」][join-handles]<!-- ignore -->では、`std::thread::spawn`を呼ぶと返される`JoinHandle`型の`join`メソッドを使う方法を示しました。`trpl::join`関数はそれと似ていますが、Futureを扱います。2つのFutureを渡すと、両方が完了した時点で、それぞれの出力を含むタプルを出力とする1つの新しいFutureを生成します。そのためリスト17-8では、`trpl::join`を使って`fut1`と`fut2`の両方が終わるのを待ちます。`fut1`と`fut2`を個別に待機するのではなく、`trpl::join`が生成した新しいFutureを待機します。出力は2つのユニット値からなるタプルにすぎないため無視します。

<Listing number="17-8" caption="`trpl::join`を使って2つの無名Futureを待機する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-08/src/main.rs:join}}
```

</Listing>

実行すると、両方のFutureが完了まで動くことを確認できます。

<!-- 出力の違いは重要ではなく、コンパイラの変更よりスレッドの実行順による可能性が高いため抽出しない -->

```text
hi number 1 from the first task!
hi number 1 from the second task!
hi number 2 from the first task!
hi number 2 from the second task!
hi number 3 from the first task!
hi number 3 from the second task!
hi number 4 from the first task!
hi number 4 from the second task!
hi number 5 from the first task!
hi number 6 from the first task!
hi number 7 from the first task!
hi number 8 from the first task!
hi number 9 from the first task!
```

今度は毎回まったく同じ順番になります。スレッドや、リスト17-7で`trpl::spawn_task`を使ったときとは大きく異なります。これは`trpl::join`関数が*公平*だからです。各Futureを同じ頻度で交互に確認し、もう一方の準備ができているとき、一方だけが先へ進み続けることを許しません。スレッドでは、どのスレッドを確認し、どれだけ長く実行させるかをOSが決めます。非同期Rustでは、どのタスクを確認するかをランタイムが決めます。実際には、非同期ランタイムが並行性を管理するため内部でOSスレッドを使うこともあり、詳細は複雑です。その場合、公平性の保証にはランタイム側でより多くの作業が必要になりますが、それでも実現できます。ランタイムは、どの処理についても公平性を保証する義務はなく、公平性を求めるかどうか選べる異なるAPIを提供することがよくあります。

Futureの待機方法を次のように変え、何が起きるか試してみてください。

- 一方または両方のループを囲むasyncブロックを取り除く。
- 各asyncブロックを定義した直後に待機する。
- 最初のループだけをasyncブロックで囲み、2つ目のループ本体の後で、そのFutureを待機する。

さらに挑戦したい場合は、コードを実行する*前*に、それぞれどのような出力になるか考えてみてください。

<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="message-passing"></a>
<a id="counting-up-on-two-tasks-using-message-passing"></a>

### メッセージ受け渡しで2つのタスク間にデータを送る

Future間でデータを共有する方法にも見覚えがあるでしょう。もう一度メッセージ受け渡しを使いますが、今回は型と関数の非同期版を使います。スレッドによる並行性とFutureによる並行性の重要な違いを示すため、第16章の[「メッセージ受け渡しでスレッド間のデータを転送する」][message-passing-threads]<!-- ignore -->とは少し違う進め方をします。リスト17-9では、別のスレッドを生成したときとは異なり、別のタスクを生成せず、1つのasyncブロックだけから始めます。

<Listing number="17-9" caption="非同期チャネルを作り、2つの半分を`tx`と`rx`へ割り当てる" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-09/src/main.rs:channel}}
```

</Listing>

ここでは、第16章でスレッドとともに使った複数生産者・単一消費者チャネルAPIの非同期版である`trpl::channel`を使います。非同期版APIとスレッド版の違いはわずかです。受信側`rx`は不変ではなく可変であり、`recv`メソッドは値を直接生成する代わりに、待機する必要のあるFutureを生成します。これで送信側から受信側へメッセージを送れます。別のスレッドもタスクも生成する必要はなく、`rx.recv`呼び出しを待機するだけでよいことに注目してください。

`std::mpsc::channel`の同期的な`Receiver::recv`メソッドは、メッセージを受信するまでブロックします。`trpl::Receiver::recv`メソッドは非同期なので、ブロックしません。代わりに、メッセージを受信するかチャネルの送信側が閉じるまで、ランタイムへ制御を返します。一方、`send`呼び出しはブロックしないので待機しません。送信先のチャネルには容量の上限がないため、ブロックする必要がないのです。

> 注：この非同期コードはすべて`trpl::block_on`呼び出し内のasyncブロックで実行されるため、その内部ではブロックを避けられます。ただし、外側のコードは`block_on`関数が戻るまでブロックします。それが`trpl::block_on`関数の目的です。どの非同期コード群を待つ場所でブロックするか、したがって同期コードと非同期コードの境界をどこに置くかを選べます。

この例について2つの点に注目してください。第1に、メッセージはすぐ届きます。第2に、ここではFutureを使っているものの、並行性はまだありません。リスト内の処理は、Futureが存在しない場合と同じように、すべて順番に実行されます。

まず、リスト17-10のように一連のメッセージを送り、その間でスリープすることで、第1の点を変えてみましょう。

<!-- この例は停止しないためテストできない -->

<Listing number="17-10" caption="非同期チャネルで複数のメッセージを送受信し、各メッセージの間で`await`を伴うスリープを行う" file-name="src/main.rs">

```rust,ignore
{{#rustdoc_include ../listings/ch17-async-await/listing-17-10/src/main.rs:many-messages}}
```

</Listing>

メッセージを送るだけでなく、受信する必要もあります。今回は届くメッセージの数が分かっているので、`rx.recv().await`を4回呼び出して手作業で受信することもできます。しかし実際には通常、*未知の*個数のメッセージを待つため、それ以上メッセージがないと分かるまで待ち続ける必要があります。

リスト16-10では、同期チャネルから受信したすべての要素を処理するため`for`ループを使いました。しかし、Rustにはまだ、*非同期に生成される*一連の要素に`for`ループを使う方法がありません。そこで、まだ見たことのないループである`while let`条件ループを使う必要があります。これは、第6章の[「`if let`と`let...else`による簡潔な制御フロー」][if-let]<!-- ignore -->で見た`if let`構文のループ版です。指定したパターンが値に一致し続ける間、ループも実行を続けます。

`rx.recv`呼び出しはFutureを生成し、それを待機します。Futureの準備が整うまで、ランタイムはそのFutureを一時停止します。メッセージが届くと、届くたびにFutureは`Some(message)`へ解決されます。チャネルが閉じると、メッセージが*1つでも*届いたかどうかにかかわらず、Futureは代わりに`None`へ解決されます。これは、値がもうなく、したがってポーリング、つまり待機をやめるべきことを示します。

`while let`ループが、これらをすべて組み合わせます。`rx.recv().await`を呼んだ結果が`Some(message)`なら、`if let`の場合と同じようにメッセージへアクセスし、ループ本体で使えます。結果が`None`ならループは終了します。ループが1回終わるたびに再び待機地点へ達するので、別のメッセージが届くまでランタイムがもう一度一時停止します。

これでコードはすべてのメッセージを正しく送受信します。残念ながら、まだ2つ問題があります。第1に、メッセージは0.5秒間隔で届きません。プログラムの開始から2秒（2,000ミリ秒）後に、すべてが一度に届きます。第2に、このプログラムは終了しません。新しいメッセージを永遠に待ち続けます。<kbd>ctrl</kbd>-<kbd>C</kbd>で終了させる必要があります。

#### 1つのasyncブロック内のコードは直線的に実行される

まず、メッセージ同士の間に遅延が入らず、遅延時間の合計が経過した後ですべて同時に届く理由を調べます。1つのasyncブロック内では、コード中に`await`キーワードが現れる順番が、プログラム実行時に待機する順番でもあります。

リスト17-10にはasyncブロックが1つしかないため、その中の処理はすべて直線的に実行されます。並行性はまだありません。すべての`tx.send`呼び出しが実行され、その間にすべての`trpl::sleep`呼び出しと対応する待機地点を通ります。それが終わって初めて、`while let`ループが`recv`呼び出しの待機地点を処理できます。

各メッセージの間にスリープの遅延が入る、期待どおりの動作にするには、リスト17-11のように`tx`と`rx`の処理を別々のasyncブロックへ入れる必要があります。そうすれば、リスト17-8と同じように、ランタイムが`trpl::join`を使ってそれぞれを個別に実行できます。ここでも、個々のFutureではなく`trpl::join`呼び出しの結果を待機します。個々のFutureを順番に待機すると、まさに避けようとしている直列の流れへ戻ってしまいます。

<!-- この例は停止しないためテストできない -->

<Listing number="17-11" caption="`send`と`recv`を別々の`async`ブロックへ分け、それらのブロックのFutureを待機する" file-name="src/main.rs">

```rust,ignore
{{#rustdoc_include ../listings/ch17-async-await/listing-17-11/src/main.rs:futures}}
```

</Listing>

リスト17-11の更新後のコードでは、2秒後にすべてが一度に表示されるのではなく、500ミリ秒間隔でメッセージが表示されます。

#### 所有権をasyncブロックへ移動する

それでもプログラムは終了しません。`while let`ループと`trpl::join`が次のように相互作用するためです。

- `trpl::join`が返すFutureは、渡された*両方*のFutureが完了した場合にだけ完了します。
- Future `tx_fut`は、`vals`の最後のメッセージを送った後のスリープが終わると完了します。
- Future `rx_fut`は、`while let`ループが終了するまで完了しません。
- `while let`ループは、`rx.recv`の待機結果が`None`になるまで終了しません。
- `rx.recv`の待機が`None`を返すのは、チャネルのもう一方の端が閉じた場合だけです。
- チャネルが閉じるのは、`rx.close`を呼び出すか、送信側`tx`がドロップされた場合だけです。
- どこでも`rx.close`を呼んでおらず、`tx`は`trpl::block_on`へ渡した最も外側のasyncブロックが終了するまでドロップされません。
- そのブロックは`trpl::join`の完了を待ってブロックされているため終了できず、この一覧の最初へ戻ります。

現在、メッセージを送るasyncブロックは`tx`を*借用*するだけです。メッセージの送信には所有権が不要だからです。しかし、`tx`をそのasyncブロックへ*移動*できれば、そのブロックの終了時にドロップされます。第13章の[「参照をキャプチャするか所有権を移動する」][capture-or-move]<!-- ignore -->では、クロージャに`move`キーワードを使う方法を学びました。また、第16章の[「スレッドで`move`クロージャを使う」][move-threads]<!-- ignore -->で説明したように、スレッドを扱うときはデータをクロージャへ移動する必要がよくあります。asyncブロックにも同じ基本的な仕組みが当てはまり、`move`キーワードはクロージャの場合と同じように使えます。

リスト17-12では、メッセージ送信用のブロックを`async`から`async move`へ変更します。

<Listing number="17-12" caption="完了時に正しく終了するよう、リスト17-11のコードを修正する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-12/src/main.rs:with-move}}
```

</Listing>

この版のコードを実行すると、最後のメッセージを送受信した後、正常に終了します。次に、複数のFutureからデータを送るには何を変える必要があるかを見てみましょう。

#### `join!`マクロで複数のFutureを結合する

この非同期チャネルも複数生産者チャネルなので、リスト17-13のように、複数のFutureからメッセージを送りたければ`tx`の`clone`を呼び出せます。

<Listing number="17-13" caption="asyncブロックで複数の生産者を使う" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-13/src/main.rs:here}}
```

</Listing>

まず`tx`をクローンし、最初のasyncブロックの外側で`tx1`を作ります。先ほど`tx`で行ったのと同じように、`tx1`をそのブロックへ移動します。その後、元の`tx`を*新しい*asyncブロックへ移動し、少し長い間隔でさらにメッセージを送ります。ここでは新しいasyncブロックを受信処理用のasyncブロックより後ろに置いていますが、前に置いても構いません。重要なのはFutureを待機する順番であり、作成する順番ではありません。

送信用の2つのasyncブロックは、どちらも`async move`ブロックにする必要があります。そうすれば各ブロックの終了時に`tx`と`tx1`がドロップされます。そうしなければ、最初に遭遇したのと同じ無限ループへ戻ってしまいます。

最後に、追加したFutureを扱うため`trpl::join`から`trpl::join!`へ切り替えます。`join!`マクロは、コンパイル時に個数が分かっている任意の数のFutureを待機します。個数が分からないFutureのコレクションを待機する方法は、この章の後半で説明します。

これで、両方の送信用Futureからのメッセージがすべて表示されます。また、送信用Futureはメッセージを送った後にそれぞれ少し異なる時間だけ待つため、メッセージも異なる間隔で受信されます。

<!-- 出力の違いは重要ではなく、コンパイラの変更よりスレッドの実行順による可能性が高いため抽出しない -->

```text
received 'hi'
received 'more'
received 'from'
received 'the'
received 'messages'
received 'future'
received 'for'
received 'you'
```

ここまで、Future間でデータを送るメッセージ受け渡し、asyncブロック内のコードが順番に実行されること、所有権をasyncブロックへ移動する方法、複数のFutureを結合する方法を調べました。次は、別のタスクへ切り替えてよいとランタイムへ伝える方法と、その理由を説明します。

[thread-spawn]: ch16-01-threads.html#creating-a-new-thread-with-spawn
[join-handles]: ch16-01-threads.html#waiting-for-all-threads-to-finish
[message-passing-threads]: ch16-02-message-passing.html
[if-let]: ch06-03-if-let.html
[capture-or-move]: ch13-01-closures.html#capturing-references-or-moving-ownership
[move-threads]: ch16-01-threads.html#using-move-closures-with-threads

> **C言語との比較**
>
> C言語のスレッド間キューでは、受信関数がスレッドをブロックするか、ノンブロッキングAPIとイベント通知を組み合わせます。非同期チャネルの`recv().await`は、メッセージがない間にOSスレッドを占有せず、タスクだけを一時停止します。一方、同じasyncブロック内の文は通常どおり順番に実行されるため、並行に進めたい処理は別々のFutureとして構成する必要があります。
