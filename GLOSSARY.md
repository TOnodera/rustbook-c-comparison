# 用語集

訳語は文脈に応じて調整できますが、同じ概念に複数の日本語を無秩序に当てないよう、この表を基準にします。初出時は必要に応じて英語を併記します。

| 英語 | 基本訳 | 補足 |
|---|---|---|
| ownership | 所有権 | Rustの仕組みを指す場合 |
| owner | 所有者 | 値を所有する変数など |
| borrow / borrowing | 借用 | 動詞では「借用する」 |
| reference | 参照 | `&T`、`&mut T` |
| mutable | 可変 | 必要に応じて「変更できる」と補足 |
| immutable | 不変 | 必要に応じて「変更できない」と補足 |
| binding | 束縛 | 変数束縛 |
| scope | スコープ | 初出時に「有効範囲」と補足可 |
| lifetime | ライフタイム | 初出時に「参照が有効な期間」と説明 |
| trait | トレイト | 日本語へ置き換えない |
| generic | ジェネリック | |
| crate | クレート | パッケージとの違いを文脈で説明 |
| package | パッケージ | Cargoの用語 |
| module | モジュール | |
| pattern matching | パターンマッチング | |
| enum | 列挙型 | Rustの型名としては `enum` を併記 |
| struct | 構造体 | RustとCの違いに注意 |
| smart pointer | スマートポインタ | |
| heap | ヒープ | |
| stack | スタック | |
| move | ムーブ | 「移動」だけに統一しない |
| copy | コピー | `Copy`トレイトとの違いを明示 |
| drop | 破棄 | `Drop`、`drop`はコード表記を維持 |
| closure | クロージャ | |
| iterator | イテレータ | |
| concurrency | 並行処理 | parallelismとの違いに注意 |
| parallelism | 並列処理 | concurrencyとの違いに注意 |
| async / asynchronous | 非同期 | `async`はコード表記を維持 |
| future | Future | 型・トレイトを指す場合はコード表記 |
| stream | ストリーム | |
| unsafe | unsafe | Rustの機能名ではコード表記を維持 |
