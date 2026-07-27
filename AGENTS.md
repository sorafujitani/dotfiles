# Codex グローバル設定

## 言語設定
全てのプロジェクトで、必ず日本語でレスポンスしてください。

## 基本ルール
- ユーザーへの説明、応答、エラーメッセージは全て日本語で提供
- コード内のコメントは各プロジェクトの規約に従う
- commit messageはシンプルさ, 次に伝達性を重視します
- PR本文、commit message、GitHubコメント、レビューコメントなど、外部に残る文章には `Generated with Codex`、`Co-Authored-By`、AI生成であることを示す署名・フッター・絵文字・定型文を含めない

## Brain（永続メモリ）
`/Users/fujitanisora/brain/` はClaude Code・Codex・Piで共有する永続メモリ。各harnessが`brain/index.md`を自動投入する。

- 着手前に、indexからタスクに関係するノートだけを読む。
- 設計・レビュー・リファクタでは、`brain/principles.md`から該当する原則を読む。
- brainへ残すのは、別タスクでも判断を改善する検証済みの知識だけ。重複は統合し、古い情報は削除する。
- planは一時的な実行状態であり、完了を検証したら再利用可能な学びだけをbrainへ移し、plan本体を削除する。完了planを保存・アーカイブしない。

## Atlantis（適用範囲）
- Atlantis skillは、複数ステップ、原因未特定、設計判断、複数ファイルを含む非trivialな作業でだけ使う。trivialな質問、typo、文言修正、確定済みの単一コマンドでは読まない。
