# 验收核验记录

核验日期：2026-09-30（Asia/Shanghai）。对象：E:/moonbit/moon_graph，非父目录已有的 MoonPulse 项目。

| 验收要求 | 状态 | 证据或缺口 |
| --- | --- | --- |
| 1. MoonBit 为主，moonc >= 0.10.14 | 本地满足 | moonc -v = v0.10.14+7d59c7ec9；模型、五种算法、路由、JSON/文本、SVG 全部使用 MoonBit |
| 2. GitHub 公开可访问，提交记录清晰 | 已确认 | Moon Graph 已通过 bffde2d、6956b9a 提交上传到 code3055/moonpulse；用户已确认仓库为 Public |
| 3. 结构清晰且声明核心功能可用 | 本地满足 | graph/ 库、bridge/ 导出、cli/ I/O 分离；实现及边界见 README 和 COMPATIBILITY |
| 4. README 可复现 | 本地满足 | 说明目标、工具链、构建、API、CLI、示例与限制；命令已实际执行 |
| 5. CI 检查、构建、测试 | 用户已确认通过 | 用户已确认 Verify Moon Graph 显示绿色对勾；后续提交仍须单独检查其运行结果 |
| 6. 至少一个可运行示例 | 本地满足 | moon run examples/api；四组 JSON/文本输入和生成 SVG；npm run examples |
| 7. 完整核心路径测试 | 本地满足 | wasm-gc 与 JS 各 382/382，CLI 子进程 38/38；覆盖与限制见 TESTING |
| 8. 发布到 mooncakes.io | 已发布并验证 | code3055/moon_graph@0.1.0 注册中心记录可查；独立项目成功下载安装，JS 与 wasm-gc 使用方测试各 6/6 通过 |
| 9. OSI 开源许可证及参考合规 | 本地满足 | 完整 MIT LICENSE；原创代码，未复制 ELK/elkjs 源码，参考来源和兼容范围已标明 |

## 已执行检查

- moon fmt --check
- moon check --target wasm-gc / --target js
- moon build --target wasm-gc
- moon build --target js --release
- moon test --target wasm-gc / --target js：各 382 项通过
- npm test：38 项通过
- npm run examples：生成四份 SVG
- moon run examples/api：输出包含节点位置与边 sections 的 JSON
- moon package --list：核验本地归档内容；此命令不会发布包。

## mooncakes 发布结果

- 发布时间：2026-09-30 16:19:42（Asia/Shanghai）。
- 正式发布命令返回 Server status: 200 OK，精确版本查询返回 success，版本未撤回。
- 上传归档 SHA256 与注册中心 checksum 一致。
- 在仓库外新建项目，通过 moon add 下载 0.1.0，未使用本地路径覆盖；布局、JSON、SVG、非法输入、算法列表和输入不变性测试在两个目标上均通过。
- 完整证据见 [RELEASE-0.1.0.md](RELEASE-0.1.0.md)。

## GitHub 后续核验

发布配置和核验记录须同步到公开仓库，并检查该提交对应的 CI 结果；此前已通过的工作流结果不能代替后续提交的结果。

本记录不是新增报名表或要求再次提交的表格，只是项目内的工程核验文档。验收以公开仓库和已发布包的真实状态为准。
