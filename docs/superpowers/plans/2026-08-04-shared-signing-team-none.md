# Shared Signing Team None Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 全セッションでXcodeのTeamを`None`にする共有設定を導入する。

**Architecture:** Git管理される`project.yml`を署名設定の唯一の共有元にする。AppとWidgetへ空のTeamと手動署名を明示し、Xcodeプロジェクトは再生成する。

**Tech Stack:** XcodeGen、Xcode 17、iOS 17

## Global Constraints

- AppとWidgetの全構成でTeamを空にする。
- 実機ビルド時はXcode上でTeamを一時設定する。
- Git履歴は書き換えない。
- `main`へPushして全セッションへ共有する。

---

### Task 1: 署名設定の共有化

**Files:**
- Modify: `project.yml`
- Regenerate: `Hyht.xcodeproj/project.pbxproj`（Git管理外）

**Interfaces:**
- Consumes: XcodeGenの`targets.*.settings.base`
- Produces: AppとWidgetの空Team・手動署名設定

- [ ] **Step 1: 現状チェックが失敗することを確認する**

Run: `rg -n 'DEVELOPMENT_TEAM|CODE_SIGN_STYLE' project.yml`

Expected: 一致なし。共有設定が未定義であることを確認する。

- [ ] **Step 2: AppとWidgetへ共有署名設定を追加する**

両ターゲットの`settings.base`へ`DEVELOPMENT_TEAM: ""`と`CODE_SIGN_STYLE: Manual`を追加する。

- [ ] **Step 3: Xcodeプロジェクトを再生成する**

Run: `xcodegen generate`

Expected: `Hyht.xcodeproj`が正常に生成される。

- [ ] **Step 4: 生成結果を検証する**

Run: `rg -n 'DEVELOPMENT_TEAM|CODE_SIGN_STYLE' Hyht.xcodeproj/project.pbxproj`

Expected: Teamは空文字、署名方式はManualのみ。

- [ ] **Step 5: Simulatorビルドを検証する**

Run: `xcodebuild build -project Hyht.xcodeproj -scheme Hyht -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 6: 設定をコミットする**

```bash
git add project.yml
git commit -m "chore: keep signing team unset"
```

- [ ] **Step 7: mainへPushする**

Run: `git push origin main`

Expected: GitHubの`main`が新しい設定コミットを指す。
