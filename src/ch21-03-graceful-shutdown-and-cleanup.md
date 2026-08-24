## 正常なシャットダウンと片付け

リスト21-20のコードは、意図したとおりスレッドプールを使ってリクエストへ非同期に応答します。ただし、直接使っていない`workers`、`id`、`thread`フィールドについて警告が出ます。これは、何も後片付けしていないことを思い出させてくれます。洗練されているとは言いがたい<kbd>ctrl</kbd>+<kbd>C</kbd>でメインスレッドを停止すると、ほかのスレッドはリクエストの処理中であっても即座に停止します。

このコードが動いているところを確認するために、`main`を変更してサーバを正常に閉じる前に2つしかリクエストを受け付けないようにしましょう。
リスト21-25のようにします。

ここから行う変更は、クロージャの実行を担う部分には影響しません。そのため、非同期ランタイム用のスレッドプールを使う場合でも、ここで扱う内容は同じです。

### `ThreadPool`に`Drop`トレイトを実装する

スレッドプールに`Drop`を実装するところから始めましょう。プールがドロップされると、
スレッドはすべてjoinして、作業を完了したことを確認するべきです。リスト21-22は、`Drop`実装の最初の試みを示しています。
このコードはまだ完全には動きません。

<Listing number="21-22" file-name="src/lib.rs" caption="スレッドプールがスコープを抜けるときに各スレッドをjoinする">

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch21-web-server/listing-21-22/src/lib.rs:here}}
```

</Listing>

まず、スレッドプール`workers`それぞれを走査します。`self`は可変参照であり、`worker`を可変化できる必要もあるので、
これには`&mut`を使用しています。ワーカーそれぞれに対して、特定のワーカーを終了する旨のメッセージを出力し、
それから`join`をワーカースレッドに対して呼び出しています。`join`の呼び出しが失敗したら、
`unwrap`を使用してRustをパニックさせ、正常でないシャットダウンに移行します。

こちらが、このコードをコンパイルする際に出るエラーです:

```text
error[E0507]: cannot move out of borrowed content
  --> src/lib.rs:65:13
   |
65 |             worker.thread.join().unwrap();
   |             ^^^^^^ cannot move out of borrowed content
```

```console
{{#include ../listings/ch21-web-server/listing-21-22/output.txt}}
```

各`worker`の可変参照しかなく、`join`は引数の所有権を奪うためにこのエラーは`join`を呼び出せないと教えてくれています。
この問題を解決するには、`join`がスレッドを消費できるように、`thread`を所有する`Worker`インスタンスからスレッドをムーブする必要があります。
これをリスト17-15では行いました: `Worker`が代わりに`Option<thread::JoinHandle<()>>`を保持していれば、
`Option`に対して`take`メソッドを呼び出し、`Some`列挙子から値をムーブし、その場所に`None`列挙子を残すことができます。
言い換えれば、実行中の`Worker`には`thread`に`Some`列挙子があり、`Worker`を片付けたい時には、
ワーカーが実行するスレッドがないように`Some`を`None`で置き換えるのです。

しかし、この問題が生じるのは`Worker`をドロップするときだけです。そのための回避策として`Option`を使うと、`worker.thread`へアクセスするあらゆる場所で`Option<thread::JoinHandle<()>>`を扱わなければなりません。慣用的なRustコードでは`Option`を頻繁に使いますが、必ず存在すると分かっている値を回避策として`Option`で包んでいるなら、コードを簡潔で間違いにくくする別の方法がないか検討するとよいでしょう。

この場合は、`Vec::drain`メソッドというよりよい方法があります。このメソッドは、ベクタから取り除く要素を範囲引数で指定し、取り除いた要素のイテレータを返します。範囲に`..`を渡すと、ベクタから*すべて*の値を取り除きます。

そこで、`ThreadPool`の`drop`実装を次のように更新します。

<Listing file-name="src/lib.rs">

```rust
{{#rustdoc_include ../listings/ch21-web-server/no-listing-04-update-drop-definition/src/lib.rs:here}}
```

</Listing>

これでコンパイルエラーが解消され、ほかのコードを変更する必要もありません。ただし、パニック中に`drop`が呼ばれる場合もあるため、`unwrap`もパニックすると二重パニックになり、プログラムが即座にクラッシュして進行中の後片付けも終了します。サンプルプログラムでは問題ありませんが、本番コードには推奨されません。

### スレッドに仕事をリッスンするのを止めるよう通知する

ここまでの変更により、コードは警告なしでコンパイルできます。しかし残念ながら、まだ期待どおりには動きません。鍵となるのは、`Worker`インスタンスのスレッドで実行されるクロージャのロジックです。現在は`join`を呼び出しますが、スレッドは仕事を探して永遠に`loop`するため終了しません。現在の`drop`実装で`ThreadPool`をドロップすると、メインスレッドは最初のスレッドが終了するのを永遠に待ってブロックします。

この問題を解決するには、`ThreadPool`の`drop`実装と、それに続いて`Worker`のループを変更する必要があります。

最初のエラーは`Drop`実装内にあります。先ほど、`Option`値に対して`take`を呼び出し、
`thread`を`worker`からムーブする意図があることに触れました。以下の変更がそれを行います:

<Listing number="21-23" file-name="src/lib.rs" caption="`Worker`スレッドをjoinする前に`sender`を明示的にドロップする">

```rust,noplayground,not_desired_behavior
{{#rustdoc_include ../listings/ch21-web-server/listing-21-23/src/lib.rs:here}}
```

</Listing>

`sender`をドロップするとチャネルが閉じ、もうメッセージが送信されないことを示します。すると、`Worker`インスタンスが無限ループ内で行うすべての`recv`呼び出しがエラーを返します。リスト21-24では、その場合に`Worker`がループを正常に抜けるよう変更します。これにより、`ThreadPool`の`drop`実装がスレッドに対して`join`を呼ぶと、スレッドは終了します。

<Listing number="21-24" file-name="src/lib.rs" caption="`recv`がエラーを返したときに明示的にループを抜ける">

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/listing-21-24/src/lib.rs:here}}
```

</Listing>

このコードが動いているところを確認するために、`main`を変更してサーバを正常に閉じる前に2つしかリクエストを受け付けないようにしましょう。
リスト21-25のようにします。

<Listing number="21-25" file-name="src/main.rs" caption="ループを抜け、2つのリクエストを処理した後にサーバを停止する">

```rust,ignore
{{#rustdoc_include ../listings/ch21-web-server/listing-21-25/src/main.rs:here}}
```

</Listing>

現実世界のWebサーバには、たった2つリクエストを受け付けた後にシャットダウンしてほしくはないでしょう。
このコードは、単に正常なシャットダウンとクリーンアップが正しく機能することを示すだけです。

`take`メソッドは、`Iterator`トレイトで定義されていて、最大でも繰り返しを最初の2つの要素だけに制限します。
`ThreadPool`は`main`の末端でスコープを抜け、`drop`実装が実行されます。

`cargo run`でサーバを起動し、3回リクエストしてください。サーバは2回目のリクエストを処理した後に停止するため、3回目はエラーになるはずです。端末には次のような出力が表示されます。

<!-- manual-regeneration
cd listings/ch21-web-server/listing-21-25
cargo run
curl http://127.0.0.1:7878
curl http://127.0.0.1:7878
curl http://127.0.0.1:7878
third request will error because server will have shut down
copy output below
Can't automate because the output depends on making requests
-->

```console
$ cargo run
   Compiling hello v0.1.0 (file:///projects/hello)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.41s
     Running `target/debug/hello`
Worker 0 got a job; executing.
Shutting down.
Shutting down worker 0
Worker 3 got a job; executing.
Worker 1 disconnected; shutting down.
Worker 2 disconnected; shutting down.
Worker 3 disconnected; shutting down.
Worker 0 disconnected; shutting down.
Shutting down worker 1
Shutting down worker 2
Shutting down worker 3
```

表示される`Worker`のIDとメッセージの順序は異なる場合があります。この出力では、`Worker` 0と3が最初の2つのリクエストを受け取りました。サーバは2つ目の接続後に受け付けを停止し、`Worker` 3が仕事を開始するより前に`ThreadPool`の`Drop`実装が動き始めています。`sender`をドロップすると、すべての`Worker`がチャネルから切断され、停止するよう通知されます。各`Worker`は切断時にメッセージを表示し、スレッドプールは各`Worker`スレッドの終了を`join`で待ちます。

おめでとうございます！プロジェクトを完成させました; スレッドプールを使用して非同期に応答する基本的なWebサーバができました。
サーバの正常なシャットダウンを行うことができ、プールの全スレッドを片付けます。

参考までに、こちらが全コードです:

<Listing file-name="src/main.rs">

```rust,ignore
{{#rustdoc_include ../listings/ch21-web-server/no-listing-07-final-code/src/main.rs}}
```

</Listing>

<Listing file-name="src/lib.rs">

```rust,noplayground
{{#rustdoc_include ../listings/ch21-web-server/no-listing-07-final-code/src/lib.rs}}
```

</Listing>

ここでできることはまだあるでしょう！よりこのプロジェクトを改善したいのなら、こちらがアイディアの一部です:

- `ThreadPool`とその公開メソッドへ、さらにドキュメントを追加する。
- ライブラリの機能を検証するテストを追加する。
- `unwrap`の呼び出しを、より堅牢なエラー処理へ変更する。
- Webリクエストの処理以外の仕事を`ThreadPool`で実行する。
- [crates.io](https://crates.io/)でスレッドプールのクレートを探し、それを使って同様のWebサーバを実装する。そのAPIと堅牢性を、ここで実装したスレッドプールと比較する。

## まとめ

よくやりました！本の最後に到達しました！Rustのツアーに参加していただき、感謝の辞を述べたいです。
もう、ご自身のRustプロジェクトや他の方のプロジェクトのお手伝いをする準備ができています。
あなたがこれからのRustの旅で遭遇する、あらゆる困難の手助けを是非とも行いたいRustaceanたちの温かいコミュニティがあることを心に留めておいてくださいね。
