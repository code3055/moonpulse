# MoonPulse · MoonBit 文本分析器

MoonPulse 是一个不依赖网络和第三方服务的 MoonBit 文本分析器，面向 README、CHANGELOG、Issue 和会议记录等真实文本。

## 已实现功能

- 统计总行数与非空行数
- 统计词数与字符数
- 按词统计频次并输出高频词列表
- 空文本与多行文本处理
- MoonBit 单元测试覆盖核心场景
- 网页端提供实时文本统计演示

## 预期使用场景

1. 发布前检查 CHANGELOG，快速确认版本说明长度和词数。
2. 提交 GitHub Issue 前检查问题描述，避免内容过短或重复堆叠。
3. 编写 README 或会议记录时快速查看行数、字符数和高频词。

## 运行

需要安装 [MoonBit](https://www.moonbitlang.com/)。

```powershell
cd E:\moonbit
moon check
moon test
moon run cmd\moonpulse
```

当前 CLI 演示使用内置样例文本；网页端可直接粘贴任意文本进行实时分析。文件路径读取将作为下一阶段 CLI 增量功能，核心分析 API 已与输入来源解耦。

## 参赛验收对照

- **项目方向**：数据处理 / 开发者工具。
- **MoonBit 为主**：`moonpulse/analyzer.mbt` 包含核心分析逻辑，CLI 与测试均使用 MoonBit。
- **公开记录**：仓库保留持续提交、Issue、PR 与更新日志。
- **可运行**：提供 CLI、在线演示和 `moon test` 测试。
- **实质新增**：本期新增分词、频次统计、行字符统计和测试覆盖。
- **开源合规**：MIT License；无移植代码，依赖为空。
- **AI 可解释**：AI 仅用于页面整理和测试草稿，算法取舍、边界行为和验证由参赛者确认。

## 许可证

MIT
