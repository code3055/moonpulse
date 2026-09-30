# 数据格式与 ELK 兼容边界

Moon Graph 是原创 MoonBit 库，参考 ELK JSON 的形状，不是 ELK / elkjs 的完整实现或直接替代。名称中的 ELK 风格 API 仅便于理解布局入口。算法输出的节点顺序、坐标、路由点和质量目标与 ELK 不承诺相同。

## 明确支持的 JSON 字段

| 对象 | 字段 | 说明 |
| --- | --- | --- |
| 节点 / 根容器 | id, x, y, width, height, children, edges, ports, labels, layoutOptions | id 必填；children 为嵌套节点 |
| 边 | id, sources, targets, labels, sections | sources / targets 各恰好一个字符串 |
| 端口 | id, x, y, layoutOptions | 唯一选项 elk.port.side；布局重新定位端口 |
| 标签 | text | 只支持文字，不支持独立的标签尺寸 / 坐标 |
| section | id, startPoint, endPoint, bendPoints | 最多一个 section；id 可选 |
| point | x, y | 有限且非负的数字 |

未知字段立即拒绝，不静默丢弃。因此向本库传入一般 ELK 图前，调用者须显式清理自己理解的扩展字段；不能假定任意 elkjs 输入均可使用。

序列化会写出默认坐标、尺寸、空数组和空 layoutOptions，数值选项内部按字符串保存，section ID 规范化为边 ID 加 _section。因此语义往返不等于源文件字节保真；边布局也会替换原有 sections。

## 结构约束

边存储在其所在容器的 edges 中，端点仅指向该容器的直接子节点或这些节点的端口。复合节点向外连接时使用复合节点 ID 或其端口；其内部边放在该节点的 edges 中。跨层直接连接孙节点、父节点端口作为内部边端点、超边和多 section 边均不支持。

节点、边与端口的 ID 必须全局唯一。子节点与路由点以边所在容器为坐标系，端口坐标相对其所属节点。SVG 会累加容器偏移。

MoonBit 记录可变；如果调用者手工构建了循环引用的 children 对象树，应先调用 validate 并处理错误。clone_graph、graph_json、render_svg 不承担输入校验，要求有效且无循环引用的层级树；图的边形成有向环则属于正常支持的结构。

## 算法和布局选项

实现 layered、force、radial、box、fixed 五个名称及对应 org.eclipse.elk. 前缀别名。其名称描述本库算法，不表示移植了同名 ELK 算法全部阶段与参数。

Stress、MrTree、RectPacking、Spore、Random、Vertiflex、Graphviz、libavoid、disco、topdownpacking 等未实现，传入后返回 Unsupported algorithm，不会静默改用其他算法。

节点选项完整白名单：elk.algorithm、elk.direction、elk.spacing.nodeNode、elk.layered.spacing.nodeNodeBetweenLayers、moon.padding、moon.force.iterations、moon.seed、elk.edgeRouting。端口只支持 elk.port.side。范围和默认值见 README。其他选项（例如 elk.portConstraints、elk.nodeSize.constraints）会明确报错。

复合节点从父节点继承配置并按自身配置覆盖；叶子节点上的已知选项可通过校验，但它在父容器中的位置由父容器的算法决定。标签不参加节点尺寸测量，长标签可能超出节点矩形。正交路由并不包含一般障碍物避让，边可能交叉或穿过其他节点。radial 的重叠消解可能改变精确圆环形状。

fixed 保留已有节点 x/y，但仍扩展容器尺寸、重置端口位置并重算边路由；它不是完整几何透传模式。节点坐标非负，负坐标输入不支持。

## 文本与服务接口

parse_text 是项目自定义的逐行 node / edge / option 语法，不兼容 ELK Text 或通用 Graph Text。文本语法没有嵌套容器、端口、引号字符串或内联注释。

引擎为同步 MoonBit API；不包含 Eclipse 插件、OSGi 服务注册、SWT/JFace UI、elkjs worker 协议、交互编辑器或外部 Graphviz 进程。JS bridge 仅是字符串输入输出的函数导出。

## 测试和参考关系

当前测试验证本库的结构保持、确定性、方向、边端点、有限几何、端口定位、JSON 往返、SVG 转义及错误边界。没有将这些测试称为与 ELK / elkjs 的差异测试，也未建立上游像素级等价性。

未来如开展参考实现比较，应固定上游版本，分别比较数据格式、约束遵守和布局质量指标，并把算法差异与真正兼容性缺陷分开报告。

参考资料：

- Eclipse Layout Kernel 项目：https://github.com/eclipse-elk/elk
- ELK JSON 格式：https://eclipse.dev/elk/documentation/tooldevelopers/graphdatastructure/jsonformat.html
- MoonBit 包配置与 JS 导出：https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html

本库未复制上述项目源码；MIT 覆盖本项目原创代码，不能据此推断第三方参考项目的许可相同。
