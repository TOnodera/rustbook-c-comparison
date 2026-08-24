## `use`キーワードでパスをスコープに持ち込む

関数を呼び出すためにパスを略さずに書かなくてはならないのは、繰り返しも多くて不便に感じられるでしょう。
リスト7-7においては、絶対パスを使うか相対パスを使うかにかかわらず、`add_to_waitlist`関数を呼ぼうと思うたびに`front_of_house`と`hosting`も指定しないといけませんでした。
ありがたいことに、この手続きを簡単化する方法があります:
一度`use`キーワードを使ってショートカットを作成すれば、そのスコープ内であればどこでも、より短い名前を使用できます。

リスト7-11では、`crate::front_of_house::hosting`モジュールを`eat_at_restaurant`関数のスコープに持ち込むことで、`eat_at_restaurant`において、`hosting::add_to_waitlist`と指定するだけで`add_to_waitlist`関数を呼び出せるようにしています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground,test_harness
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-11/src/lib.rs}}
```

<span class="caption">リスト7-11: `use` でモジュールをスコープに持ち込む</span>

`use`とパスをスコープに追加することは、ファイルシステムにおいてシンボリックリンクを張ることに似ています。
`use crate::front_of_house::hosting`をクレートルートに追加することで、`hosting`はこのスコープで有効な名前となり、まるで`hosting`はクレートルートで定義されていたかのようになります。
スコープに`use`で持ち込まれたパスも、他のパスと同じようにプライバシーがチェックされます。

`use`は、`use`が出現した特定のスコープでのみ使えるショートカットを作成することに注意してください。
リスト7-12は`eat_at_restaurant`関数を新しい子モジュール`customer`の中に移動していますが、このモジュールは`use`文とは異なるスコープなので、この関数本体はコンパイルできないでしょう:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground,test_harness,does_not_compile,ignore
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-12/src/lib.rs}}
```

<span class="caption">リスト7-12: `use`文はそれが属するスコープ内にのみ適用される</span>

コンパイルエラーは`customer`モジュール内ではショートカットが適用されないことを示しています:

```console
{{#include ../listings/ch07-managing-growing-projects/listing-07-12/output.txt}}
```

`use`がそのスコープ内で使用されていないという警告も出ていることに気づくでしょう！
この問題を修正するには、`use`も`customer`モジュールの中に移動するか、`customer`子モジュールの中で`super::hosting`によって親モジュールにあるショートカットを参照してください。

### 慣例に従った`use`パスを作る

リスト7-11を見て、なぜ`use crate::front_of_house::hosting`と書いて`eat_at_restaurant`内で`hosting::add_to_waitlist`と呼び出したのか不思議に思っているかもしれません。リスト7-13のように、`use`で`add_to_waitlist`までのパスをすべて指定しても同じ結果が得られるのに、と。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground,test_harness
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-13/src/lib.rs}}
```

<span class="caption">リスト7-13: `add_to_waitlist` 関数を`use` でスコープに持ち込む。このやりかたは慣例的ではない</span>

リスト7-11も7-13もおなじ仕事をしてくれますが、関数をスコープに`use`で持ち込む場合、リスト7-11のほうが慣例的なやり方です。
関数の親モジュールを`use`で持ち込むということは、関数を呼び出す際、毎回親モジュールを指定しなければならないということです。
関数を呼び出すときに親モジュールを指定することで、フルパスを繰り返して書くことを抑えつつ、関数がローカルで定義されていないことを明らかにできます。
リスト7-13のコードではどこで`add_to_waitlist`が定義されたのかが不明瞭です。

一方で、構造体やenumその他の要素を`use`で持ち込むときは、フルパスを書くのが慣例的です。
リスト7-14は標準ライブラリの`HashMap`構造体をバイナリクレートのスコープに持ち込む慣例的なやり方を示しています。


<span class="filename">ファイル名: src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-14/src/main.rs}}
```

<span class="caption">リスト7-14: `HashMap`を慣例的なやり方でスコープに持ち込む</span>

こちらの慣例の背後には、はっきりとした理由はありません。自然に発生した慣習であり、みんなRustのコードをこのやり方で読み書きするのに慣れてしまったというだけです。

同じ名前の2つの要素を`use`でスコープに持ち込むのはRustでは許されないので、そのときこの慣例は例外的に不可能です。
リスト7-15は、同じ名前を持つけれど異なる親モジュールを持つ2つの`Result`型をスコープに持ち込み、それらを参照するやり方を示しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-15/src/lib.rs:here}}
```

<span class="caption">リスト7-15: 同じ名前を持つ2つの型を同じスコープに持ち込むには親モジュールを使わないといけない。</span>

このように、親モジュールを使うことで2つの`Result`型を区別できます。
もし`use std::fmt::Result` と `use std::io::Result`と書いていたとしたら、2つの`Result`型が同じスコープに存在することになり、私達が`Result`を使ったときにどちらのことを意味しているのかRustはわからなくなってしまいます。

### 新しい名前を`as`キーワードで与える

同じ名前の2つの型を`use`を使って同じスコープに持ち込むという問題には、もう一つ解決策があります。パスの後に、`as`と型の新しいローカル名、即ち*エイリアス*を指定すればよいのです。
リスト7-16は、リスト7-15のコードを、2つの`Result`型のうち一つを`as`を使ってリネームするという別のやり方で書いたものを表しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-16/src/lib.rs:here}}
```

<span class="caption">リスト7-16: 型がスコープに持ち込まれた時、`as`キーワードを使ってその名前を変えている</span>

2つめの`use`文では、`std::io::Result`に、`IoResult`という新たな名前を選んでやります。`std::fmt`の`Result`もスコープに持ち込んでいますが、この名前はこれとは衝突しません。
リスト7-15もリスト7-16も慣例的とみなされているので、どちらを使っても構いませんよ！

### `pub use`を使って名前を再公開する

`use`キーワードで名前をスコープに持ちこんだ時、新しいスコープで使用できるその名前は非公開です。
私達のコードを呼び出すコードが、まるでその名前が私達のコードのスコープで定義されていたかのように参照できるようにするためには、`pub`と`use`を組み合わせればいいです。
このテクニックは、要素を自分たちのスコープに持ち込むだけでなく、他の人がその要素をその人のスコープに持ち込むことも可能にすることから、*再公開 (re-exporting)* と呼ばれています。

リスト7-17はリスト7-11のコードのルートモジュールでの`use`を`pub use`に変更したものを示しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground,test_harness
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-17/src/lib.rs}}
```

<span class="caption">リスト7-17: `pub use`で、新たなスコープのコードがその名前を使えるようにする</span>

この変更を行う前の状態では、外部のコードはパス`restaurant::front_of_house::hosting::add_to_waitlist()`を使用して`add_to_wishlist`関数を呼ばなくてはなりませんでした。
この`pub use`によってルートモジュールから`hosting`モジュールを再公開された今、外部のコードはパス`restaurant::hosting::add_to_waitlist()`を使用できるようになりました。

再公開は、あなたのコードの内部構造と、あなたのコードを呼び出すプログラマーたちのその領域に関しての見方が異なるときに有用です。
例えば、レストランの比喩では、レストランを経営している人は「接客部門 (front of house)」と「後方部門 (back of house)」のことについて考えるでしょう。
しかし、レストランを訪れるお客さんは、そのような観点からレストランの部門について考えることはありません。
`pub use`を使うことで、ある構造でコードを書きつつも、別の構造で公開するということが可能になります。
こうすることで、私達のライブラリを、ライブラリを開発するプログラマにとっても、ライブラリを呼び出すプログラマにとっても、よく整理されたものとすることができます。
第14章の[「`pub use`で便利な公開APIをエクスポートする」][ch14-pub-use]の節で、`pub use`の別の例と、それがクレートのドキュメンテーションにどう影響するかを見ることにしましょう。

### 外部のパッケージを使う

2章で、乱数を得るために`rand`という外部パッケージを使って、数当てゲームをプログラムしました。
`rand`を私達のプロジェクトで使うために、次の行を *Cargo.toml* に書き加えましたね：

<span class="filename">ファイル名: Cargo.toml</span>

```toml
{{#include ../listings/ch02-guessing-game-tutorial/listing-02-02/Cargo.toml:9:}}
```

`rand`を依存 (dependency) として *Cargo.toml* に追加すると、`rand`パッケージとそのすべての依存を[crates.io](https://crates.io/)からダウンロードして、私達のプロジェクトで`rand`が使えるようにするようCargoに命令します。

そして、`rand`の定義を私達のパッケージのスコープに持ち込むために、クレートの名前である`rand`から始まる`use`の行を追加し、そこにスコープに持ち込みたい要素を並べました。
2章の[乱数を生成する][rand]の節で、`Rng`トレイトをスコープに持ち込み`rand::thread_rng`関数を呼び出したことを思い出してください。

```rust,ignore
{{#rustdoc_include ../listings/ch02-guessing-game-tutorial/listing-02-03/src/main.rs:ch07-04}}
```

Rustコミュニティに所属する人々が[crates.io](https://crates.io/)でたくさんのパッケージを利用できるようにしてくれており、上と同じステップを踏めばそれらをあなたのパッケージに取り込むことができます：あなたのパッケージの *Cargo.toml* ファイルにそれらを書き並べ、`use`を使って要素をクレートからスコープへと持ち込めばよいのです。

標準`std`ライブラリも、私達のパッケージの外部にあるクレートだということに注意してください。
標準ライブラリはRust言語に同梱されているので、 *Cargo.toml* を `std`を含むように変更する必要はありません。
しかし、その要素をそこから私達のパッケージのスコープに持ち込むためには、`use`を使って参照する必要はあります。
例えば、`HashMap`には次の行を使います。

```rust
use std::collections::HashMap;
```

これは標準ライブラリクレートの名前`std`から始まる絶対パスです。

### 巨大な`use`のリストをネストしたパスを使って整理する

同じクレートか同じモジュールで定義された複数の要素を使おうとする時、それぞれの要素を一行一行並べると、縦に大量のスペースを取ってしまいます。
例えば、リスト2-4の数当てゲームで使った次の2つの`use`文が`std`からスコープへ要素を持ち込みました。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch07-managing-growing-projects/no-listing-01-use-std-unnested/src/main.rs:here}}
```

代わりに、ネストしたパスを使うことで、同じ一連の要素を1行でスコープに持ち込めます。
これをするには、リスト7-18に示されるように、パスの共通部分を書き、2つのコロンを続け、そこで波括弧で互いに異なる部分のパスのリストを囲みます。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-18/src/main.rs:here}}
```

<span class="caption">リスト7-18: 同じプレフィックスをもつ複数の要素をスコープに持ち込むためにネストしたパスを指定する</span>

大きなプログラムにおいては、同じクレートやモジュールからのたくさんの要素をネストしたパスで持ち込むようにすれば、独立した`use`文の数を大きく減らすことができます！

ネストしたパスはパスのどの階層においても使うことができます。これはサブパスを共有する2つの`use`文を合体させるときに有用です。
例えば、リスト7-19は2つの`use`文を示しています：1つは`std::io`をスコープに持ち込み、もう一つは`std::io::Write`をスコープに持ち込んでいます。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-19/src/lib.rs}}
```

<span class="caption">リスト7-19: 片方がもう片方のサブパスである2つの`use`文</span>

これらの2つのパスの共通部分は`std::io`であり、そしてこれは最初のパスにほかなりません。これらの2つのパスを1つの`use`文へと合体させるには、リスト7-20に示されるように、ネストしたパスに`self`を使いましょう。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch07-managing-growing-projects/listing-07-20/src/lib.rs}}
```

<span class="caption">リスト7-20: リスト7-19のパスを一つの `use` 文に合体させる</span>

この行は `std::io` と`std::io::Write` をスコープに持ち込みます。

### glob演算子

パスにおいて定義されているすべての公開要素をスコープに持ち込みたいときは、glob演算子 `*` をそのパスの後ろに続けて書きましょう：

```rust
use std::collections::*;
```

この`use`文は`std::collections`のすべての公開要素を現在のスコープに持ち込みます。
glob演算子を使う際にはご注意を！
globをすると、どの名前がスコープ内にあり、プログラムで使われている名前がどこで定義されたのか分かりづらくなります。

glob演算子はしばしば、テストの際、テストされるあらゆるものを`tests`モジュールに持ち込むために使われます。これについては11章[テストの書き方][writing-tests]の節で話します。
glob演算子はプレリュードパターンの一部としても使われることがあります：そのようなパターンについて、より詳しくは[標準ライブラリのドキュメント](https://doc.rust-lang.org/std/prelude/index.html#other-preludes)をご覧ください。

[ch14-pub-use]: ch14-02-publishing-to-crates-io.html#pub-useで便利な公開apiをエクスポートする
[rand]: ch02-00-guessing-game-tutorial.html#乱数を生成する
[writing-tests]: ch11-01-writing-tests.html#テストの記述法


