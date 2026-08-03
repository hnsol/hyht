# Hyht 表示改善プランへの第7回フィードバック

## 差分確認

同じプランファイルだが、内容は初版実装計画から、初版完成後の表示改善計画へ全面的に更新されている。

以下の原因分析と方針は妥当。

- ホームWidgetの背景を`containerBackground(for: .widget)`へ一本化する
- systemMediumを左右2ブロックの横割りへ変更する
- accessoryCircularは中央固定として無効なサイズ別配置UIを削除する
- bundled JSONとコード内fallbackを同時に更新する
- accessoryCircularで単位を常時表示する

ただし、実装開始前に以下をプランへ反映すること。

## 必須修正1: accessoryRectangularのalignment適用方法を具体化する

`VStack(alignment: .leading)`を`style.alignment`へ置き換えるだけでは不十分。
`VStack`の`alignment`は内部の子Viewを揃えるだけで、レイアウト全体をWidgetの左・中央・右へ移動しない。現在は親の`ZStack`内で中央配置されるため、leading/trailingを選んでも期待どおり移動しない可能性がある。

通常表示では少なくとも次の両方を行うこと。

```swift
VStack(alignment: style.alignment.horizontalAlignment, spacing: 2) {
    // ...
}
.frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
```

必要に応じて各行の`HStack`にも`frame(maxWidth: .infinity, alignment:)`を適用し、テキストの揃え方もalignmentと一致させる。

また、`CompletionLayoutView.rectangularLayout`にも`.leading`のハードコードがある。通常表示だけ直すと、期限到達後に配置設定が無効へ戻る。完了表示のaccessoryRectangularも同じalignment規則へ統一すること。

確認項目へ以下を追加する。

- accessoryRectangularの通常表示でleading/center/trailingがそれぞれ反映される
- accessoryRectangularの完了表示でもleading/center/trailingが反映される
- accessoryCircularは通常・完了とも中央固定

## 必須修正2: Smallの「全要素表示」を条件付きにしない

現プランの「フォントサイズ調整が必要なら微調整」は未確定事項であり、実装担当が完了判定できない。systemSmallへ4要素を縦積みすると、Bold/Softの既定フォント、padding、spacingの組み合わせによって切れや過度な縮小が起き得る。

次のいずれかをプランで確定すること。

1. 各テンプレートのsystemSmallで使用する具体的なフォントサイズ・padding・spacingを決める
2. Small専用の縮小規則を実装し、4要素が必ずフレーム内へ収まるようにする

少なくとも初版の受入範囲を「3つの内蔵テンプレートの既定値」と明記し、158×158のプレビューで次を確認する。

- emoji、eventName、primaryValue、unitがすべて見える
- primaryValueが不自然に極小化されない
- eventNameは1行で安全に省略される
- 要素が上下でクリップされない

ユーザーが極端なフォントサイズへ上書きした場合まで保証しないなら、その範囲は明記する。

## 必須修正3: テンプレートテストをflagsだけで終わらせない

`shows... == true`でも、`elementOrder`に要素が無ければSmallでは表示されない。次を検証する自動テストを追加すること。

- systemSmallの`elementOrder`に`emoji`、`eventName`、`primaryValue`、`unit`が各1回含まれる
- accessoryCircularは`showsUnit == true`で、データ定義も`[primaryValue, unit]`
- accessoryCircularのalignmentは全テンプレートでcenter
- Bold systemMediumのalignmentはcenter
- accessoryRectangularはname/emoji/unitがすべてtrue
- 3つのbundled templateだけでなく`WidgetTemplate.fallback`も同じ方針を満たす

mediumとaccessoryRectangularで`elementOrder`を使用しないなら、その事実をテスト名またはコメントで明示し、表示要件はレイアウト側の目視確認で担保する。

## 追加修正

### 背景修正の対象を明確にする

`CompletionLayoutView`自体には背景描画がなく、背景は`CountdownWidgetView`外周のZStackだけである。プランの「完了レイアウト側にもあれば」という条件文は削除し、通常・完了の双方が同じ外周背景条件を通ることを明記する。

関連するdoc commentも、現在の「home-screen families self-paint regardless of context」という説明から新仕様へ更新する。

### 検証端末名を統一する

コマンドは`iPhone 17`、目視条件は`iPhone 17 Pro`になっている。実際に使用するSimulator名へ統一する。

### 目視確認を追加する

- ホームSmall/Mediumの通常表示と完了表示で二重背景がない
- systemMediumのleading/center/trailingで2ブロック全体が期待位置へ移動する
- 長いイベント名、最大桁のweek/day/hour値でも横割りが崩れない
- accessoryRectangularの通常・完了表示で配置変更が反映される

## 判定

方向性は正しい。上記3つの必須修正をプランへ反映後、実装開始可能。
