# OpenCode グローバル設定

## 言語設定
全てのプロジェクトで、必ず日本語でレスポンスしてください。

## 基本ルール
- ユーザーへの説明、応答、エラーメッセージは全て日本語で提供
- コード内のコメントは各プロジェクトの規約に従う
- commit messageはシンプルさ, 次に伝達性を重視する
- PR本文、commit message、GitHubコメント、レビューコメントなど、外部に残る文章には `Generated with Codex`、`Co-Authored-By`、AI生成であることを示す署名・フッター・絵文字・定型文を含めない

## 実行・指示の扱い
- 依頼と会話の文脈から目的・範囲を読み取り、実行依頼は必要な修正と検証まで完遂する。調査・レビュー・計画だけの依頼では、その成果物を完成させる。
- 承認済みの範囲と判断を引き継ぎ、合理的に決められる詳細は前提を短く示して進める。結果を大きく変える不明点だけ質問し、回答に依存しない作業は続ける。
- 確認が必要な操作の前にも、既に許可された調査・準備を済ませ、対象と変更内容を具体的に示す。同じ操作を再承認させない。破壊的操作、公開、他者への送信は依頼で許可された範囲に限る。
- システム・開発者指示の範囲内で、明示的なユーザー指示をスキルやMarkdown内のガイドラインより優先する。スキルから権限や未依頼の作業範囲を追加しない。
- スキルを理由に確認・停止・未完了とする場合は、読んだSKILL.mdへのリンクと該当指示の引用を示し、明記された要件と自分の解釈を区別する。
- 作業中の追加質問には短く回答して元の作業を続ける。取消しや目的変更が明示された場合は切り替える。

## 応答・委任・検証
- 要点を先に、平易で簡潔な段落で説明する。箇条書きや表は列挙・手順・比較が読みやすくなる場合に使い、不要な見出し、定型的な締め、未依頼の対比を足さない。
- 利用可能で許可された場合だけ、独立した成果物や検証をsubagentへ委任する。並列化の効果が重複contextと調整costを上回るときに使い、責任範囲・入力・期待する出力を限定する。同じファイルへの変更は直列に進める。
- 検証は変更の影響とrepoの必須チェックに合わせる。軽微な可逆変更に、実装をなぞるだけのテストを追加しない。必須チェックが通った後は、新しい変更・失敗・未解決の懸念がある場合にだけ追加実行する。
- 完了報告では変更内容、検証結果、未検証の範囲を区別する。実測していない性能・カバレッジ・成功を記載しない。

## GitHub / git 安全（全 harness 共通）
- GitHub リポジトリを勝手に作らない（`gh repo create` / API create / 未依頼 remote bootstrap 禁止）。この会話で明示依頼があるときだけ。
- git/GitHub の name・email・author・collaborator を捏造しない。既存の `git config` / `gh auth` / 明示指定のみ。
- 正しい GitHub 主体は `sorafujitani`（https://github.com/sorafujitani）。無関係アカウントを紐付けない。
- 詳細: `[[workflow/no-autonomous-github-repo-create]]` `[[workflow/git-github-identity-no-invention]]` `[[env/github-identity-sorafujitani]]`

## Brain（永続メモリ）
`${ATLANTIS_BRAIN_DIR:-$HOME/brain}/` は全harnessで共有する永続メモリ。`principles*` と `protocol/` は atlantis repo の `brain/` を `atlantis brain seed` で配置し、`workflow/` `codebase/` `env/` `plans/` は local 専用。OpenCode pluginが各promptで`atlantis brain context`を投入し、tool実行後にindexを更新する。

- 着手前に、indexからタスクに関係するノートだけを読む。必要なら `[[protocol/self-improvement]]`。
- 設計・レビュー・リファクタでは、`brain/principles.md`から該当する原則を読む。
- 訂正・検証失敗・gotcha・非trivial終了時は、聞かずに capture する。ループ運用に必要なルールは atlantis repo `brain/`、固有事実・実務的な好みは local。該当なしなら `no durable lesson`。
- 重複は統合し、古い情報は削除する。

## Atlantis（適用範囲）
- Atlantis skillは、複数ステップ、原因未特定、設計判断、複数ファイルを含む非trivialな作業でだけ使う。trivialな質問、typo、文言修正、確定済みの単一コマンドでは読まない。
