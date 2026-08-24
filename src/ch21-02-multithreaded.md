## シングルスレッドサーバをマルチスレッド化する

現状、サーバはリクエストを順番に処理します。つまり、最初の接続が処理し終わるまで、2番目の接続は処理しないということです。
サーバが受け付けるリクエストの量が増えるほど、この連続的な実行は、最適ではなくなるでしょう。
サーバが処理するのに長い時間がかかるリクエストを受け付けたら、新しいリクエストは迅速に処理できても、
続くリクエストは長いリクエストが完了するまで待たなければならなくなるでしょう。これを修正する必要がありますが、
まずは、実際に問題が起こっているところを見ます。

### 現在のサーバの実装で遅いリクエストをシミュレーションする

処理が遅いリクエストが現在のサーバ実装に対して行われる他のリクエストにどう影響するかに目を向けます。
リスト21-10は、応答する前に5秒サーバをスリープさせる遅いレスポンスをシミュレーションした */sleep*へのリクエストを扱う実装です。

<span class="filename">ファイル名: src/main.rs</span>

```rust,no_run
{{#rustdoc_include ../listings/ch21-web-server/listing-21-10/src/main.rs:here}}
```

<span class="caption">リスト21-10: */sleep*を認識して5秒間スリープすることで遅いリクエストをシミュレーションする</span>

このコードはちょっと汚いですが、シミュレーション目的には十分です。2番目のリクエスト`sleep`を作成し、
そのデータをサーバは認識します。`if`ブロックの後に`else if`を追加し、*/sleep*へのリクエストを確認しています。
そのリクエストが受け付けられると、サーバは成功のHTMLページを描画する前に5秒間スリープします。

我々のサーバがどれだけ基礎的か見て取れます: 本物のライブラリは、もっと冗長でない方法で複数のリクエストの認識を扱うでしょう！

`cargo run`でサーバを開始してください。それから2つブラウザのウインドウを開いてください: 1つは、
*http://localhost:7878/* 用、そしてもう1つは*http://localhost:7878/sleep* 用です。
以前のように */* URIを数回入力したら、素早く応答するでしょう。しかし、*/sleep*を入力し、それから */* をロードしたら、
`sleep`がロードする前にきっかり5秒スリープし終わるまで、*/* は待機するのを目撃するでしょう。

より多くのリクエストが遅いリクエストの背後に回ってしまうのを回避するようWebサーバが動く方法を変える方法は複数あります;
これから実装するのは、スレッドプールです。

### スレッドプールでスループットを向上させる

*スレッドプール*は、待機し、タスクを処理する準備のできた一塊りの大量に生成されたスレッドです。
プログラムが新しいタスクを受け取ったら、プールのスレッドのどれかをタスクにあてがい、
そのスレッドがそのタスクを処理します。
プールの残りのスレッドは、最初のスレッドが処理中にやってくる他のあらゆるタスクを扱うために利用可能です。
最初のスレッドがタスクの処理を完了したら、アイドル状態のスレッドプールに戻り、新しいタスクを処理する準備ができます。
スレッドプールにより、並行で接続を処理でき、サーバのスループットを向上させます。

プール内のスレッド数は、小さい数字に制限し、DoS(Denial of Service; サービスの拒否)攻撃から保護します; リクエストが来た度に新しいスレッドをプログラムに生成させたら、
1000万リクエストをサーバに行う誰かが、サーバのリソースを使い尽くし、リクエストの処理を停止に追い込むことで、
大混乱を招くことができてしまうでしょう。

無制限にスレッドを大量生産するのではなく、プールに固定された数のスレッドを待機させます。リクエストが来る度に、
処理するためにプールに送られます。プールは、やって来るリクエストのキューを管理します。
プールの各スレッドがこのキューからリクエストを取り出し、リクエストを処理し、そして、別のリクエストをキューに要求します。
この設計により、`N`リクエストを並行して処理でき、ここで`N`はスレッド数です。各スレッドが実行に時間のかかるリクエストに応答していたら、
続くリクエストはそれでも、キュー内で待機させられてしまうこともありますが、その地点に到達する前に扱える時間のかかるリクエスト数を増加させました。

このテクニックは、Webサーバのスループットを向上させる多くの方法の1つに過ぎません。探究する可能性のある他の選択肢は、
fork/joinモデルと、シングルスレッドの非同期I/Oモデルです。この話題にご興味があれば、他の解決策についてもっと読み、
Rustで実装を試みることができます; Rustのような低レベル言語であれば、これらの選択肢全部が可能なのです。

スレッドプールを実装し始める前に、プールを使うのはどんな感じになるはずなのかについて語りましょう。コードの設計を試みる際、
クライアントのインターフェイスをまず書くことは、設計を導く手助けになることがあります。呼び出したいように構成されるよう、
コードのAPIを記述してください; そして、機能を実装してから公開APIの設計をするのではなく、その構造内で機能を実装してください。

第12章のプロジェクトでTDDを使用したように、ここではCompiler Driven Development(コンパイラ駆動開発)を使用します。
欲しい関数を呼び出すコードを書き、それからコンパイラの出すエラーを見てコードが動くように次に何を変更すべきかを決定します。

#### 各リクエストに対してスレッドを立ち上げられる場合のコードの構造

まず、全接続に対して新しいスレッドを確かに生成した場合にコードがどんな見た目になるかを探究しましょう。
先ほど述べたように、無制限にスレッドを大量生産する可能性があるという問題のため、これは最終的な計画ではありませんが、
開始点です。リスト21-11は、新しいスレッドを立ち上げて`for`ループ内で各ストリームを扱うために`main`に行う変更を示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust,no_run
{{#rustdoc_include ../listings/ch21-web-server/listing-21-11/src/main.rs:here}}
```

<span class="caption">リスト21-11: 各ストリームに対して新しいスレッドを立ち上げる</span>

第16章で学んだように、`thread::spawn`は新しいスレッドを生成し、それからクロージャ内のコードを新しいスレッドで実行します。
このコードを実行してブラウザで */sleep*をロードし、それからもう2つのブラウザのタブで */* をロードしたら、
確かに */* へのリクエストは、*/sleep*が完了するのを待機しなくても済むことがわかるでしょう。
ですが、前述したように、無制限にスレッドを生成することになるので、これは最終的にシステムを参らせてしまうでしょう。

#### 有限数のスレッド用に似たインターフェイスを作成する

スレッドからスレッドプールへの変更にAPIを使用するコードへの大きな変更が必要ないように、
スレッドプールには似た、馴染み深い方法で動作してほしいです。リスト21-12は、
`thread::spawn`の代わりに使用したい`ThreadPool`構造体の架空のインターフェイスを表示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch21-web-server/listing-21-12/src/main.rs:here}}
```

<span class="caption">リスト21-12: `ThreadPool`の理想的なインターフェイス</span>

`ThreadPool::new`を使用して設定可能なスレッド数で新しいスレッドプールを作成し、今回の場合は4です。
それから`for`ループ内で、`pool.execute`は、プールが各ストリームに対して実行すべきクロージャを受け取るという点で、
`thread::spawn`と似たインターフェイスです。`pool.execute`を実装する必要があるので、
これはクロージャを取り、実行するためにプール内のスレッドに与えます。このコードはまだコンパイルできませんが、
コンパイラがどう修正したらいいかガイドできるように試してみます。

#### コンパイラ駆動開発で`ThreadPool`構造体を構築する

リスト21-12の変更を*src/main.rs*に行い、それから開発を駆動するために`cargo check`からのコンパイラエラーを活用しましょう。
こちらが得られる最初のエラーです:

```text
$ cargo check
   Compiling hello v0.1.0 (file:///projects/hello)
error[E0433]: failed to resolve. Use of undeclared type or module `ThreadPool`
(エラー: 解決に失敗しました。未定義の型またはモジュール`ThreadPool`を使用しています)
  --> src\main.rs:10:16
   |
10 |     let pool = ThreadPool::new(4);
   |                ^^^^^^^^^^^^^^^ Use of undeclared type or module
   `ThreadPool`

error: aborting due to previous error
```

よろしい!このエラーは`ThreadPool`型かモジュールが必要なことを教えてくれているので、今構築します。
`ThreadPool`の実装は、Webサーバが行う仕事の種類とは独立しています。従って、`hello`クレートをバイナリクレートからライブラリクレートに切り替え、
`ThreadPool`の実装を保持させましょう。ライブラリクレートに変更後、
個別のスレッドプールライブラリをWebリクエストを提供するためだけではなく、スレッドプールでしたいあらゆる作業にも使用できます。

以下を含む*src/lib.rs*を生成してください。これは、現状存在できる最も単純な`ThreadPool`の定義です:

<span class="filename">ファイル名: src/lib.rs</span>

```rust
pub struct ThreadPool;
```

それから新しいディレクトリ、*src/bin*を作成し、*src/main.rs*に根付くバイナリクレートを*src/bin/main.rs*に移動してください。
そうすると、ライブラリクレートが*hello*ディレクトリ内で主要クレートになります; それでも、
`cargo run`で*src/bin/main.rs*のバイナリを実行することはできます。*main.rs*ファイルを移動後、
編集してライブラリクレートを持ち込み、以下のコードを*src/bin/main.rs*の先頭に追記して`ThreadPool`をスコープに導入してください:

<span class="filename">ファイル名: src/bin/main.rs</span>

```rust,ignore
extern crate hello;
use hello::ThreadPool;
```

このコードはまだ動きませんが、再度それを確認して扱う必要のある次のエラーを手に入れましょう:

```text
$ cargo check
   Compiling hello v0.1.0 (file:///projects/hello)
error[E0599]: no function or associated item named `new` found for type
`hello::ThreadPool` in the current scope
(エラー: 現在のスコープで型`hello::ThreadPool`の関数または関連アイテムに`new`というものが見つかりません)
 --> src/bin/main.rs:13:16
   |
13 |     let pool = ThreadPool::new(4);
   |                ^^^^^^^^^^^^^^^ function or associated item not found in
   `hello::ThreadPool`
```

このエラーは、次に、`ThreadPool`に対して`new`という関連関数を作成する必要があることを示唆しています。
また、`new`には`4`を引数として受け入れる引数1つがあり、`ThreadPool`インスタンスを返すべきということも知っています。
それらの特徴を持つ最も単純な`new`関数を実装しましょう:

<span class="filename">ファイル名: src/lib.rs</span>

```rust
pub struct ThreadPool;

impl ThreadPool {
    pub fn new(size: usize) -> ThreadPool {
        ThreadPool
    }
}
```

`size`引数の型として、`usize`を選択しました。何故なら、マイナスのスレッド数は、何も筋が通らないことを知っているからです。
また、この4をスレッドのコレクションの要素数として使用し、第3章の「整数型」節で議論したように、これは`usize`のあるべき姿であることも知っています。

コードを再度確認しましょう:

```text
$ cargo check
   Compiling hello v0.1.0 (file:///projects/hello)
warning: unused variable: `size`
(警告: 未使用の変数: `size`)
 --> src/lib.rs:4:16
  |
4 |     pub fn new(size: usize) -> ThreadPool {
  |                ^^^^
  |
  = note: #[warn(unused_variables)] on by default
  = note: to avoid this warning, consider using `_size` instead

error[E0599]: no method named `execute` found for type `hello::ThreadPool` in the current scope
  --> src/bin/main.rs:18:14
   |
18 |         pool.execute(|| {
   |              ^^^^^^^
```

今度は、警告とエラーが出ました。一時的に警告は無視して、`ThreadPool`に`execute`メソッドがないためにエラーが発生しました。
「有限数のスレッド用に似たインターフェイスを作成する」節で我々のスレッドプールは、
`thread::spawn`と似たインターフェイスにするべきと決定したことを思い出してください。
さらに、`execute`関数を実装するので、与えられたクロージャを取り、実行するようにプールの待機中のスレッドに渡します。

`ThreadPool`に`execute`メソッドをクロージャを引数として受け取るように定義します。
第13章の「ジェネリック引数と`Fn`トレイトを使用してクロージャを保存する」節から、
3つの異なるトレイトでクロージャを引数として取ることができることを思い出してください: `Fn`、`FnMut`、`FnOnce`です。
ここでは、どの種類のクロージャを使用するか決定する必要があります。最終的には、
標準ライブラリの`thread::spawn`実装に似たことをすることがわかっているので、
`thread::spawn`のシグニチャで引数にどんな境界があるか見ることができます。ドキュメンテーションは、以下のものを示しています:

```rust,ignore
pub fn spawn<F, T>(f: F) -> JoinHandle<T>
    where
        F: FnOnce() -> T + Send + 'static,
        T: Send + 'static
```

`F`型引数がここで関心のあるものです; `T`型引数は戻り値と関係があり、関心はありません。`spawn`は、
`F`のトレイト境界として`FnOnce`を使用していることが確認できます。これはおそらく、我々が欲しているものでもあるでしょう。
というのも、最終的には`execute`で得た引数を`spawn`に渡すからです。さらに`FnOnce`は使用したいトレイトであると自信を持つことができます。
リクエストを実行するスレッドは、そのリクエストのクロージャを1回だけ実行し、これは`FnOnce`の`Once`に合致するからです。

`F`型引数にはまた、トレイト境界の`Send`とライフタイム境界の`'static`もあり、この状況では有用です:
あるスレッドから別のスレッドにクロージャを移動するのに`Send`が必要で、スレッドの実行にどれくらいかかるかわからないので、
`'static`も必要です。`ThreadPool`にこれらの境界のジェネリックな型`F`の引数を取る`execute`メソッドを生成しましょう:

<span class="filename">ファイル名: src/lib.rs</span>

```rust
# pub struct ThreadPool;
impl ThreadPool {
    // --snip--

    pub fn execute<F>(&self, f: F)
        where
            F: FnOnce() + Send + 'static
    {

    }
}
```

それでも、`FnOnce`の後に`()`を使用しています。この`FnOnce`は引数を取らず、値も返さないクロージャを表すからです。
関数定義同様に、戻り値の型はシグニチャから省略できますが、引数がなくても、カッコは必要です。

またもや、これが`execute`メソッドの最も単純な実装です: 何もしませんが、
コードがコンパイルできるようにしようとしているだけです。再確認しましょう:

```text
$ cargo check
   Compiling hello v0.1.0 (file:///projects/hello)
warning: unused variable: `size`
 --> src/lib.rs:4:16
  |
4 |     pub fn new(size: usize) -> ThreadPool {
  |                ^^^^
  |
  = note: #[warn(unused_variables)] on by default
  = note: to avoid this warning, consider using `_size` instead

warning: unused variable: `f`
 --> src/lib.rs:8:30
  |
8 |     pub fn execute<F>(&self, f: F)
  |                              ^
  |
  = note: to avoid this warning, consider using `_f` instead
```

これで警告を受け取るだけになり、コンパイルできるようになりました！しかし、`cargo run`を試して、
ブラウザでリクエストを行うと、章の冒頭で見かけたエラーがブラウザに現れることに注意してください。
ライブラリは、まだ実際に`execute`に渡されたクロージャを呼び出していないのです！

> 注釈: HaskellやRustなどの厳密なコンパイラがある言語についての格言として「コードがコンパイルできたら、
> 動作する」というものをお聴きになったことがある可能性があります。ですが、この格言は普遍的に当てはまるものではありません。
> このプロジェクトはコンパイルできますが、全く何もしません！本物の完璧なプロジェクトを構築しようとしているのなら、
> ここが単体テストを書き始めて、コードがコンパイルでき、*かつ*欲しい振る舞いを保持していることを確認するのに良い機会でしょう。

#### `new`でスレッド数を検査する

`new`と`execute`の引数で何もしていないので、警告が出続けます。欲しい振る舞いでこれらの関数の本体を実装しましょう。
まずはじめに、`new`を考えましょう。先刻、`size`引数に非負整数型を選択しました。負のスレッド数のプールは、
全く道理が通らないからです。しかしながら、0スレッドのプールも全く意味がわかりませんが、0も完全に合法な`usize`です。
`ThreadPool`インスタンスを返す前に`size`が0よりも大きいことを確認するコードを追加し、リスト21-13に示したように、
`assert!`マクロを使用することで0を受け取った時にプログラムをパニックさせます。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/listing-21-13/src/lib.rs:here}}
```

<span class="caption">リスト21-13: `ThreadPool::new`を実装して`size`が0ならパニックする</span>

doc commentで`ThreadPool`にドキュメンテーションを追加しました。第14章で議論したように、
関数がパニックすることもある場面を声高に叫ぶセクションを追加することで、
いいドキュメンテーションの実践に<ruby>倣<rp>(</rp><rt>なら</rt><rp>)</rp></ruby>っていることに注意してください。
試しに`cargo doc --open`を実行し、`ThreadPool`構造体をクリックして、`new`の生成されるドキュメンテーションがどんな見た目か確かめてください！

ここでしたように`assert!`マクロを追加する代わりに、リスト12-9のI/Oプロジェクトの`Config::new`のように、
`new`に`Result`を返させることもできるでしょう。しかし、今回の場合、スレッドなしでスレッドプールを作成しようとするのは、
回復不能なエラーであるべきと決定しました。野心を感じるのなら、以下のシグニチャの`new`も書いてみて、両者を比較してみてください:

```rust,ignore
pub fn new(size: usize) -> Result<ThreadPool, PoolCreationError> {
```

#### スレッドを格納するスペースを生成する

今や、プールに格納する合法なスレッド数を知る方法ができたので、`ThreadPool`構造体を返す前にスレッドを作成して格納できます。
ですが、どのようにスレッドを「格納」するのでしょうか？もう一度、`thread::spawn`シグニチャを眺めてみましょう:

```rust,ignore
pub fn spawn<F, T>(f: F) -> JoinHandle<T>
    where
        F: FnOnce() -> T + Send + 'static,
        T: Send + 'static
```

`spawn`関数は、`JoinHandle<T>`を返し、ここで`T`は、クロージャが返す型です。試しに同じように`JoinHandle`を使ってみて、
どうなるか見てみましょう。我々の場合、スレッドプールに渡すクロージャは接続を扱い、何も返さないので、
`T`はユニット型`()`になるでしょう。

リスト21-14のコードはコンパイルできますが、まだスレッドは何も生成しません。`ThreadPool`の定義を変更して、
`thread::JoinHandle<()>`インスタンスのベクタを保持し、`size`キャパシティのベクタを初期化し、
スレッドを生成する何らかのコードを実行する`for`ループを設定し、それらを含む`ThreadPool`インスタンスを返します。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,not_desired_behavior
{{#rustdoc_include ../listings/ch21-web-server/listing-21-14/src/lib.rs:here}}
```

<span class="caption">リスト21-14: `ThreadPool`にスレッドを保持するベクタを生成する</span>

ライブラリクレート内で`std::thread`をスコープに導入しました。`ThreadPool`のベクタの要素の型として、
`thread::JoinHandle`を使用しているからです。

一旦、合法なサイズを受け取ったら、`ThreadPool`は`size`個の要素を保持できる新しいベクタを生成します。
この本ではまだ、`with_capacity`関数を使用したことがありませんが、これは`Vec::new`と同じ作業をしつつ、
重要な違いがあります: ベクタに予めスペースを確保しておくのです。ベクタに`size`個の要素を格納する必要があることはわかっているので、
このメモリ確保を前もってしておくと、`Vec::new`よりも少しだけ効率的になります。`Vec::new`は、
要素が挿入されるにつれて、自身のサイズを変更します。

再び`cargo check`を実行すると、もういくつか警告が出るものの、成功するはずです。

#### `ThreadPool`からスレッドにコードを送信する責任を負う`Worker`構造体

リスト21-14の`for`ループにスレッドの生成に関するコメントを残しました。ここでは、実際にスレッドを生成する方法に目を向けます。
標準ライブラリはスレッドを生成する手段として`thread::spawn`を提供し、`thread::spawn`は、
生成されるとすぐにスレッドが実行すべき何らかのコードを得ることを予期します。ところが、我々の場合、
スレッドを生成して、後ほど送信するコードを*待機*してほしいです。標準ライブラリのスレッドの実装は、
それをするいかなる方法も含んでいません; それを手動で実装しなければなりません。

この新しい振る舞いを管理するスレッドと`ThreadPool`間に新しいデータ構造を導入することでこの振る舞いを実装します。
このデータ構造を`Worker`と呼び、プール実装では一般的な用語です。レストランのキッチンで働く人々を思い浮かべてください:
労働者は、お客さんからオーダーが来るまで待機し、それからそれらのオーダーを取り、満たすことに責任を負います。

スレッドプールに`JoinHandle<()>`インスタンスのベクタを格納する代わりに、`Worker`構造体のインスタンスを格納します。
各`Worker`が単独の`JoinHandle<()>`インスタンスを格納します。そして、`Worker`に実行するコードのクロージャを取り、
既に走っているスレッドに実行してもらうために送信するメソッドを実装します。ログを取ったり、デバッグする際にプールの異なるワーカーを区別できるように、
各ワーカーに`id`も付与します。

`ThreadPool`を生成する際に発生することに以下の変更を加えましょう。このように`Worker`をセットアップした後に、
スレッドにクロージャを送信するコードを実装します:

1. `id`と`JoinHandle<()>`を保持する`Worker`構造体を定義する。
2. `ThreadPool`を変更し、`Worker`インスタンスのベクタを保持する。
3. `id`番号を取り、`id`と空のクロージャで大量生産されるスレッドを保持する`Worker`インスタンスを返す`Worker::new`関数を定義する。
4. `ThreadPool::new`で`for`ループカウンタを使用して`id`を生成し、その`id`で新しい`Worker`を生成し、ベクタにワーカーを格納する。

挑戦に積極的ならば、リスト21-15のコードを見る前にご自身でこれらの変更を実装してみてください。

いいですか？こちらが先ほどの変更を行う1つの方法を行ったリスト21-15です。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/listing-21-15/src/lib.rs:here}}
```

<span class="caption">リスト21-15: `ThreadPool`を変更してスレッドを直接保持するのではなく、`Worker`インスタンスを保持する</span>

`ThreadPool`のフィールド名を`threads`から`workers`に変更しました。`JoinHandle<()>`インスタンスではなく、
`Worker`インスタンスを保持するようになったからです。`for`ループのカウンタを`Worker::new`への引数として使用し、
それぞれの新しい`Worker`を`workers`というベクタに格納します。

外部のコード(*src/bin/main.rs*のサーバなど)は、`ThreadPool`内で`Worker`構造体を使用していることに関する実装の詳細を知る必要はないので、
`Worker`構造体とその`new`関数は非公開にしています。`Worker::new`関数は与えた`id`を使用し、
空のクロージャを使って新しいスレッドを立ち上げることで生成される`JoinHandle<()>`インスタンスを格納します。

このコードはコンパイルでき、`ThreadPool::new`への引数として指定した数の`Worker`インスタンスを格納します。
ですが*それでも*、`execute`で得るクロージャを処理してはいません。次は、それをする方法に目を向けましょう。

#### チャネル経由でスレッドにリクエストを送信する

さて、`thread::spawn`に与えられたクロージャが全く何もしないという問題に取り組みましょう。現在、
`execute`メソッドで実行したいクロージャを得ています。ですが、`ThreadPool`の生成中、`Worker`それぞれを生成する際に、
実行するクロージャを`thread::spawn`に与える必要があります。

作ったばかりの`Worker`構造体に`ThreadPool`が保持するキューから実行するコードをフェッチして、
そのコードをスレッドが実行できるように送信してほしいです。

第16章でこのユースケースにぴったりであろう*チャネル*(2スレッド間コミュニケーションをとる単純な方法)について学びました。
チャネルをキューの仕事として機能させ、`execute`は`ThreadPool`から`Worker`インスタンスに仕事を送り、
これが仕事をスレッドに送信します。こちらが計画です:

1. `ThreadPool`はチャネルを生成し、チャネルの送信側に就く。
2. `Worker`それぞれは、チャネルの受信側に就く。
3. チャネルに送信したいクロージャを保持する新しい`Job`構造体を生成する。
4. `execute`メソッドは、実行したい仕事をチャネルの送信側に送信する。
5. スレッド内で、`Worker`はチャネルの受信側をループし、受け取ったあらゆる仕事のクロージャを実行する。

`ThreadPool::new`内でチャネルを生成し、`ThreadPool`インスタンスに送信側を保持することから始めましょう。リスト21-16のようにですね。
今の所、`Job`構造体は何も保持しませんが、チャネルに送信する種類の要素になります。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/listing-21-16/src/lib.rs:here}}
```

<span class="caption">リスト21-16: `ThreadPool`を変更して`Job`インスタンスを送信するチャネルの送信側を格納する</span>

`ThreadPool::new`内で新しいチャネルを生成し、プールに送信側を保持させています。これはコンパイルに成功しますが、
まだ警告があります。

スレッドプールがワーカーを生成する際に各ワーカーにチャネルの受信側を試しに渡してみましょう。
受信側はワーカーが大量生産するスレッド内で使用したいことがわかっているので、クロージャ内で`receiver`引数を参照します。
リスト21-17のコードはまだ完璧にはコンパイルできません。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch21-web-server/listing-21-17/src/lib.rs:here}}
```

<span class="caption">リスト21-17: チャネルの受信側をワーカーに渡す</span>

多少些細で単純な変更を行いました: チャネルの受信側を`Worker::new`に渡し、それからクロージャの内側で使用しています。

このコードのチェックを試みると、このようなエラーが出ます:

```text
$ cargo check
   Compiling hello v0.1.0 (file:///projects/hello)
error[E0382]: use of moved value: `receiver`
  --> src/lib.rs:27:42
   |
27 |             workers.push(Worker::new(id, receiver));
   |                                          ^^^^^^^^ value moved here in
   previous iteration of loop
   |
   = note: move occurs because `receiver` has type
   `std::sync::mpsc::Receiver<Job>`, which does not implement the `Copy` trait
```

このコードは、`receiver`を複数の`Worker`インスタンスに渡そうとしています。第16章を思い出すように、これは動作しません:
Rustが提供するチャネル実装は、複数の*生成者*、単独の*消費者*です。要するに、
チャネルの消費側をクローンするだけでこのコードを修正することはできません。たとえできたとしても、
使用したいテクニックではありません; 代わりに、全ワーカー間で単独の`receiver`を共有することで、
スレッド間に仕事を分配したいです。

さらに、チャネルキューから仕事を取り出すことは、`receiver`を可変化することに関連するので、
スレッドには、`receiver`を共有して変更する安全な方法が必要です; さもなくば、
競合状態に陥る可能性があります(第16章で説明しました)。

第16章で議論したスレッド安全なスマートポインタを思い出してください: 複数のスレッドで所有権を共有しつつ、
スレッドに値を可変化させるためには、`Arc<Mutex<T>>`を使用する必要があります。`Arc`型は、
複数のワーカーに受信者を所有させ、`Mutex`により、1度に受信者から1つの仕事をたった1つのワーカーが受け取ることを保証します。
リスト21-18は、行う必要のある変更を示しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/listing-21-18/src/lib.rs:here}}
```

<span class="caption">リスト21-18: `Arc`と`Mutex`を使用してワーカー間でチャネルの受信側を共有する</span>

`ThreadPool::new`で、チャネルの受信側を`Arc`と`Mutex`に置いています。新しいワーカーそれぞれに対して、
`Arc`をクローンして参照カウントを跳ね上げているので、ワーカーは受信側の所有権を共有することができます。

これらの変更でコードはコンパイルできます！ゴールはもうすぐそこです！

#### `execute`メソッドを実装する

最後に`ThreadPool`に`execute`メソッドを実装しましょう。
`Job`も構造体から`execute`が受け取るクロージャの型を保持するトレイトオブジェクトの型エイリアスに変更します。
第19章の「型エイリアスで型同義語を生成する」節で議論したように、型エイリアスにより長い型を短くできます。
リスト21-19をご覧ください。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/listing-21-19/src/lib.rs:here}}
```

<span class="caption">リスト21-19: 各クロージャを保持する`Box`に対して`Job`型エイリアスを生成し、それからチャネルに仕事を送信する</span>

`execute`で得たクロージャを使用して新しい`Job`インスタンスを生成した後、その仕事をチャネルの送信側に送信しています。
送信が失敗した時のために`send`に対して`unwrap`を呼び出しています。これは例えば、全スレッドの実行を停止させるなど、
受信側が新しいメッセージを受け取るのをやめてしまったときなどに起こる可能性があります。現時点では、
スレッドの実行を止めることはできません: スレッドは、プールが存在する限り実行し続けます。
`unwrap`を使用している理由は、失敗する場合が起こらないとわかっているからですが、コンパイラにはわかりません。

ですが、まだやり終えたわけではありませんよ！ワーカー内で`thread::spawn`に渡されているクロージャは、
それでもチャネルの受信側を*参照*しているだけです。その代わりに、クロージャには永遠にループし、
チャネルの受信側に仕事を要求し、仕事を得たらその仕事を実行してもらう必要があります。
リスト21-20に示した変更を`Worker::new`に行いましょう。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/listing-21-20/src/lib.rs:here}}
```

<span class="caption">リスト21-20: ワーカーのスレッドで仕事を受け取り、実行する</span>

ここで、まず`receiver`に対して`lock`を呼び出してミューテックスを獲得し、それから`unwrap`を呼び出して、
エラーの際にはパニックします。ロックの獲得は、ミューテックスが*毒された*状態なら失敗する可能性があり、
これは、他のどれかのスレッドがロックを保持している間に、解放するのではなく、パニックした場合に起き得ます。
この場面では、`unwrap`を呼び出してこのスレッドをパニックさせるのは、取るべき正当な行動です。
この`unwrap`をあなたにとって意味のあるエラーメッセージを伴う`expect`に変更することは、ご自由に行ってください。

ミューテックスのロックを獲得できたら、`recv`を呼び出してチャネルから`Job`を受け取ります。
最後の`unwrap`もここであらゆるエラーを超えていき、これはチャネルの送信側を保持するスレッドが閉じた場合に発生する可能性があり、
受信側が閉じた場合に`send`メソッドが`Err`を返すのと似ています。

`recv`の呼び出しはブロックするので、まだ仕事がなければ、現在のスレッドは、仕事が利用可能になるまで待機します。
`Mutex<T>`により、ただ1つの`Worker`スレッドのみが一度に仕事の要求を試みることを保証します。

これでスレッドプールが動作する状態になりました！`cargo run`を実行し、いくつかリクエストしてみましょう。

<!-- manual-regeneration
cd listings/ch21-web-server/listing-21-20
cargo run
make some requests to 127.0.0.1:7878
Can't automate because the output depends on making requests
-->

```console
$ cargo run
   Compiling hello v0.1.0 (file:///projects/hello)
warning: field `workers` is never read
 --> src/lib.rs:7:5
  |
6 | pub struct ThreadPool {
  |            ---------- field in this struct
7 |     workers: Vec<Worker>,
  |     ^^^^^^^
  |
  = note: `#[warn(dead_code)]` on by default

warning: fields `id` and `thread` are never read
  --> src/lib.rs:48:5
   |
47 | struct Worker {
   |        ------ fields in this struct
48 |     id: usize,
   |     ^^
49 |     thread: thread::JoinHandle<()>,
   |     ^^^^^^

warning: `hello` (lib) generated 2 warnings
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 4.91s
     Running `target/debug/hello`
Worker 0 got a job; executing.
Worker 2 got a job; executing.
Worker 1 got a job; executing.
Worker 3 got a job; executing.
Worker 0 got a job; executing.
Worker 2 got a job; executing.
Worker 1 got a job; executing.
Worker 3 got a job; executing.
Worker 0 got a job; executing.
Worker 2 got a job; executing.
```

成功です！接続を非同期に処理するスレッドプールができました。生成されるスレッドは常に4つ以下なので、サーバが大量のリクエストを受けてもシステムが過負荷になりません。*/sleep*へリクエストしている間も、別のスレッドがほかのリクエストを処理できます。

> 注: 複数のブラウザウィンドウで*/sleep*を同時に開くと、5秒間隔で1つずつ読み込まれることがあります。ブラウザによっては、キャッシュの都合で同じリクエストを複数回、順番に実行するためです。これはWebサーバ側の制限ではありません。

ここで少し立ち止まり、仕事にクロージャではなくFutureを使った場合、リスト21-18、21-19、21-20のコードがどう変わるか考えてみましょう。どの型が変わるでしょうか。メソッドのシグネチャは変わるでしょうか。変わらない部分はどこでしょうか。

第17章と第19章で`while let`ループを学んだので、リスト21-21のように`Worker`スレッドを書かなかった理由が気になるかもしれません。

<Listing number="21-21" file-name="src/lib.rs" caption="`while let`を使った`Worker::new`の別実装">

```rust,ignore,not_desired_behavior
{{#rustdoc_include ../listings/ch21-web-server/listing-21-21/src/lib.rs:here}}
```

</Listing>

このコードはコンパイルも実行もできますが、望んだスレッド動作にはなりません。遅いリクエストがあると、ほかのリクエストはやはり処理を待たされます。理由は少し分かりにくいものです。`Mutex`構造体には公開の`unlock`メソッドがありません。ロックの所有権は、`lock`メソッドが返す`LockResult<MutexGuard<T>>`内の`MutexGuard<T>`のライフタイムに基づくからです。これにより借用チェッカーは、ロックを保持していなければ`Mutex`に守られたリソースへアクセスできないという規則をコンパイル時に強制できます。しかし、`MutexGuard<T>`のライフタイムを意識しないと、意図したより長くロックを保持することにもなります。

リスト21-20の`let job = receiver.lock().unwrap().recv().unwrap();`が正しく動くのは、`let`文では等号の右辺で使った一時値が、その`let`文の終了時にすぐドロップされるためです。一方、`while let`（および`if let`と`match`）では、対応するブロックの終わりまで一時値がドロップされません。リスト21-21では`job()`の呼び出し中もロックが保持されるため、ほかの`Worker`は仕事を受け取れません。

[type-aliases]: ch20-03-advanced-types.html#type-synonyms-and-type-aliases
[integer-types]: ch03-02-data-types.html#integer-types
[moving-out-of-closures]: ch13-01-closures.html#moving-captured-values-out-of-closures
[builder]: https://doc.rust-lang.org/std/thread/struct.Builder.html
[builder-spawn]: https://doc.rust-lang.org/std/thread/struct.Builder.html#method.spawn
