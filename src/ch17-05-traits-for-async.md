<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="digging-into-the-traits-for-async"></a>

## 非同期処理を支えるトレイトを詳しく見る

この章では、`Future`、`Stream`、`StreamExt`トレイトをさまざまな方法で使ってきました。しかし、これまではそれらがどう動き、互いにどう関係するかという詳細には踏み込みませんでした。日常的にRustを使うときは、ほとんどの場合それで問題ありません。ただし、ときには`Pin`型や`Unpin`トレイトとともに、これらのトレイトについてもう少し詳しく理解する必要がある状況に出会います。この節では、そのような場面で役立つところまで掘り下げます。*本当に*深い説明は、ほかの文書に譲ります。

<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="future"></a>

### `Future`トレイト

まず、`Future`トレイトがどのように動くかを詳しく見ましょう。Rustでは次のように定義されています。

```rust
use std::pin::Pin;
use std::task::{Context, Poll};

pub trait Future {
    type Output;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output>;
}
```

このトレイト定義には新しい型がいくつもあり、まだ見たことのない構文もあります。定義を部分ごとに確認しましょう。

第1に、`Future`の関連型`Output`は、そのFutureが最終的にどの型へ解決されるかを示します。これは`Iterator`トレイトの関連型`Item`に似ています。第2に、`Future`には`poll`メソッドがあります。`self`引数として特別な`Pin`参照を取り、`Context`型への可変参照を受け取り、`Poll<Self::Output>`を返します。`Pin`と`Context`については、すぐ後で詳しく説明します。まずはメソッドの戻り値である`Poll`型に注目しましょう。

```rust
pub enum Poll<T> {
    Ready(T),
    Pending,
}
```

`Poll`型は`Option`に似ています。値を持つ`Ready(T)`と、値を持たない`Pending`という2つの列挙子があります。しかし、`Poll`が表す意味は`Option`とは大きく異なります。`Pending`は、そのFutureにまだ行うべき処理があり、呼び出し側が後でもう一度確認する必要があることを示します。`Ready`は、Futureが処理を終え、値`T`を利用できることを示します。

> 注：`poll`を直接呼ぶ必要はほとんどありません。呼ぶ必要がある場合は、ほとんどのFutureについて、Futureが`Ready`を返した後に呼び出し側が再び`poll`を呼んではならないことを覚えておいてください。多くのFutureは、準備完了後に再度ポーリングされるとパニックします。再度ポーリングしても安全なFutureは、ドキュメントで明示されます。これは`Iterator::next`の振る舞いと似ています。

`await`を使うコードを見つけると、Rustは内部で`poll`を呼ぶコードへコンパイルします。1つのURLのページタイトルが解決された後に表示したリスト17-4を振り返ると、Rustはおおよそ、ただし完全に同じではありませんが、次のようなコードへコンパイルします。

```rust,ignore
match page_title(url).poll() {
    Ready(page_title) => match page_title {
        Some(title) => println!("The title for {url} was {title}"),
        None => println!("{url} had no title"),
    }
    Pending => {
        // But what goes here?
    }
}
```

Futureがまだ`Pending`なら、どうすればよいでしょうか。最終的に準備が整うまで、何度も繰り返し試す方法が必要です。つまり、ループが必要です。

```rust,ignore
let mut page_title_fut = page_title(url);
loop {
    match page_title_fut.poll() {
        Ready(value) => match page_title {
            Some(title) => println!("The title for {url} was {title}"),
            None => println!("{url} had no title"),
        }
        Pending => {
            // continue
        }
    }
}
```

しかし、Rustがまさにこのコードへコンパイルしたなら、すべての`await`がブロッキングになります。これは目指していたものと正反対です。代わりにRustは、このループが、Futureの処理を一時停止し、その間に別のFutureを処理して、後で再び確認できる何かへ制御を渡せるようにします。すでに見てきたように、その何かが非同期ランタイムであり、このスケジューリングと調整がランタイムの主要な仕事の1つです。

[「メッセージ受け渡しで2つのタスク間にデータを送る」][message-passing]<!-- ignore -->では、`rx.recv`を待機する処理を説明しました。`recv`呼び出しはFutureを返し、そのFutureを待機するとポーリングされます。メッセージを受け取って`Some(message)`になるか、チャネルが閉じて`None`になる準備が整うまで、ランタイムがFutureを一時停止すると説明しました。`Future`トレイト、特に`Future::poll`をより深く理解した今なら、その動作が分かります。`Poll::Pending`が返ると、ランタイムはFutureの準備が整っていないと判断します。逆に`poll`が`Poll::Ready(Some(message))`または`Poll::Ready(None)`を返すと、Futureの準備が整ったと判断して先へ進めます。

ランタイムがそれを実現する正確な詳細は、この本の範囲外です。ただしFutureの基本的な仕組みは重要です。ランタイムは管理する各Futureを*ポーリング*し、まだ準備が整っていなければ再び休止させます。

<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="pinning-and-the-pin-and-unpin-traits"></a>
<a id="the-pin-and-unpin-traits"></a>

### `Pin`型と`Unpin`トレイト

リスト17-13では、`trpl::join!`マクロを使って3つのFutureを待機しました。しかし、実行時まで個数が分からないFutureを、ベクタなどのコレクションへ格納することもよくあります。リスト17-13をリスト17-23のコードへ変更し、3つのFutureをベクタへ入れて、代わりに`trpl::join_all`関数を呼び出してみます。ただし、これはまだコンパイルできません。

<Listing number="17-23" caption="コレクション内のFutureを待機する"  file-name="src/main.rs">

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch17-async-await/listing-17-23/src/main.rs:here}}
```

</Listing>

第12章の「`run`からエラーを返す」で行ったのと同じように、各Futureを`Box`へ入れて*トレイトオブジェクト*にします。トレイトオブジェクトは第18章で詳しく説明します。トレイトオブジェクトを使うと、これらの型が生成した無名のFutureをすべて同じ型として扱えます。すべてが`Future`トレイトを実装しているからです。

これは意外に思えるかもしれません。どのasyncブロックも値を返さないため、それぞれが`Future<Output = ()>`を生成します。しかし、`Future`はトレイトであり、出力型が同じでも、コンパイラはasyncブロックごとに一意なenumを作ることを思い出してください。手書きした2つの異なる構造体を1つの`Vec`へ入れられないのと同じように、コンパイラが生成した異なるenumを混在させることはできません。

次にFutureのコレクションを`trpl::join_all`関数へ渡し、その結果を待機します。しかしコンパイルできません。エラーメッセージの該当部分を次に示します。

<!-- manual-regeneration
cd listings/ch17-async-await/listing-17-23
cargo build
copy *only* the final `error` block from the errors
-->

```text
error[E0277]: `dyn Future<Output = ()>` cannot be unpinned
  --> src/main.rs:48:33
   |
48 |         trpl::join_all(futures).await;
   |                                 ^^^^^ the trait `Unpin` is not implemented for `dyn Future<Output = ()>`
   |
   = note: consider using the `pin!` macro
           consider using `Box::pin` if you need to access the pinned value outside of the current scope
   = note: required for `Box<dyn Future<Output = ()>>` to implement `Future`
note: required by a bound in `futures_util::future::join_all::JoinAll`
  --> file:///home/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/futures-util-0.3.30/src/future/join_all.rs:29:8
   |
27 | pub struct JoinAll<F>
   |            ------- required by a bound in this struct
28 | where
29 |     F: Future,
   |        ^^^^^^ required by this bound in `JoinAll`
```

エラーメッセージの注記は、`pin!`マクロで値を*ピン留め*するべきだと伝えています。ピン留めとは、値がメモリ内で移動しないと保証する`Pin`型の内側へ値を置くことです。`dyn Future<Output = ()>`が`Unpin`トレイトを実装する必要があるのに、現在は実装していないため、ピン留めが必要だとエラーメッセージは示しています。

`trpl::join_all`関数は`JoinAll`という構造体を返します。この構造体は型`F`についてジェネリックであり、`F`は`Future`トレイトを実装するよう制約されています。Futureを`await`で直接待機すると、そのFutureは暗黙にピン留めされます。Futureを待機する場所すべてで`pin!`を使う必要がないのは、このためです。

しかし、ここではFutureを直接待機していません。代わりにFutureのコレクションを`join_all`関数へ渡し、新しいFuture `JoinAll`を構築しています。`join_all`のシグネチャは、コレクション内の要素の型すべてが`Future`トレイトを実装することを要求します。そして`Box<T>`が`Future`を実装するのは、内包する`T`が`Unpin`トレイトを実装するFutureである場合だけです。

一度に理解するには多い内容です。正しく理解するため、`Future`トレイトが実際にどのように動くか、特にピン留めについてもう少し詳しく見ましょう。`Future`トレイトの定義をもう一度確認します。

```rust
use std::pin::Pin;
use std::task::{Context, Poll};

pub trait Future {
    type Output;

    // Required method
    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output>;
}
```

`cx`引数とその`Context`型は、遅延評価を維持しながら、特定のFutureをいつ確認すべきかをランタイムが実際に知るための鍵です。ここでも、その正確な仕組みはこの章の範囲外であり、通常は独自に`Future`を実装するときだけ考えればよいものです。代わりに`self`の型へ注目します。`self`に型注釈が付いたメソッドを見るのは、これが初めてです。`self`の型注釈は、ほかの関数引数の型注釈と似ていますが、2つの重要な違いがあります。

- メソッドを呼び出すために、`self`がどの型でなければならないかをRustへ伝えます。
- 任意の型にはできません。メソッドを実装した型、その型への参照またはスマートポインタ、あるいはその型への参照を包む`Pin`に制限されます。

この構文については[第18章][ch-18]<!-- ignore -->でさらに説明します。今は、Futureが`Pending`か`Ready(Output)`かをポーリングして確認するには、その型への可変参照を`Pin`で包む必要があると分かれば十分です。

`Pin`は、`&`、`&mut`、`Box`、`Rc`などのポインタのような型を包むラッパーです。厳密には`Deref`または`DerefMut`トレイトを実装する型とともに使えますが、これは事実上、参照とスマートポインタだけを扱うことと同じです。`Pin`自体はポインタではなく、`Rc`や`Arc`の参照カウントのような独自の振る舞いも持ちません。ポインタの使い方に関する制約をコンパイラが強制するためだけの道具です。

`await`が`poll`呼び出しを基に実装されることを思い出すと、先ほどのエラーメッセージを理解し始められます。しかし、そのエラーは`Pin`ではなく`Unpin`について述べていました。`Pin`と`Unpin`は具体的にどう関係し、なぜ`Future`は`poll`を呼び出すために`self`が`Pin`型に入っていることを必要とするのでしょうか。

この章の前半で、Future内の一連の待機地点は状態機械へコンパイルされ、コンパイラが、その状態機械に借用や所有権を含むRustの通常の安全規則すべてを守らせると説明しました。そのためRustは、ある待機地点から次の待機地点、またはasyncブロックの終わりまでに必要なデータを調べます。そして、コンパイル後の状態機械に対応する列挙子を作ります。各列挙子は、その部分のソースコードで使うデータへ、所有権を得るか、可変または不変の参照を得ることで、必要な形でアクセスします。

ここまでは問題ありません。特定のasyncブロック内で所有権や参照の扱いを間違えると、借用チェッカーが教えてくれます。しかし、そのブロックに対応するFutureを、たとえば`join_all`へ渡すため`Vec`へ移動する場合には、事情が複雑になります。

Futureをデータ構造へ追加して`join_all`でイテレータとして使う場合でも、関数から返す場合でも、Futureを移動することは、Rustが作成した状態機械を移動することを意味します。そしてRustがasyncブロック用に作るFutureは、Rustのほとんどの型と異なり、図17-4の簡略図のように、特定の列挙子のフィールドが自分自身への参照を持つことがあります。

<figure>

<img alt="Future fut1を表す1列3行の表。最初の2行にデータ値0と1があり、3行目から2行目へ戻る矢印がFuture内部の参照を表している。" src="img/trpl17-04.svg" class="center" />

<figcaption>図17-4：自己参照するデータ型</figcaption>

</figure>

しかしデフォルトでは、自分自身への参照を持つオブジェクトの移動は安全ではありません。参照は常に、参照先の実際のメモリアドレスを指すためです（図17-5）。データ構造自体を移動すると、内部の参照は古い場所を指したまま残ります。しかし、そのメモリ位置はもう無効です。まず、データ構造を変更しても、その場所の値は更新されません。さらに重要なことに、コンピュータはそのメモリを別の用途に再利用できます。後でまったく無関係なデータを読み取ってしまう可能性があります。

<figure>

<img alt="Futureをfut1からfut2へ移動した結果を表す、1列3行の2つの表。fut1は灰色で、各位置には不明なメモリを表す疑問符がある。fut2の最初と2番目の行には0と1があり、3行目からfut1の2行目へ戻る矢印が、移動前のFutureの古いメモリ位置を参照するポインタを表している。" src="img/trpl17-05.svg" class="center" />

<figcaption>図17-5：自己参照するデータ型を移動した安全でない結果</figcaption>

</figure>

理論上、Rustコンパイラはオブジェクトが移動するたびに、そのオブジェクトへのすべての参照を更新しようとすることもできます。しかし、特に参照の網全体を更新する場合は、大きな性能上のオーバーヘッドになり得ます。代わりに、そのデータ構造が*メモリ内で移動しない*と保証できれば、参照を更新する必要はありません。Rustの借用チェッカーは、まさにそのためにあります。安全なコードでは、有効な参照を持つ要素を移動できないようにします。

`Pin`はその仕組みを基に、必要とする正確な保証を提供します。値へのポインタを`Pin`で包んで値を*ピン留め*すると、その値は移動できなくなります。したがって`Pin<Box<SomeType>>`がある場合、実際にピン留めするのは`Box`ポインタではなく、*`SomeType`の値*です。図17-6はこの処理を示します。

<figure>

<img alt="横に並んだ3つの箱。左からPin、b1、pinnedと書かれている。pinned内にはFutureを表すfutという1列表があり、最初のセルは0、2番目のセルから4番目の値1のセルへ矢印が出ている。3番目にはほかの部分を示す破線と省略記号がある。Pinから出た矢印はb1を通り、pinned内のfutで終わる。" src="img/trpl17-06.svg" class="center" />

<figcaption>図17-6：自己参照するFuture型を指す`Box`をピン留めする</figcaption>

</figure>

実際、`Box`ポインタ自体はその後も自由に移動できます。重要なのは、最終的に参照されるデータが同じ場所に留まることです。図17-7のように、ポインタが移動しても、*指しているデータ*が同じ場所にあれば問題はありません。独立した練習として、各型と`std::pin`モジュールのドキュメントを読み、`Box`を包む`Pin`でこれをどのように行うか考えてみてください。重要なのは、自己参照する型自体はピン留めされたままなので移動できないことです。

<figure>

<img alt="前の図とほぼ同じ4つの箱。2列目だけが変わり、b1とb2という2つの箱がある。b1は灰色で、Pinからの矢印はb1ではなくb2を通る。ポインタはb1からb2へ移動したが、pinned内のデータは移動していないことを示す。" src="img/trpl17-07.svg" class="center" />

<figcaption>図17-7：自己参照するFuture型を指す`Box`を移動する</figcaption>

</figure>

ただし、多くの型は`Pin`ポインタの背後にあっても、まったく安全に移動できます。内部参照を持つ要素についてだけ、ピン留めを考える必要があります。数値や真偽値などのプリミティブ値は内部参照を持たないことが明らかなので安全です。普段Rustで扱う型のほとんどにも内部参照はありません。たとえば`Vec`は心配せず移動できます。ここまでの知識だけを当てはめると、`Pin<Vec<String>>`がある場合、ほかに参照がなければ`Vec<String>`は常に安全に移動できるにもかかわらず、`Pin`が提供する安全だが制限の多いAPIだけを使う必要が生じます。このような場合は要素を移動して構わないとコンパイラへ伝える方法が必要です。そこで`Unpin`が登場します。

`Unpin`は、第16章で見た`Send`や`Sync`と似たマーカートレイトであり、独自の機能を持ちません。マーカートレイトは、そのトレイトを実装する型を特定の文脈で使っても安全だとコンパイラへ伝えるためだけに存在します。`Unpin`は、その型の値を安全に移動できるかどうかについて、特別な保証を維持する必要が*ない*ことをコンパイラへ伝えます。

<!--
  次のブロックのインラインcodeは、その内側にインラインemを置き、NoStarchのスタイルと合わせ、
  通常の型とは異なるものだと本文内で強調するためのもの。
-->

`Send`や`Sync`と同じように、安全だと証明できるすべての型について、コンパイラが`Unpin`を自動的に実装します。やはり`Send`や`Sync`と似た特別な場合として、型に`Unpin`が実装され*ない*場合があります。その記法は<code>impl !Unpin for <em>SomeType</em></code>です。ここで<code><em>SomeType</em></code>は、その型へのポインタを`Pin`で使うとき、安全のためにその保証を維持する*必要がある*型の名前です。

言い換えると、`Pin`と`Unpin`の関係について2つ覚えておく必要があります。第1に、`Unpin`が「通常」の場合であり、`!Unpin`が特別な場合です。第2に、型が`Unpin`と`!Unpin`のどちらを実装するかが問題になるのは、<code>Pin<&mut <em>SomeType</em>></code>のように、その型へのピン留めされたポインタを使う場合*だけ*です。

具体例として`String`を考えましょう。`String`は長さと、それを構成するUnicode文字を持ちます。図17-8のように`String`を`Pin`で包めます。しかし、Rustのほとんどの型と同じように、`String`は`Unpin`を自動的に実装します。

<figure>

<img alt="左側にPinと書かれた箱があり、右側のStringという箱へ矢印が伸びている。Stringの箱には文字列の長さを表す5usizeと、このStringインスタンスに保存されたhelloの各文字h、e、l、l、oがある。点線の長方形がStringの箱とラベルを囲むが、Pinの箱は囲まない。" src="img/trpl17-08.svg" class="center" />

<figcaption>図17-8：`String`をピン留めする。点線は`String`が`Unpin`トレイトを実装するため、実際には固定されないことを示す</figcaption>

</figure>

その結果、図17-9のように、メモリ内のまったく同じ場所で、ある文字列を別の文字列へ置き換えるなど、`String`が`!Unpin`を実装していれば不正になる操作も行えます。`String`には移動を危険にする内部参照がないため、これは`Pin`の契約に違反しません。まさにこの理由で、`String`は`!Unpin`ではなく`Unpin`を実装します。

<figure>

<img alt="前の例のhello文字列データがs1と書かれ、灰色になっている。前の例のPinの箱は、s2と書かれた別の有効なStringインスタンスを指す。s2の長さは7usizeで、goodbyeの各文字を含む。s2もUnpinを実装するため点線の長方形で囲まれている。" src="img/trpl17-09.svg" class="center" />

<figcaption>図17-9：メモリ内の`String`をまったく別の`String`へ置き換える</figcaption>

</figure>

これで、リスト17-23の`join_all`呼び出しに対して報告されたエラーを理解するのに十分な知識が揃いました。最初は、asyncブロックが生成したFutureを`Vec<Box<dyn Future<Output = ()>>>`へ移動しようとしました。しかし見てきたように、それらのFutureは内部参照を持つ可能性があるため、自動的には`Unpin`を実装しません。ピン留めすれば、Future内の基になるデータが移動しないと確信して、得られた`Pin`型を`Vec`へ渡せます。リスト17-24では、3つのFutureを定義する場所でそれぞれ`pin!`マクロを呼び出し、トレイトオブジェクトの型を調整してコードを直す方法を示します。

<Listing number="17-24" caption="Futureをベクタへ移動できるようにピン留めする">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-24/src/main.rs:here}}
```

</Listing>

この例はコンパイルして実行できるようになりました。実行時にベクタへFutureを追加したり削除したりし、それらすべてを結合できます。

`Pin`と`Unpin`が主に重要になるのは、日常的なRustコードより、低水準ライブラリやランタイム自体を構築するときです。ただし、エラーメッセージにこれらのトレイトが現れたとき、これでコードを直す方法を以前より想像できるでしょう。

> 注：`Pin`と`Unpin`の組み合わせにより、自己参照するため実装が難しくなる、複雑な型の一群をRustで安全に実装できます。現在、`Pin`を必要とする型は非同期Rustで最もよく現れますが、ときには別の文脈で目にすることもあります。
>
> `Pin`と`Unpin`がどのように動き、どの規則を守る必要があるかは、`std::pin`のAPIドキュメントで詳しく説明されています。さらに学びたければ、そこから始めるとよいでしょう。
>
> 内部の仕組みをさらに詳しく理解したい場合は、[_Asynchronous Programming in Rust_][async-book]の第[2章][under-the-hood]<!-- ignore -->と第[4章][pinning]<!-- ignore -->を参照してください。

### `Stream`トレイト

`Future`、`Pin`、`Unpin`トレイトを深く理解したので、次は`Stream`トレイトへ注目しましょう。この章の前半で学んだとおり、Streamは非同期のイテレータに似ています。ただし、本書執筆時点では`Iterator`や`Future`と異なり、`Stream`は標準ライブラリに定義されていません。一方、エコシステム全体で使われている、`futures`クレートの非常に一般的な定義があります。

`Stream`トレイトが両者をどのように組み合わせるかを見る前に、`Iterator`と`Future`トレイトの定義を振り返りましょう。`Iterator`からは、列という考え方を得ます。その`next`メソッドは`Option<Self::Item>`を提供します。`Future`からは、時間の経過に伴う準備状態という考え方を得ます。その`poll`メソッドは`Poll<Self::Output>`を提供します。時間の経過とともに準備が整う一連の要素を表すため、これらの機能を組み合わせた`Stream`トレイトを定義します。

```rust
use std::pin::Pin;
use std::task::{Context, Poll};

trait Stream {
    type Item;

    fn poll_next(
        self: Pin<&mut Self>,
        cx: &mut Context<'_>
    ) -> Poll<Option<Self::Item>>;
}
```

`Stream`トレイトは、Streamが生成する要素の型を表す`Item`という関連型を定義します。要素が0個から多数まで存在し得る点で`Iterator`と似ており、ユニット型`()`の場合も含め、必ず1つの`Output`がある`Future`とは異なります。

`Stream`は、要素を取得するメソッドも定義します。`Future::poll`と同じ方法でポーリングし、`Iterator::next`と同じ方法で一連の要素を生成することが分かるよう、`poll_next`と呼びます。戻り値の型は`Poll`と`Option`を組み合わせています。Futureと同じように準備状態を確認する必要があるため、外側の型は`Poll`です。イテレータと同じように、さらにメッセージがあるかどうかを示す必要があるため、内側の型は`Option`です。

この定義によく似たものが、将来Rustの標準ライブラリに加わる可能性があります。それまでも、ほとんどのランタイムの道具一式に含まれているため、利用できます。ここから説明する内容も、通常はそのまま当てはまります。

しかし[「Stream：順番に届くFuture」][streams]<!-- ignore -->の例では、`poll_next`も`Stream`も使わず、代わりに`next`と`StreamExt`を使いました。もちろん、独自の`Stream`状態機械を手書きし、`poll_next` APIを直接使うこともできます。Futureを`poll`メソッドで直接扱うことが*可能*なのと同じです。しかし`await`を使うほうがずっと簡単であり、`StreamExt`トレイトは、それを可能にする`next`メソッドを提供します。

```rust
{{#rustdoc_include ../listings/ch17-async-await/no-listing-stream-ext/src/lib.rs:here}}
```

<!--
TODO: tokioなどがMSRVを更新し、トレイト内の非同期関数を使うようになった場合は更新する。
現時点でこの形ではない理由は、トレイト内の非同期関数を使えなかったバージョンをサポートするため。
-->

> 注：この章の前半で使った実際の定義は、トレイト内で非同期関数をまだサポートしていなかったRustのバージョンにも対応するため、これとは少し異なります。その結果、次のような形になっています。
>
> ```rust,ignore
> fn next(&mut self) -> Next<'_, Self> where Self: Unpin;
> ```
>
> この`Next`型は`Future`を実装する`struct`です。`Next<'_, Self>`を使って`self`への参照のライフタイムへ名前を付けられるため、このメソッドに`await`を使えます。

`StreamExt`トレイトには、Streamで利用できる便利なメソッドもすべて置かれています。`Stream`を実装するすべての型に`StreamExt`が自動的に実装されますが、基礎となるトレイトへ影響を与えず、便利なAPIをコミュニティが改善し続けられるよう、これらのトレイトは分けて定義されています。

`trpl`クレートが使う版の`StreamExt`トレイトは、`next`メソッドを定義するだけでなく、`Stream::poll_next`を呼ぶ詳細を正しく処理する`next`のデフォルト実装も提供します。つまり、独自のストリーミングデータ型を書く必要がある場合でも、実装する必要があるのは`Stream`*だけ*です。そのデータ型の利用者は、自動的に`StreamExt`とそのメソッドを使えます。

これらのトレイトの低水準な詳細について、この本で扱うのはここまでです。最後に、Streamを含むFuture、タスク、スレッドが、どのように組み合わさるのかを考えましょう。

[message-passing]: ch17-02-concurrency-with-async.md#sending-data-between-two-tasks-using-message-passing
[ch-18]: ch18-00-oop.html
[async-book]: https://rust-lang.github.io/async-book/
[under-the-hood]: https://rust-lang.github.io/async-book/02_execution/01_chapter.html
[pinning]: https://rust-lang.github.io/async-book/04_pinning/01_chapter.html
[first-async]: ch17-01-futures-and-syntax.html#our-first-async-program
[any-number-futures]: ch17-03-more-futures.html#working-with-any-number-of-futures
[streams]: ch17-04-streams.html

> **C言語との比較**
>
> C言語で自己参照構造体を移動すると、内部ポインタが古いアドレスを指し続ける危険があります。Rustの`Pin`は、同じ問題に対し「値そのものを移動できない」という契約を型で表します。`Unpin`は、移動しても安全な通常の型についてその制限を外す印です。日常的なasyncコードでは`await`が暗黙に扱いますが、異なるFutureをコレクションへ格納するときなどに、この違いが型エラーとして現れます。
