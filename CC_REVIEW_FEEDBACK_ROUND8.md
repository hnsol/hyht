# Hyht 表示改善プランへの第8回フィードバック

## 結論

第7回レビューの指摘は、申告どおりほぼ反映されている。背景、通常時の長方形alignment、Small既定値、テンプレートテストの方針は実装可能。

ただし、完了表示のalignmentについて、現在の`StyleResolver`との整合を1点修正すること。

## 必須修正: 完了表示のalignmentの設定元を明記する

現在の`StyleResolver.resolve(...)`は次の順でalignmentを解決する。

1. テンプレートのfamily alignment
2. 通常設定の共通alignment override
3. 通常設定のfamily別alignment override
4. テンプレートのcompletion alignment
5. ユーザーのcompletion alignment

内蔵テンプレートのcompletion alignmentはcenterであるため、期限到達後は通常設定のfamily別alignmentが上書きされる。したがって、`CompletionLayoutView.rectangularLayout`で`style.alignment`を参照するだけでは、詳細設定の「Lock Rectangular」配置を完了画面へ引き継げない。

初版では次の仕様に確定することを推奨する。

- 通常表示の配置: 詳細設定の共通＋family別alignmentで制御
- 完了表示の配置: 完了画面設定のalignmentで制御
- 完了画面設定は全family共通
- accessoryCircularだけは通常・完了ともalignment設定を無視して中央固定
- Completion画面のalignment UIには「Lock Circularでは中央固定」の注記を表示する

目視確認も設定元を分ける。

- 通常accessoryRectangular: 詳細設定のLock Rectangularをleading/center/trailingへ変更して確認
- 完了accessoryRectangular: 完了画面設定のAlignmentをleading/center/trailingへ変更して確認
- 詳細設定のfamily別alignmentが完了画面にも引き継がれる、とは記載しない

もし通常のfamily別alignmentを完了画面にも引き継ぐ仕様にするなら、`CompletionStyle`の優先順位またはデータモデル変更が必要になるため、単なるView修正として扱わないこと。

## 軽微な修正: `fixedSize`の説明を訂正する

`fixedSize(horizontal: false, vertical: true)`は上下クリップを防ぐAPIではない。Textを理想高さに固定するため、親フレームを超えれば逆にオーバーフローし得る。

- 「fixedSizeでクリップを防ぐ」という保証表現を削除する
- 既定値が収まることは、確定フォント値＋158×158の目視確認で担保する
- `fixedSize`を採用する場合は、圧縮を避けるための実装詳細として扱い、クリップ防止とは説明しない

## 判定

上記を局所修正後、実装開始可能。全面再レビューは不要。
