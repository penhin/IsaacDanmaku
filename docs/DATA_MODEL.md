# IsaacDanmaku 数据模型

> 最后更新：2026-08-11  
> Comment schema：2

## 原子事实

领域层接收普通 Lua 表：

```lua
{
  kind = "room_entered",
  frame = 120,
  data = { room_index = 7, room_type = "boss", has_enemies = true }
}
```

首版事实类型为`run_started`、`new_level`、`room_entered`、`room_cleared`、`player_damaged`、
`health_snapshot`、`player_died`和`run_ended`。`health_snapshot`用于在受伤回调后的更新帧同步真实生命值；
事实只描述游戏状态，不携带置信度或推测文案。

## RunContext

保存`active`、`run_seed`、`is_continued`、楼层、房间、房间/战斗开始帧、当前生命、累计受伤、
本房间受伤和场景序号。新局完全重置；换层清除房间状态；换房清除本房间状态；终局设为非活动。

## Scenario

```lua
{
  id = "A3",
  frame = 120,
  sequence = 4,
  priority = 80,
  critical = false,
  facts = { room_type = "boss" },
  lifecycle_ids = nil
}
```

`lifecycle_ids`用于表达共享事实，例如`F1`携带`H3`、`C8`携带`H5`，不会触发第二条消息。

## Rule schema v2

规则字段为`schema_version=2`、稳定`id`、`scenario_id`、`priority`、`cooldown_frames`、
`max_per_run`、`spoiler_level`以及按三人格分组的`variants`。规则随 Mod 发布，不支持运行时导入。

文案变体由`run_seed + scenario.sequence + rule.id`稳定选择。最近八条文本参与去重。

## Settings

设置 schema v1：`enabled`、`frequency`、`persona`、`spoiler_level`、`position`、`speed`、
`font_size`、`opacity(0.5–1.0)`和`max_visible(1–4)`。未知字段忽略，非法值恢复对应默认值。
