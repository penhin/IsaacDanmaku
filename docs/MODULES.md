# IsaacDanmaku 模块说明

> 最后更新：2026-08-11

运行代码位于 `mod/isaac_danmaku/`。

| 模块 | 职责 |
|---|---|
| `main.lua` | 组合模块、加载设置、注册回调；不包含领域判断 |
| `callbacks.lua` | 调用 Isaac API，将回调转换为普通原子事实 |
| `run_context.lua` | 维护本局、楼层、房间、生命与战斗状态 |
| `scenario_detector.lua` | 将事实映射到稳定 A1–I9 场景，并合并重叠生命周期 |
| `rules.lua` | schema v2 内置中文规则和三人格变体 |
| `comment_engine.lua` | 频率、剧透、冷却、次数、稳定选择和最近去重 |
| `danmaku.lua` | 队列、轨道、滚动动画和 UTF-8 字体渲染 |
| `settings.lua` | 默认值、严格归一化、JSON SaveData 持久化 |
| `mcm.lua` | 可选 Mod Config Menu 中文设置注册 |
| `constants.lua` | schema、枚举、场景和渲染常量 |

依赖方向固定为：游戏适配层依赖领域层，领域层不依赖 Isaac 全局对象。`tests/run.lua`通过注入渲染
平台替身测试领域模块，禁止为测试复制另一套业务实现。

字体资源位于 `resources/font/`，由 OFL 许可的 Noto Sans CJK SC 生成当前文本所需字形子集。
