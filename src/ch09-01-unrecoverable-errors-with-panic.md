## `panic!`で回復不能なエラー

時として、コード内で悪いことが起き、それに対してできることは何も無い、ということがあるでしょう。
このような場面で、Rustには`panic!`マクロが用意されています。
実際にパニックを発生させる方法は2つあります:
コードをパニックさせるような操作（配列にその終端を超えてアクセスするなど）を行う方法と、明示的に`panic!`マクロを呼び出す方法です。
いずれの場合でも、プログラムでパニックが発生します。
デフォルトでは、これらのパニックは失敗メッセージを出力し、スタックを巻き戻し、片付け、プログラムを終了させます。
パニックが発生したときにはそのパニックの発生源を特定しやすくするために、
環境変数を介してコールスタックを表示するように指示することもできます。


> ### パニックに対してスタックを巻き戻すかアボートするか
>
> デフォルトでは、パニックが発生すると、プログラムは*巻き戻し*を始めます。
> つまり、コンパイラ生成コードがスタックを遡り、遭遇した各関数のデータを片付けるということです。
> しかし、この遡行と片付けはすべきことが多くなります。そのためRustでは、
> 即座に*アボート*し、片付けをせずにプログラムを終了させることを、代替として選択できるようになっています。
>
> そうなると、プログラムが使用していたメモリは、
> OSが片付ける必要があります。プロジェクトにおいて、実行可能ファイルを極力小さくする必要があれば、
> *Cargo.toml*ファイルの適切な`[profile]`欄に`panic = 'abort'`を追記することで、
> パニック時に巻き戻しからアボートするように切り替えることができます。例として、
> リリースモード時にアボートするようにしたければ、以下を追記してください:
>
> ```toml
> [profile.release]
> panic = 'abort'
> ```

単純なプログラムで`panic!`の呼び出しを試してみましょう:

<span class="filename">ファイル名: src/main.rs</span>

```rust,should_panic,panics
{{#rustdoc_include ../listings/ch09-error-handling/no-listing-01-panic/src/main.rs}}
```

このプログラムを実行すると、以下のような出力を目の当たりにするでしょう:

```console
{{#include ../listings/ch09-error-handling/no-listing-01-panic/output.txt}}
```

`panic!`の呼び出しが、最後の2行に含まれるエラーメッセージを発生させているのです。
1行目にパニックメッセージとソースコード中でパニックが発生した箇所を示唆しています:
*src/main.rs:2:5*は、*src/main.rs*ファイルの2行目5文字目であることを示しています。

この場合、示唆される行は、自分のコードの一部で、その箇所を見に行けば、`panic!`マクロ呼び出しがあるわけです。
それ以外では、`panic!`呼び出しが、自分のコードが呼び出しているコードの一部になっている可能性もあるわけです。
エラーメッセージで報告されるファイル名と行番号が、結果的に`panic!`呼び出しに導いた自分のコードの行ではなく、
`panic!`マクロが呼び出されている他人のコードになるでしょう。`panic!`呼び出しの発生元である関数のバックトレースを使用して、
問題を起こしている自分のコードの箇所を割り出すことができます。次はバックトレースについてはより詳しく議論しましょう。

別の例を眺めて、自分のコードでマクロを直接呼び出す代わりに、コードに存在するバグにより、
ライブラリで`panic!`呼び出しが発生するとどんな感じなのか確かめてみましょう。リスト9-1は、
ベクタに有効な添え字の範囲の外の添え字でアクセスを試みるコードです。

<span class="filename">ファイル名: src/main.rs</span>

```rust,should_panic,panics
{{#rustdoc_include ../listings/ch09-error-handling/listing-09-01/src/main.rs}}
```

<span class="caption">リスト9-1: ベクタの境界を超えて要素へのアクセスを試み、`panic!`の呼び出しを発生させる</span>

ここでは、ベクタの100番目の要素(添え字は0始まりなので添え字99)にアクセスを試みていますが、ベクタには3つしか要素がありません。
この場面では、Rustはパニックします。`[]`の使用は、要素を返すと想定されるものの、
無効な添え字を渡せば、ここでRustが返せて正しいと思われる要素は何もないわけです。

Cでは、データ構造の終端を超えて読み込みを行おうとすることは未定義動作です。
メモリがデータ構造に属していないにもかかわらず、そのデータ構造内のその要素に対応するメモリ上の箇所にある何かを返してくるかもしれません。
これは、*バッファオーバーリード* (*buffer overread*)と呼ばれ、
攻撃者が、データ構造の後に格納された読めるべきでないデータを読み出せるように添え字を操作できたら、
セキュリティ脆弱性につながる可能性があります。

この種の脆弱性からプログラムを保護するために、存在しない添え字の要素を読もうとしたら、
Rustは実行を中止し、継続を拒みます。試して確認してみましょう:

```console
{{#include ../listings/ch09-error-handling/listing-09-01/output.txt}}
```

このエラーは*main.rs*の4行目を指していて、ここではインデックス99にアクセスを試みています。
その次の注釈行は、`RUST_BACKTRACE`環境変数をセットして、まさしく何が起き、
エラーが発生したのかのバックトレースを得られることを教えてくれています。
*バックトレース*とは、ここに至るまでに呼び出された全関数の一覧です。Rustのバックトレースも、
他の言語同様に動作します: バックトレースを読むコツは、頭からスタートして自分のファイルを見つけるまで読むことです。
そこが、問題が発生した場所です。この場所より上の行は、自分のコードが呼び出したコードになります;
それより下の行は、自分のコードを呼び出しているコードになります。これらの前後の行には、Rustの核となるコード、標準ライブラリのコード、
使用しているクレートなどが含まれるかもしれません。`RUST_BACKTRACE`環境変数を0以外の値にセットして、
バックトレースを出力してみましょう。リスト9-2のような出力が得られるでしょう。

```console
$ RUST_BACKTRACE=1 cargo run
thread 'main' panicked at src/main.rs:4:6:
index out of bounds: the len is 3 but the index is 99
stack backtrace:
   0: rust_begin_unwind
             at /rustc/07dca489ac2d933c78d3c5158e3f43beefeb02ce/library/std/src/panicking.rs:645:5
   1: core::panicking::panic_fmt
             at /rustc/07dca489ac2d933c78d3c5158e3f43beefeb02ce/library/core/src/panicking.rs:72:14
   2: core::panicking::panic_bounds_check
             at /rustc/07dca489ac2d933c78d3c5158e3f43beefeb02ce/library/core/src/panicking.rs:208:5
   3: <usize as core::slice::index::SliceIndex<[T]>>::index
             at /rustc/07dca489ac2d933c78d3c5158e3f43beefeb02ce/library/core/src/slice/index.rs:255:10
   4: core::slice::index::<impl core::ops::index::Index<I> for [T]>::index
             at /rustc/07dca489ac2d933c78d3c5158e3f43beefeb02ce/library/core/src/slice/index.rs:18:9
   5: <alloc::vec::Vec<T,A> as core::ops::index::Index<I>>::index
             at /rustc/07dca489ac2d933c78d3c5158e3f43beefeb02ce/library/alloc/src/vec/mod.rs:2770:9
   6: panic::main
             at ./src/main.rs:4:6
   7: core::ops::function::FnOnce::call_once
             at /rustc/07dca489ac2d933c78d3c5158e3f43beefeb02ce/library/core/src/ops/function.rs:250:5
note: Some details are omitted, run with `RUST_BACKTRACE=full` for a verbose backtrace.
```

<span class="caption">リスト9-2: `RUST_BACKTRACE`環境変数をセットした時に表示される、
`panic!`呼び出しが生成するバックトレース</span>

出力が多いですね！OSやRustのバージョンによって、出力の詳細は変わる可能性があります。この情報とともに、
バックトレースを得るには、デバッグシンボルを有効にしなければなりません。デバッグシンボルは、
`--release`オプションなしで`cargo build`や`cargo run`を使用していれば、標準で有効になり、
ここではそうなっています。

リスト9-2の出力で、バックトレースの6行目が問題発生箇所を指し示しています: *src/main.rs*の4行目です。
プログラムにパニックしてほしくなければ、自分のファイルについて言及している最初の行で示されている箇所から調査を開始すべきです。
わざとパニックするコードを書いたリスト9-1において、パニックを解消する方法は、
ベクタの添え字の範囲を超えた要素を要求しないようにすることです。
将来コードがパニックしたら、パニックを引き起こすどんな値でコードがどんな動作をしているのかと、
代わりにコードは何をすべきなのかを算出する必要があるでしょう。

この章の後ほど、[「`panic!`すべきかするまいか」][to-panic-or-not-to-panic]節で`panic!`とエラー状態を扱うのに`panic!`を使うべき時と使わぬべき時に戻ってきます。
次は、`Result`を使用してエラーから回復する方法を見ましょう。

[to-panic-or-not-to-panic]:
ch09-03-to-panic-or-not-to-panic.html#panicすべきかするまいか

