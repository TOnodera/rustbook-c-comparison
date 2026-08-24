

## Cargoのワークスペース

第12章で、バイナリクレートとライブラリクレートを含むパッケージを構築しました。プロジェクトの開発が進むにつれて、
ライブラリクレートの肥大化が続き、その上で複数のライブラリクレートにパッケージを分割したくなることでしょう。
Cargoは*ワークスペース*という協調して開発された関連のある複数のパッケージを管理するのに役立つ機能を提供しています。

### ワークスペースを生成する

*ワークスペース*は、同じ*Cargo.lock*と出力ディレクトリを共有する一連のパッケージです。
ワークスペースを使用したプロジェクトを作成し、ワークスペースの構造に集中できるよう、瑣末なコードを使用しましょう。
ワークスペースを構築する方法は複数あるので、よく使われる方法だけを提示しましょう。バイナリ1つとライブラリ2つを含むワークスペースを作ります。
バイナリは、主要な機能を提供しますが、2つのライブラリに依存しています。
一方のライブラリは、`add_one`関数を提供し、2番目のライブラリは、`add_two`関数を提供します。
これら3つのクレートが同じワークスペースの一部になります。ワークスペース用の新しいディレクトリを作ることから始めましょう:

```console
$ mkdir add
$ cd add
```

次に*add*ディレクトリにワークスペース全体を設定する*Cargo.toml*ファイルを作成します。
このファイルには`[package]`セクションはありません。
代わりに、バイナリクレートを含むパッケージへのパスを指定することでワークスペースにメンバを追加させてくれる`[workspace]`セクションから開始します。
今回の場合、そのパスは*adder*です。

<span class="filename">ファイル名: Cargo.toml</span>

```toml
{{#include ../listings/ch14-more-about-cargo/no-listing-01-workspace/add/Cargo.toml}}
```

次に、*add*ディレクトリ内で`cargo new`を実行することで`adder`バイナリクレートを作成しましょう:

```console
$ cargo new adder
    Creating binary (application) `adder` package
      Adding `adder` as member of workspace at `file:///projects/add`
```

ワークスペース内で`cargo new`を実行すると、新しく作成されたパッケージがワークスペースの`Cargo.toml`にある`members`キーへ自動的に追加されます。

<span class="filename">ファイル名: Cargo.toml</span>

```toml
{{#include ../listings/ch14-more-about-cargo/output-only-01-adder-crate/add/Cargo.toml}}
```

この時点で、`cargo build`を実行するとワークスペースを構築できます。*add*ディレクトリに存在するファイルは、
以下のようになるはずです。

```text
├── Cargo.lock
├── Cargo.toml
├── adder
│   ├── Cargo.toml
│   └── src
│       └── main.rs
└── target
```

ワークスペースは、コンパイルした生成物が置かれる単一の*target*ディレクトリを最上位に持ちます。
`adder`パッケージには*target*ディレクトリはありません。
*adder*ディレクトリ内部から`cargo build`を実行することになっていたとしても、コンパイルされる生成物は、
*add/adder/target*ではなく、*add/target*に落ち着くでしょう。ワークスペースのクレートは、
お互いに依存しあうことを意味するので、Cargoはワークスペースの*target*ディレクトリをこのように構成します。
各クレートが*target*ディレクトリを持っていたら、各クレートは自身の*target*ディレクトリにワークスペースの他のクレートの生成物を置くために、
ワークスペースの他のクレートを再コンパイルしなくてはならなくなるでしょう。一つの*target*ディレクトリを共有することで、
クレートは不必要な再ビルドを回避できるのです。

### ワークスペース内に2番目のパッケージを作成する

次に、ワークスペースに別のメンバパッケージを作成し、`add_one`と呼びましょう。
最上位の*Cargo.toml*を変更して`members`リストで*add_one*パスを指定するようにしてください。

<span class="filename">ファイル名: Cargo.toml</span>

```toml
{{#include ../listings/ch14-more-about-cargo/no-listing-02-workspace-with-two-crates/add/Cargo.toml}}
```

それから、`add_one`という名前のライブラリクレートを生成してください。

```console
$ cargo new add_one --lib
     Created library `add_one` package
```

これで*add*ディレクトリには、以下のディレクトリやファイルが存在するはずです。

```text
├── Cargo.lock
├── Cargo.toml
├── add_one
│   ├── Cargo.toml
│   └── src
│       └── lib.rs
├── adder
│   ├── Cargo.toml
│   └── src
│       └── main.rs
└── target
```

*add_one/src/lib.rs*ファイルに`add_one`関数を追加しましょう:

<span class="filename">ファイル名: add_one/src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch14-more-about-cargo/no-listing-02-workspace-with-two-crates/add/add_one/src/lib.rs}}
```

これで、バイナリを持つパッケージ`adder`を、ライブラリを持つパッケージ`add_one`に依存させることができるようになりました。
まず、`add_one`へのパス依存を*adder/Cargo.toml*に追加する必要があります。

<span class="filename">ファイル名: adder/Cargo.toml</span>

```toml
{{#include ../listings/ch14-more-about-cargo/no-listing-02-workspace-with-two-crates/add/adder/Cargo.toml:6:7}}
```

Cargoはワークスペースのクレートが、お互いに依存しているとは想定していないので、
依存関係について明示する必要があります。

次に、`adder`クレート内で(`add_one`クレートの)`add_one`関数を使用しましょう。*adder/src/main.rs*ファイルを開き、
冒頭に`use`行を追加して新しい`add_one`ライブラリクレートをスコープに導入してください。
それから`main`関数を変更し、`add_one`関数を呼び出します。リスト14-7のようにですね。

<span class="filename">ファイル名: adder/src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch14-more-about-cargo/listing-14-07/add/adder/src/main.rs}}
```

<span class="caption">リスト14-7: `adder`クレートから`add_one`ライブラリクレートを使用する</span>

最上位の*add*ディレクトリで`cargo build`を実行することでワークスペースをビルドしましょう！

```console
$ cargo build
   Compiling add_one v0.1.0 (file:///projects/add/add_one)
   Compiling adder v0.1.0 (file:///projects/add/adder)
    Finished dev [unoptimized + debuginfo] target(s) in 0.68s
```

*add*ディレクトリからバイナリクレートを実行するには、`-p`引数とパッケージ名を`cargo run`と共に使用して、
実行したいワークスペースのパッケージを指定することができます。

```console
$ cargo run -p adder
    Finished dev [unoptimized + debuginfo] target(s) in 0.0s
     Running `target/debug/adder`
Hello, world! 10 plus one is 11!
```

これにより、*adder/src/main.rs*のコードが実行され、これは`add_one`クレートに依存しています。

#### ワークスペースの外部パッケージに依存する

ワークスペースには、各クレートのディレクトリそれぞれに*Cargo.lock*が存在するのではなく、
最上位階層にただ一つの*Cargo.lock*が存在するだけのことに注目してください。
これにより、全クレートが全依存の同じバージョンを使用していることが確認されます。
`rand`パッケージを*adder/Cargo.toml*と*add_one/Cargo.toml*ファイルに追加すると、
Cargoは両者をあるバージョンの`rand`に解決し、それを一つの*Cargo.lock*に記録します。
ワークスペースの全クレートに同じ依存を使用させるということは、
クレートが相互に互換性を常に維持するということになります。
`add_one`クレートで`rand`クレートを使用できるように、
*add_one/Cargo.toml*ファイルの`[dependencies]`セクションに`rand`クレートを追加しましょう:

<span class="filename">ファイル名: add_one/Cargo.toml</span>

```toml
{{#include ../listings/ch14-more-about-cargo/no-listing-03-workspace-with-external-dependency/add/add_one/Cargo.toml:6:7}}
```

これで、*add_one/src/lib.rs*ファイルに`use rand;`を追加でき、
*add*ディレクトリで`cargo build`を実行することでワークスペース全体をビルドすると、
`rand`クレートを持ってきてコンパイルするでしょう。
スコープ内に持ち込んだ`rand`を参照していないので、警告が出るでしょう。

```console
$ cargo build
    Updating crates.io index
  Downloaded rand v0.8.5
   --snip--
   Compiling rand v0.8.5
   Compiling add_one v0.1.0 (file:///projects/add/add_one)
warning: unused import: `rand`
(警告: 未使用のインポート: `rand`)
 --> add_one/src/lib.rs:1:5
  |
1 | use rand;
  |     ^^^^
  |
  = note: `#[warn(unused_imports)]` on by default

warning: `add_one` (lib) generated 1 warning
   Compiling adder v0.1.0 (file:///projects/add/adder)
    Finished dev [unoptimized + debuginfo] target(s) in 10.18s
```

さて、最上位の*Cargo.lock*は、`rand`に対する`add_one`の依存の情報を含むようになりました。
ですが、`rand`はワークスペースのどこかで使用されているにも関わらず、それぞれの*Cargo.toml*ファイルにも、
`rand`を追加しない限り、ワークスペースの他のクレートでそれを使用することはできません。
例えば、`adder`パッケージの*adder/src/main.rs*ファイルに`use rand;`を追加すると、
エラーが出ます。

```console
$ cargo build
  --snip--
   Compiling adder v0.1.0 (file:///projects/add/adder)
error[E0432]: unresolved import `rand`
(エラー: 未解決のインポート`rand`)
 --> adder/src/main.rs:2:5
  |
2 | use rand;
  |     ^^^^ no external crate `rand`
  |         (外部クレート`rand`は存在しません)
```

これを修正するには、`adder`パッケージの*Cargo.toml*ファイルを編集し、これも`rand`に依存していることを示してください。
`adder`パッケージをビルドすると、`rand`を*Cargo.lock*の`adder`の依存一覧に追加しますが、
`rand`のファイルが追加でダウンロードされることはありません。Cargoが、
ワークスペース内で`rand`パッケージを使用するすべてのパッケージ内のすべてのクレートが、
同じバージョンを使用することを保証してくれるのです。これによりスペースを節約し、
ワークスペースのクレートが相互に互換性があることを保証してくれます。

#### ワークスペースにテストを追加する

さらなる改善として、`add_one`クレート内に`add_one::add_one`関数のテストを追加しましょう:

<span class="filename">ファイル名: add_one/src/lib.rs</span>

```rust,noplayground
{{#rustdoc_include ../listings/ch14-more-about-cargo/no-listing-04-workspace-with-tests/add/add_one/src/lib.rs}}
```

では、最上位の*add*ディレクトリで`cargo test`を実行してください。
このような構造をしたワークスペースで`cargo test`を実行すると、ワークスペースの全クレートのテストを実行します。

```console
$ cargo test
   Compiling add_one v0.1.0 (file:///projects/add/add_one)
   Compiling adder v0.1.0 (file:///projects/add/adder)
    Finished test [unoptimized + debuginfo] target(s) in 0.27s
     Running unittests src/lib.rs (target/debug/deps/add_one-f0253159197f7841)

running 1 test
test tests::it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests src/main.rs (target/debug/deps/adder-49979ff40686fa8e)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests add_one

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

出力の最初の区域が、`add_one`クレートの`it_works`テストが通ったことを示しています。
次の区域には、`adder`クレートにはテストが見つからなかったことが示され、
さらに最後の区域には、`add_one`クレートにドキュメンテーションテストは見つからなかったと表示されています。

`-p`フラグを使用し、テストしたいクレートの名前を指定することで最上位ディレクトリから、
ワークスペースのある特定のクレート用のテストを実行することもできます。

```console
$ cargo test -p add_one
    Finished test [unoptimized + debuginfo] target(s) in 0.00s
     Running unittests src/lib.rs (target/debug/deps/add_one-b3235fea9a156f74)

running 1 test
test tests::it_works ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests add_one

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

この出力は、`cargo test`が`add_one`クレートのテストのみを実行し、`adder`クレートのテストは実行しなかったことを示しています。

ワークスペースのクレートを [crates.io](https://crates.io/) に公開したら、ワークスペースのクレートは個別に公開される必要があります。
`cargo test`のように、`-p`フラグを使用して公開したいクレートの名前を指定することで、ワークスペース内の特定のクレートを公開することができます。

鍛錬を積むために、`add_one`クレートと同様の方法でワークスペースに`add_two`クレートを追加してください！

プロジェクトが肥大化してきたら、ワークスペースの使用を考えてみてください。 大きな一つのコードの塊よりも、
微細で個別のコンポーネントの方が理解しやすいです。またワークスペースにクレートを保持することは、
同時に変更されることが多いのなら、クレート間の協調をしやすくなることにも繋がります。
