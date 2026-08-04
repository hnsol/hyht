# Repository Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** ローカル作業用レビュー資料を公開リポジトリから分離し、`.gitignore`を分類して保守しやすくする。

**Architecture:** レビュー資料9件を`.local/reviews/`へ移動し、`.local/`を丸ごとGit無視対象にする。既存の生成物・Xcode関連のignoreは維持し、履歴は改変しない。

**Tech Stack:** Git、Markdown、`.gitignore`

## Global Constraints

- レビュー資料はローカルに保持する。
- 既存Git履歴は書き換えない。
- ソースコード、テスト、公開ドキュメントは変更しない。

---

### Task 1: レビュー資料のローカル移動

**Files:**
- Move: `CC_REVIEW_FEEDBACK.md` → `.local/reviews/CC_REVIEW_FEEDBACK.md`
- Move: `CC_REVIEW_FEEDBACK_ROUND2.md`〜`CC_REVIEW_FEEDBACK_ROUND9.md` → `.local/reviews/`

- [ ] **Step 1: 移動先を作成する**

```bash
mkdir -p .local/reviews
```

- [ ] **Step 2: 9件を移動する**

```bash
mv CC_REVIEW_FEEDBACK.md CC_REVIEW_FEEDBACK_ROUND{2,3,4,5,6,7,8,9}.md .local/reviews/
```

- [ ] **Step 3: 移動結果を確認する**

```bash
test "$(find .local/reviews -maxdepth 1 -type f -name 'CC_REVIEW_FEEDBACK*.md' | wc -l | tr -d ' ')" = 9
test ! -e CC_REVIEW_FEEDBACK.md
```

### Task 2: `.gitignore`を整理する

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: 既存ルールを分類・更新する**

`.gitignore`を次の内容に整理する。

```gitignore
# OS
.DS_Store

# Xcode / Swift build artifacts
*.xcodeproj
*.xcworkspace
build/
build17/
DerivedData/
.swiftpm/
*.xcuserstate
xcuserdata/
Packages/HyhtCore/.swiftpm/

# Local worktrees and tool state
.worktrees/
.superpowers/
.claude/

# Local-only review and scratch materials
.local/

# Generated local plist files
App/Info.plist
Widget/Info.plist
```

- [ ] **Step 2: ignore判定を確認する**

```bash
git check-ignore -v .local/reviews/CC_REVIEW_FEEDBACK.md
git check-ignore -v build/ App/Info.plist
```

### Task 3: Git差分と回帰を検証する

**Files:**
- Test: Git状態と追跡対象

- [ ] **Step 1: レビュー資料が追跡対象でないことを確認する**

```bash
test -z "$(git ls-files '.local/reviews/CC_REVIEW_FEEDBACK*.md')"
```

- [ ] **Step 2: ルートのレビュー資料がなく、ローカル資料が存在することを確認する**

```bash
test "$(find .local/reviews -maxdepth 1 -type f -name 'CC_REVIEW_FEEDBACK*.md' | wc -l | tr -d ' ')" = 9
test -z "$(find . -maxdepth 1 -type f -name 'CC_REVIEW_FEEDBACK*.md')"
```

- [ ] **Step 3: 差分の整合性を確認する**

```bash
git diff --check
git status --short
git diff --stat
```

- [ ] **Step 4: 変更をコミットする**

```bash
git add .gitignore
git add -u CC_REVIEW_FEEDBACK.md CC_REVIEW_FEEDBACK_ROUND2.md CC_REVIEW_FEEDBACK_ROUND3.md CC_REVIEW_FEEDBACK_ROUND4.md CC_REVIEW_FEEDBACK_ROUND5.md CC_REVIEW_FEEDBACK_ROUND6.md CC_REVIEW_FEEDBACK_ROUND7.md CC_REVIEW_FEEDBACK_ROUND8.md CC_REVIEW_FEEDBACK_ROUND9.md
git commit -m "chore: separate local review materials"
```
