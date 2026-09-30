# 验收核验记录

核验日期：2026-09-30（Asia/Shanghai）。对象：E:/moonbit/moon_graph，非父目录已有的 MoonPulse 项目。

| 验收要求 | 状态 | 证据或缺口 |
| --- | --- | --- |
| 1. MoonBit 为主，moonc >= 0.10.14 | 本地满足 | moonc -v = v0.10.14+7d59c7ec9；模型、五种算法、路由、JSON/文本、SVG 全部使用 MoonBit |
| 2. GitHub 公开可访问，提交记录清晰 | 尚未满足 | 新目录仍未纳入 Git 提交；父仓库 origin 指向 code3055/moonpulse，不是本项目已发布的证明 |
| 3. 结构清晰且声明核心功能可用 | 本地满足 | graph/ 库、bridge/ 导出、cli/ I/O 分离；实现及边界见 README 和 COMPATIBILITY |
| 4. README 可复现 | 本地满足 | 说明目标、工具链、构建、API、CLI、示例与限制；命令已实际执行 |
| 5. CI 检查、构建、测试 | 配置完成，远程运行待验 | 已增加父仓库根工作流；另带独立仓库工作流；尚无本项目的 GitHub Actions 成功运行记录 |
| 6. 至少一个可运行示例 | 本地满足 | moon run examples/api；四组 JSON/文本输入和生成 SVG；npm run examples |
| 7. 完整核心路径测试 | 本地满足 | wasm-gc 与 JS 各 378/378，CLI 子进程 38/38；覆盖与限制见 TESTING |
| 8. 发布到 mooncakes.io | 尚未满足 | 未发布；moon.mod 仍为 local/moon_graph，repository 待填，需真实发布命名空间和账户 |
| 9. OSI 开源许可证及参考合规 | 本地满足 | 完整 MIT LICENSE；原创代码，未复制 ELK/elkjs 源码，参考来源和兼容范围已标明 |

## 已执行检查

- moon fmt --check
- moon check --target wasm-gc / --target js
- moon build --target wasm-gc
- moon build --target js --release
- moon test --target wasm-gc / --target js：各 378 项通过
- npm test：38 项通过
- npm run examples：生成四份 SVG
- moon run examples/api：输出包含节点位置与边 sections 的 JSON
- moon package --list：本地归档可生成；提示 repository 尚未填写。此命令不会发布包。

## 仍须完成的外部交付

1. 确定使用当前公开仓库的 moon_graph 子目录，还是独立仓库；只提交本项目及相应工作流，保留其他未提交工作。
2. 将提交推送到 GitHub，核实匿名访问、源码路径和清晰提交记录。
3. 获取本项目 CI 检查、构建、测试全部通过的真实链接。
4. 使用自己的 mooncakes 命名空间，补全发布元数据，发布版本，并从干净项目安装该版本验证。

本记录不是新增报名表或要求再次提交的表格，只是项目内的工程核验文档。验收以公开仓库和已发布包的真实状态为准。
