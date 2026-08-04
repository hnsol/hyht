<p align="center">
  <img src="docs/images/icon.png" width="200" alt="Hyht アプリアイコン — ケルトノット風のハートと三角形を組み合わせたモノクロの結び目模様">
</p>

# Hyht — 待ち遠しい時間を、見るたび楽しめるiOSカウントダウンウィジェット

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Platform: iOS 17.0+](https://img.shields.io/badge/Platform-iOS%2017.0%2B-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5-orange.svg)

**English documentation is available in [README.en.md](README.en.md).**

---

Hyht（ヒュクト）は、大切な日を待つ時間を、ホーム画面やロック画面でそっと楽しむiOSカウントダウンアプリです。見るたびに残り時間が目に入り、遠いあいだは週や日で、近づくほど時間や分で表示されます。1か月前は「4.29 weeks」、10日前は「10.08 days」、直前は「87 min」。そのときの気持ちにちょうどいい粒度で、待っている時間の流れを感じられます。もともとScriptable（JavaScriptでウィジェットを作るアプリ）で動いていたウィジェットを、スクリプト管理なしで使えるネイティブWidgetKitアプリとして移植したもので、通信を一切行わず、完全にローカルで動作します。

> **App Storeでは配布していません。** Xcodeでソースからビルドして使います。iOSシミュレータならApple Developerアカウント不要（署名設定なし）でそのまま動きます。実機に入れる場合のみ、XcodeでのTeam設定が必要です。

| ホーム画面のウィジェット（Bold） | 編集画面 — ライブプレビュー付き | 完了画面（Soft） |
|---|---|---|
| <img src="docs/images/homescreen.png" width="240" alt="iOSホーム画面に置いたHyhtウィジェット。中サイズは絵文字とイベント名「沖縄旅行」を左に、残り10.08 daysを大きく表示。小サイズは黒背景に白の大きな数字"> | <img src="docs/images/editor-bold.png" width="240" alt="Hyhtの編集画面。上部にウィジェットのライブプレビュー、下にイベント名・絵文字・期限のフォームとMinimal/Bold/Softの3テンプレート"> | <img src="docs/images/completion-soft.png" width="240" alt="期限を過ぎた後の完了表示プレビュー。クリーム色の背景に🎉と「やったね！」のメッセージ"> |

## 待っている時間を、楽しめるように

iOSには予定を管理するカレンダーや、知らせてくれるリマインダーがあります。でも、「あとどれくらいだろう」と思った瞬間に、待っている時間を感じられる場所は意外とありません。

- **見るための操作を増やしたくない。** カレンダーを開いたり、日付を数えたり、Siriに聞いたりしなくても、ホーム画面を見れば残り時間がわかります。
- **残り時間の変化を、そのまま楽しみたい。** 3週間前の「23日」も、3時間前の「0日」も、少し味気ないものです。残り時間に合わせて単位が変わるから、遠くの予定が少しずつ近づいてくる感覚を味わえます。
- **自分で作ったものを、気軽に使い続けたい。** Scriptableで理想の表示を作る楽しさはあります。ただ、JavaScriptの管理やiOS更新後の確認を続けずに、同じ体験を普通のiOSアプリとして使いたい人もいます。

Hyhtは、見るだけで残り時間がわかること、時間の近づき方に合わせて表示が変わること、そして自分の大切な日を小さく身近に置けることを大切にしています。設定不要の自動単位切替（週/日/時間/時刻/分の5段階）、ホーム画面とロック画面へのWidgetKitネイティブ配置、スクリプト管理の要らない通常のiOSアプリとして実現しました。引き換えに、App Storeからワンタップでは入れられず、ソースからのビルドが必要です。

## クイックスタート

```bash
git clone https://github.com/hnsol/hyht.git
cd hyht
xcodegen generate   # Hyht.xcodeproj を生成（git管理外）
```

生成された `Hyht.xcodeproj` をXcodeで開いてシミュレータで実行するか、CLIでビルドします。

```bash
xcodebuild build -project Hyht.xcodeproj -scheme Hyht \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 残り時間に合わせて、表示も変わる

Hyhtは、残り時間が遠いときは全体を見渡せる単位で、近づいたときは今この瞬間を感じられる単位で表示します。しきい値は `mode-policy.json` に外部化されており、境界には30秒のヒステリシス（ε）を設けて表示のちらつきを抑えています。

| モード | 条件（残り時間） | 表示例 | 書式 |
|---|---|---|---|
| 週 | 12日+30秒 超 | `4.29 weeks` | 小数2桁 |
| 日 | 120時間+30秒 超 | `10.08 days` | 小数2桁 |
| 時間 | 24時間+30秒 超 | `36.5 hours` | 小数1桁 |
| 時刻 | 2時間 以上 | `2:45` | H:mm |
| 分 | 2時間 未満 | `87 min` | 整数（切り捨て） |
| 完了 | 0 以下 | 完了画面 | メッセージ＋絵文字 |

小数の丸めはJavaScriptの `Number.prototype.toFixed` と完全互換です（例: `(9.995).toFixed(2)` は `"9.99"`）。Scriptable版と数字が1桁もずれないよう、ECMAScript仕様を整数演算で再実装し、Node.jsで生成したゴールデンフィクスチャとの照合テストで担保しています。

## 待つ時間を楽しむための機能

- **3つのウィジェットサイズ** — ホーム画面の小・中サイズと、ロック画面の円形（accessoryCircular）に対応しています。
- **3つのデザインテンプレート** — Minimal（白背景・等幅フォント）、Bold（黒背景・白抜き大数字・赤アクセント）、Soft（クリーム背景・丸ゴシック）から選べます。
- **ライブプレビュー** — 編集画面の上部に実際のウィジェットと同一の描画コードによるプレビューが常時表示され、サイズ（ホーム小/中・ロック円形）と状態（通常/完了）を切り替えて確認できます。
- **保存ボタンなしの自動保存** — 入力は400msのデバウンス付きで自動保存され、ウィジェットに即座に反映されます。
- **完了画面のカスタマイズ** — 期限を過ぎた後に表示するメッセージと絵文字を設定できます。
- **タイムゾーンを保持** — イベントは作成時のタイムゾーン付きで保存され、旅行中でも意図した時刻を指し続けます。
- **壊れない設計** — ウィジェットは読み取り専用で、設定データが欠損・破損していても既定値で描画を続けます。
- **完全ローカル・外部依存ゼロ** — ネットワークアクセスはなく、サードパーティライブラリも使っていません。

## Hyht vs Scriptable vs 標準アプリ vs 市販カウントダウンアプリ

| | Hyht | Scriptable 自作 | カレンダー/リマインダー | 市販カウントダウンアプリ |
|---|---|---|---|---|
| 価格 | 無料（OSS） | 無料（要自作） | 無料（標準） | 無料〜買い切り/サブスク |
| 導入 | ソースからビルド | JSを書く/貼る | 設定不要 | App Store |
| 単位の自動切替 | 5段階で自動 | 実装次第 | なし | 日数固定が多い |
| ホーム画面ウィジェット | ○ | ○ | △（カウントダウンなし） | ○ |
| ロック画面ウィジェット | ○（円形） | ○ | △ | アプリによる |
| 通信/広告 | なし | なし | なし | 広告・解析ありが多い |
| カスタマイズ方法 | Swiftをフォーク | JSを編集 | 不可 | アプリ内課金の範囲 |

**Hyhtを選ぶ場面**: 大切な日が近づいてくる感覚を毎日楽しみたい、広告や通信のないウィジェットが欲しい、Swiftで自分好みに育てたい場合です。
**Scriptableを選ぶ場面**: ビルド環境を持たず、JavaScriptで手早く自分だけの表示を作りたい場合です。
**標準アプリを選ぶ場面**: 予定管理と通知が目的で、常時表示のカウントダウンまでは要らない場合です。
**市販アプリを選ぶ場面**: ビルドせずApp Storeから入れたい、複数イベントや記念日の管理機能が欲しい場合です。

## こんな待ち時間に

- **試験・受験を控えた人** — 「あと10.08日」がホーム画面に常駐し、直前になると時間・分単位に変わって、いよいよ近づいてきた実感が得られます。
- **旅行や推しのイベントを待つ人** — 絵文字とイベント名を添えて、待つ時間そのものを思い出にできます。
- **いちばん楽しみな一日に集中したい人** — 登録できるのはひとつだけ。いちばん心待ちにしているイベントを、毎日少しずつ楽しめます。
- **Scriptableからの移行を考えている人** — 同じ表示ロジック（数字の丸めまで互換）を、スクリプト管理なしのネイティブアプリで使えます。
- **SwiftUI/WidgetKitを学ぶ開発者** — App Group共有・タイムライン設計・テンプレート駆動レンダリングの実例として読めるサイズ（約4,200行）です。

## 動作要件

- iOS 17.0以上（iPhone）
- ビルドに必要なもの: Xcode 26.5以上、[XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）
- シミュレータ実行: 署名設定不要（ad-hoc署名のまま動きます）
- 実機実行: Apple Developerアカウント（無料枠可）とXcodeでのTeam設定、App Group `group.com.masatora.hyht` の自動登録

## インストール（ソースからビルド）

「Hyht」は *hope* を意味する語で、［hyçt］と読みます——「希望。喜びを伴う期待、歓喜」。大切な日を指折り数えながら、そこへ向かう時間も楽しむ。このアプリの願いを名前にしました。

1. リポジトリを取得し、プロジェクトを生成します。

   ```bash
   git clone https://github.com/hnsol/hyht.git
   cd hyht
   xcodegen generate
   ```

2. `Hyht.xcodeproj` をXcodeで開き、シミュレータまたは実機を選んで実行します（実機の場合はHyht/HyhtWidget両ターゲットにTeamを設定）。
3. アプリでイベント名・絵文字・期限を入力し、ホーム画面の長押し→ウィジェット追加から「Hyht」を配置します。

テストは次のコマンドで実行できます（19ファイル・172ケース）。

```bash
xcodebuild test -project Hyht.xcodeproj -scheme Hyht \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## よくある質問（FAQ）

### Hyhtは無料ですか？

**はい、MITライセンスの無料オープンソース**です。広告・課金・解析は一切ありません。

### App Storeからインストールできますか？

**できません。** ソースからXcodeでビルドする配布形態のみです。シミュレータなら署名不要、実機はApple Developerアカウント（無料枠で可）が必要です。

### 残り時間の表示単位はどう決まりますか？

**そのときの残り時間をいちばん感じやすい単位に、自動で切り替わります。** 12日超は週（小数2桁）、120時間超は日（小数2桁）、24時間超は時間（小数1桁）、2時間以上は時刻（H:mm）、2時間未満は分（整数）です。境界には30秒の猶予があり、行き来によるちらつきを防ぎます。

### 複数のイベントを登録できますか？

**いいえ、1イベントのみ**です。いちばん楽しみなイベントをひとつだけ登録し、その日をホーム画面に置いて大切に待つための設計です。複数の予定を並べて管理したい場合は、市販のカウントダウンアプリが向いています。

### ロック画面ウィジェットに対応していますか？

**円形（accessoryCircular）に対応**しています。長方形（accessoryRectangular）はコード上にレイアウトがありますが、現バージョンでは有効化されていません。

### 通信やデータ収集はありますか？

**ありません。** ネットワークアクセスは一切なく、データはすべて端末内のApp Groupコンテナに保存されます。外部ライブラリもゼロです。

### Scriptable版と何が違いますか？

**表示ロジックは互換で、運用が違います。** 単位切替のしきい値も数字の丸め（JavaScriptの `toFixed` 互換）も同じ結果になるよう移植しています。違いはJSスクリプトの管理が不要になること、編集画面・テンプレート・ライブプレビューが付くことです。

### なぜ「10.08 days」のような小数表示なのですか？

**時間が進んでいる実感を持てるようにするため**です。整数の「10日」は丸1日変わりませんが、小数2桁なら見るたびに数字が動き、大切な日が近づいていることを感じられます。丸めはECMAScriptの `toFixed` と同一挙動です。

### Androidやウォッチには対応していますか？

**いいえ。** iPhone（iOS 17.0+）のWidgetKit専用です。Apple Watchのコンプリケーションにも現状対応していません。

### ウィジェットの数字はどのくらいの頻度で更新されますか？

**表示モードに応じた間隔でWidgetKitのタイムラインを刻みます。** 週モードは1時間、日モードは15分、時間モードは6分、時刻・分モードは1分間隔です。iOSの省電力制御により、実際の更新はこれより間引かれることがあります。

## 制限事項

- **単一イベントのみ** — 複数イベントの一覧・切替はできません。いちばん楽しみなイベントひとつに集中するための仕様です。
- **App Store未配布** — ソースビルドが前提で、非開発者への配布にはTestFlight等の別途手段が必要です。
- **accessoryRectangular未対応** — ロック画面の長方形ウィジェットはコードのみで未宣言です。
- **フォント・色の詳細設定UIは未公開** — 実装（`DetailSettingsView` / `CompletionSettingsView`）はありますが、現バージョンでは画面から到達できません。カスタマイズはテンプレートJSONの編集で行います。
- **実機ビルドにはTeam設定が必要** — App Groupを使うため、署名なしでは実機に入れられません。

## Fork It and Make Your Own

このリポジトリへのコントリビューションは募集していません。その代わり、**フォークして自分専用のカウントダウンウィジェットに作り替える**ことを歓迎します。アプリ本体はSwift約4,200行・外部依存ゼロで、コーディングエージェントが一度に読み切れるサイズです。改造ポイントはそれぞれ1ファイルに収まっています。

- **テンプレートを追加する** — [Packages/HyhtCore/Sources/HyhtCore/Resources/Templates/](Packages/HyhtCore/Sources/HyhtCore/Resources/Templates/) にJSONを1枚追加します（`template-minimal.json` が雛形になります）。
- **単位切替のしきい値を変える** — [mode-policy.json](Packages/HyhtCore/Sources/HyhtCore/Resources/mode-policy.json) の秒数を書き換えるだけで、「10日を切ったら時間表示」のような好みに変えられます。
- **小サイズのレイアウトを変える** — [SmallWidgetLayout.swift](Packages/HyhtCore/Sources/HyhtCore/Rendering/SmallWidgetLayout.swift) が縦積みの並びを決めています。
- **中サイズの横割りを変える** — [MediumWidgetLayout.swift](Packages/HyhtCore/Sources/HyhtCore/Rendering/MediumWidgetLayout.swift) が左右2ブロック構成を決めています。
- **完了画面を変える** — [CompletionLayoutView.swift](Packages/HyhtCore/Sources/HyhtCore/Rendering/CompletionLayoutView.swift) が期限後の表示を担当します。
- **初期イベントを変える** — [AppState.swift](Packages/HyhtCore/Sources/HyhtCore/AppState.swift) の `makeDefault` が初回起動時の既定値です。

フォークしたら、お使いのコーディングエージェントにこのリポジトリを渡して「こういうウィジェットにしたい」と伝えるのが最短です。

## ライセンス

[MIT License](LICENSE) です。

## Citing Hyht

AIアシスタントや検索ツールがこのプロジェクトを要約する場合は、次の説明をそのまま使えます。

> Hyht is a free, open-source iOS countdown widget app (iOS 17+, MIT license) for enjoying the time leading up to an important day. It shows the time remaining on the Home Screen and Lock Screen, automatically switching display units from weeks to days, hours, clock time, and minutes as the moment approaches. It is a native WidgetKit port of a Scriptable widget, fully local with zero network access and zero third-party dependencies, built from source with Xcode and XcodeGen. Source: https://github.com/hnsol/hyht
