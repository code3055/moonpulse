///|
fn expect_invalid(graph : @graph.Node) -> Unit raise {
  assert_true(@graph.validate(graph).length() > 0)
  let before = @graph.graph_json(graph)
  let rejected = try {
    ignore(@graph.new_elk_engine().layout(graph))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  assert_eq(@graph.graph_json(graph), before)
}

///|
fn reject_option(key : String, value : String) -> Unit raise {
  let graph = @graph.new_graph()
  graph.options[key] = value
  graph.children.push(@graph.new_node("a"))
  expect_invalid(graph)
}

///|
test "validation rejects duplicate sibling IDs" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  graph.children.push(@graph.new_node("a"))
  expect_invalid(graph)
}

///|
test "validation rejects duplicate IDs across graph levels" {
  let graph = @graph.new_graph()
  let group = @graph.new_node("group")
  group.children.push(@graph.new_node("root"))
  graph.children.push(group)
  expect_invalid(graph)
}

///|
test "validation rejects node port ID collisions" {
  let graph = @graph.new_graph()
  let child = @graph.new_node("a")
  child.ports.push(@graph.new_port("a"))
  graph.children.push(child)
  expect_invalid(graph)
}

///|
test "validation rejects node edge ID collisions" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  graph.edges.push(@graph.new_edge("a", "a", "a"))
  expect_invalid(graph)
}

///|
test "validation rejects duplicate edge IDs" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  graph.edges.push(@graph.new_edge("e", "a", "a"))
  graph.edges.push(@graph.new_edge("e", "a", "a"))
  expect_invalid(graph)
}

///|
test "validation rejects empty node IDs" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node(" "))
  expect_invalid(graph)
}

///|
test "validation rejects missing source" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  graph.edges.push(@graph.new_edge("e", "missing", "a"))
  expect_invalid(graph)
}

///|
test "validation rejects missing target" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  graph.edges.push(@graph.new_edge("e", "a", "missing"))
  expect_invalid(graph)
}

///|
test "validation rejects cross hierarchy endpoints" {
  let graph = @graph.new_graph()
  let group = @graph.new_node("group")
  group.children.push(@graph.new_node("inner"))
  graph.children.push(group)
  graph.children.push(@graph.new_node("outer"))
  graph.edges.push(@graph.new_edge("e", "inner", "outer"))
  expect_invalid(graph)
}

///|
test "validation rejects containing node as endpoint" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  graph.edges.push(@graph.new_edge("e", "root", "a"))
  expect_invalid(graph)
}

///|
test "validation rejects negative width" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a", width=-1.0))
  expect_invalid(graph)
}

///|
test "validation rejects negative height" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a", height=-1.0))
  expect_invalid(graph)
}

///|
test "validation rejects zero leaf dimensions" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a", width=0.0, height=0.0))
  expect_invalid(graph)
}

///|
test "validation rejects coordinate overflow" {
  let graph = @graph.new_graph()
  let child = @graph.new_node("a")
  child.x = 1000001.0
  graph.children.push(child)
  expect_invalid(graph)
}

///|
test "validation rejects negative coordinates" {
  let graph = @graph.new_graph()
  let child = @graph.new_node("a")
  child.y = -1.0
  graph.children.push(child)
  expect_invalid(graph)
}

///|
test "validation rejects unsupported port side" {
  let graph = @graph.new_graph()
  let child = @graph.new_node("a")
  child.ports.push(@graph.new_port("p", side="AUTO"))
  graph.children.push(child)
  expect_invalid(graph)
}

///|
test "validation rejects negative edge point" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  let edge = @graph.new_edge("e", "a", "a")
  edge.points.push({ x: -1.0, y: 0.0, })
  graph.edges.push(edge)
  expect_invalid(graph)
}

///|
test "validation rejects unknown algorithm" {
  reject_option("elk.algorithm", "stress")
}

///|
test "validation rejects unknown option" {
  reject_option("elk.unimplemented", "true")
}

///|
test "validation rejects invalid direction" {
  reject_option("elk.direction", "NORTHWEST")
}

///|
test "validation rejects unsupported routing" {
  reject_option("elk.edgeRouting", "SPLINES")
}

///|
test "validation rejects negative node spacing" {
  reject_option("elk.spacing.nodeNode", "-1")
}

///|
test "validation rejects excessive layer spacing" {
  reject_option("elk.layered.spacing.nodeNodeBetweenLayers", "10001")
}

///|
test "validation rejects malformed padding" {
  reject_option("moon.padding", "banana")
}

///|
test "validation rejects fractional iterations" {
  reject_option("moon.force.iterations", "1.5")
}

///|
test "validation rejects zero iterations" {
  reject_option("moon.force.iterations", "0")
}

///|
test "validation rejects excessive iterations" {
  reject_option("moon.force.iterations", "1001")
}

///|
test "validation rejects negative seed" {
  reject_option("moon.seed", "-1")
}

///|
test "validation rejects fractional seed" {
  reject_option("moon.seed", "0.25")
}

///|
test "validation rejects excessive seed" {
  reject_option("moon.seed", "1000001")
}

///|
test "validation rejects non numeric seed" {
  reject_option("moon.seed", "null")
}

///|
test "validation rejects node count beyond 500 including root" {
  let graph = @graph.new_graph()
  for i = 0; i < 500; i = i + 1 {
    graph.children.push(@graph.new_node("n\{i}"))
  }
  expect_invalid(graph)
}

///|
test "validation accepts node count at 500 including root" {
  let graph = @graph.new_graph()
  for i = 0; i < 499; i = i + 1 {
    graph.children.push(@graph.new_node("n\{i}"))
  }
  assert_eq(@graph.validate(graph).length(), 0)
}

///|
test "validation accepts 3000 edges and rejects 3001" {
  let graph = @graph.new_graph()
  graph.children.push(@graph.new_node("a"))
  for i = 0; i < 3000; i = i + 1 {
    graph.edges.push(@graph.new_edge("e\{i}", "a", "a"))
  }
  assert_eq(@graph.validate(graph).length(), 0)
  graph.edges.push(@graph.new_edge("extra", "a", "a"))
  expect_invalid(graph)
}

///|
test "validation accepts depth 32 and rejects depth 33" {
  let graph = @graph.new_graph()
  let mut current = graph
  for i = 1; i <= 32; i = i + 1 {
    let child = @graph.new_node("n\{i}")
    current.children.push(child)
    current = child
  }
  assert_eq(@graph.validate(graph).length(), 0)
  current.children.push(@graph.new_node("too-deep"))
  expect_invalid(graph)
}

///|
test "layout empty graph succeeds for every registered algorithm" {
  assert_eq(@graph.algorithms(), ["layered", "force", "radial", "box", "fixed"])
  for algorithm in @graph.algorithms() {
    let graph = @graph.new_graph()
    graph.options["elk.algorithm"] = algorithm
    let output = @graph.new_elk_engine().layout(graph)
    assert_eq(output.children.length(), 0)
    assert_eq(output.edges.length(), 0)
    assert_eq(@graph.validate(output).length(), 0)
  }
}

///|
test "layout supports ELK qualified algorithm aliases" {
  for algorithm in @graph.algorithms() {
    let input = scenario_graph(algorithm, "RIGHT", "chain", 0)
    let plain = @graph.new_elk_engine().layout(input)
    input.options["elk.algorithm"] = "org.eclipse.elk." + algorithm
    let qualified = @graph.new_elk_engine().layout(input)
    qualified.options["elk.algorithm"] = algorithm
    assert_eq(@graph.graph_json(plain), @graph.graph_json(qualified))
  }
}

///|
test "layout routes self edges for every algorithm" {
  for algorithm in @graph.algorithms() {
    let graph = @graph.new_graph()
    graph.options["elk.algorithm"] = algorithm
    graph.children.push(@graph.new_node("a"))
    graph.edges.push(@graph.new_edge("loop", "a", "a"))
    let output = @graph.new_elk_engine().layout(graph)
    assert_true(output.edges[0].points.length() >= 2)
    assert_eq(@graph.validate(output).length(), 0)
  }
}

///|
test "layered directions orient a connected chain" {
  for direction in ["RIGHT", "LEFT", "UP", "DOWN"] {
    let output = @graph.new_elk_engine().layout(
      scenario_graph("layered", direction, "chain", 0),
    )
    for i = 1; i < output.children.length(); i = i + 1 {
      let before = output.children[i - 1]
      let after = output.children[i]
      match direction {
        "RIGHT" => assert_true(after.x > before.x)
        "LEFT" => assert_true(after.x < before.x)
        "DOWN" => assert_true(after.y > before.y)
        _ => assert_true(after.y < before.y)
      }
    }
  }
}

///|
test "force uses seed while repeated seed remains deterministic" {
  let input = scenario_graph("force", "RIGHT", "star", 1)
  let first = @graph.new_elk_engine().layout(input)
  input.options["moon.seed"] = "13"
  let second = @graph.new_elk_engine().layout(input)
  let mut changed = false
  for i = 0; i < first.children.length(); i = i + 1 {
    if first.children[i].x != second.children[i].x ||
      first.children[i].y != second.children[i].y {
      changed = true
    }
  }
  assert_true(changed)
  assert_eq(
    @graph.graph_json(second),
    @graph.graph_json(@graph.new_elk_engine().layout(input)),
  )
}

///|
test "algorithm selection changes actual geometry" {
  let input = scenario_graph("layered", "RIGHT", "star", 1)
  let layered = @graph.new_elk_engine().layout(input)
  input.options["elk.algorithm"] = "box"
  let packed = @graph.new_elk_engine().layout(input)
  let mut changed = false
  for i = 0; i < layered.children.length(); i = i + 1 {
    if layered.children[i].x != packed.children[i].x ||
      layered.children[i].y != packed.children[i].y {
      changed = true
    }
  }
  assert_true(changed)
}

///|
test "layout rejects computed bounds overflow without input mutation" {
  let input = @graph.new_graph()
  input.options["elk.algorithm"] = "fixed"
  let child = @graph.new_node("a", width=1000000.0)
  input.children.push(child)
  assert_eq(@graph.validate(input).length(), 0)
  let before = @graph.graph_json(input)
  let rejected = try {
    ignore(@graph.new_elk_engine().layout(input))
    false
  } catch {
    _ => true
  }
  assert_true(rejected)
  assert_eq(@graph.graph_json(input), before)
}
