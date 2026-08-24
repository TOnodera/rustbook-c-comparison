# Rust Book 日本語訳・C言語比較

Rust公式書籍『The Rust Programming Language』を、省略せず自然な日本語へ翻訳し、Rust初心者およびC言語初心者向けの比較解説を加えるプロジェクトです。

## 翻訳元

- 原著: [rust-lang/book](https://github.com/rust-lang/book)
- 基準コミット: [`917544888a55e4da7109bdba8c88c893c0da70f4`](https://github.com/rust-lang/book/commit/917544888a55e4da7109bdba8c88c893c0da70f4)
- Rust Edition: 2024

詳細は[原著の追従情報](UPSTREAM.md)を参照してください。

## 方針

- 原著の内容を要約・省略せずに翻訳します。
- 日本語として自然に読める表現を使用します。
- コード、リンク、表、注記、画像、説明順序を維持します。
- C言語との比較と初心者向け補足は、原著本文と明確に区別します。
- 原則として一章につき一つのPull Requestで進めます。

詳細は[翻訳ガイド](TRANSLATION_GUIDE.md)と[用語集](GLOSSARY.md)を参照してください。

翻訳に使用した原著と既存日本語訳については、[翻訳の帰属](ATTRIBUTION.md)を参照してください。

## ローカルでの確認

mdBook 0.4.52をインストールします。

```bash
cargo install mdbook --locked --version 0.4.52
```

構造検査とビルドを実行します。

```bash
bash scripts/check-book.sh
mdbook build
```

生成された書籍は `book/index.html` から確認できます。開発中にプレビューする場合は次を実行します。

```bash
mdbook serve --open
```

## ライセンス

原著はMIT LicenseまたはApache License 2.0の条件で提供されています。このリポジトリには原著の[`LICENSE-MIT`](LICENSE-MIT)と[`LICENSE-APACHE`](LICENSE-APACHE)を収録します。

このリポジトリはRustプロジェクトによる公式日本語訳ではありません。
