# 验证与复现

在 moon_graph 目录运行：

~~~sh
moon fmt --check
moon check --target wasm-gc
moon check --target js
moon test --target wasm-gc
moon test --target js
moon build --target wasm-gc
npm run build
npm test
npm run examples
moon run examples/api
~~~

测试无额外 npm 依赖。MoonBit 使用其自带核心库与测试框架，CLI 测试使用 Node 内置 node:test 和真实子进程。

## 核心场景

graph/scenarios_test.mbt 的生成矩阵覆盖 5 算法 × 4 方向 × 8 图族 × 2 参数变体，共 320 个独立命名场景。图族包含链、星、环、断开分量、二叉树、菱形、端口图与复合节点；两个变体改变尺寸、图规模、种子和路由方式。公共场景检查函数验证结构保留、输入不变、确定性、有限坐标、路由端点以及适用的布局约束。生成器只负责生成测试声明，断言在 MoonBit 中实际执行。

graph/validation_test.mbt 覆盖错误选项、尺寸、引用、重复 ID、图规模和输入不变等边界。graph/io_test.mbt 覆盖 JSON / 文本解析、往返输出、非法字段、Unicode 和 SVG 转义。实际总数以 moon test 的报告为准。

重新生成矩阵：node scripts/generate-tests.mjs，然后运行 moon fmt 并执行两后端测试。不要仅以生成数量作为质量证明，应保留各场景所检查的不变量。

## CLI 集成验证

cli/cli.test.mjs 启动真实 CLI，检查 JSON / 文本、stdin / 文件输入、五种算法、四个方向、根选项覆盖、层级端口、自环、pretty、输出文件、UTF-8、SVG 安全转义，以及错误参数、超限输入和非零退出码。Windows 在超限读取主动关闭管道时可能向父进程报告 EOF / EPIPE；对应测试仍要求子进程退出 1 且明确报告超限。

构建必须先于 CLI 测试：npm run build 生成 release JS 模块，npm test 不隐式触发编译，避免测试旧文件时误判。

## SVG 示例

npm run examples 使用 CLI 调用编译后的 MoonBit，实现对 pipeline.json、hierarchy-ports.json、cycle.json、workflow.txt 的 SVG 渲染。生成文件存放在 examples/，可直接用浏览器查看。没有使用 JavaScript 重新实现布局或 SVG。

## 验证边界

当前测试不是 ELK / elkjs 差异测试，不证明最优布局、无交叉路由、任意负载下的性能或浏览器 UI 的交互行为。公开 API 的输入规模上限用于可控资源边界，不是性能 SLA。CI 使用安装时可获取的 MoonBit 工具链；本地已验证的具体版本在 README 中记录。
