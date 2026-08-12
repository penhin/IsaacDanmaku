# IsaacDanmaku

IsaacDanmaku 是面向 Windows Steam 版《以撒的结合：忏悔+》单机玩法的中文局内弹幕 Mod。
它直接消费游戏回调，在本地判断场景并显示从右向左滚动的公式弹幕；不截图、不联网，也不需要桌面程序。

```text
Repentance+ 回调 → 原子事实 → RunContext → 场景 ID → 内置规则 → 游戏内弹幕
```

## 当前能力

- 新局/续局、换层、普通战斗、Boss、清房、受伤、死亡和通关；
- 宝箱房、商店、恶魔房、天使房、献祭房和隐藏房；
- 冷静军师、幽默损友和温暖鼓励三种人格；
- 冷却、次数限制、稳定文案选择和最近文本去重；
- 顶部/中部/底部、速度、字号、透明度和同屏数量设置；
- 可选兼容“Mod配置菜单（中文版）”，未安装时使用默认设置。

IsaacDanmaku 不支持 Repentance+ 在线模式，因为在线玩法要求禁用所有 Mod。

## 开发与验证

Workshop 发布目录是 `mod/isaac_danmaku/`。纯逻辑测试不依赖游戏运行时：

```bash
lua tests/run.lua
```

CI 使用 Lua 5.3 执行测试。实机验收步骤见 [TEST_CASES.md](docs/TEST_CASES.md)。

## 本地热重载

开发时可把 `mod/isaac_danmaku` 目录联接到游戏的 `mods/isaac_danmaku`。修改 Lua 后，
在游戏调试控制台执行 `luamod isaac_danmaku` 即可重新载入；局内重载会静默恢复当前楼层和房间上下文。

重载后可使用开发命令快速预览弹幕：

```text
idm test A3
idm test all
idm list
idm status
idm clear
```

常用预览也支持短写：`idm A3`、`idm all`。

如果当前 Mod 组合拦截了自定义命令，可使用游戏内置 `lua` 命令作为等价入口：

```text
lua IsaacDanmakuDev("test A3")
lua IsaacDanmakuDev("test all")
lua IsaacDanmakuDev("status")
lua IsaacDanmakuDev("clear")
```

`idm test`只注入显示预览，不修改真实 RunContext、计数或规则冷却；真实事件链仍由自动化和实机流程验证。

## 文档

- [架构](docs/ARCHITECTURE.md)
- [模块](docs/MODULES.md)
- [数据模型](docs/DATA_MODEL.md)
- [设计决策](docs/DECISIONS.md)
- [事件目录](docs/EVENT_CATALOG.md)
- [测试用例](docs/TEST_CASES.md)
- [变更日志](CHANGELOG.md)

功能修改必须同步更新相关文档和 `CHANGELOG.md`。场景 ID 一旦发布不得复用。
