# 变更日志

## [Unreleased]

### Added

- 新增可直接发布到 Steam Workshop 的 Repentance+ Lua Mod。
- 新增 M0 回调、RunContext、A1–I9场景映射和 schema v2 内置规则。
- 新增三人格中文滚动弹幕、轨道调度和布局设置。
- 新增可选“Mod配置菜单（中文版）”兼容及 SaveData 持久化。
- 新增基于 Noto Sans CJK SC 的 OFL 中文位图字体子集。
- 新增不依赖游戏运行时的 Lua 自动化测试。

### Fixed

- 归一化换层时`MC_POST_NEW_ROOM`早于`MC_POST_NEW_LEVEL`的原生回调顺序，避免重复播报。
- 配置菜单异常时保留核心 Mod，并让透明度滑杆完整覆盖 50%–100%。

### Security

- 当前版本不联网、不截图、不使用`--luadebug`，也不加载外部可执行代码。
