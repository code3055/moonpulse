# 发布准备

当前状态：开发版本已通过本地测试和打包检查，尚未发布 GitHub 提交或 mooncakes 包。

## GitHub

当前父仓库 remote 为 code3055/moonpulse；新 moon_graph 文件夹可保留为子项目，也可作为独立仓库根目录。不要把父项目已有的提交、CI、发布记录算作新项目的记录。

子项目工作流位于父仓库 .github/workflows/moon-graph.yml；独立仓库则使用本目录 .github/workflows/ 中的工作流。上传后检查仓库是否公开、源码是否可匿名读取，并记录真实 Actions 运行结果。

提交信息应描述真实实现及验证，不制造或回填开发历史。暂存时限定 moon_graph 和对应工作流，避免把父目录其他未提交内容一起上传。

## mooncakes

1. 将 moon.mod 的 name 从 local/moon_graph 换成自己拥有的用户名或组织名下的包名。
2. 同步替换 bridge/moon.pkg、examples/api/moon.pkg 和文档中的 local/moon_graph/graph 导入路径。
3. 在 moon.mod 填写真实公开 repository，核实 version、readme、license 和 description。
4. 在本目录运行完整检查：moon fmt --check、moon check、moon test、moon test --target js、npm run build、npm test。
5. 运行 moon package --list，人工检查归档中包含 LICENSE、README、MoonBit 源码，且不含密钥或本地状态。
6. 使用 MoonBit 工具链的 moon login 登录自己的账户，完成授权后执行 moon publish。请先查看本机 moon login --help 和 moon publish --help 的当前参数。
7. 发布成功后在 mooncakes.io 核实包名和版本；在一个干净 MoonBit 项目安装该版本并运行 README 最小样例，保存可访问的包页面链接。

本机已确认 moon publish 支持 --dry-run，但 dry-run、moon package 或本地构建都不等于远程发布成功。不要在未发布时填写虚构的包地址或发布版本证明。
