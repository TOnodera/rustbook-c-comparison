

## `cargo install`でバイナリをインストールする

`cargo install`コマンドにより、バイナリクレートをローカルにインストールし、使用することができます。
これは、システムパッケージを置き換えることを意図したものではありません。<ruby>即<rp>(</rp><rt>すなわ</rt><rp>)</rp></ruby>ち、
Rustの開発者が、他人が[crates.io](https://crates.io/)に共有したツールをインストールするのに便利な方法を意味するのです。
バイナリターゲットを持つパッケージのみインストールできることに注意してください。*バイナリターゲット*とは、
クレートが*src/main.rs*ファイルやバイナリとして指定された他のファイルを持つ場合に生成される実行可能なプログラムのことであり、
単独では実行不可能なものの、他のプログラムに含むのには適しているライブラリターゲットとは一線を画します。
通常、クレートには、*README*ファイルに、クレートがライブラリかバイナリターゲットか、両方をもつかという情報があります。

`cargo install`でインストールされるバイナリはすべて、インストールのルートの*bin*フォルダに保持されます。
*rustup.rs*を使用しRustをインストールし、独自の設定を何も行なっていなければ、このディレクトリは、*$HOME/.cargo/bin*になります。
`cargo install`でインストールしたプログラムを実行できるようにするためには、そのディレクトリが`$PATH`に含まれていることを確かめてください。

例えば、第12章で、ファイルを検索する`ripgrep`という`grep`ツールのRust版があることに触れました。
`ripgrep`をインストールするには、以下を実行することができます。

```console
$ cargo install ripgrep
    Updating crates.io index
  Downloaded ripgrep v14.1.1
  Downloaded 1 crate (213.6 KB) in 0.40s
  Installing ripgrep v14.1.1
--snip--
   Compiling grep v0.3.2
    Finished `release` profile [optimized + debuginfo] target(s) in 6.73s
  Installing ~/.cargo/bin/rg
   Installed package `ripgrep v14.1.1` (executable `rg`)
```

出力の最後から2番目の行が、インストールされたバイナリの位置と名前を示していて、`ripgrep`の場合、`rg`です。
インストールディレクトリが`$PATH`に存在する限り、前述したように、`rg --help`を実行して、
より高速でRustらしいファイル検索ツールを使用し始めることができます！
