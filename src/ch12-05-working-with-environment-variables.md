

## 環境変数を取り扱う

おまけの機能を追加して`minigrep`を改善します。 環境変数でユーザーがオンにできる大文字小文字無視の検索用のオプションです。
この機能をコマンドラインオプションにして、適用したい度にユーザーが入力しなければならないようにすることもできますが、
代わりに環境変数とすることで、ユーザーは1回環境変数をセットすれば、そのターミナルセッションの間は大文字小文字無視の検索を行うことができるようにします。

### 大文字小文字を区別しない`search`関数用に失敗するテストを書く

まず、環境変数が値を持つ場合に呼び出される`search_case_insensitive`関数を新しく追加します。テスト駆動開発の過程に従い続けるので、
最初の手順は、今回も失敗するテストを書くことです。新しい`search_case_insensitive`関数用の新規テストを追加し、
古いテストを`one_result`から`case_sensitive`に名前変更して、二つのテストの差異を明確化します。
リスト12-20に示したようにですね。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-20/src/lib.rs:here}}
```

<span class="caption">リスト12-20: 追加しようとしている大文字小文字を区別しない関数用の失敗するテストを新しく追加する</span>

古いテストの`contents`も変更していることに注意してください。大文字小文字を区別する検索を行う際に、
`"duct"`というクエリに合致しないはずの大文字Dを使用した`"Duct tape"`(ガムテープ)という新しい行を追加しました。
このように古いテストを変更することで、既に実装済みの大文字小文字を区別する検索機能を誤って壊してしまわないことを保証する助けになります。
このテストはもう通り、大文字小文字を区別しない検索に取り掛かっても通り続けるはずです。

大文字小文字を区別*しない*検索の新しいテストは、クエリに`"rUsT"`を使用しています。
追加直前の`search_case_insensitive`関数では、`"rUsT"`というクエリは、
両方ともクエリとは大文字小文字が異なるのに、大文字Rの`"Rust:"`を含む行と、
`"Trust me."`という行にもマッチするはずです。これが失敗するテストであり、まだ`search_case_insensitive`関数を定義していないので、
コンパイルは失敗するでしょう。リスト12-16の`search`関数で行ったのと同様に空のベクタを常に返すような仮実装を追加し、テストがコンパイルされるものの、失敗する様をご自由に確認してください。

### `search_case_insensitive`関数を実装する

`search_case_insensitive`関数は、リスト12-21に示しましたが、`search`関数とほぼ同じです。
唯一の違いは、`query`と各`line`を小文字化していることなので、入力引数の大文字小文字によらず、
行がクエリを含んでいるか確認する際には、同じになるわけです。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-21/src/lib.rs:here}}
```

<span class="caption">リスト12-21: 比較する前にクエリと行を小文字化するよう、`search_case_insensitive`関数を定義する</span>

まず、`query`文字列を小文字化し、同じ名前の覆い隠された変数に保存します。ユーザーのクエリが`"rust"`や`"RUST"`、
`"Rust"`、`"rUsT"`などだったりしても、`"rust"`であり、大文字小文字を区別しないかのようにクエリを扱えるように、
`to_lowercase`をクエリに対して呼び出すことは必須です。
`to_lowercase`は基本的なUnicodeを処理しますが、100%正確ではありません。
現実のアプリケーションを書いているとしたら、ここでもう少し処理を入れたくなるでしょうが、
この節は環境変数についての節であってUnicodeについての節ではないので、ここではそのままにしておきましょう。

`query`はもはや、文字列スライスではなく`String`であることに注意してください。というのも、
`to_lowercase`を呼び出すと、既存のデータを参照するというよりも、新しいデータを作成するからです。
例として、クエリは`"rUsT"`だとしましょう: その文字列スライスは、小文字の`u`や`t`を使えるように含んでいないので、
`"rust"`を含む新しい`String`のメモリを確保しなければならないのです。今、`contains`メソッドに引数として`query`を渡すと、
アンド記号を追加する必要があります。`contains`のシグニチャは、文字列スライスを取るよう定義されているからです。

次に、各`line`に対して`to_lowercase`の呼び出しを追加し、全文字を小文字化しています。
今や`line`と`query`を小文字に変換したので、クエリが大文字であろうと小文字であろうとマッチを検索するでしょう。

この実装がテストを通過するか確認しましょう:

```console
{{#include ../listings/ch12-an-io-project/listing-12-21/output.txt}}
```

素晴らしい！どちらも通りました。では、`run`関数から新しい`search_case_insensitive`関数を呼び出しましょう。
1番目に大文字小文字の区別を切り替えられるよう、`Config`構造体に設定オプションを追加します。
まだどこでも、このフィールドの初期化をしていないので、追加するとコンパイルエラーが起きます。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-22/src/main.rs:here}}
```

論理値を持つ`ignore_case`フィールドを追加しました。次に、`run`関数に、
`ignore_case`フィールドの値を確認し、`search`関数か`search_case_insensitive`関数を呼ぶかを決定するのに使ってもらう必要があります。
リスト12-22のようにですね。それでも、これはまだコンパイルできません。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-22/src/main.rs:there}}
```

<span class="caption">リスト12-22: `config.ignore_case`の値に基づいて`search`か`search_case_insensitive`を呼び出す</span>

最後に、環境変数を確認する必要があります。環境変数を扱う関数は、標準ライブラリの`env`モジュールにあるので、
*src/lib.rs*の冒頭でそのモジュールをスコープ内に持ち込みます。そして、
`env`モジュールから`var`関数を使用して、`IGNORE_CASE`という環境変数に何らかの値が設定されているかチェックします。
リスト12-23のようにですね。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore,noplayground
{{#rustdoc_include ../listings/ch12-an-io-project/listing-12-23/src/main.rs:here}}
```

<span class="caption">リスト12-23: `IGNORE_CASE`という環境変数に何らかの値が設定されているかチェックする</span>

ここで、`ignore_case`という新しい変数を生成しています。その値をセットするために、
`env::var`関数を呼び出し、`IGNORE_CASE`環境変数の名前を渡しています。`env::var`関数は、
環境変数に何らかの値がセットされていたら、環境変数の値を含む`Ok`列挙子の成功値になる`Result`を返します。
環境変数がセットされていなければ、`Err`列挙子を返すでしょう。

`Result`の`is_ok`メソッドを使用して、環境変数が設定されているか、つまりプログラムが大文字小文字を区別しない検索を行うべきかどうかを、
チェックしています。`IGNORE_CASE`環境変数が何にも設定されていなければ、
`is_ok`はfalseを返し、プログラムは大文字小文字を区別する検索を実行するでしょう。環境変数の*値*はどうでもよく、
セットされているかどうかだけ気にするので、`unwrap`や`expect`あるいは、他のここまで見かけた`Result`のメソッドを使用するのではなく、
`is_ok`をチェックしています。

`ignore_case`変数の値を`Config`インスタンスに渡しているので、リスト12-22で実装したように、
`run`関数はその値を読み取り、`search_case_insensitive`か`search`を呼び出すか決定できるのです。

試行してみましょう！まず、環境変数をセットせずにクエリは`to`でプログラムを実行し、
この時はすべて小文字で"to"という言葉を含むあらゆる行が合致するはずです。

```console
{{#include ../listings/ch12-an-io-project/listing-12-23/output.txt}}
```

まだ機能しているようです！では、`IGNORE_CASE`を1にしつつ、同じクエリの`to`でプログラムを実行しましょう。

```console
$ IGNORE_CASE=1 cargo run -- to poem.txt
```

PowerShellを使用しているなら、環境変数の設定とプログラムの実行を別々のコマンドとして実行する必要があるでしょう。

```console
PS> $Env:IGNORE_CASE=1; cargo run -- to poem.txt
```

これを実行すると、`IGNORE_CASE`は以降のシェルセッションでも残り続けるでしょう。
これは`Remove-Item`コマンドレットで解除することができます。

```console
PS> Remove-Item Env:IGNORE_CASE
```

大文字も含む可能性のある"to"を含有する行が得られるはずです。

```console
Are you nobody, too?
How dreary to be somebody!
To tell your name the livelong day
To an admiring bog!
```

素晴らしい、"To"を含む行も出てきましたね！`minigrep`プログラムはこれで、
環境変数によって制御できる大文字小文字を区別しない検索も行えるようになりました。もうコマンドライン引数か、
環境変数を使ってオプションを管理する方法も知りましたね。

引数*と*環境変数で同じ設定を行うことができるプログラムもあります。そのような場合、
プログラムはどちらが優先されるか決定します。自身の別の鍛錬として、コマンドライン引数か、
環境変数で大文字小文字の区別を制御できるようにしてみてください。
片方は大文字小文字を区別するようにセットされ、もう片方は無視するようにセットしてプログラムが実行された時に、
コマンドライン引数と環境変数のどちらの優先度が高くなるかを決めてください。

`std::env`モジュールは、環境変数を扱うもっと多くの有用な機能を有しています。
ドキュメンテーションを確認して、何が利用可能か確かめてください。
