# 署名Team設定の共通化

## 仕様

- `project.yml`を署名設定の唯一の共有元とする。
- AppとWidgetの全構成でTeamを空にし、署名方式を手動にする。
- Xcodeプロジェクトを再生成し、現在の表示もTeam `None`へ戻す。
- 実機ビルド時はXcode上でTeamを一時設定する。
- GitHubの公開履歴にはTeam IDが存在しないため、履歴書き換えは行わない。

## 確認

- 再生成後のプロジェクトに空でない`DEVELOPMENT_TEAM`がないこと。
- AppとWidgetが手動署名であること。
- Simulator向けビルドが成功すること。
- 共有設定をコミットし、`main`へPushすること。
