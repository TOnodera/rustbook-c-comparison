<!-- 以前の見出しです。リンク切れを防ぐため削除しないでください。 -->

<a id="streams"></a>

## Stream：順番に届くFuture

この章の前半にある[「メッセージ受け渡し」][17-02-messages]<!-- ignore -->の節で、非同期チャネルの受信側を使ったことを思い出してください。非同期の`recv`メソッドは、時間の経過とともに一連の要素を生成します。これは、*Stream*と呼ばれる、もっと一般的なパターンの一例です。多くの概念をStreamとして自然に表現できます。キュー内で順次利用可能になる要素、データ全体がコンピュータのメモリに収まらないときにファイルシステムから少しずつ読み出すデータ片、時間の経過とともにネットワークから届くデータなどです。StreamはFutureでもあるため、ほかの種類のFutureと一緒に使い、興味深い方法で組み合わせられます。たとえば、ネットワーク呼び出しが多くなりすぎないようイベントをまとめたり、長時間実行される一連の処理にタイムアウトを設定したり、不要な処理を避けるためUIイベントの流量を制限したりできます。

第13章の[「`Iterator`トレイトと`next`メソッド」][iterator-trait]<!-- ignore -->では、一連の要素を扱いました。しかし、イテレータと非同期チャネルの受信側には2つの違いがあります。1つ目は時間です。イテレータは同期的ですが、チャネルの受信側は非同期です。2つ目はAPIです。`Iterator`を直接扱うときは、同期的な`next`メソッドを呼び出します。一方、特に`trpl::Receiver`のStreamでは、代わりに非同期の`recv`メソッドを呼び出しました。それ以外の点では、これらのAPIはよく似ています。この類似は偶然ではありません。Streamは、非同期版の反復処理のようなものです。ただし、`trpl::Receiver`が特にメッセージの受信を待つのに対し、汎用的なStream APIの範囲はもっと広く、`Iterator`と同じように次の要素を提供しますが、その処理を非同期に行います。

RustではイテレータとStreamが似ているため、実際にどのイテレータからでもStreamを作れます。イテレータと同じように、Streamの`next`メソッドを呼び出し、その出力を待機することでStreamを扱えます。リスト17-21に示しますが、これはまだコンパイルできません。

<Listing number="17-21" caption="イテレータからStreamを作り、その値を表示する" file-name="src/main.rs">

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch17-async-await/listing-17-21/src/main.rs:stream}}
```

</Listing>

まず数値の配列をイテレータへ変換し、`map`を呼び出してすべての値を2倍にします。次に、`trpl::stream_from_iter`関数でイテレータをStreamへ変換します。その後、`while let`ループを使い、Streamに届いた要素を順番に処理します。

残念ながら、このコードを実行しようとするとコンパイルできず、利用できる`next`メソッドがないと報告されます。

<!-- manual-regeneration
cd listings/ch17-async-await/listing-17-21
cargo build
copy only the error output
-->

```text
error[E0599]: no method named `next` found for struct `tokio_stream::iter::Iter` in the current scope
  --> src/main.rs:10:40
   |
10 |         while let Some(value) = stream.next().await {
   |                                        ^^^^
   |
   = help: items from traits can only be used if the trait is in scope
help: the following traits which provide `next` are implemented but not in scope; perhaps you want to import one of them
   |
1  + use crate::trpl::StreamExt;
   |
1  + use futures_util::stream::stream::StreamExt;
   |
1  + use std::iter::Iterator;
   |
1  + use std::str::pattern::Searcher;
   |
help: there is a method `try_next` with a similar name
   |
10 |         while let Some(value) = stream.try_next().await {
   |                                        ~~~~~~~~
```

この出力が説明しているとおり、コンパイルエラーの原因は、`next`メソッドを使うために適切なトレイトをスコープへ導入する必要があることです。ここまでの説明から、そのトレイトは`Stream`だと思うかもしれません。しかし実際には`StreamExt`です。`Ext`は*extension*（拡張）の略で、あるトレイトを別のトレイトで拡張するときにRustコミュニティでよく使われる命名パターンです。

`Stream`トレイトは、事実上`Iterator`トレイトと`Future`トレイトを組み合わせた、低水準のインターフェイスを定義します。`StreamExt`は`Stream`の上に、より高水準なAPI群を提供します。そこには`next`メソッドのほか、`Iterator`トレイトが提供するものに似た便利なメソッドがあります。`Stream`と`StreamExt`はまだRustの標準ライブラリには含まれていませんが、エコシステムのほとんどのクレートが似た定義を使っています。

コンパイルエラーを直すには、リスト17-22のように`trpl::StreamExt`の`use`文を追加します。

<Listing number="17-22" caption="イテレータを基にしたStreamを正しく使用する" file-name="src/main.rs">

```rust
{{#rustdoc_include ../listings/ch17-async-await/listing-17-22/src/main.rs:all}}
```

</Listing>

これらをすべて組み合わせると、コードは期待どおりに動きます。さらに、`StreamExt`をスコープに導入したので、イテレータと同じように、その便利なメソッドをすべて使えます。

[17-02-messages]: ch17-02-concurrency-with-async.html#message-passing
[iterator-trait]: ch13-02-iterators.html#the-iterator-trait-and-the-next-method

> **C言語との比較**
>
> C言語では、連続して到着するデータをコールバックやイベントキューで扱うことが一般的です。Streamは「次の値が今すぐ得られるとは限らないイテレータ」と考えると理解しやすいでしょう。値の列を扱うという点はイテレータと共通ですが、待機中にスレッドを占有せず、ほかの処理へ実行を譲れる点が異なります。
