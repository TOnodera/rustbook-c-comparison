

## Crates.ioにクレートを公開する

プロジェクトの依存として[crates.io](https://crates.io/)のパッケージを使用しましたが、
自分のパッケージを公開することで他の人とコードを共有することもできます。
[crates.io](https://crates.io/)のクレートレジストリは、自分のパッケージのソースコードを配布するので、
主にオープンソースのコードをホストします。

RustとCargoは、公開されたパッケージを人々が見つけやすく、使いやすくしてくれる機能を有しています。
これらの機能の一部を次に語り、そして、パッケージの公開方法を説明します。

### 役に立つドキュメンテーションコメントを行う

パッケージを正確にドキュメントすることで、他のユーザーがパッケージを使用する方法や、いつ使用すべきかを理解する手助けをすることになるので、
ドキュメンテーションを書くことに時間を費やす価値があります。第3章で、2連スラッシュ、`//`でRustのコードにコメントをつける方法を議論しました。
Rustには、ドキュメンテーション用のコメントも用意されていて、便利なことに*ドキュメンテーションコメント*として知られ、
HTMLドキュメントを生成します。クレートの*実装*法とは対照的にクレートの*使用*法を知ることに興味のあるプログラマ向けの、
公開API用のドキュメンテーションコメントの中身をこのHTMLは表示します。

ドキュメンテーションコメントは、2つではなく、3連スラッシュ、`///`を使用し、テキストを整形するMarkdown記法もサポートしています。
ドキュメント対象の要素の直前にドキュメンテーションコメントを配置してください。
リスト14-1は、`my_crate`という名のクレートの`add_one`関数用のドキュメンテーションコメントを示しています。

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch14-more-about-cargo/listing-14-01/src/lib.rs}}
```

<span class="caption">リスト14-1: 関数のドキュメンテーションコメント</span>

ここで、`add_one`関数がすることの説明を与え、`Examples`というタイトルでセクションを開始し、
`add_one`関数の使用法を模擬するコードを提供しています。このドキュメンテーションコメントから`cargo doc`を実行することで、
HTMLドキュメントを生成することができます。このコマンドはコンパイラとともに配布されている`rustdoc`ツールを実行し、
生成されたHTMLドキュメントを*target/doc*ディレクトリに配置します。

利便性のために、`cargo doc --open`を実行しれば、現在のクレートのドキュメント用のHTML(と、
自分のクレートが依存しているすべてのドキュメント)を構築し、その結果をWebブラウザで開きます。
`add_one`関数まで下り、図14-1に示したように、ドキュメンテーションコメントのテキストがどう描画されるかを確認しましょう:

<img alt="`my_crate`の`add_one`関数の描画済みのHTMLドキュメント" src="img/trpl14-01.png" class="center" />

<span class="caption">図14-1: `add_one`関数のHTMLドキュメント</span>

#### よく使われるセクション

`# Examples`マークダウンのタイトルをリスト14-1で使用し、「例」というタイトルのセクションをHTMLに生成しました。
こちらがこれ以外にドキュメントでよくクレート筆者が使用するセクションです。

* **Panics**: ドキュメント対象の関数がパニックする可能性のある筋書きです。プログラムをパニックさせたくない関数の使用者は、
これらの状況で関数が呼ばれないことを確かめる必要があります。
* **Errors**: 関数が`Result`を返すなら、起きうるエラーの種類とどんな条件がそれらのエラーを引き起こす可能性があるのか解説すると、
呼び出し側の役に立つので、エラーの種類によって処理するコードを変えて書くことができます。
* **Safety**: 関数が呼び出すのに`unsafe`(unsafeについては第20章で説明します)なら、
関数がunsafeな理由を説明し、関数が呼び出し元に保持していると期待する不変条件を説明するセクションがあるべきです。

多くのドキュメンテーションコメントでは、これらすべてのセクションが必要になることはありませんが、
これはコードの利用者が知りたいと思うコードの方向性を思い出させてくれるいいチェックリストになります。

#### テストとしてのドキュメンテーションコメント

ドキュメンテーションコメントに例のコードブロックを追加すると、ライブラリの使用方法のデモに役立ち、
おまけもついてきます。 `cargo test`を実行すると、ドキュメントのコード例をテストとして実行するのです！
例付きのドキュメントに上回るものはありません。しかし、ドキュメントが書かれてからコードが変更されたがために、
動かない例がついているよりも悪いものもありません。リスト14-1から`add_one`関数のドキュメンテーションとともに、
`cargo test`を実行したら、テスト結果に以下のような区域が見られます。

```text
   Doc-tests my_crate

running 1 test
test src/lib.rs - add_one (line 5) ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.27s
```

さて、例の`assert_eq!`がパニックするように、関数か例を変更し、再度`cargo test`を実行したら、
docテストが、例とコードがお互いに同期されていないことを捕捉するところを確認できるでしょう！

#### 含まれている要素にコメントする

`//!`スタイルのdocコメントは、コメントに続く要素にではなく、コメントを含む要素にドキュメンテーションを付け加えます。
典型的には、クレートのルートファイル(慣例的には、*src/lib.rs*)内部や、
モジュールの内部で使用して、クレートやモジュール全体にドキュメントをつけます。

例えば、`add_one`関数を含む`my_crate`クレートの目的を解説するドキュメンテーションを追加するには、
`//!`で始まるドキュメンテーションコメントを*src/lib.rs*ファイルの先頭につけます。
リスト14-2に示したようにですね:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch14-more-about-cargo/listing-14-02/src/lib.rs:here}}
```

<span class="caption">リスト14-2: 全体として`my_crate`クレートにドキュメントをつける</span>

`//!`で始まる最後の行のあとにコードがないことに注目してください。`///`ではなく、`//!`でコメントを開始しているので、
このコメントに続く要素ではなく、このコメントを含む要素にドキュメントをつけているわけです。
今回の場合、そのような要素は*src/lib.rs*ファイルであり、クレートのルートです。
これらのコメントは、クレート全体を解説しています。

`cargo doc --open`を実行すると、これらのコメントは、`my_crate`のドキュメントの最初のページ、
クレートの公開要素のリストの上部に表示されます。図14-2のようにですね:

<img alt="クレート全体のコメント付きの描画済みHTMLドキュメンテーション" src="img/trpl14-02.png" class="center" />

<span class="caption">図14-2: クレート全体を解説するコメントを含む`my_crate`の描画されたドキュメンテーション</span>

要素内のドキュメンテーションコメントは、特にクレートやモジュールを解説するのに有用です。
コンテナの全体の目的を説明し、使用者がクレートの体系を理解する手助けをするのに使用してください。

### `pub use`で便利な公開APIをエクスポートする

自分の公開APIの構造は、クレートを公開する際に考慮すべき点です。自分のクレートを使用したい人は、
自分よりもその構造に馴染みがないですし、クレートのモジュール階層が大きければ、使用したい部分を見つけるのが困難になる可能性があります。

第7章において、`pub`キーワードで要素を公開にする方法、`use`キーワードで要素をスコープに導入する方法について説明しました。
しかしながら、クレートの開発中に自分にとって意味のある構造は、ユーザーにはあまり便利ではない可能性があります。
複数階層を含む階層で自分の構造体を体系化したくなるかもしれませんが、それから階層の深いところで定義した型を使用したい人は、
型が存在することを見つけ出すのに困難を伴う可能性もあります。また、そのような人は、
`use my_crate::UsefulType`の代わりに`use my_crate::some_module::another_module::UsefulType;`と入力するのを煩わしく感じる可能性もあります。

嬉しいお知らせは、構造が他人が他のライブラリから使用するのに便利では*ない*場合、内部的な体系を再構築する必要はないということです。
代わりに、要素を再エクスポートし、`pub use`で自分の非公開構造とは異なる公開構造にできます。
再エクスポートは、ある場所の公開要素を一つ取り、別の場所で定義されているかのように別の場所で公開します。

例えば、芸術的な概念をモデル化するために`art`という名のライブラリを作ったとしましょう。
このライブラリ内には、2つのモジュールがあります。 `PrimaryColor`と`SecondaryColor`という名前の2つのenumを含む、
`kinds`モジュールと`mix`という関数を含む`utils`モジュールです。リスト14-3のようにですね:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,noplayground,test_harness
{{#rustdoc_include ../listings/ch14-more-about-cargo/listing-14-03/src/lib.rs:here}}
```

<span class="caption">リスト14-3: `kinds`と`utils`モジュールに体系化される要素を含む`art`ライブラリ</span>

図14-3は、`cargo doc`により生成されるこのクレートのドキュメンテーションの最初のページがどんな見た目になるか示しています。

<img alt="`kinds`と`utils`モジュールを列挙する`art`クレートの描画されたドキュメンテーション" src="img/trpl14-03.png" class="center" />

<span class="caption">図14-3: `kinds`と`utils`モジュールを列挙する`art`のドキュメンテーションのトップページ</span>

`PrimaryColor`型も`SecondaryColor`型も、`mix`関数もトップページには列挙されていないことに注意してください。
`kinds`と`utils`をクリックしなければ、参照することができません。

このライブラリに依存する別のクレートは、現在定義されているモジュール構造を指定して、
`art`の要素をスコープ内に持ち込む`use`文が必要になるでしょう。リスト14-4は、
`art`クレートから`PrimaryColor`と`mix`要素を使用するクレートの例を示しています。

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch14-more-about-cargo/listing-14-04/src/main.rs}}
```

<span class="caption">リスト14-4: 内部構造がエクスポートされて`art`クレートの要素を使用するクレート</span>

リスト14-4は`art`クレートを使用していますが、このコードの作者は、`PrimaryColor`が`kinds`モジュールにあり、
`mix`が`utils`モジュールにあることを理解しなければなりませんでした。`art`クレートのモジュール構造は、
`art`クレートの使用者よりも、`art`クレートに取り組む開発者などに関係が深いです。
この内部構造は`art`クレートの使用方法を理解しようとする人とって役に立つ情報を何も含んでおらず、むしろ、
利用者はどこを見ればよいのか探し出す必要があり、モジュール名を`use`文で指定しなければならないので、
混乱を招くものです。

公開APIから内部体系を除去するために、リスト14-3の`art`クレートコードを変更し、`pub use`文を追加して、
最上位で要素を再エクスポートすることができます。リスト14-5みたいにですね:

<span class="filename">ファイル名: src/lib.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch14-more-about-cargo/listing-14-05/src/lib.rs:here}}
```

<span class="caption">リスト14-5: `pub use`文を追加して要素を再エクスポートする</span>

このクレートに対して`cargo doc`が生成するAPIドキュメンテーションは、これで図14-4のようにトップページに再エクスポートを列挙しリンクするので、
`PrimaryColor`型と`SecondaryColor`型と`mix`関数を見つけやすくします。

<img alt="トップページに再エクスポートのある`art`クレートの描画されたドキュメンテーション" src="img/trpl14-04.png" class="center" />

<span class="caption">図14-4: 再エクスポートを列挙する`art`のドキュメンテーションのトップページ</span>

`art`クレートのユーザーは、それでも、リスト14-4にデモされているように、リスト14-3の内部構造を見て使用することもできますし、
リスト14-5のより便利な構造を使用することもできます。リスト14-6に示したようにですね:

<span class="filename">ファイル名: src/main.rs</span>

```rust,ignore
{{#rustdoc_include ../listings/ch14-more-about-cargo/listing-14-06/src/main.rs:here}}
```

<span class="caption">リスト14-6: `art`クレートの再エクスポートされた要素を使用するプログラム</span>

ネストされたモジュールがたくさんあるような場合、最上位階層で`pub use`により型を再エクスポートすることは、
クレートの使用者の経験に大きな違いを生みます。別のよくある`pub use`の使用法は、
依存クレートの定義をクレートの公開APIの一部とするために、現在のクレートの中で依存クレートの定義を再エクスポートすることです。

役に立つAPI構造を作ることは、科学というよりも芸術の領域であり、ユーザーにとって何が最善のAPIなのか、
探究するために繰り返してみることができます。`pub use`は、内部的なクレート構造に柔軟性をもたらし、
その内部構造をユーザーに提示する構造から切り離してくれます。インストールしてある他のクレートを見て、
内部構造が公開APIと異なっているか確認してみてください。

### Crates.ioのアカウントをセットアップする

クレートを公開する前に、[crates.io](https://crates.io/)のアカウントを作成し、
APIトークンを取得する必要があります。そうするには、[crates.io](https://crates.io/)のホームページを訪れ、
Githubアカウントでログインしてください。(現状は、Githubアカウントがなければなりませんが、
いずれは他の方法でもアカウントを作成できるようになる可能性があります。)ログインしたら、
[https://crates.io/me/](https://crates.io/me/)で自分のアカウントの設定に行き、
APIキーを取り扱ってください。そして、`cargo login`コマンドをAPIキーとともに実行してください。
以下のようにですね:

```console
$ cargo login
abcdefghijklmnopqrstuvwxyz012345
```

このコマンドは、CargoにAPIトークンを知らせ、*~/.cargo/credentials*にローカルに保存します。
このトークンは、*秘密*です。 他人とは共有しないでください。なんらかの理由で他人と実際に共有してしまったら、
古いものを破棄して[crates.io](https://crates.io/)で新しいトークンを生成するべきです。

### 新しいクレートにメタデータを追加する

公開したいクレートがあるとしましょう。公開前に、
*Cargo.toml*ファイルの`[package]`セクションにメタデータを追加する必要があるでしょう。

クレートには、一意な名前が必要でしょう。クレートをローカルで作成している間、
クレートの名前はなんでもいい状態でした。ところが、[crates.io](https://crates.io/)のクレート名は、
最初に来たもの勝ちの精神で付与されていますので、一旦クレート名が取られてしまったら、
その名前のクレートを他の人が公開することは絶対できません。クレートを公開しようとする前に使いたい名前を検索してください。
すでに使用されている場合は、他の名前を探して、*Cargo.toml*ファイルの`[package]`セクション下の`name`フィールドを編集して、
公開用に新しい名前を使う必要があるでしょう。以下のように:

<span class="filename">ファイル名: Cargo.toml</span>

```toml
[package]
name = "guessing_game"
```

たとえ、一意な名前を選択していたとしても、この時点で`cargo publish`を実行すると、警告とエラーが出ます。

```console
$ cargo publish
    Updating crates.io index
warning: manifest has no description, license, license-file, documentation, homepage or repository.
See https://doc.rust-lang.org/cargo/reference/manifest.html#package-metadata for more info.
--snip--
error: failed to publish to registry at https://crates.io

Caused by:
  the remote server responded with an error (status 400 Bad Request): missing or empty metadata fields: description, license. Please see https://doc.rust-lang.org/cargo/reference/manifest.html for more information on configuring these fields
```

これがエラーになるのは、大事な情報を一部入れていないからです。 説明とライセンスは、
他の人があなたのクレートは何をし、どんな条件の元で使っていいのかを知るために必要なのです。
*Cargo.toml*に1文か2文程度の説明をつけてください。これは、検索結果に表示されますからね。
`license`フィールドには、*ライセンス識別子*を与える必要があります。
[Linux団体のSoftware Package Data Exchange(SPDX)][spdx]に、この値に使用できる識別子が列挙されています。
例えば、自分のクレートをMITライセンスでライセンスするためには、
`MIT`識別子を追加してください。

<span class="filename">ファイル名: Cargo.toml</span>

```toml
[package]
name = "guessing_game"
license = "MIT"
```

SPDXに出現しないライセンスを使用したい場合、そのライセンスをファイルに配置し、
プロジェクトにそのファイルを含め、それから`license`キーを使う代わりに、
そのファイルの名前を指定するのに`license-file`を使う必要があります。

どのライセンスが自分のプロジェクトに<ruby>相<rp>(</rp><rt>ふ</rt><rp>)</rp>応<rp>(</rp><rt>さわ</rt><rp>)</rp></ruby>しいかというガイドは、
この本の範疇を超えています。Rustコミュニティの多くの人間は、`MIT OR Apache-2.0`のデュアルライセンスを使用することで、
Rust自体と同じようにプロジェクトをライセンスします。この実践は、`OR`で区切られる複数のライセンス識別子を指定して、
プロジェクトに複数のライセンスを持たせることもできることを模擬しています。

一意な名前、バージョン、説明、ライセンスが追加され、
公開準備のできたプロジェクト用の`Cargo.toml`ファイルは以下のような見た目になっていることでしょう。

<span class="filename">ファイル名: Cargo.toml</span>

```toml
[package]
name = "guessing_game"
version = "0.1.0"
edition = "2024"
description = "A fun game where you guess what number the computer has chosen."
license = "MIT OR Apache-2.0"

[dependencies]
```

[Cargoのドキュメンテーション](https://doc.rust-lang.org/cargo)には、
指定して他人が発見し、より容易くクレートを使用できることを保証する他のメタデータが解説されています。

### Crates.ioに公開する

アカウントを作成し、APIトークンを保存し、クレートの名前を決め、必要なメタデータを指定したので、
公開する準備が整いました！クレートを公開すると、特定のバージョンが、
[crates.io](http://crates.io/)に他の人が使用できるようにアップロードされます。

公開は*永久*なので、気をつけてください。バージョンは絶対に上書きできず、
コードも削除できません。[crates.io](https://crates.io/)の一つの主な目標が、
[crates.io](https://crates.io/)のクレートに依存しているすべてのプロジェクトのビルドが、
動き続けるようにコードの永久アーカイブとして機能することなのです。バージョン削除を可能にしてしまうと、
その目標を達成するのが不可能になってしまいます。ですが、公開できるクレートバージョンの数に制限はありません。

再度`cargo publish`コマンドを実行してください。今度は成功するはずです。

```console
$ cargo publish
    Updating crates.io index
   Packaging guessing_game v0.1.0 (file:///projects/guessing_game)
    Packaged 6 files, 1.2KiB (895.0B compressed)
   Verifying guessing_game v0.1.0 (file:///projects/guessing_game)
   Compiling guessing_game v0.1.0
(file:///projects/guessing_game/target/package/guessing_game-0.1.0)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.19s
   Uploading guessing_game v0.1.0 (file:///projects/guessing_game)
    Uploaded guessing_game v0.1.0 to registry `crates-io`
note: waiting for `guessing_game v0.1.0` to be available at registry
`crates-io`.
You may press ctrl-c to skip waiting; the crate should be available shortly.
   Published guessing_game v0.1.0 at registry `crates-io`
```

おめでとうございます！Rustコミュニティとコードを共有し、誰でもあなたのクレートを依存として簡単に追加できます。

### 既存のクレートの新バージョンを公開する

クレートに変更を行い、新バージョンをリリースする準備ができたら、
*Cargo.toml*ファイルに指定された`version`の値を変更し、再公開します。
[セマンティックバージョンルール][semver]を使用して加えた変更の種類に基づいて次の適切なバージョン番号を決定してください。
そして、`cargo publish`を実行し、新バージョンをアップロードします。

### `cargo yank`でCrates.ioからバージョンを非推奨化する

以前のバージョンのクレートを削除することはできないものの、将来のプロジェクトがこれに新たに依存することを防ぐことはできます。
これは、なんらかの理由により、クレートバージョンが壊れている場合に有用です。そのような場面において、
Cargoはクレートバージョンの *取り下げ(yank)* をサポートしています。

バージョンを取り下げると、それに依存するすべての既存のプロジェクトは引き続き依存することができますが、
新規プロジェクトがそのバージョンに依存することはできなくなります。つまるところ、取り下げは、
すでに*Cargo.lock*が存在するプロジェクトは壊さないが、将来的に生成された*Cargo.lock*ファイルは
取り下げられたバージョンを使わない、ということを意味します。

あるバージョンのクレートを取り下げるには、以前公開したクレートのディレクトリで、取り下げたいバージョンを指定して`cargo yank`を実行してください。
例えば、`guessing_game`という名前のクレートのバージョン1.0.1を公開したことがあり、それを取り下げたい場合は、
`guessing_game`のプロジェクトディレクトリで以下を実行します。

```console
$ cargo yank --vers 1.0.1
    Updating crates.io index
        Yank guessing_game@1.0.1
```

`--undo`をコマンドに付与することで、取り下げを取り消し、再度あるバージョンにプロジェクトを依存させ始めることもできます。

```console
$ cargo yank --vers 1.0.1 --undo
    Updating crates.io index
      Unyank guessing_game@1.0.1
```

取り下げは、コードの削除は一切*しません*。例えば、誤ってアップロードされた秘密鍵を削除することはできません。
もしそうなってしまったら、即座に秘密鍵をリセットしなければなりません。

[spdx]: https://spdx.org/licenses/
[semver]: https://semver.org/
