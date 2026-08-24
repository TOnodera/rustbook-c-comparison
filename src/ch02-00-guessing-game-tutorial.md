# 数当てゲームのプログラミング

> **C言語との比較**
>
> この章で使う`Result`や`match`は、入力失敗などのケースを型として明示的に扱います。C言語では、`scanf`などの戻り値や`errno`を確認する形が一般的ですが、確認を忘れてもコンパイラは通常警告できません。Rustでは処理結果が`Result`として返るため、成功と失敗の両方を意識したコードを書きやすくなっています。

ハンズオン形式のプロジェクトに一緒に取り組むことで、Rustの世界に飛び込んでみましょう！&nbsp;
この章ではRustの一般的な概念を、実際のプログラムでの使い方を示しながら紹介します。
`let`、`match`、メソッド、関連関数、外部クレートなどについて学びます！&nbsp;
これらについての詳細は後続の章で取り上げますので、この章では基本的なところだけを練習します。

プログラミング初心者向けの定番問題である「数当てゲーム」を実装してみましょう。
これは次のように動作します。
プログラムは1から100までのランダムな整数を生成します。
そして、プレーヤーに予想（した数字）を入力するように促します。
予想が入力されると、プログラムはその予想が小さすぎるか大きすぎるかを表示します。
予想が当たっているなら、お祝いのメッセージを表示し、ゲームを終了します。

## 新規プロジェクトの立ち上げ

新しいプロジェクトを立ち上げましょう。
第1章で作成した*projects*ディレクトリに移動し、以下のようにCargoを使って新規プロジェクトを作成します。

```console
$ cargo new guessing_game
$ cd guessing_game
```

最初のコマンド`cargo new`は、第1引数としてプロジェクト名 (`guessing_game`) を取ります。
2番目のコマンドは新規プロジェクトのディレクトリに移動します。

生成された*Cargo.toml*ファイルを見てみましょう。

<span class="filename">ファイル名：Cargo.toml</span>

```toml
{{#include ../listings/ch02-guessing-game-tutorial/no-listing-01-cargo-new/Cargo.toml}}
```

第1章で見たように`cargo new`は「Hello, world!」プログラムを生成してくれます。
*src/main.rs*ファイルをチェックしてみましょう。

<span class="filename">ファイル名：src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/no-listing-01-cargo-new/src/main.rs}}
```

さて、`cargo run`コマンドを使って、この「Hello, world!」プログラムのコンパイルと実行を一気に行いましょう。

```console
{{#include ../listings/ch02-guessing-game-tutorial/no-listing-01-cargo-new/output.txt}}
```

このゲーム（の開発）では各イテレーションを素早くテストしてから、次のイテレーションに移ります。
`run`コマンドは、今回のようにプロジェクトのイテレーションを素早く回したいときに便利です。

> アジャイル開発ではイテレーションを数週間の短いスパンで一通り回し、それを繰り返すことで開発を進めていきます。
> 
> この章では「実装」→「テスト」のごく短いサイクルを繰り返すことで、プログラムに少しずつ機能を追加していきます。

*src/main.rs*ファイルを開き直しましょう。
このファイルにすべてのコードを書いていきます。

## 予想を処理する

数当てゲームプログラムの最初の部分は、ユーザに入力を求め、その入力を処理し、期待した形式になっていることを確認することです。
手始めに、プレーヤーが予想を入力できるようにしましょう。
リスト2-1のコードを*src/main.rs*に入力してください。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:all}}
```

<span class="caption">リスト2-1：ユーザに予想を入力してもらい、それを出力するコード</span>

このコードには多くの情報が詰め込まれています。
行ごとに見ていきましょう。
ユーザ入力を受け付け、結果を出力するためには`io`（入出力）ライブラリをスコープに入れる必要があります。
`io`ライブラリは、`std`と呼ばれる標準ライブラリに含まれています。

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:io}}
```

Rustはデフォルトで、標準ライブラリで定義されているアイテムの中のいくつかを、すべてのプログラムのスコープに取り込みます。
このセットは*prelude*（プレリュード）と呼ばれ、[標準ライブラリのドキュメント][prelude]でその中のすべてを見ることができます。

使いたい型がpreludeにない場合は、その型を`use`文で明示的にスコープに入れる必要があります。
`std::io`ライブラリを`use`すると、ユーザ入力を受け付ける機能など（入出力に関する）多くの便利な機能が利用できるようになります。

第1章で見た通り、`main`関数がプログラムの実行を開始するエントリーポイントになります。

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:main}}
```

`fn`構文は関数を新しく宣言し、かっこの`()`は引数がないことを示し、波括弧の`{`は関数の本体を開始します。

また、第1章で学んだように、`println!`は画面に文字列を表示するマクロです.


```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:print}}
```

このコードはゲームの内容などを示すプロンプトを表示し、ユーザに入力を求めています。

### 値を変数に保持する

次に、ユーザの入力を格納するための*変数*を作りましょう。
こんな感じです。

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:string}}
```

プログラムが少し興味深いものになってきました。
この小さな行の中でいろいろなことが起きています。
`let`文を使って変数を作っています。
別の例も見てみましょう。

```rust,ignore
let apples = 5;
```

この行では`apples`という名前の新しい変数を作成し`5`という値に束縛しています。
Rustでは変数はデフォルトで不変（immutable）で、これは一度変数に値を与えたらその値は変わらないという意味です。
この概念については第3章の[「変数と可変性」][variables-and-mutability]の節で詳しく説明します。
変数を可変（mutable）にするには、変数名の前に`mut`をつけます。

```rust,ignore
let apples = 5; // immutable
                // 不変
let mut bananas = 5; // mutable
                     // 可変
```

> 注：`//`構文は行末まで続くコメントを開始し、Rustはコメント内のすべて無視します。
> コメントについては[第3章][comments]で詳しく説明します。

数当てゲームのプログラムに戻りましょう。
ここまでの話で`let mut guess`が`guess`という名前の可変変数を導入することがわかったと思います。
等号記号（`=`）はRustに、いまこの変数を何かに束縛したいことを伝えます。
等号記号の右側には`guess`が束縛される値があります。
これは`String::new`関数を呼び出すことで得られた値で、この関数は`String`型の新しいインスタンスを返します。
[`String`][string]は標準ライブラリによって提供される文字列型で、サイズが拡張可能な、UTF-8でエンコードされたテキスト片になります。

`::new`の行にある`::`構文は`new`が`String`型の関連関数であることを示しています。
*関連関数*とは、ある型（ここでは`String`）に対して実装される関数のことです。
この`new`関数は新しい空の文字列を作成します。
`new`関数は多くの型に見られます。
なぜなら、何らかの新しい値を作成する関数によくある名前だからです。

つまり`let mut guess = String::new();`という行は可変変数を作成し、その変数は現時点では新しい空の`String`のインスタンスに束縛されているわけです。
ふう！


### ユーザの入力を受け取る

プログラムの最初の行に`use std::io`と書いて、標準ライブラリの入出力機能を取り込んだことを思い出してください。
ここで`io`モジュールの`stdin`関数を呼び出して、ユーザ入力を処理できるようにしましょう。

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:read}}
```

もし、プログラムの最初に`use std::io;`と書いて`io`ライブラリをインポートしていなかったとしても、`std::io::stdin`のように呼び出せば、この関数を利用できます。
`stdin`関数はターミナルの標準入力へのハンドルを表す型である[`std::io::Stdin`][iostdin]のインスタンスを返します。

次の`.read_line(&mut guess)`行は、標準入力ハンドルの[`read_line`][read_line]メソッドを呼び出し、ユーザからの入力を得ています。
また、`read_line`の引数として`&mut guess`を渡し、ユーザ入力をどの文字列に格納するかを指示しています。
`read_line`メソッドの仕事は、ユーザが標準入力に入力したものを文字列に（いまの内容を上書きせずに）追加することですので、文字列を引数として渡しているわけです。
引数の文字列は、その内容をメソッドが変更できるように、可変である必要があります。

この`&`は、この引数が*参照*であることを示し、これによりコードの複数の部分が同じデータにアクセスしても、そのデータを何度もメモリにコピーしなくて済みます。
参照は複雑な機能ですが、Rustの大きな利点の一つは参照を安全かつ簡単に使用できることです。
このプログラムを完成させるのに、そのような詳細を知る必要はないでしょう。
とりあえず知っておいてほしいのは、変数のように参照もデフォルトで不変であることです。
したがって、`&guess`ではなく`&mut guess`と書いて可変にする必要があります。
（参照については第4章でより詳しく説明します）

### `Result`で失敗の可能性を扱う

まだ、このコードの行は終わってません。
これから説明するのはテキスト上は3行目になりますが、まだ一つの論理的な行の一部分に過ぎません。
次の部分はこのメソッドです。

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:expect}}
```

このコードは、こう書くこともできました。

```rust,ignore
io::stdin().read_line(&mut guess).expect("Failed to read line");
```

しかし、長い行は読みづらいので分割したほうがよいでしょう。
`.method_name()`構文でメソッドを呼び出すとき、長い行を改行と空白で分割するのが賢明なことがよくあります。
それでは、この行（`expect()`メソッド）が何をするのか説明します。

前述したように、`read_line`メソッドは渡された文字列にユーザが入力したものを入れますが、同時に`Result`値も返します。
[`Result`][result]は[*列挙型*][enums]、または*enum*ともよく呼ばれるもののひとつです。
列挙型は、複数の取りうる状態の中からどれか一つになることができる型です。
私たちはこのそれぞれの取りうる状態のことを*列挙子* (variant) と呼びます。

enumについては[第6章][enums]で詳しく説明します。
これらの`Result`型の目的は、エラー処理に関わる情報を符号化（エンコード）することです。

`Result`の列挙子は`Ok`か`Err`です。
`Ok`列挙子は処理が成功したことを示し、`Ok`の中には正常に生成された値が入っています。
`Err`列挙子は処理が失敗したことを意味し、`Err`には処理が失敗した過程や理由についての情報が含まれています。

`Result`型の値にも、他の型と同様にメソッドが定義されています。
`Result`のインスタンスには[`expect`メソッド][expect]がありますので、これを呼び出せます。
この`Result`インスタンスが`Err`の値の場合、`expect`メソッドはプログラムをクラッシュさせ、引数として渡されたメッセージを表示します。
`read_line`メソッドが`Err`を返したら、それはおそらく基礎となるオペレーティング・システムに起因するものでしょう。
もしこの`Result`オブジェクトが`Ok`値の場合、`expect`メソッドは`Ok`列挙子が保持する戻り値を取り出して、その値だけを返してくれます。
こうして私たちはその値を使うことができるわけです。
今回の場合、その値はユーザ入力のバイト数になります。

もし`expect`メソッドを呼び出さなかったら、コンパイルはできるものの警告が出るでしょう。

```console
{{#include ../listings/ch02-guessing-game-tutorial/no-listing-02-without-expect/output.txt}}
```

Rustは私たちが`read_line`から返された`Result`値を使用していないことを警告し、これはプログラムがエラーの可能性に対処していないことを示します。

警告を抑制する正しい方法は実際にエラー処理コードを書くことです。
しかし、現時点では問題が起きたときにこのプログラムをクラッシュさせたいだけなので、`expect`が使えるわけです。
エラーからの回復については第9章で学びます。

### `println!`マクロのプレースホルダーで値を表示する

閉じ波かっこを除けば、ここまでのコードで説明するのは残り1行だけです。

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-01/src/main.rs:print_guess}}
```

この行はユーザの入力を現在保持している文字列を表示します。
一組の波括弧の`{}`はプレースホルダーです。
`{}`は値を所定の場所に保持する小さなカニのはさみだと考えてください。
変数の値を表示するときは、変数名を波括弧の中に入れればよいです。
式の評価結果を表示するときは、フォーマット文字列の中に空の波括弧を置き、それぞれの空の波括弧プレースホルダに表示する式を同じ順で、カンマ区切りリストにして続けてください。
一回の`println!`の呼び出しで変数と式の結果を表示するなら次のようになります。

```rust
let x = 5;
let y = 10;

println!("x = {x} and y + 2 = {}", y + 2);
```

このコードは`x = 5 and y + 2 = 12`と表示するでしょう。

### 最初の部分をテストする

数当てゲームの最初の部分をテストしてみましょう。
`cargo run`で走らせてください。

```console
$ cargo run
   Compiling guessing_game v0.1.0 (file:///projects/guessing_game)
    Finished dev [unoptimized + debuginfo] target(s) in 6.44s
     Running `target/debug/guessing_game`
Guess the number!
Please input your guess.
6
You guessed: 6
```

これで、キーボードからの入力を得て、それを表示するという、ゲームの最初の部分は完成になります。

## 秘密の数字を生成する

次にユーザが数当てに挑戦する秘密の数字を生成する必要があります。
この数字を毎回変えることで何度やっても楽しいゲームになります。
ゲームが難しくなりすぎないように1から100までの乱数を使用しましょう。
Rustの標準ライブラリには、まだ乱数の機能は含まれていません。
ですが、Rustの開発チームがこの機能を持つ[`rand`クレート][randcrate]を提供してくれています。

### クレートを使用して機能を追加する

クレートはRustソースコードを集めたものであることを思い出してください。
私たちがここまで作ってきたプロジェクトは*バイナリクレート*であり、これは実行可能ファイルになります。
`rand`クレートは*ライブラリクレート*です。
他のプログラムで使用するためのコードが含まれており、単独で実行することはできません。

Cargoがその力を発揮するのは外部クレートと連携するときです。
`rand`を使ったコードを書く前に、*Cargo.toml*ファイルを編集して`rand`クレートを依存関係に含める必要があります。
そのファイルを開いて、Cargoが作ってくれた`[dependencies]`セクションヘッダの下に次の行を追加してください。
バージョンナンバーを含め、ここに書かれている通り正確に`rand`を指定してください。
そうしないと、このチュートリアルのコード例が動作しないかもしれません:

<span class="filename">ファイル名：Cargo.toml</span>

```toml
{{#include ../listings/ch02-guessing-game-tutorial/listing-02-02/Cargo.toml:8:}}
```

*Cargo.toml*ファイルでは、ヘッダに続くものはすべて、他のセクションが始まるまで続くセクションの一部になります。
`[dependencies]`はプロジェクトが依存する外部クレートと必要とするバージョンをCargoに伝えます。
今回は`rand`クレートを`0.10.1`というセマンティックバージョン指定子で指定します。
Cargoは[セマンティックバージョニング][semver]（*SemVer*と呼ばれることもあります）を理解しており、これはバージョンナンバーを記述するための標準です。
`0.10.1`という指定子は実際には`^0.10.1`の省略記法で、0.10.1以上0.11.0未満の任意のバージョンを意味します。

Cargoはこれらのバージョンを、バージョン0.10.1と互換性のある公開APIを持つものとみなします。
この仕様により、この章のコードが引き続きコンパイルできるようにしつつ、最新のパッチリリースを取得できるようになります。
0.11.0以降のバージョンは、以下の例で使用しているものと同じAPIを持つことを保証しません。

さて、コードを一切変えずに、次のリスト2-2のようにプロジェクトをビルドしてみましょう。

```console
$ cargo build
    Updating crates.io index
     Locking 8 packages to latest Rust 1.96.0 compatible versions
  Downloaded rand_core v0.10.1
  Downloaded chacha20 v0.10.1
  Downloaded rand v0.10.1
  Downloaded 3 crates (162.9KiB) in 0.59s
   Compiling libc v0.2.186
   Compiling rand_core v0.10.1
   Compiling getrandom v0.4.3
   Compiling cfg-if v1.0.4
   Compiling chacha20 v0.10.1
   Compiling rand v0.10.1
   Compiling guessing_game v0.1.0 (file:///projects/guessing_game)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 2.03s
```

<span class="caption">リスト2-2：randクレートを依存として追加した後の`cargo build`コマンドの出力</span>

もしかしたら異なるバージョンナンバー（とはいえ、SemVerのおかげですべてのコードに互換性があります）や、
異なる行（オペレーティングシステムに依存します）が表示されるかもしれません。
また、行の順序も違うかもしれません。

外部依存を持つようになると、Cargoはその依存関係が必要とするすべてについて最新のバージョンを*レジストリ*から取得します。
レジストリとは[Crates.io][cratesio]のデータのコピーです。
Crates.ioは、Rustのエコシステムにいる人たちがオープンソースのRustプロジェクトを投稿し、他の人が使えるようにする場所です。

レジストリの更新後、Cargoは`[dependencies]`セクションにリストアップされているクレートをチェックし、まだ取得していないものがあればダウンロードします。
ここでは依存関係として`rand`だけを書きましたが、`rand`が動作するために依存している他のクレートも取り込まれています。
クレートをダウンロードしたあと、Rustはそれらをコンパイルし、依存関係が利用できる状態でプロジェクトをコンパイルします。

何も変更せずにすぐに`cargo build`コマンドを再度実行すると、`Finished`の行以外は何も出力されないでしょう。
Cargoはすでに依存関係をダウンロードしてコンパイル済みであることを認識しており、また、あなたが*Cargo.toml*ファイルを変更していないことも知っているからです。
さらに、Cargoはあなたがコードを何も変更していないことも知っているので、再コンパイルもしません。
何もすることがないので単に終了します。

*src/main.rs*ファイルを開いて些細な変更を加え、それを保存して再度ビルドすると2行しか表示されません。

```console
$ cargo build
   Compiling guessing_game v0.1.0 (file:///projects/guessing_game)
    Finished dev [unoptimized + debuginfo] target(s) in 2.53 secs
```

これらの行はCargoが*src/main.rs*ファイルへの小さな変更に対して、ビルドを更新していることを示しています。
依存関係は変わっていないので、Cargoは既にダウンロードしてコンパイルしたものが再利用できることを知っています。

#### *Cargo.lock*ファイルで再現可能なビルドを確保する

Cargoはあなたや他の人があなたのコードをビルドするたびに、同じ生成物をリビルドできるようにするしくみを備えています。
Cargoは何も指示されない限り、指定したバージョンの依存のみを使用します。
たとえば来週`rand`クレートのバージョン0.10.2が出て、そのバージョンには重要なバグ修正が含まれていますが、同時にあなたのコードを破壊するリグレッションも含まれているとします。
これに対応するため、Rustは`cargo build`を最初に実行したときに*Cargo.lock*ファイルを作成します。
（いまの*guessing_game*ディレクトリにもあるはずです）

プロジェクトを初めてビルドするとき、Cargoは条件に合うすべての依存関係のバージョンを計算し*Cargo.lock*ファイルに書き込みます。
次にプロジェクトをビルドすると、Cargoは*Cargo.lock*ファイルが存在することを確認し、バージョンを把握するすべての作業を再び行う代わりに、そこで指定されているバージョンを使うでしょう。
これにより再現性のあるビルドを自動的に行えます。
言い換えれば、*Cargo.lock*ファイルのおかげで、あなたが明示的にアップグレードするまで、プロジェクトは0.10.1を使い続けます。
*Cargo.lock*ファイルは再現性のあるビルドのために重要なので、プロジェクトの残りのコードとともにソース管理にチェックインされることが多いです。

#### クレートを更新して新バージョンを取得する

クレートを*本当に*アップグレードしたくなったときのために、Cargoは`update`コマンドを提供します。
このコマンドは*Cargo.lock*ファイルを無視して、*Cargo.toml*ファイル内の全ての指定に適合する最新バージョンを算出します。
成功したらCargoはそれらのバージョンを*Cargo.lock*ファイルに記録します。
ただし、デフォルトでCargoは0.10.1より大きく、0.11.0未満のバージョンのみを検索します。
もし`rand`クレートの新しいバージョンとして0.10.2と0.999.0の二つがリリースされていたなら、`cargo update`を実行したときに以下のようなメッセージが表示されるでしょう。

```console
$ cargo update
    Updating crates.io index
     Locking 1 package to latest Rust 1.96.0 compatible version
    Updating rand v0.10.1 -> v0.10.2 (available: v0.999.0)
```

Cargoは0.999.0リリースを無視します。
またそのとき、*Cargo.lock*ファイルが変更され、`rand`クレートの現在使用中のバージョンが0.10.2になったことにも気づくでしょう。
そうではなく、`rand`のバージョン0.999.0か、0.999.*x*系のどれかを使用するには、*Cargo.toml*ファイルを以下のように変更する必要があります。

```toml
[dependencies]
rand = "0.999.0"
```

次に`cargo build`コマンドを実行したとき、Cargoは利用可能なクレートのレジストリを更新し、あなたが指定した新しいバージョンに従って`rand`の要件を再評価します。

[Cargo][doccargo]と[そのエコシステム][doccratesio]については、まだ伝えたいことが山ほどありますが、それらについては第14章で説明します。
いまのところは、これだけ知っていれば十分です。
Cargoはライブラリの再利用をとても簡単にしてくれるので、Rustaceanが数多くのパッケージから構成された小さなプロジェクトを書くことが可能になっています。

### 乱数を生成する

`rand`クレートを使って予想する数字を生成しましょう。
次のステップは*src/main.rs*ファイルをリスト2-3のように更新することです。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-03/src/main.rs:all}}
```

<span class="caption">リスト2-3：乱数を生成するコードの追加</span>

まず`use rand::Rng;`という行を追加します。
`Rng`トレイトは乱数生成器が実装すべきメソッドを定義しており、それらのメソッドを使用するには、このトレイトがスコープ内になければなりません。
トレイトについて詳しくは第10章で解説します。

次に、途中に2行を追加しています。
最初の行では`rand::thread_rng`関数を呼び出して、これから使う、ある特定の乱数生成器を取得しています。
なお、この乱数生成器は現在のスレッドに固有で、オペレーティングシステムからシード値を得ています。
そして、この乱数生成器の`gen_range`メソッドを呼び出しています。
このメソッドは`use rand::Rng;`文でスコープに導入した`Rng`トレイトで定義されています。
`gen_range`メソッドは範囲式を引数にとり、その範囲内の乱数を生成してくれます。
ここで使っている範囲式の種類は`開始..=終了`という形式で、下限値と上限値をともに含みます。
そのため、1から100までの数をリクエストするには`1..101`と指定する必要があります。

> 注：クレートのどのトレイトを`use`するかや、どのメソッドや関数を呼び出すかを知るために、各クレートにはその使い方を説明したドキュメントが用意されています。
> Cargoのもう一つの素晴らしい機能は、`cargo doc --open`コマンドを走らせると、すべての依存クレートが提供するドキュメントをローカルでビルドして、ブラウザで開いてくれることです。
> たとえば`rand`クレートの他の機能に興味があるなら、`cargo doc --open`コマンドを実行して、左側のサイドバーにある`rand`をクリックしてください。

コードに追加した2行目は秘密の数字を表示します。
これはプログラムを開発している間のテストに便利ですが、最終版からは削除する予定です。
プログラムが始まってすぐに答えが表示されたらゲームになりませんからね！

試しにプログラムを何回か走らせてみてください。

```console
$ cargo run
   Compiling guessing_game v0.1.0 (file:///projects/guessing_game)
    Finished dev [unoptimized + debuginfo] target(s) in 2.53s
     Running `target/debug/guessing_game`
Guess the number!
The secret number is: 7
Please input your guess.
4
You guessed: 4

$ cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.02s
     Running `target/debug/guessing_game`
Guess the number!
The secret number is: 83
Please input your guess.
5
You guessed: 5
```

毎回異なる乱数を取得し、それらはすべて1から100の範囲内の数字になるはずです。
よくやりました！

## 予想と秘密の数字を比較する

さて、ユーザ入力と乱数が揃ったので両者を比較してみましょう。
このステップをリスト2-4に示します。
これから説明するように、このコードはまだコンパイルできないことに注意してください。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-04/src/main.rs:here}}
```

<span class="caption">リスト2-4：二つの数値を比較したときに返される可能性のある値を処理する</span>

まず`use`文を追加して標準ライブラリから`std::cmp::Ordering`という型をスコープに導入しています。
`Ordering`もenumの一つで`Less`、`Greater`、`Equal`という列挙子を持っています。
これらは二つの値を比較したときに得られる3種類の結果です。

それから`Ordering`型を使用する新しい5行をいちばん下に追加してしています。
`cmp`メソッドは二つの値の比較を行い、比較できるものになら何に対しても呼び出せます。
比較対象への参照をとり、ここでは`guess`と`secret_number`を比較しています。
そして`use`文でスコープに導入した`Ordering`列挙型の列挙子を返します。
ここでは[`match`][match]式を使用しており、`guess`と`secret_number`の値に対して`cmp`を呼んだ結果返された`Ordering`の列挙子に基づき、次の動作を決定しています。

`match`式は複数の*アーム*（腕）で構成されます。
各アームはマッチさせる*パターン*と、`match`に与えられた値がそのアームのパターンにマッチしたときに実行されるコードで構成されます。
Rustは`match`に与えられた値を受け取って、各アームのパターンを順に照合していきます。
パターンと`match`式はRustの強力な機能です: コードが遭遇する可能性のあるさまざまな状況を表現し、それらすべてを確実に処理できるようにします。
これらの機能については、それぞれ第6章と第18章で詳しく説明します。

ここで使われている`match`式に対して、例を通して順に見ていきましょう。
たとえばユーザが50と予想し、今回ランダムに生成された秘密の数字は38だったとしましょう。

コードが50と38を比較すると、50は38よりも大きいので`cmp`メソッドは`Ordering::Greater`を返します。
`match`式は`Ordering::Greater`の値を取得し、各アームのパターンを吟味し始めます。
まず最初のアームのパターンである`Ordering::Less`を見て、`Ordering::Greater`の値と`Ordering::Less`がマッチしないことがわかります。
そのため、このアームのコードは無視して、次のアームに移ります。
次のアームのパターンは`Ordering::Greater`で、これは`Ordering::Greater`と*マッチ*します！&nbsp;
このアームに関連するコードが実行され、画面に`Too big!`と表示されます。
このシナリオでは最初に成功したマッチで`match`式（の評価）は終了し、最後のアームとは照合されません。

ところがリスト2-4のコードはまだコンパイルできません。
試してみましょう。

```console
{{#include ../listings/ch02-guessing-game-tutorial/listing-02-04/output.txt}}
```

このエラーの核心は*型の不一致*があると述べていることです。
Rustは強い静的型システムを持ちますが、型推論も備えています。
`let guess = String::new()`と書いたとき、Rustは`guess`が`String`型であるべきと推論したので、私たちはその型を書かずに済みました。
一方で`secret_number`は数値型です。
Rustのいくつかの数値型は1から100までの値を表現でき、それらの型には32ビット数値の`i32`、符号なしの32ビット数値の`u32`、64ビット数値の`i64`などがあります。
Rustのデフォルトは`i32`型で、型情報をどこかに追加してRustに異なる数値型だと推論させない限り`secret_number`の型はこれになります。
エラーの原因はRustが文字列と数値型を比較できないためです。

最終的にはプログラムが入力として読み込んだ`String`を実数型に変換し、秘密の数字と数値として比較できるようにしたいわけです。
そのためには`main`関数の本体に次の行を追加します。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/no-listing-03-convert-string-to-number/src/main.rs:here}}
```

その行とはこれのことです。

```rust,ignore
let guess: u32 = guess.trim().parse().expect("Please type a number!");
```

`guess`という名前の変数を作成しています。
しかし待ってください、このプログラムには既に`guess`という名前の変数がありませんでしたか？&nbsp;
たしかにありますが、Rustでは`guess`の前の値を新しい値で覆い隠す（shadowする）ことが許されているのです。
*シャドーイング*（shadowing）は、`guess_str`と`guess`のような重複しない変数を二つ作る代わりに、`guess`という変数名を再利用させてくれるのです。
これについては[第3章][shadowing]で詳しく説明しますが、今のところ、この機能はある型から別の型に値を変換するときによく使われることを知っておいてください。

この新しい変数を`guess.trim().parse()`という式に束縛しています。
式の中にある`guess`は、入力が文字列として格納されたオリジナルの`guess`変数を指しています。
`String`インスタンスの`trim`メソッドは文字列の先頭と末尾の空白をすべて削除します。
これは数値データのみを表現できる`u32`型とこの文字列を比較するために（準備として）行う必要があります。
ユーザは予想を入力したあと`read_line`の処理を終えるために<span class="keystroke">Enterキー</span>を押す必要がありますが、これにより文字列に改行文字が追加されます。
たとえばユーザが<span class="keystroke">5</span>と入力して<span class="keystroke">Enterキー</span>を押すと、`guess`は`5\n`になります。
この`\n`は「改行」を表しています。（WindowsではEnterキーを押すとキャリッジリターンと改行が入り`\r\n`となります。）
`trim`メソッドは`\n`や`\r\n`を削除するので、その結果`5`だけになります。

[文字列の`parse`メソッド][parse]は文字列を別の型に変換します。
ここでは、私たちは文字列を数値に変換するために使います。
`let guess: u32`として、Rustに欲しい数値の正確な型を伝える必要があります。
`guess`の後にコロン（`:`）を付けることで変数の型に注釈をつけることをRustに伝えています。
Rustには組み込みの数値型がいくつかあります。
ここにある`u32`は符号なし32ビット整数で、小さな正の数を表すデフォルトの型に適しています。
他の数値型については[第3章][integers]で学びます。

さらに、このサンプルプログラムでは、`u32`という注釈と`secret_number`変数との比較していることから、Rustは`secret_number`変数も`u32`型であるべきだと推論しています。
つまり、いまでは二つの同じ型の値を比較することになるわけです！

`parse`メソッドは論理的に数値に変換できる文字にしか使えないので、よくエラーになります。
たとえば文字列に`A👍%`が含まれていたら数値に変換する術はありません。
解析に失敗する可能性があるため、`parse`メソッドは`read_line`メソッドと同様に`Result`型を返します
（[「`Result`で失敗の可能性を扱う」](#resultで失敗の可能性を扱う)で説明しました）&nbsp;
今回も`expect`メソッドを使用して`Result`型を同じように扱います。
`parse`メソッドが文字列から数値を作成できなかったために`Result`型の`Err`列挙子を返したら、`expect`の呼び出しはゲームをクラッシュさせ、私たちが与えたメッセージを表示します。
`parse`が文字列をうまく数値へ変換できたときは`Result`型の`Ok`列挙子を返し、`expect`は`Ok`値から欲しい数値を返してくれます。

さあ、プログラムを走らせましょう:

```console
$ cargo run
   Compiling guessing_game v0.1.0 (file:///projects/guessing_game)
    Finished dev [unoptimized + debuginfo] target(s) in 0.43s
     Running `target/debug/guessing_game`
Guess the number!
The secret number is: 58
Please input your guess.
  76
You guessed: 76
Too big!
```

いい感じです！&nbsp;
予想の前にスペースを追加したにもかかわらず、プログラムはちゃんとユーザが76と予想したことを理解しました。
このプログラムを何回か走らせ、数字を正しく言い当てたり、大きすぎる数字や小さすぎる数字を予想したりといった、異なる種類の入力に対する動作の違いを検証してください。

現在、ゲームの大半は動作していますが、まだユーザは1回しか予想できません。
ループを追加して、その部分を変更しましょう！

## ループで複数回の予想を可能にする

`loop`キーワードは無限ループを作成します。
ループを追加してユーザが数字を予想する機会を増やします。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/no-listing-04-looping/src/main.rs:here}}
```

見ての通り予想入力のプロンプト以降をすべてループ内に移動しました。
ループ内の行をさらに4つのスペースでインデントして、もう一度プログラムを実行してください。
プログラムはいつまでも推測を求めるようになりましたが、実はこれが新たな問題を引き起こしています。
これではユーザが（ゲームを）終了できません！

ユーザはキーボードショートカットの<span class="keystroke">ctrl-c</span>を使えば、いつでもプログラムを中断させられます。
しかし「[予想と秘密の数字を比較する](#予想と秘密の数字を比較する)」の`parse`で述べたように、この飽くなきモンスターから逃れる方法はもう一つあります。
ユーザが数字以外の答えを入力すればプログラムはクラッシュします。
それを利用して以下のようにすれば終了できます。

```console
$ cargo run
   Compiling guessing_game v0.1.0 (file:///projects/guessing_game)
    Finished dev [unoptimized + debuginfo] target(s) in 1.50s
     Running `target/debug/guessing_game`
Guess the number!
The secret number is: 59
Please input your guess.
45
You guessed: 45
Too small!
Please input your guess.
60
You guessed: 60
Too big!
Please input your guess.
59
You guessed: 59
You win!
Please input your guess.
quit
thread 'main' panicked at 'Please type a number!: ParseIntError { kind: InvalidDigit }', src/main.rs:28:47
(スレッド'main'は'数字を入力してください！：ParseIntError { kind: InvalidDigit }', src/libcore/result.rs:785でパニックしました)
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
(注：`RUST_BACKTRACE=1`で走らせるとバックトレースを見れます)
```

`quit`と入力すればゲームが終了しますが、数字以外の入力でもそうなります。
これは控えめに言っても最適ではありません。
私たちは正しい数字が予想されたときにゲームが停止するようにしたいのです。

### 正しい予想をした後に終了する

`break`文を追加して、ユーザが勝ったらゲームが終了するようにプログラムしましょう。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/no-listing-05-quitting/src/main.rs:here}}
```

`You win!`の後に`break`の行を追記することで、ユーザが秘密の数字を正確に予想したときにプログラムがループを抜けるようになりました。
ループは`main`関数の最後の部分なので、ループを抜けることはプログラムを抜けることを意味します。

### 不正な入力を処理する

このゲームの動作をさらに洗練させるために、ユーザが数値以外を入力したときにプログラムをクラッシュさせるのではなく、数値以外を無視してユーザが数当てを続けられるようにしましょう。
これはリスト2-5のように、`String`から`u32`に`guess`を変換する行を変えることで実現できます。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-05/src/main.rs:here}}
```

<span class="caption">リスト2-5：数値以外の予想を無視し、プログラムをクラッシュさせるのではなく、もう1回予想してもらう</span>

`expect`の呼び出しから`match`式に切り替えて、エラーによるクラッシュからエラー処理へと移行します。
`parse`が`Result`型を返すことと、`Result`が`Ok`と`Err`の列挙子を持つ列挙型であることを思い出してください。
ここでは`match`式を、`cmp`メソッドから返される`Ordering`を処理したときと同じように使っています。

もし`parse`メソッドが文字列から数値への変換に成功したなら、結果の数値を保持する`Ok`値を返します。
この`Ok`値は最初のアームのパターンにマッチします。
`match`式は`parse`メソッドが生成して`Ok`値に格納した`num`の値を返します。
その数値は私たちが望んだように、これから作成する新しい`guess`変数に収まります。

もし`parse`メソッドが文字列から数値への変換に*失敗*したなら、エラーに関する詳細な情報を含む`Err`値を返します。
この`Err`値は最初の`match`アームの`Ok(num)`パターンにはマッチしませんが、2番目のアームの`Err(_)`パターンにはマッチします。
アンダースコアの`_`はすべての値を受け付けます。
この例ではすべての`Err`値に対して、その中にどんな情報があってもマッチさせたいと言っているのです。
したがってプログラムは2番目のアームのコードである`continue`を実行します。
これは`loop`の次の繰り返しに移り、別の予想を求めるようプログラムに指示します。
つまり実質的にプログラムは`parse`メソッドが遭遇し得るエラーをすべて無視するようになります！

これでプログラム内のすべてが期待通りに動作するはずです。
試してみましょう。

```console
$ cargo run
   Compiling guessing_game v0.1.0 (file:///projects/guessing_game)
    Finished dev [unoptimized + debuginfo] target(s) in 4.45s
     Running `target/debug/guessing_game`
Guess the number!
The secret number is: 61
Please input your guess.
10
You guessed: 10
Too small!
Please input your guess.
99
You guessed: 99
Too big!
Please input your guess.
foo
Please input your guess.
61
You guessed: 61
You win!
```

素晴らしい！&nbsp;
最後にほんの少し手を加えれば数当てゲームは完成です。
このプログラムはまだ秘密の数字を表示していることを思い出してください。
テストには便利でしたが、これではゲームが台無しです。
秘密の数字を表示している`println!`を削除しましょう。
最終的なコードをリスト2-6に示します。

<span class="filename">ファイル名：src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-06/src/main.rs}}
```

<span class="caption">リスト2-6：数当てゲームの完全なコード</span>

数当てゲームを無事に作り上げることができました。
おめでとうございます！

## まとめ

このプロジェクトではハンズオンを通して、`let`、`match`、メソッド、関連関数、外部クレートの使いかたなど、多くの新しいRustの概念に触れました。
以降の章では、これらの概念についてより詳しく学びます。
第3章では変数、データ型、関数など多くのプログラミング言語が持つ概念を取り上げ、Rustでの使い方を説明します。
第4章ではRustを他の言語とは異なるものに特徴づける、所有権について説明します。
第5章では構造体とメソッドの構文について説明し、第6章では列挙型がどのように動くのかについて説明します。

[prelude]: https://doc.rust-lang.org/stable/std/prelude/index.html
[variables-and-mutability]: ch03-01-variables-and-mutability.html#変数と可変性
[comments]: ch03-04-comments.html
[string]: https://doc.rust-lang.org/stable/std/string/struct.String.html
[iostdin]: https://doc.rust-lang.org/stable/std/io/struct.Stdin.html
[read_line]: https://doc.rust-lang.org/stable/std/io/struct.Stdin.html#method.read_line
[result]: https://doc.rust-lang.org/stable/std/result/enum.Result.html
[enums]: ch06-00-enums.html
[expect]: https://doc.rust-lang.org/stable/std/result/enum.Result.html#method.expect
[recover]: ch09-02-recoverable-errors-with-result.html
[randcrate]: https://crates.io/crates/rand
[semver]: http://semver.org
[cratesio]: https://crates.io/
[doccargo]: https://doc.rust-lang.org/cargo/
[doccratesio]: https://doc.rust-lang.org/cargo/reference/publishing.html
[match]: ch06-02-match.html
[shadowing]: ch03-01-variables-and-mutability.html#シャドーイング
[parse]: https://doc.rust-lang.org/stable/std/primitive.str.html#method.parse
[integers]: ch03-02-data-types.html#整数型
