<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="yielding"></a>

### ランタイムへ制御を譲る

[「最初の非同期プログラム」][async-program]<!-- ignore -->の節で説明したように、待機地点（await point）では、待っているFutureの準備ができていなければ、Rustはランタイムにそのタスクを一時停止して別のタスクへ切り替える機会を与えます。逆もまた成り立ちます。Rustがasyncブロックを一時停止し、ランタイムへ制御を返すのは、待機地点*だけ*です。待機地点と次の待機地点の間にある処理は、すべて同期的に実行されます。

つまり、asyncブロック内で待機地点を挟まずに大量の処理を行うと、そのFutureがほかのFutureの進行を妨げます。この状態を、あるFutureがほかのFutureを*飢餓状態*（starving）にすると表現することがあります。大きな問題にならない場合もありますが、負荷の高い準備処理や長時間の処理を行う場合、あるいは特定の処理を無期限に続けるFutureがある場合は、いつ、どこでランタイムへ制御を返すかを考える必要があります。

飢餓状態の問題を示すため、長時間かかる処理を再現し、その解決方法を調べましょう。リスト17-14では`slow`関数を導入します。

<Listing number="17-14" caption="`thread::sleep`で遅い処理を再現する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-14/src/main.rs:slow}}
```

</Listing>

このコードは`trpl::sleep`ではなく`std::thread::sleep`を使うため、`slow`を呼び出すと、指定したミリ秒の間、現在のスレッドがブロックされます。`slow`を使えば、実際の長時間かつブロッキングな処理を代わりに表現できます。

リスト17-15では、2つのFuture内で、この種のCPUバウンドな処理を行う状況を`slow`で再現します。

<Listing number="17-15" caption="`slow`関数を呼び出して遅い処理を再現する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-15/src/main.rs:slow-futures}}
```

</Listing>

どちらのFutureも、複数の遅い処理を実行し終えるまでランタイムへ制御を返しません。このコードを実行すると、次の出力が表示されます。

<!-- manual-regeneration
cd listings/ch17-async-await/listing-17-15/
cargo run
copy just the output
-->

```text
'a' started.
'a' ran for 30ms
'a' ran for 10ms
'a' ran for 20ms
'b' started.
'b' ran for 75ms
'b' ran for 10ms
'b' ran for 15ms
'b' ran for 350ms
'a' finished.
```

2つのURLを取得するFutureを`trpl::select`で競争させたリスト17-5と同じく、`a`が終わるとすぐに`select`も終了します。しかし、2つのFutureにある`slow`の呼び出しは交互には実行されません。Future `a`は`trpl::sleep`の呼び出しを待機するまで自分の処理をすべて行い、次にFuture `b`が自身の`trpl::sleep`を待機するまで処理をすべて行い、最後にFuture `a`が完了します。2つのFutureが遅い処理の合間にも進めるようにするには、ランタイムへ制御を返すための待機地点が必要です。つまり、待機できる何かが必要です。

リスト17-15でも、この制御の受け渡しはすでに確認できます。Future `a`の最後にある`trpl::sleep`を削除すると、Future `b`が*一度も*実行されないまま`a`が完了します。処理を交互に進める出発点として、リスト17-16のように`trpl::sleep`関数を使ってみましょう。

<Listing number="17-16" caption="`trpl::sleep`を使って処理を交互に進める" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-16/src/main.rs:here}}
```

</Listing>

それぞれの`slow`呼び出しの間に、待機地点を伴う`trpl::sleep`を追加しました。これで2つのFutureの処理が交互に実行されます。

<!-- manual-regeneration
cd listings/ch17-async-await/listing-17-16
cargo run
copy just the output
-->

```text
'a' started.
'a' ran for 30ms
'b' started.
'b' ran for 75ms
'a' ran for 10ms
'b' ran for 10ms
'a' ran for 20ms
'b' ran for 15ms
'a' finished.
```

Future `a`は、最初の`trpl::sleep`より前に`slow`を呼び出すため、`b`へ制御を渡す前に少し処理を進めます。その後は、どちらかが待機地点に達するたびに2つのFutureが交互に切り替わります。ここでは`slow`を呼ぶたびに切り替えましたが、実際には用途に最も適した単位で処理を分割できます。

ただし、ここで本当に*スリープ*したいわけではありません。できるだけ速く処理を進めながら、ランタイムへ制御を返すだけでよいのです。`trpl::yield_now`関数を使えば、それを直接行えます。リスト17-17では、すべての`trpl::sleep`を`trpl::yield_now`へ置き換えます。

<Listing number="17-17" caption="`yield_now`を使って処理を交互に進める" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-17/src/main.rs:yields}}
```

</Listing>

このコードは実際の意図をより明確に示し、`sleep`を使うより大幅に高速になる可能性もあります。`sleep`が使うようなタイマーには、時間の細かさに限界があることが多いためです。たとえば、ここで使用している`sleep`は、1ナノ秒の`Duration`を渡しても必ず1ミリ秒以上スリープします。繰り返しになりますが、現代のコンピュータは*高速*であり、1ミリ秒の間にも大量の処理を実行できます。

したがって、プログラムがほかに何を行っているかによっては、計算バウンドなタスクにもasyncが役立ちます。asyncは、プログラムの各部分の関係を構成する便利な道具を提供するからです。ただし、非同期状態機械のオーバーヘッドはかかります。これは*協調的マルチタスク*（cooperative multitasking）の一種であり、各Futureが、どの待機地点で制御を渡すかを自分で決められます。そのため各Futureには、長時間ブロックしない責任もあります。Rustで作られた組み込みOSの中には、これが利用できる*唯一*のマルチタスク方式であるものもあります。

もちろん実際のコードで、1行ごとに関数呼び出しと待機地点を交互に並べることは普通ありません。この方法で制御を譲るコストは比較的小さいものの、ゼロではありません。多くの場合、計算バウンドなタスクを細かく分割しようとすると処理が大幅に遅くなるため、処理を短時間ブロックさせるほうが*全体*の性能にとってよいこともあります。コードの本当のボトルネックがどこにあるかは、必ず計測してください。ただし、並行して進むと予想した大量の処理が直列に実行されている場合には、この仕組みを思い出すことが重要です。

### 独自の非同期抽象化を構築する

Future同士を合成して、新しいパターンを作ることもできます。たとえば、すでに使った非同期の構成要素から`timeout`関数を作れます。完成した`timeout`は、さらに別の非同期抽象化を作るための構成要素になります。

リスト17-18は、処理の遅いFutureに対して、この`timeout`がどのように動くことを期待するかを示しています。

<Listing number="17-18" caption="想定した`timeout`を使い、制限時間付きで遅い処理を実行する" file-name="src/main.rs">

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch17-async-await/listing-17-18/src/main.rs:here}}
```

</Listing>

実装してみましょう。まず`timeout`のAPIについて考えます。

- `timeout`自身を待機できるように、非同期関数にする必要があります。
- 第1引数は、実行するFutureです。どのFutureでも扱えるようにジェネリックにできます。
- 第2引数は、待機する最長時間です。`Duration`を使えば、`trpl::sleep`へそのまま簡単に渡せます。
- 戻り値は`Result`にします。Futureが正常に完了すれば、そのFutureが生成した値を持つ`Ok`を返します。先にタイムアウト時間が経過した場合は、待機した時間を持つ`Err`を返します。

リスト17-19に、この宣言を示します。

<!-- This is not tested because it intentionally does not compile. -->

<Listing number="17-19" caption="`timeout`のシグネチャを定義する" file-name="src/main.rs">

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch17-async-await/listing-17-19/src/main.rs:declaration}}
```

</Listing>

これで型に関する目標を満たしました。次に、必要な*振る舞い*を考えます。渡されたFutureと制限時間を競争させたいのです。`trpl::sleep`で`Duration`からタイマーのFutureを作り、`trpl::select`を使って、そのタイマーと呼び出し側から渡されたFutureを一緒に実行できます。

リスト17-20では、`trpl::select`を待機した結果に対してパターンマッチし、`timeout`を実装します。

<Listing number="17-20" caption="`select`と`sleep`で`timeout`を定義する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-20/src/main.rs:implementation}}
```

</Listing>

`trpl::select`の実装は公平ではありません。引数を渡された順番で必ずポーリングします。別の`select`実装では、最初にポーリングする引数をランダムに選ぶこともあります。そのため、`max_time`が非常に短くても完了する機会を得られるよう、`future_to_try`を先に`select`へ渡します。`future_to_try`が先に終了すると、`select`は`future_to_try`の出力を持つ`Left`を返します。`timer`が先に終了すると、タイマーの出力`()`を持つ`Right`を返します。

`future_to_try`が成功して`Left(output)`を得た場合は、`Ok(output)`を返します。代わりにスリープタイマーが経過して`Right(())`を得た場合は、`_`で`()`を無視し、`Err(max_time)`を返します。

これで、2つの非同期ヘルパーから、実際に動く`timeout`を作れました。コードを実行すると、タイムアウト後に失敗を示す次の出力が表示されます。

```text
Failed after 2 seconds
```

Futureは別のFutureと合成できるため、小さな非同期の構成要素から非常に強力な道具を作れます。たとえば同じ方法で、タイムアウトと再試行を組み合わせ、さらにそれをネットワーク呼び出しのような処理（リスト17-5など）と組み合わせられます。

実際には通常、主に`async`と`await`を直接使い、外側のFutureをどのように実行するか制御するために、補助的に`select`のような関数や`join!`のようなマクロを使います。

ここまで、複数のFutureを同時に扱う方法をいくつも見てきました。次は、時間の経過とともに順番に現れる複数のFutureを、*Stream*で扱う方法を見ていきます。

[async-program]: ch17-01-futures-and-syntax.html#our-first-async-program

> **C言語との比較**
>
> イベントループをC言語で実装する場合、長時間のコールバックがループ全体を止めないよう、処理を適切な単位に分けて制御を返す必要があります。RustのFutureも同じ協調的な性質を持ちます。`await`はどこでも自動的に割り込む命令ではなく、「ここなら処理を止め、別のタスクへ切り替えてよい」と明示する地点です。
