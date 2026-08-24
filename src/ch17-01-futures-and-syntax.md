## Futureと非同期構文

Rustの非同期プログラミングを支える中心的な要素は、*Future*と、Rustの`async`および`await`キーワードです。

*Future*は、今はまだ準備できていなくても、将来のある時点で準備が整う値です。同じ概念は多くの言語にあり、*タスク*や*Promise*など別の名前で呼ばれることもあります。Rustは、非同期処理ごとに異なるデータ構造を使いながら共通のインターフェイスで実装できるよう、構成要素として`Future`トレイトを提供します。Rustでは、`Future`トレイトを実装する型がFutureです。それぞれのFutureは、処理がどこまで進んだか、そして何をもって「準備完了」とするかについて、自身の情報を保持します。

ブロックや関数に`async`キーワードを付けると、中断して後から再開できることを示せます。asyncブロックや非同期関数の中では、`await`キーワードを使って*Futureを待機*、つまり準備が整うまで待てます。asyncブロックや非同期関数の中でFutureを待機するすべての場所が、そのブロックや関数を一時停止し、後で再開できる地点になります。Futureの値が利用可能になったかを確認する処理を*ポーリング*（polling）と呼びます。

C#やJavaScriptなど、非同期プログラミングに`async`と`await`キーワードを使う言語はほかにもあります。それらに馴染みがあれば、Rustの構文の扱いには大きな違いがあると気づくかもしれません。後で分かるように、その違いにはもっともな理由があります。

Rustで非同期コードを書くときは、ほとんどの場合`async`と`await`キーワードを使います。Rustは、`for`ループを`Iterator`トレイトを使った同等のコードへコンパイルするのとよく似た方法で、これらを`Future`トレイトを使った同等のコードへコンパイルします。ただしRustは`Future`トレイトを公開しているため、必要なら独自のデータ型に実装することもできます。この章で登場する関数の多くは、それぞれ独自に`Future`を実装した型を返します。章の終わりでトレイトの定義に戻り、その動作をさらに詳しく調べますが、先へ進むにはこれだけ分かれば十分です。

まだ少し抽象的に感じるでしょうから、最初の非同期プログラムとして、小さなWebスクレイパーを書きましょう。コマンドラインから2つのURLを渡し、両方を並行して取得して、先に完了したほうの結果を返します。この例には新しい構文がかなり登場しますが、心配はいりません。必要なことは進みながらすべて説明します。

## 最初の非同期プログラム

この章では、エコシステムのさまざまな要素を扱うことよりasyncの学習に集中できるよう、`trpl`クレートを用意しました。`trpl`は「The Rust Programming Language」の略です。このクレートは必要な型、トレイト、関数を、主に[`futures`][futures-crate]<!-- ignore -->クレートと[`tokio`][tokio]<!-- ignore -->クレートから再エクスポートします。`futures`クレートは、Rustで非同期コードを実験するための公式な場所であり、実際に`Future`トレイトが最初に設計された場所でもあります。Tokioは、現在のRustで、特にWebアプリケーションに最も広く使われている非同期ランタイムです。ほかにも優れたランタイムがあり、目的によってはそちらが適していることもあります。`trpl`の内部で`tokio`クレートを使うのは、十分にテストされ、広く利用されているからです。

場合によっては、この章に関係する詳細へ集中できるよう、`trpl`が元のAPIの名前を変えたりラップしたりもします。このクレートの処理を理解したい場合は、[ソースコード][crate-source]を確認してみてください。それぞれの再エクスポートがどのクレートから来たかを確認でき、クレートの動作を説明する詳しいコメントも付けてあります。

`hello-async`という新しいバイナリプロジェクトを作り、`trpl`クレートを依存関係へ追加します。

```console
$ cargo new hello-async
$ cd hello-async
$ cargo add trpl
```

これで`trpl`が提供するさまざまな部品を使い、最初の非同期プログラムを書けます。2つのWebページを取得し、それぞれから`<title>`要素を取り出して、全処理が先に終わったページのタイトルを表示する、小さなコマンドラインツールを作ります。

### `page_title`関数を定義する

まず、ページのURLを引数として受け取り、そのページへリクエストを送り、`<title>`要素のテキストを返す関数を書きます（リスト17-1）。

<Listing number="17-1" file-name="src/main.rs" caption="HTMLページからtitle要素を取得する非同期関数を定義する">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-01/src/main.rs:all}}
```

</Listing>

最初に`page_title`という関数を定義し、`async`キーワードを付けます。次に`trpl::get`関数で渡されたURLを取得し、`await`キーワードを付けてレスポンスを待機します。`response`のテキストを得るため、その`text`メソッドを呼び出し、もう一度`await`キーワードで待機します。どちらも非同期の処理です。`get`関数では、HTTPヘッダーやCookieなどを含むレスポンスの最初の部分がサーバーから返るのを待つ必要があります。この部分はレスポンス本文とは別に届くことがあります。特に本文が非常に大きければ、すべて届くまで時間がかかります。レスポンスの*全体*が届くのを待つ必要があるため、`text`メソッドも非同期です。

RustのFutureは*遅延評価*され、`await`キーワードで処理を要求するまで何もしないため、両方のFutureを明示的に待機する必要があります。実際、Futureを使わなければRustはコンパイラ警告を出します。これは、第13章の[「イテレータで一連の要素を処理する」][iterators-lazy]<!-- ignore -->で説明したイテレータを思い出させるかもしれません。イテレータは、直接、`for`ループ、または内部で`next`を使う`map`などのメソッドを通じて`next`を呼び出すまで、何もしません。同様に、Futureも明示的に処理を要求するまで何もしません。この遅延評価により、Rustは実際に必要になるまで非同期コードを実行せずに済みます。

> 注：これは、第16章の[「`spawn`で新しいスレッドを生成する」][thread-spawn]<!-- ignore -->で`thread::spawn`を使ったときとは異なります。別のスレッドへ渡したクロージャは、すぐに実行を開始しました。また、多くのほかの言語が採用する非同期処理とも異なります。しかし、イテレータの場合と同じように、Rustが性能を保証するためには重要な性質です。

`response_text`を得たら、`Html::parse`を使って`Html`型のインスタンスへ解析できます。これで単なる文字列ではなく、HTMLをより豊かなデータ構造として扱える型が得られます。特に`select_first`メソッドを使うと、指定したCSSセレクタに最初に一致する要素を検索できます。文字列`"title"`を渡すと、文書内に`<title>`要素があれば最初のものを取得できます。一致する要素がない可能性もあるため、`select_first`は`Option<ElementRef>`を返します。最後に`Option::map`メソッドを使います。このメソッドは、`Option`に要素があればその要素を処理し、なければ何もしません。ここで`match`式を使うこともできますが、`map`のほうが慣用的です。`map`へ渡す関数の本体では、`title`の`inner_html`を呼び出し、その内容を`String`として取得します。すべてを終えると、`Option<String>`が得られます。

Rustの`await`キーワードは、待機する式の前ではなく*後ろ*に置くことに注目してください。つまり*後置*キーワードです。ほかの言語で`async`を使った経験がある場合は馴染みがないかもしれませんが、Rustではメソッドチェーンをとても扱いやすくします。そのためリスト17-2のように、`page_title`の本体を変更し、`trpl::get`と`text`の呼び出しを、その間に`await`を挟んで連結できます。

<Listing number="17-2" file-name="src/main.rs" caption="`await`キーワードを挟んでメソッドを連結する">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-02/src/main.rs:chaining}}
```

</Listing>

これで最初の非同期関数を正しく書けました。`main`から呼び出すコードを追加する前に、今書いたものが何を意味するのか、もう少し詳しく説明します。

Rustは、`async`キーワードが付いた*ブロック*を見つけると、`Future`トレイトを実装する、一意な無名データ型へコンパイルします。`async`が付いた*関数*を見つけると、その本体をasyncブロックとした非同期ではない関数へコンパイルします。非同期関数の戻り値の型は、コンパイラがそのasyncブロック用に作る無名データ型です。

したがって、`async fn`を書くことは、戻り値の型に対する*Future*を返す関数を書くことと同じです。コンパイラから見ると、リスト17-1の`async fn page_title`のような関数定義は、おおよそ次の非同期ではない関数と同等です。

```rust
# extern crate trpl; // required for mdbook test
use std::future::Future;
use trpl::Html;

fn page_title(url: &str) -> impl Future<Output = Option<String>> {
    async move {
        let text = trpl::get(url).await.text().await;
        Html::parse(&text)
            .select_first("title")
            .map(|title| title.inner_html())
    }
}
```

変換後の各部分を順に見ていきましょう。

- 第10章の[「引数としてのトレイト」][impl-trait]<!-- ignore -->で扱った`impl Trait`構文を使っています。
- 戻り値は、関連型`Output`を持つ`Future`トレイトを実装します。`Output`型は`Option<String>`であり、元の`async fn`版`page_title`の戻り値の型と同じです。
- 元の関数本体で呼び出していたコードは、すべて`async move`ブロックに包まれます。ブロックは式であることを思い出してください。このブロック全体が関数から返される式です。
- このasyncブロックは、先ほど説明した`Option<String>`型の値を生成します。この値は、戻り値の型にある`Output`型と一致します。これは、これまで見てきたほかのブロックと同じです。
- 新しい関数本体が`async move`ブロックになるのは、引数`url`の使い方が理由です。`async`と`async move`の違いは、この章の後半でさらに詳しく説明します。

これで`main`から`page_title`を呼び出せます。

<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id ="determining-a-single-pages-title"></a>

### ランタイムで非同期関数を実行する

最初に、リスト17-3のように1つのページのタイトルを取得します。残念ながら、このコードはまだコンパイルできません。

<Listing number="17-3" file-name="src/main.rs" caption="利用者が渡した引数を使い、`main`から`page_title`関数を呼び出す">

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch17-async-await/listing-17-03/src/main.rs:main}}
```

</Listing>

第12章の[「コマンドライン引数を受け取る」][cli-args]<!-- ignore -->で使ったのと同じパターンで、コマンドライン引数を取得します。次にURL引数を`page_title`へ渡し、その結果を待機します。Futureが生成する値は`Option<String>`なので、ページに`<title>`があった場合となかった場合に応じて異なるメッセージを表示するため、`match`式を使います。

`await`キーワードを使えるのは非同期関数またはasyncブロックの中だけであり、Rustでは特別な`main`関数に`async`を付けられません。

<!-- manual-regeneration
cd listings/ch17-async-await/listing-17-03
cargo build
copy just the compiler error
-->

```text
error[E0752]: `main` function is not allowed to be `async`
 --> src/main.rs:6:1
  |
6 | async fn main() {
  | ^^^^^^^^^^^^^^^ `main` function is not allowed to be `async`
```

`main`に`async`を付けられない理由は、非同期コードには*ランタイム*、つまり非同期コードの実行に関する詳細を管理するRustクレートが必要だからです。プログラムの`main`関数はランタイムを*初期化*できますが、それ自身はランタイムではありません。このようになる理由は、少し後でさらに説明します。非同期コードを実行するすべてのRustプログラムには、Futureを実行するランタイムを準備する場所が少なくとも1つあります。

非同期処理をサポートする言語の多くはランタイムを同梱しますが、Rustはそうしません。代わりに、さまざまな非同期ランタイムを利用でき、それぞれが対象とする用途に適した異なるトレードオフを持ちます。たとえば、多数のCPUコアと大量のRAMを持つ高スループットなWebサーバーと、CPUコアが1つでRAMが少なく、ヒープ確保もできないマイクロコントローラとでは、必要なものが大きく異なります。ランタイムを提供するクレートは、多くの場合、ファイルI/OやネットワークI/Oなど一般的な機能の非同期版も提供します。

ここからこの章の残りでは、`trpl`クレートの`block_on`関数を使います。この関数はFutureを引数に取り、そのFutureが完了するまで現在のスレッドをブロックします。内部では、`block_on`を呼び出すと`tokio`クレートを使ってランタイムが準備され、渡したFutureの実行に使われます。`trpl`クレートの`block_on`の振る舞いは、ほかのランタイムクレートが持つ`block_on`関数と似ています。Futureが完了すると、`block_on`はFutureが生成した値を返します。

`page_title`が返すFutureを直接`block_on`へ渡し、完了したら、リスト17-3で試したように結果の`Option<String>`をパターンマッチすることもできます。しかし、この章の例のほとんどと、実際の非同期コードの大部分では、非同期関数を1つ呼ぶだけではありません。そのためリスト17-4のようにasyncブロックを渡し、その中で`page_title`呼び出しの結果を明示的に待機します。

<Listing number="17-4" caption="`trpl::block_on`でasyncブロックを待機する" file-name="src/main.rs">

<!-- mdbookのテストは引数を渡さないためshould_panic,noplayground -->

```rust,should_panic,noplayground
{{#rustdoc_include ../listings/ch17-async-await/listing-17-04/src/main.rs:run}}
```

</Listing>

このコードを実行すると、最初に期待した動作が得られます。

<!-- manual-regeneration
cd listings/ch17-async-await/listing-17-04
cargo build # ビルド時の長い出力は省略
cargo run -- "https://www.rust-lang.org"
# 出力をここへコピー
-->

```console
$ cargo run -- "https://www.rust-lang.org"
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.05s
     Running `target/debug/async_await 'https://www.rust-lang.org'`
The title for https://www.rust-lang.org was
            Rust Programming Language
```

やっと、動作する非同期コードができました。2つのサイトを競争させるコードを加える前に、Futureがどのように動くかへ少しだけ戻りましょう。

各*待機地点*、つまりコードが`await`キーワードを使うすべての場所は、制御をランタイムへ返す地点です。これを機能させるため、Rustはasyncブロックに関係する状態を記録する必要があります。そうすれば、ランタイムは別の処理を開始し、最初の処理を再び進められる準備が整ったときに戻ってこられます。これは目に見えない状態機械であり、各待機地点の現在の状態を保存するため、次のようなenumを記述したかのように働きます。

```rust
{{#rustdoc_include ../listings/ch17-async-await/no-listing-state-machine/src/lib.rs:enum}}
```

しかし、各状態間を遷移するコードを手作業で書くのは面倒で、間違いも起きやすいでしょう。後で機能や状態を追加する必要が生じれば、なおさらです。幸い、Rustコンパイラは非同期コードの状態機械に使うデータ構造を自動的に作成し、管理します。データ構造に関する通常の借用と所有権の規則はすべてそのまま適用され、コンパイラが検査して分かりやすいエラーメッセージも提供します。この章の後半で、その例をいくつか確認します。

最終的には、何かがこの状態機械を実行しなければなりません。それがランタイムです。ランタイムについて調べると*Executor*という言葉を目にすることがありますが、Executorは非同期コードの実行を担当する、ランタイムの一部分です。

これで、リスト17-3でコンパイラが`main`自身を非同期関数にすることを許さなかった理由が分かります。`main`が非同期関数なら、`main`が返すFutureの状態機械を何か別のものが管理する必要があります。しかし`main`はプログラムの開始地点です。そこで`main`内で`trpl::block_on`関数を呼び出してランタイムを準備し、asyncブロックが返すFutureを完了まで実行しました。

> 注：ランタイムの中には、非同期な`main`関数を書けるようにするマクロを提供するものもあります。そのようなマクロは`async fn main() { ... }`を通常の`fn main`へ書き換えます。書き換え後の関数は、リスト17-4で手作業したのと同じく、`trpl::block_on`のようにFutureを完了まで実行する関数を呼び出します。

それでは、これらの部品を組み合わせ、並行コードを書く方法を見ていきましょう。

<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="racing-our-two-urls-against-each-other"></a>

### 2つのURLを並行に競争させる

リスト17-5では、コマンドラインから渡された2つの異なるURLで`page_title`を呼び出し、先に終了したFutureを選ぶことで競争させます。

<Listing number="17-5" caption="2つのURLに対して`page_title`を呼び出し、どちらが先に返るか確認する" file-name="src/main.rs">

<!-- mdbookは引数を渡さないためshould_panic,noplayground -->

```rust,should_panic,noplayground
{{#rustdoc_include ../listings/ch17-async-await/listing-17-05/src/main.rs:all}}
```

</Listing>

まず、利用者が渡した各URLに対して`page_title`を呼び出します。得られたFutureを`title_fut_1`と`title_fut_2`へ保存します。Futureは遅延評価され、まだ待機していないため、この時点では何もしないことを思い出してください。次に、それらのFutureを`trpl::select`へ渡します。この関数は、渡されたFutureのどちらが先に完了したかを示す値を返します。

> 注：内部では、`trpl::select`は`futures`クレートに定義された、より汎用的な`select`関数を基に作られています。`futures`クレートの`select`関数は、`trpl::select`にはできない多くのことを行えますが、追加の複雑さもあります。今はその詳細を省略できます。

どちらのFutureが「勝って」も正しいので、`Result`を返すのは適切ではありません。代わりに`trpl::select`は、まだ見たことのない`trpl::Either`型を返します。`Either`型には2つの場合があるという点で`Result`と少し似ています。しかし`Result`と異なり、`Either`自体には成功や失敗という意味は組み込まれていません。代わりに`Left`と`Right`で「どちらか一方」を表します。

```rust
enum Either<A, B> {
    Left(A),
    Right(B),
}
```

第1引数のFutureが勝つと、`select`関数はそのFutureの出力を持つ`Left`を返します。第2引数のFutureが勝つと、*そちら*の出力を持つ`Right`を返します。これは関数呼び出しで引数が現れる順番と一致します。第1引数は第2引数の左側にあります。

さらに、`page_title`が、渡されたものと同じURLも返すように変更します。そうすれば、先に応答したページに解決可能な`<title>`がなくても、意味のあるメッセージを表示できます。この情報を利用し、どちらのURLが先に完了したかと、そのURLにあるWebページの`<title>`が何であるか、または存在しなかったかを示すよう、最後に`println!`の出力を更新します。

これで、小さいながら動作するWebスクレイパーを構築できました。2つのURLを選び、コマンドラインツールを実行してみてください。常にほかより速いサイトもあれば、実行するたびに速いサイトが変わる場合もあると分かるでしょう。さらに重要なこととして、Futureを扱う基礎を学びました。これで、asyncを使って何ができるのか、さらに深く調べられます。

[impl-trait]: ch10-02-traits.html#traits-as-parameters
[iterators-lazy]: ch13-02-iterators.html
[thread-spawn]: ch16-01-threads.html#creating-a-new-thread-with-spawn
[cli-args]: ch12-01-accepting-command-line-arguments.html

<!-- TODO: ソースへのリンクをRustのバージョンに対応させる？ -->

[crate-source]: https://github.com/rust-lang/book/tree/main/packages/trpl
[futures-crate]: https://crates.io/crates/futures
[tokio]: https://tokio.rs

> **C言語との比較**
>
> C言語では、非同期処理の途中状態を構造体や状態番号として手作業で管理することがあります。Rustの`async`は、その状態機械をコンパイラが生成します。ただし、状態の中に保持される参照や所有値には通常の借用規則が適用されます。`await`はFutureを別スレッドで自動実行する命令ではなく、ランタイムがそのFutureを進め、必要なら別の処理へ切り替えられる地点です。
