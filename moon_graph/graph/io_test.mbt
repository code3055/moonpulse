///|
test "JSON defaults preserve leaf and root sizes" {
  let graph = @graph.parse_graph("{\"id\":\"r\",\"children\":[{\"id\":\"a\"}]}")
  assert_eq(graph.width, 0.0)
  assert_eq(graph.children[0].width, 100.0)
  assert_eq(graph.children[0].height, 48.0)
}

///|
test "JSON roundtrip preserves Unicode labels ports options and sections" {
  let root = @graph.new_graph()
  let a = @graph.new_node("a")
  a.labels.push({ text: "中文 😀 & < > \"", })
  a.ports.push(@graph.new_port("out", side="WEST"))
  root.children.push(a)
  root.children.push(@graph.new_node("b"))
  root.options.set("elk.direction", "DOWN")
  let edge = @graph.new_edge("e", "out", "b")
  edge.labels.push({ text: "连接", })
  edge.points = [{ x: 1.0, y: 2.0, }, { x: 3.0, y: 4.0, }, { x: 5.0, y: 6.0, }]
  root.edges.push(edge)
  let parsed = @graph.parse_graph(@graph.graph_json(root, pretty=true))
  assert_eq(parsed.children[0].labels[0].text, a.labels[0].text)
  assert_eq(parsed.children[0].ports[0].side, "WEST")
  assert_eq(parsed.options.get("elk.direction"), Some("DOWN"))
  assert_eq(parsed.edges[0].points.length(), 3)
  assert_eq(parsed.edges[0].points[1].x, 3.0)
  assert_eq(@graph.graph_json(parsed), @graph.graph_json(root))
}

///|
test "JSON import rejects malformed supported fields" {
  let invalid = [
    "[]", "null", "{}", "{\"id\":3}", "{\"id\":\"r\",\"children\":null}", "{\"id\":\"r\",\"width\":-1}",
    "{\"id\":\"r\",\"x\":1e309}", "{\"id\":\"r\",\"x\":1000001}", "{\"id\":\"r\",\"width\":\"1\"}",
    "{\"id\":\"r\",\"labels\":[{\"text\":false}]}", "{\"id\":\"r\",\"layoutOptions\":{\"elk.direction\":[]}}",
    "{\"id\":\"r\",\"unknown\":true}", "{\"id\":\"r\",\"edges\":[{\"id\":\"e\",\"sources\":[\"a\",\"b\"],\"targets\":[\"c\"]}]}",
    "{\"id\":\"r\",\"edges\":[{\"id\":\"e\",\"sources\":[],\"targets\":[\"c\"]}]}",
    "{\"id\":\"r\",\"edges\":[{\"id\":\"e\",\"sources\":[5],\"targets\":[\"c\"]}]}",
    "{\"id\":\"r\",\"ports\":[{\"id\":\"p\",\"layoutOptions\":{\"unknown\":\"x\"}}]}",
    "{\"id\":\"r\",\"children\":[{\"id\":\"a\"},{\"id\":\"a\"}]}",
  ]
  for text in invalid {
    let rejected = try {
      ignore(@graph.parse_graph(text))
      false
    } catch {
      @graph.GraphError(_) => true
    }
    assert_true(rejected, msg=text)
  }
}

///|
test "JSON import rejects malformed edge sections" {
  for
    section in [
      "{}", "{\"startPoint\":{\"x\":0,\"y\":0}}", "{\"startPoint\":{\"x\":0},\"endPoint\":{\"x\":0,\"y\":0}}",
      "{\"startPoint\":{\"x\":0,\"y\":0},\"endPoint\":{\"x\":0,\"y\":0},\"bendPoints\":false}",
    ] {
    let text = "{\"id\":\"r\",\"children\":[{\"id\":\"a\"},{\"id\":\"b\"}],\"edges\":[{\"id\":\"e\",\"sources\":[\"a\"],\"targets\":[\"b\"],\"sections\":[" +
      section +
      "]}]}"
    let rejected = try {
      ignore(@graph.parse_graph(text))
      false
    } catch {
      @graph.GraphError(_) => true
    }
    assert_true(rejected)
  }
}

///|
test "JSON import bounds raw UTF-8 input and nesting" {
  let large = "中".repeat(350000)
  let rejected = try {
    ignore(@graph.parse_graph(large))
    false
  } catch {
    @graph.GraphError(_) => true
  }
  assert_true(rejected)
  let deep = "[".repeat(129) + "0" + "]".repeat(129)
  let rejected = try {
    ignore(@graph.parse_graph(deep))
    false
  } catch {
    @graph.GraphError(_) => true
  }
  assert_true(rejected)
  let mut nested = "{\"id\":\"leaf\"}"
  for i = 0; i < 34; i = i + 1 {
    nested = "{\"id\":\"n\{i}\",\"children\":[" + nested + "]}"
  }
  let rejected = try {
    ignore(@graph.parse_graph(nested))
    false
  } catch {
    @graph.GraphError(_) => true
  }
  assert_true(rejected)
}

///|
test "text import permits forward references comments and Unicode labels" {
  let graph = @graph.parse_text(
    "# flow\nedge e a b 条件 成立\nnode\ta 第一 步\r\nnode b 第二步\noption elk.direction DOWN\n",
  )
  assert_eq(graph.children.length(), 2)
  assert_eq(graph.children[0].labels[0].text, "第一 步")
  assert_eq(graph.edges[0].labels[0].text, "条件 成立")
  assert_eq(graph.options.get("elk.direction"), Some("DOWN"))
}

///|
test "text import rejects invalid commands duplicates and missing endpoints" {
  for
    input in [
      "node", "edge e a", "option key", "option key value extra", "banana a", "node a\nnode a",
      "node a\nedge e a b", "option elk.direction UP\noption elk.direction DOWN",
    ] {
    let rejected = try {
      ignore(@graph.parse_text(input))
      false
    } catch {
      @graph.GraphError(_) => true
    }
    assert_true(rejected, msg=input)
  }
}

///|
test "SVG escapes text and attributes and filters XML control characters" {
  let graph = @graph.new_graph(id="<script>&\"'")
  let child = @graph.new_node("<node>")
  child.labels.push({ text: "<script>alert(1)</script> & \u0001", })
  graph.children.push(child)
  let svg = @graph.render_svg(graph)
  assert_true(!svg.contains("<script>"))
  assert_true(svg.contains("&lt;script&gt;"))
  assert_true(svg.contains("&quot;"))
  assert_true(svg.contains("&apos;"))
  assert_true(!svg.contains("\u0001"))
}

///|
test "SVG accumulates compound offsets and includes edge paths ports" {
  let graph = @graph.new_graph()
  let group = @graph.new_node("group")
  group.x = 100.0
  group.y = 200.0
  let child = @graph.new_node("leaf")
  child.x = 10.0
  child.y = 20.0
  let port = @graph.new_port("p")
  port.x = 5.0
  port.y = 6.0
  child.ports.push(port)
  group.children.push(child)
  let edge = @graph.new_edge("e", "leaf", "leaf")
  edge.points = [{ x: 10.0, y: 20.0, }, { x: 30.0, y: 40.0, }]
  edge.labels.push({ text: "loop", })
  group.edges.push(edge)
  graph.children.push(group)
  let svg = @graph.render_svg(graph)
  assert_true(svg.contains("x=\"110\" y=\"220\""))
  assert_true(svg.contains("cx=\"115\" cy=\"226\""))
  assert_true(svg.contains("M 110 220 L 130 240"))
  assert_true(svg.contains("marker-end=\"url(#moon-graph-arrow)\""))
  assert_true(svg.contains(">loop</text>"))
}

///|
test "SVG viewbox includes negative fixed positions" {
  let graph = @graph.new_graph()
  let child = @graph.new_node("a")
  child.x = -100.0
  child.y = -80.0
  graph.children.push(child)
  assert_true(@graph.render_svg(graph).contains("viewBox=\"-116 -96"))
}

///|
test "layout JSON integrates routing and pretty serialization" {
  let input = "{\"id\":\"r\",\"children\":[{\"id\":\"a\"},{\"id\":\"b\"}],\"edges\":[{\"id\":\"e\",\"sources\":[\"a\"],\"targets\":[\"b\"]}]}"
  let output = @graph.layout_json(input, pretty=true)
  assert_true(output.contains("\n"))
  let graph = @graph.parse_graph(output)
  assert_true(graph.width > 0.0)
  assert_true(graph.edges[0].points.length() >= 2)
}
