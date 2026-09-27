# MoonPulse · MoonBit 文本分析器

MoonPulse 是本期黑客松项目：一个不依赖网络和第三方服务的 MoonBit 文本分析器。它面向发布说明、Issue、会议记录等真实文本，输出行数、词数、字符数、非空行数和高频词，帮助开发者在公开发布前快速检查内容。

## 为什么做它

很多开源项目在提交 README、CHANGELOG 或 Issue 前，需要一个轻量的内容检查工具。MoonPulse 选择数据处理方向，核心逻辑全部由 MoonBit 实现，CLI 可以在 CI 或本地直接运行。

## 运行

需要安装 [MoonBit](https://www.moonbitlang.com/)。

```bash
moon test
moon run cmd/moonpulse
```

项目页面中的“在线演示”使用同一套规则展示结果；正式 CLI 版本可直接接入仓库的 CI 流程。

## 参赛验收对照

- **MoonBit 为主**：`moonpulse/analyzer.mbt` 包含核心分析逻辑，CLI 与测试均为 MoonBit。
- **公开记录**：仓库保留持续提交、Issue、PR 与更新日志。
- **可运行**：提供 CLI、示例输入和 `moon test` 测试。
- **实质新增**：本期新增分词、统计、排序与测试覆盖。
- **开源合规**：MIT License；无移植代码，依赖为空。
- **AI 可解释**：AI 仅用于整理页面与测试草稿，算法取舍、边界行为和验证由参赛者确认。

## 许可证

MIT
