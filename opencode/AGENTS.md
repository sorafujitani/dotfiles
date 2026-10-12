# OpenCode グローバル設定

## 言語設定
全てのプロジェクトで、必ず日本語でレスポンスしてください。

## 基本ルール
- ユーザーへの説明、応答、エラーメッセージは全て日本語で提供
- コード内のコメントは各プロジェクトの規約に従う
- commit messageはシンプルさ, 次に伝達性を重視する
- PR本文、commit message、GitHubコメント、レビューコメントなど、外部に残る文章には `Generated with Codex`、`Co-Authored-By`、AI生成であることを示す署名・フッター・絵文字・定型文を含めない

## Brain（永続メモリ）
`/Users/fujitanisora/brain/` は全harnessで共有する永続メモリ。OpenCode pluginが起動時に`brain/index.md`を更新してcontextを自動投入し、tool実行後にindexを自動更新する。

- 着手前に、indexからタスクに関係するノートだけを読む。
- 設計・レビュー・リファクタでは、`brain/principles.md`から該当する原則を読む。
- brainへ残すのは、別タスクでも判断を改善する検証済みの知識だけ。重複は統合し、古い情報は削除する。

## Atlantis（適用範囲）
- Atlantis skillは、複数ステップ、原因未特定、設計判断、複数ファイルを含む非trivialな作業でだけ使う。trivialな質問、typo、文言修正、確定済みの単一コマンドでは読まない。
