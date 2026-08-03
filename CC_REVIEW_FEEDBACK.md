# Hyht 実装プランへのフィードバック

着手前に、以下をプランへ反映してください。

## 必須修正

### 1. 30秒マージンの説明を修正する

Scriptable実装は次の条件です。

- `remaining > 12日 + 30秒`: week
- `remaining > 120時間 + 30秒`: day
- `remaining > 24時間 + 30秒`: hour
- `remaining >= 120分`: clock
- `remaining > 0`: min
- `remaining <= 0`: done

したがって、次モードへの切替は基準境界の「30秒後」ではなく「30秒前」です。Scriptable互換を優先するなら、プランの「境界時刻＋30秒経過後に次モードへ切替」を「基準境界の30秒前に次モードへ切替」へ修正してください。

境界テストには±1秒に加え、次の完全一致を含めてください。

- 12日30秒
- 120時間30秒
- 24時間30秒
- 120分
- 0秒

### 2. タイムライン生成規則を矛盾なく定義する

「全モード境界を必ず含める」と「上限到達時に `.after(lastEntry.date)`」は両立しません。遠い将来の境界をエントリーへ追加すると、それが最終エントリーとなり、途中の再生成が止まる可能性があります。

次の規則へ変更してください。

- 300件はAppleの仕様上限ではなく、アプリ独自上限と明記する
- 現在から連続する更新エントリーを最大300件生成する
- 生成期間内に存在するモード境界だけ、正確な時刻で追加する
- 再生成日時は、最後の通常更新エントリーより後の時刻にする
- 分単位エントリーは時計の分境界に整列させる
- 完了後はdoneエントリー1件と `.never` を返す
- WidgetKitの更新は厳密な時刻保証ではないため、許容する表示遅延を受入条件に定める

### 3. パリティの対象を限定する

新仕様はScriptable版から次の表示を変更します。

- 円形で短縮表記を許容する
- 単位表記をテンプレート設定にする
- 完了画面をユーザー設定に置換する
- ホーム画面small/mediumを新規追加する

そのため、「同一入力なら常に同一表示文字列」という受入条件は成立しません。次のいずれかへ変更してください。

- `CountdownModePolicy`と数値計算のみScriptable互換とする
- Legacyテンプレート使用時のaccessoryCircular/accessoryRectangularに限り、表示文字列まで互換とする

Scriptable版にはホーム画面small/mediumの実装がないため、これらはパリティ対象外と明記してください。

### 4. XcodeGenとSwiftPMの構成を明確にする

ローカルSwiftPMを採用する場合、構成を次のように区別してください。

- XcodeGenターゲット: `Hyht`、`HyhtWidget`、必要なXCTestターゲット
- SwiftPM Product: `HyhtCore`
- SwiftPM Test TargetまたはXcode Test Target: `HyhtCoreTests`

併せて以下を定義してください。

- 内蔵JSONテンプレートをSwiftPM resourceとして登録し、`Bundle.module`で読み込む
- テスト対象schemeとSimulator destination
- 生成した `.xcodeproj` をGit管理するか否か
- 使用するXcodeGenの対応バージョン
- App GroupをDeveloper Portal側でも有効化する手順
- 実機署名前に必要なBundle ID、Team、Provisioning設定

### 5. 実装プランを単独で実行可能にする

「元プラン通り」「元プラン§13」「会話履歴参照」だけでは、第三者が完了条件や対象外を確定できません。実装担当へ渡す最終版では、元プランと統合し、全フェーズ・完了条件・受入チェックリストを本文へ含めてください。

## 追加修正

### Scriptable互換

- 元コードの定数名・コメントは実値と一致していないため、移植時は数値を正とする
  - `TEN_DAYS_MS`の実値は12日
  - `HUNDRED_HOURS_MS`の実値は120時間
  - `HUNDRED_MINUTES_MS`の実値は120分
- Swift側では`TWELVE_DAYS`、`ONE_HUNDRED_TWENTY_HOURS`等、実値と一致する名称にする
- `toFixed`互換では丸めだけでなく、末尾ゼロと小数点を含む文字列を検証する
  - 例: `1.20`、`120.0`
- 代表値と丸め境界値のゴールデンテストを追加する

### 保存・更新

- `AppState`にもschemaVersionとマイグレーション方針を追加する
- 未知の新しいschemaVersionと破損データを区別する
- Repositoryから`WidgetCenter`を直接呼ばず、アプリ側の保存Coordinatorからタイムラインを再読み込みする
- Widget kindが1つなら、原則として`reloadTimelines(ofKind:)`を使う

### 表示・設定

- 完了画面の配色もホーム画面限定と明記する
- 「フォント変更」の範囲を確定する。現プランにはフォントサイズしか記載されていないため、書体・weight・designを編集可能にするか明記する
- 「中サイズの自由配置」を、座標、アンカー、範囲、衝突処理を含むデータ仕様として定義する
- ロック画面だけでなく、ホーム画面でもOSのrendering modeにより色が変更される場合があるため、full-color、accented、vibrant相当を確認する
- Dynamic Typeはサイズ別の上限とレイアウト崩れ時の処理を定義する
- VoiceOver用の単位・期限・完了メッセージはローカライズされた読み上げ文を別途生成する

### Deep Link

`widgetURL`だけでなく、以下を追加してください。

- URL SchemeまたはUniversal Linkの登録
- 起動時の遷移先
- 不正・未知URLの処理
- ウィジェットからの起動テスト

## 完了条件への追加

- 各モード境界の完全一致・±1秒テストが成功する
- Legacy互換の対象範囲について表示文字列のゴールデンテストが成功する
- 300件を超える長期カウントダウンでも、タイムラインが途中で停止しない
- 保存後に対象Widget kindが更新される
- 完了後は不要なタイムライン再生成を行わない
- full-color、accented、vibrant相当で文字が判読可能である
- URLからアプリを正常に起動できる
- App Groupを使ったアプリ・Widget間の読み書きを実機またはSimulatorで確認できる
