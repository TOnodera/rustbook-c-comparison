## 高度な関数とクロージャ

この節では、関数ポインタやクロージャを返す方法など、関数とクロージャに関係する高度な機能を調べます。

### 関数ポインタ

クロージャを関数へ渡す方法を説明しましたが、通常の関数を別の関数へ渡すこともできます。この技法は、新しいクロージャを定義するのではなく、すでに定義した関数を渡したいときに便利です。関数は`fn`（小文字の*f*）型へ型強制されます。クロージャトレイトの`Fn`と混同しないでください。`fn`型は*関数ポインタ*と呼ばれます。関数ポインタで関数を渡すと、別の関数の引数として関数を使えます。

引数が関数ポインタであることを指定する構文は、クロージャの構文と似ています。リスト20-28では、引数へ1を加える`add_one`関数を定義しています。`do_twice`関数は2つの引数を取ります。1つは`i32`引数を受け取って`i32`を返す任意の関数への関数ポインタ、もう1つは`i32`値です。`do_twice`は関数`f`を2回呼び、それぞれへ値`arg`を渡して、2回の関数呼び出しの結果を加算します。`main`関数は`add_one`と`5`を引数として`do_twice`を呼び出します。

<Listing number="20-28" file-name="src/main.rs" caption="引数として関数ポインタを受け取るため`fn`型を使う">

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-28/src/main.rs}}
```

</Listing>

このコードは`The answer is: 12`と表示します。`do_twice`の引数`f`を、`i32`型の引数を1つ受け取って`i32`を返す`fn`として指定します。すると`do_twice`の本体で`f`を呼び出せます。`main`では、関数名`add_one`を`do_twice`の第1引数として渡せます。

クロージャと異なり、`fn`はトレイトではなく型です。そのため、`Fn`トレイトのいずれかをトレイト境界として持つジェネリック型引数を宣言する代わりに、`fn`を引数の型として直接指定します。

関数ポインタは、3つのクロージャトレイト（`Fn`、`FnMut`、`FnOnce`）をすべて実装します。つまり、クロージャを期待する関数には、常に関数ポインタを引数として渡せます。関数とクロージャのどちらでも受け取れるよう、ジェネリック型とクロージャトレイトの1つを使って関数を書くのが通常は最適です。

それでも、クロージャを持たない外部コードとのインターフェイスでは、クロージャではなく`fn`だけを受け取りたいことがあります。Cの関数は関数を引数として受け取れますが、Cにはクロージャがありません。

その場で定義したクロージャと名前付き関数のどちらでも使える例として、標準ライブラリの`Iterator`トレイトが提供する`map`メソッドを見ましょう。`map`で数値のベクタを文字列のベクタへ変換するには、リスト20-29のようにクロージャを使えます。

<Listing number="20-29" caption="`map`メソッドでクロージャを使い、数値を文字列へ変換する">

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-29/src/main.rs:here}}
```

</Listing>

クロージャの代わりに、関数を名前で`map`の引数へ渡すこともできます。リスト20-30に示します。

<Listing number="20-30" caption="`map`メソッドで`String::to_string`関数を使い、数値を文字列へ変換する">

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-30/src/main.rs:here}}
```

</Listing>

`to_string`という名前の関数は複数あるため、[「高度なトレイト」][advanced-traits]<!-- ignore -->で説明した完全修飾構文を使う必要があることに注意してください。

ここでは`ToString`トレイトに定義された`to_string`関数を使っています。標準ライブラリは、`Display`を実装するすべての型に`ToString`を実装しています。

第6章の[「enumの値」][enum-values]<!-- ignore -->で説明したように、定義したenumの各列挙子の名前は初期化関数にもなります。この初期化関数はクロージャトレイトを実装する関数ポインタとして使えます。つまりリスト20-31のように、クロージャを受け取るメソッドの引数へ初期化関数を渡せます。

<Listing number="20-31" caption="`map`メソッドでenumの初期化関数を使い、数値から`Status`インスタンスを作る">

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-31/src/main.rs:here}}
```

</Listing>

ここでは`Status::Value`の初期化関数を使い、`map`を呼び出した範囲内の各`u32`値から`Status::Value`インスタンスを作ります。この書き方を好む人も、クロージャを好む人もいます。どちらも同じコードへコンパイルされるので、自分にとって明確なほうを使ってください。

### クロージャを返す

クロージャはトレイトで表されるため、クロージャを直接返すことはできません。トレイトを返したい場面の多くでは、そのトレイトを実装する具体型を関数の戻り値として使えます。しかしクロージャには、戻り値として記述できる具体型が通常はないため、この方法は使えません。たとえば、クロージャがスコープ内の値を取り込む場合、関数ポインタ`fn`を戻り値の型にはできません。

代わりに通常は、第10章で学んだ`impl Trait`構文を使います。`Fn`、`FnOnce`、`FnMut`を使い、任意の関数型を返せます。たとえばリスト20-32のコードは問題なくコンパイルできます。

<Listing number="20-32" caption="`impl Trait`構文を使って関数からクロージャを返す">

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-32/src/lib.rs}}
```

</Listing>

しかし第13章の[「クロージャの型を推論し注釈する」][closure-types]<!-- ignore -->で説明したように、各クロージャはそれぞれ異なる型でもあります。シグネチャは同じでも実装が異なる複数の関数を一緒に扱う必要がある場合は、トレイトオブジェクトを使う必要があります。リスト20-33のようなコードを書くと何が起きるか考えてみましょう。

<Listing file-name="src/main.rs" number="20-33" caption="`impl Fn`型を返す関数が定義したクロージャから`Vec<T>`を作る">

```rust,ignore,does_not_compile
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-33/src/main.rs}}
```

</Listing>

ここには`returns_closure`と`returns_initialized_closure`という2つの関数があり、どちらも`impl Fn(i32) -> i32`を返します。同じトレイトを実装していても、返すクロージャは異なることに注目してください。コンパイルしようとすると、Rustはこのコードが動かないと伝えます。

```text
{{#include ../listings/ch20-advanced-features/listing-20-33/output.txt}}
```

エラーメッセージは、`impl Trait`を返すたびにRustが一意な*不透明型*を作ると伝えています。不透明型では、Rustが構築した詳細を確認できず、Rustが生成する型を推測して自分で記述することもできません。したがって、これらの関数が同じ`Fn(i32) -> i32`トレイトを実装するクロージャを返しても、関数ごとにRustが生成する不透明型は別の型です。これは、第17章の[「`Pin`型と`Unpin`トレイト」][future-types]<!-- ignore -->で見たように、出力型が同じでも、異なるasyncブロックに対してRustが異なる具体型を生成することと似ています。この問題の解決方法は、すでに何度か見てきました。リスト20-34のようにトレイトオブジェクトを使います。

<Listing number="20-34" caption="同じ型になるよう`Box<dyn Fn>`を返す関数が定義したクロージャから`Vec<T>`を作る">

```rust
{{#rustdoc_include ../listings/ch20-advanced-features/listing-20-34/src/main.rs:here}}
```

</Listing>

このコードは問題なくコンパイルできます。トレイトオブジェクトについて詳しくは、第18章の[「トレイトオブジェクトで共通の振る舞いを抽象化する」][trait-objects]<!-- ignore -->を参照してください。

次はマクロを見ていきましょう。

[advanced-traits]: ch20-02-advanced-traits.html#高度なトレイト
[enum-values]: ch06-01-defining-an-enum.html#enumの値
[closure-types]: ch13-01-closures.html#クロージャの型推論と注釈
[future-types]: ch17-05-traits-for-async.html#pin型とunpinトレイト
[trait-objects]: ch18-02-trait-objects.html
