# Settings Feedback and Mode Selector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 自動保存の通常メッセージを消し、通常／完了の編集切替をセグメント表示にする。

**Architecture:** 既存の `previewCompleted: Bool` を状態の唯一の情報源として維持し、SwiftUIの `Picker` へ直接バインドする。保存処理は変更せず、`EditView` の表示分岐だけを簡素化する。

**Tech Stack:** Swift 5、SwiftUI、XCTest、Xcode 17

## Global Constraints

- `idle`、`saving`、`saved`では保存状態を表示しない。
- `failed`では既存のエラー表示を維持する。
- 初期編集モードは通常とする。
- 保存データ形式は変更しない。

---

### Task 1: 保存状態と編集モードUIの簡素化

**Files:**
- Modify: `App/EditScreen/EditView.swift`
- Modify: `App/EditScreen/PreviewSectionView.swift`
- Modify: `App/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: `EditView.previewCompleted: Bool`、`EditViewModel.saveStatus: SaveStatus`
- Produces: `Picker("Preview Mode", selection: $isCompleted)`による通常／完了切替

- [ ] **Step 1: 現状の回帰基準を確認する**

Run: `xcodebuild test -project Hyht.xcodeproj -scheme Hyht -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: 172 tests pass.

- [ ] **Step 2: 完了トグルをセグメントへ置き換える**

`PreviewSectionView`の`Toggle`を次へ置き換える。

```swift
Picker("Preview Mode", selection: $isCompleted) {
    Text("Active").tag(false)
    Text("Completed").tag(true)
}
.pickerStyle(.segmented)
.labelsHidden()
```

既存の`@Binding var isCompleted: Bool`は維持する。

- [ ] **Step 3: 保存成功メッセージを非表示にする**

`EditView.saveStatusView`を次へ変更する。

```swift
switch viewModel.saveStatus {
case .idle, .saving, .saved:
    EmptyView()
case .failed(let message):
    Label("Save failed: \(message)", systemImage: "exclamationmark.triangle")
        .foregroundStyle(.red)
}
```

- [ ] **Step 4: ローカライズ文字列を追加する**

`App/Resources/Localizable.xcstrings`へ`Active`（通常）と`Preview Mode`（表示モード）を追加し、既存の`Completed`（完了）を使う。

- [ ] **Step 5: ビルドと全テストを実行する**

Run: `xcodebuild test -project Hyht.xcodeproj -scheme Hyht -destination 'platform=iOS Simulator,name=iPhone 17'`

Run: `xcodebuild build -project Hyht.xcodeproj -scheme Hyht -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'`

Expected: tests and build succeed.

- [ ] **Step 6: シミュレータで表示を確認する**

初期状態が「通常」であり、「完了」への切替でフォーム、固定プレビュー、テンプレートカードが同期することを確認する。通常の自動保存後にフッターメッセージが出ず、保存失敗の表示コードが残ることも確認する。

- [ ] **Step 7: コミットする**

```bash
git add App/EditScreen/EditView.swift App/EditScreen/PreviewSectionView.swift App/Resources/Localizable.xcstrings
git commit -m "refactor: simplify editing feedback and mode selection"
```
