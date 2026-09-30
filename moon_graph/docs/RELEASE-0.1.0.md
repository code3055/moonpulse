# Moon Graph 0.1.0 发布记录

- 包名：code3055/moon_graph
- 版本：0.1.0
- 发布时间：2026-09-30 16:19:42（Asia/Shanghai）
- 注册中心 UTC 时间：2026-09-30T08:19:42.419013+00:00
- 许可证：MIT
- 源码仓库：https://github.com/code3055/moonpulse，项目位于 moon_graph 子目录

## 注册中心证据

moon publish 返回 Server status: 200 OK。随后执行 moon view code3055/moon_graph@0.1.0 --json，返回 status=success、version=0.1.0、yanked=false。

注册中心 checksum 与本地上传归档的 SHA256 均为：

~~~text
fcbd2c8ab8917898b5a5d4e53361cb7a40fd9be03d59c6fdce3cd184f9ee3c52
~~~

归档包含 40 个文件，包括 LICENSE、README、公开 API 源码、CLI、示例和测试；未包含本地输出、构建缓存、.git、.omx、.mooncakes 或 node_modules。

## 发布前验证

- moon fmt --check、JS/wasm-gc 检查和构建通过。
- 核心 MoonBit 测试：JS 382/382；wasm-gc 382/382。
- CLI 集成测试：38/38。
- 发布工具自动解压上传归档并再次执行 moon check，通过。

## 独立安装验证

在仓库外的全新临时项目执行 moon add code3055/moon_graph；工具更新注册中心索引并下载 code3055/moon_graph@0.1.0。生成的 moon.mod 明确声明该版本，未使用本地 path 覆盖。

使用已下载依赖调用公开 API，以下六项测试在 JS 与 wasm-gc 上均通过：

1. 有向工作流节点位置、顺序及边路由。
2. JSON 导入、布局、导出和再次解析。
3. 中文 SVG、XML 转义和箭头标记。
4. 无效边端点返回可处理的错误。
5. 五种已注册布局算法列表。
6. 布局不修改输入图。

使用方验证结果：JS 6/6；wasm-gc 6/6。

## 安装

在已有 MoonBit 项目中执行：

~~~sh
moon add code3055/moon_graph
~~~

调用方 moon.pkg 导入 code3055/moon_graph/graph，API 示例见 README。

本报告在远程发布完成后补充；上传归档内的验收表为发布前快照。发布记录以注册中心元数据、校验和与独立安装结果为准。
