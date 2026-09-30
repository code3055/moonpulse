# 发布准备

发布账号为 code3055（通过 moon whoami 确认），包名为 code3055/moon_graph。首个版本 0.1.0 已发布，并通过独立安装验证，详见 RELEASE-0.1.0.md。维护者发布后续版本时须先更新版本号，不能重复发布 0.1.0。

## GitHub

当前父仓库 remote 为 code3055/moonpulse，moon_graph 作为其子项目维护；用户已确认该目录的代码上传、仓库公开和 CI 通过。

子项目工作流位于父仓库 .github/workflows/moon-graph.yml；独立仓库则使用本目录 .github/workflows/ 中的工作流。上传后检查仓库是否公开、源码是否可匿名读取，并记录真实 Actions 运行结果。

提交信息应描述真实实现及验证，不制造或回填开发历史。暂存时限定 moon_graph 和对应工作流，避免把父目录其他未提交内容一起上传。

## mooncakes

1. 核实 moon whoami 显示 code3055，moon.mod 的 name 为 code3055/moon_graph。
2. 核实 bridge/moon.pkg、examples/api/moon.pkg 和文档中的导入路径为 code3055/moon_graph/graph。
3. 核实 moon.mod 的真实公开 repository、version、readme、license 和 description；用 moon view code3055/moon_graph --versions 检查待发布版本是否已存在，避免重复发布。
4. 在本目录运行完整检查：moon fmt --check、moon check、moon test、moon test --target js、npm run build、npm test。
5. 运行 moon package --list，人工检查归档中包含 LICENSE、README、MoonBit 源码，且不含密钥或本地状态。
6. 使用 MoonBit 工具链的 moon login 登录自己的账户，完成授权后执行 moon publish。请先查看本机 moon login --help 和 moon publish --help 的当前参数。
7. 执行 moon view code3055/moon_graph@0.1.0 --json 核实远程版本。在仓库之外创建独立 MoonBit 项目，执行 moon add code3055/moon_graph，确认依赖为 0.1.0 且未使用本地路径覆盖，再运行 README API 的使用方测试。

如发布请求中断，先查询上述精确版本的注册中心记录，再决定是否重试。独立安装结果和发布记录写入 ACCEPTANCE.md。

本机已确认 moon publish 支持 --dry-run，但 dry-run、moon package 或本地构建都不等于远程发布成功。不要在未发布时填写虚构的包地址或发布版本证明。
