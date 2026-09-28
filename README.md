# MoonPulse · MoonBit 文本分析器

MoonPulse 是一个不依赖网络和第三方服务的 MoonBit 文本分析器，面向 README、CHANGELOG、Issue 和会议记录等真实文本。

## 已实现功能

- 统计总行数与非空行数
- 统计词数与字符数
- 按词统计频次并输出高频词列表
- 支持空格、制表符、换行和常见标点
- 英文大小写归一化与稳定排序
- JSON 报告输出
- PowerShell 文件分析脚本
- MoonBit 单元测试与 GitHub Actions 自动验证
- 网页端实时文本分析演示

## 安装

需要安装 MoonBit CLI（`moonc` 版本不低于 0.10.14）和 Node.js 20+。

```powershell
# MoonBit CLI 安装说明
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex

cd E:\moonbit
npm ci
```

## 使用方法

运行内置示例：

```powershell
cd E:\moonbit
moon check
moon build
moon test
moon run cmd\moonpulse
```

分析本地文件：

```powershell
.\scripts\moonpulse.ps1 .\README.md
```

输出 JSON，便于接入脚本或 CI：

```powershell
.\scripts\moonpulse.ps1 .\README.md -Json
```

网页演示：

```powershell
npm run dev
```

然后打开终端显示的本地地址，粘贴文本即可实时分析。

## 预期使用场景

1. 发布前检查 CHANGELOG，快速确认版本说明长度和词数。
2. 提交 GitHub Issue 前检查问题描述，避免内容过短或重复堆叠。
3. 编写 README 或会议记录时快速查看行数、字符数和高频词。
4. 在 CI 或脚本中使用 JSON 输出，将文本统计结果交给其他工具继续处理。

## 项目验收对照

- **项目方向**：数据处理 / 开发者工具。
- **MoonBit 为主**：`moonpulse/analyzer.mbt` 包含核心分析逻辑，CLI 与测试均使用 MoonBit。
- **公开记录**：仓库保留持续提交、Issue、PR 与更新记录。
- **可运行**：提供 CLI、文件分析脚本和网页演示。
- **自动验证**：GitHub Actions 执行 `moon check`、`moon build`、`moon test` 和前端构建。
- **开源合规**：MIT License；无移植代码，依赖为空。

## 许可证

MIT
## 深度分析能力

0.2.0 增加了可复用的质量分析模块：

- 段落、标题、句子和平均句长统计
- 词汇多样性与文本密度指标
- 停用词过滤后的关键词提取
- `quality_score`、质量等级、问题编码和阅读建议
- Markdown 大纲提取与章节统计
- Word、Number、URL、Code、Punctuation Token 分类
- JSON、CSV、Markdown 三种报告格式
- 报告结构校验和可追踪的测试场景

核心 MoonBit 源码超过 500 行，测试覆盖空文本、标点、大小写、多段落、关键词、Token 和 Markdown 大纲等路径。

```powershell
# 默认文本报告
moon run cmd\moonpulse

# 文件 JSON 报告
.\scripts\moonpulse.ps1 .\README.md -Json

# 文件 Markdown 报告
$env:MOONPULSE_FORMAT = "markdown"
.\scripts\moonpulse.ps1 .\README.md
```

## CLI 工程能力

```powershell
# 标准输入
Get-Content .\README.md | .\scripts\moonpulse.ps1 -Stdin -Format json

# 批量分析 Markdown 文件
.\scripts\moonpulse.ps1 . -Batch -Config .\moonpulse.default.conf

# 递归扫描子目录
.\scripts\moonpulse.ps1 . -Batch -Recursive -Config .\moonpulse.default.conf

# 重复运行性能基准
.\scripts\benchmark.ps1 -Iterations 25 -Path .\README.md
```

配置文件使用简单的 `key=value` 格式，支持 `format`、`recursive`、`pattern`、`min_words`、`max_keywords` 和 `fail_on_warning`。批处理、标准输入和配置文件位于 PowerShell 适配层，MoonBit 核心保持纯函数接口，便于嵌入其他宿主。
