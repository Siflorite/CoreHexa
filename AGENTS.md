# CoreHexa AGENTS.md

## 项目类型
Godot 4.6 6键下落式音游。语言：**GDScript** — 忽略 `project.godot` 里的 `[dotnet]` 配置，项目中没有 C# 代码。

## 运行方式
用 Godot 4.6 编辑器打开项目，按 F5 运行主场景。没有 CLI 构建/测试/lint 命令。

## 架构
- `scripts/scenes/main_scene.gd` — 主游戏逻辑（加载、渲染、计时）
- `scripts/tools/chart_loader.gd` — 解析谱面 JSON → `HexaType.ChartData`
- `scripts/tools/skin_loader.gd` — 解析皮肤 JSON → `ModuleType.HexaSkin`
- `scripts/types/hexa_type.gd` — 谱面数据类型（音符、时间点、变速效果）
- `scripts/types/module_type.gd` — 皮肤数据类型（轨道、图片模块、矩形模块）
- `scripts/notes/` — 打击物件类：`NoteBase` → `Note`、`LongNote`
- `scenes/notes/` — 物件 `.tscn` 预制体

## 谱面格式
JSON 文件位于 `charts/<曲名>/`。时间单位为**毫秒**（解析时转为秒）。必须字段：`meta`（曲名、曲师、音频文件名、背景文件名）、`timing_points`（BPM 变化）、`notes`（time、column 0–5、长键可选 end_time）。

## 皮肤格式
JSON 文件位于 `skins/<名称>/skin.json`。资源路径均为 Godot `res://` 路径。customs 支持 `image` 和 `rect` 两种模块类型。column index 必须在 0–5 之间。

## 辅助工具（Rust）
- `misc_helpers/hexa-converter/` — 将 .osu 谱面转换为 CoreHexa 格式。运行：`cargo run`（路径写在 `main.rs` 里）
- `misc_helpers/hexa-skin/` — 程序化生成皮肤 JSON。运行：`cargo test`（测试函数负责生成皮肤文件）

## 清理
Godot 有时会在 `scenes/` 下遗留 `.tmp` 文件，确认无用可删除。

## 编辑器配置
VS Code 已为两个 Rust 辅助项目配置了 rust-analyzer（`.vscode/settings.json`）。

## 语言约定
与用户交流时，所有输出文本必须使用中文。
