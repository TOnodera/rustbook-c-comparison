

## スレッドを使用してコードを同時に実行する

多くの現代のOSでは、実行中のプログラムのコードは*プロセス*で走り、OSは同時に複数のプロセスを管理するでしょう。
プログラム内では、独立した部分を同時に実行することもできます。これらの独立した部分を実行する機能を*スレッド*と呼びます。
例えばwebサーバは、同時に複数のリクエストに応答できるように、複数のスレッドを使用することができます。

同時に複数のタスクを実行するために、プログラム内の計算を複数のスレッドに分けることで、パフォーマンスを改善することができますが、
複雑度も増します。スレッドは同時に実行することができるので、異なるスレッドのコードが走る順番に関して、
本来的に保証はありません。これは例えば以下のような問題を招きます。

* スレッドがデータやリソースに矛盾した順番でアクセスする競合状態
* 2つのスレッドがお互いを待ち、両者が継続するのを防ぐデッドロック
* 特定の状況でのみ起き、確実な再現や修正が困難なバグ

Rustは、スレッドを使用する際の悪影響を軽減しようとしていますが、それでも、マルチスレッドの文脈でのプログラミングでは、
注意深い思考と、シングルスレッドで走るプログラムでのそれとは異なるコード構造が必要です。

プログラミング言語によってスレッドはいくつかの方法で実装されており、多くのOSは、言語が呼び出すことができる、
新規スレッドを生成するためのAPIを提供しています。
Rust標準ライブラリは*1:1*モデルのスレッド実装を使用しており、1つの言語スレッドに対して1つのOSスレッドを使用します。
1:1モデルとは異なるトレードオフを選択して、他のモデルのスレッドを実装するクレートもあります。

### `spawn`で新規スレッドを生成する

新規スレッドを生成するには、`thread::spawn`関数を呼び出し、
新規スレッドで実行したいコードを含むクロージャ(クロージャについては第13章で語りました)を渡します。
リスト16-1の例は、メインスレッドと新規スレッドからテキストを出力します。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch16-fearless-concurrency/listing-16-01/src/main.rs}}
```

<span class="caption">リスト16-1: メインスレッドが別のものを出力する間に新規スレッドを生成して何かを出力する</span>

Rustプログラムのメインスレッドが完了するときには、立ち上げられたすべてのスレッドは、その実行が完了したかどうかにかかわらず、
停止されることに注意してください。このプログラムからの出力は毎回少々異なる可能性がありますが、だいたい以下のような感じでしょう。

```text
hi number 1 from the main thread!
hi number 1 from the spawned thread!
hi number 2 from the main thread!
hi number 2 from the spawned thread!
hi number 3 from the main thread!
hi number 3 from the spawned thread!
hi number 4 from the main thread!
hi number 4 from the spawned thread!
hi number 5 from the spawned thread!
```

`thread::sleep`を呼び出すと、少々の間、スレッドの実行を止め、違うスレッドを実行することができます。
スレッドはおそらく切り替わるでしょうが、保証はありません: OSがスレッドのスケジュールを行う方法によります。
この実行では、コード上では立ち上げられたスレッドのprint文が先に現れているのに、メインスレッドが先に出力しています。また、
立ち上げたスレッドには`i`が9になるまで出力するよう指示しているのに、メインスレッドが終了する前の5までしか到達していません。

このコードを実行してメインスレッドの出力しか目の当たりにできなかったり、オーバーラップがなければ、
範囲の値を増やしてOSがスレッド切り替えを行う機会を増やしてみてください。

### `join`ハンドルで全スレッドの終了を待つ

リスト16-1のコードはほとんどの場合、メインスレッドが終了することで、立ち上げたスレッドが完了する前に停止されるだけでなく、
スレッドの実行順に保証がないことから、立ち上げたスレッドがそもそも実行されるかどうかも保証できません。

`thread::spawn`の戻り値を変数に保存することで、立ち上げたスレッドが実行されなかったり、
完了する前に終了してしまったりする問題を修正することができます。`thread::spawn`の戻り値の型は`JoinHandle`です。
`JoinHandle`は、その`join`メソッドを呼び出したときにスレッドの終了を待つ所有された値です。
リスト16-2は、リスト16-1で生成したスレッドの`JoinHandle`を使用し、`join`を呼び出して、
`main`が終了する前に、立ち上げたスレッドが確実に完了する方法を示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch16-fearless-concurrency/listing-16-02/src/main.rs}}
```

<span class="caption">リスト16-2: `thread::spawn`の`JoinHandle`を保存してスレッドが完了するのを保証する</span>

ハンドルに対して`join`を呼び出すと、ハンドルが表すスレッドが終了するまで現在実行中のスレッドをブロックします。
スレッドを*ブロック*するとは、そのスレッドが動いたり、終了したりすることを防ぐことです。
`join`の呼び出しをメインスレッドの`for`ループの後に配置したので、リスト16-2を実行すると、
以下のように出力されるはずです。

```text
hi number 1 from the main thread!
hi number 2 from the main thread!
hi number 1 from the spawned thread!
hi number 3 from the main thread!
hi number 2 from the spawned thread!
hi number 4 from the main thread!
hi number 3 from the spawned thread!
hi number 4 from the spawned thread!
hi number 5 from the spawned thread!
hi number 6 from the spawned thread!
hi number 7 from the spawned thread!
hi number 8 from the spawned thread!
hi number 9 from the spawned thread!
```

2つのスレッドが代わる代わる実行されていますが、`handle.join()`呼び出しのためにメインスレッドは待機し、
立ち上げたスレッドが終了するまで終わりません。

ですが、代わりに`handle.join()`を`for`ループの前に移動したらどうなるのか確認しましょう。こんな感じに:

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch16-fearless-concurrency/no-listing-01-join-too-early/src/main.rs}}
```

メインスレッドは、立ち上げたスレッドが終了するまで待ち、それから`for`ループを実行するので、
以下のように出力はもう混ざらないでしょう。

```text
hi number 1 from the spawned thread!
hi number 2 from the spawned thread!
hi number 3 from the spawned thread!
hi number 4 from the spawned thread!
hi number 5 from the spawned thread!
hi number 6 from the spawned thread!
hi number 7 from the spawned thread!
hi number 8 from the spawned thread!
hi number 9 from the spawned thread!
hi number 1 from the main thread!
hi number 2 from the main thread!
hi number 3 from the main thread!
hi number 4 from the main thread!
```

どこで`join`を呼ぶかといったほんの些細なことが、スレッドが同時に走るかどうかに影響することもあります。

### スレッドで`move`クロージャを使用する

`thread::spawn`に渡されるクロージャでは、`move`キーワードを多用することになるでしょう。
そうすることで、クロージャは環境から使用する値の所有権を奪い、あるスレッドから別のスレッドに値の所有権を移すからです。
第13章の[「参照をキャプチャするか、所有権を移動するか」][capture]節では、クロージャの文脈で`move`について議論しました。
それでは、`move`と`thread::spawn`の相互作用により集中していきましょう。

リスト16-1において、`thread::spawn`に渡したクロージャには引数がなかったことに注目してください。
立ち上げたスレッドのコードでメインスレッドからのデータは何も使用していないのです。
立ち上げたスレッドでメインスレッドのデータを使用するには、立ち上げるスレッドのクロージャは、
必要な値をキャプチャしなければなりません。リスト16-3は、メインスレッドでベクタを生成し、
立ち上げたスレッドで使用する試みを示しています。しかしながら、すぐにわかるように、これはまだ動きません。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch16-fearless-concurrency/listing-16-03/src/main.rs}}
```

<span class="caption">リスト16-3: 別のスレッドでメインスレッドが生成したベクタを使用しようとする</span>

クロージャは`v`を使用しているので、`v`をキャプチャし、クロージャの環境の一部にしています。
`thread::spawn`はこのクロージャを新しいスレッドで実行するので、
その新しいスレッド内で`v`にアクセスできるはずです。しかし、このコードをコンパイルすると、
以下のようなエラーが出ます。

```console
{{#include ../listings/ch16-fearless-concurrency/listing-16-03/output.txt}}
```

Rustは`v`のキャプチャ方法を*推論*し、`println!`は`v`への参照のみを必要とするので、クロージャは、
`v`を借用しようとします。ですが、問題があります。 コンパイラには、立ち上げたスレッドがどのくらいの期間走るのかわからないので、
`v`への参照が常に有効であるか把握できないのです。

リスト16-4は、`v`への参照がより有効でなさそうな筋書きです。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch16-fearless-concurrency/listing-16-04/src/main.rs}}
```

<span class="caption">リスト16-4: `v`をドロップするメインスレッドから`v`への参照をキャプチャしようとするクロージャを伴うスレッド</span>

このコードを実行できてしまうなら、立ち上げたスレッドはまったく実行されることなく即座にバックグラウンドに置かれる可能性があります。
立ち上げたスレッドは内部に`v`への参照を保持していますが、メインスレッドは、第15章で説明した`drop`関数を使用して、
即座に`v`をドロップしています。そして、立ち上げたスレッドが実行を開始する時には、`v`はもう有効ではなく、
参照も不正になるのです。あちゃー！

リスト16-3のコンパイルエラーを修正するには、エラーメッセージのアドバイスを活用できます。

```text
help: to force the closure to take ownership of `v` (and any other referenced variables), use the `move` keyword
  |
6 |     let handle = thread::spawn(move || {
  |                                ++++
```

クロージャの前に`move`キーワードを付することで、コンパイラに値を借用すべきと推論させるのではなく、
クロージャに使用している値の所有権を強制的に奪わせます。リスト16-5に示したリスト16-3に対する変更は、
コンパイルでき、意図通りに動きます。

<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch16-fearless-concurrency/listing-16-05/src/main.rs}}
```

<span class="caption">リスト16-5: `move`キーワードを使用してクロージャに使用している値の所有権を強制的に奪わせる</span>

リスト16-4の、メインスレッドが`drop`を呼び出すコードを修正するためにも、
`move`クロージャを使用して同じことを試したくなるかもしれません。しかしながら、
リスト16-4が試みていることは別の理由によりできないので、この修正はうまくいきません。
クロージャに`move`を付与したら、`v`をクロージャの環境にムーブするので、
もはやメインスレッドで`drop`を呼び出すことは叶わなくなるでしょう。代わりにこのようなコンパイルエラーが出るでしょう。

```console
{{#include ../listings/ch16-fearless-concurrency/output-only-01-move-drop/output.txt}}
```

再三Rustの所有権規則が救ってくれました！リスト16-3のコードはエラーになりました。
コンパイラが一時的に保守的になり、スレッドに対して`v`を借用しただけだったからで、
これは、メインスレッドは理論上、立ち上げたスレッドの参照を不正化する可能性があることを意味します。
`v`の所有権を立ち上げたスレッドに移動するとコンパイラに指示することで、
メインスレッドはもう`v`を使用しないとコンパイラに保証しているのです。リスト16-4も同様に変更したら、
メインスレッドで`v`を使用しようとする際に所有権の規則に違反することになります。
`move`キーワードにより、Rustの保守的な借用のデフォルトが上書きされるのです。 
所有権の規則を侵害させてくれないのです。

スレッドとスレッドAPIの基礎知識を得たので、スレッドで*できる*ことを見ていきましょう。

[capture]: ch13-01-closures.html#capturing-references-or-moving-ownership
