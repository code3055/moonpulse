// Scenario helpers are maintained here; regenerate cases with scripts/generate-tests.mjs.

///|
fn scenario_graph(
  algorithm : String,
  direction : String,
  family : String,
  variant : Int,
) -> @graph.Node {
  let root = @graph.new_graph()
  root.options["elk.algorithm"] = algorithm
  root.options["elk.direction"] = direction
  root.options["moon.seed"] = if variant == 0 { "7" } else { "104729" }
  root.options["moon.force.iterations"] = "35"
  root.options["elk.edgeRouting"] = if variant == 0 {
    "ORTHOGONAL"
  } else {
    "POLYLINE"
  }
  let n = if variant == 0 { 4 } else { 7 }
  for i = 0; i < n; i = i + 1 {
    let width = if variant == 0 {
      70.0
    } else {
      32.0 + (i * 17 % 73).to_double()
    }
    let height = if variant == 0 {
      40.0
    } else {
      18.0 + (i * 11 % 41).to_double()
    }
    let node = @graph.new_node("n\{i}", width~, height~)
    node.x = 25.0 + i.to_double() * 155.0
    node.y = 30.0 + (i % 3).to_double() * 90.0
    node.labels.push({ text: "节点 \{i} <&>", })
    root.children.push(node)
  }
  if family == "compound" {
    let group = root.children[0]
    let left = @graph.new_node("inner-a", width=36.0, height=24.0)
    let right = @graph.new_node("inner-b", width=81.0, height=38.0)
    left.x = 24.0
    left.y = 24.0
    right.x = 165.0
    right.y = 24.0
    group.children.push(left)
    group.children.push(right)
    group.edges.push(@graph.new_edge("inner-edge", "inner-a", "inner-b"))
  }
  if family == "ports" {
    for i = 0; i < n; i = i + 1 {
      root.children[i].ports.push(@graph.new_port("p\{i}-in", side="WEST"))
      root.children[i].ports.push(@graph.new_port("p\{i}-out", side="EAST"))
    }
  }
  for i = 1; i < n; i = i + 1 {
    let source = if family == "star" {
      0
    } else if family == "binary" {
      (i - 1) / 2
    } else {
      i - 1
    }
    if family != "disconnected" {
      let source_id = if family == "ports" {
        "p\{source}-out"
      } else {
        "n\{source}"
      }
      let target_id = if family == "ports" { "p\{i}-in" } else { "n\{i}" }
      let edge = @graph.new_edge("e\{i}", source_id, target_id)
      edge.labels.push({ text: "边 \{i}", })
      root.edges.push(edge)
    }
  }
  if family == "cycle" {
    root.edges.push(@graph.new_edge("cycle-close", "n\{n - 1}", "n0"))
  }
  if family == "diamond" {
    root.edges.push(@graph.new_edge("diamond-split", "n0", "n2"))
    root.edges.push(@graph.new_edge("diamond-join", "n1", "n3"))
  }
  root
}

///|
fn finite_coordinate(value : Double) -> Bool {
  value == value && value >= -1000000.0 && value <= 1000000.0
}

///|
fn verify_geometry(
  node : @graph.Node,
  original : @graph.Node,
  algorithm : String,
) -> Unit raise {
  assert_true(finite_coordinate(node.x))
  assert_true(finite_coordinate(node.y))
  assert_true(finite_coordinate(node.width) && node.width >= 0.0)
  assert_true(finite_coordinate(node.height) && node.height >= 0.0)
  assert_eq(node.id, original.id)
  assert_eq(node.labels, original.labels)
  assert_eq(node.children.length(), original.children.length())
  assert_eq(node.edges.length(), original.edges.length())
  assert_eq(node.ports.length(), original.ports.length())
  if node.children.length() == 0 {
    assert_eq(node.width, original.width)
    assert_eq(node.height, original.height)
  }
  for port in node.ports {
    assert_true(finite_coordinate(port.x))
    assert_true(finite_coordinate(port.y))
    assert_true(port.x >= 0.0 && port.x <= node.width)
    assert_true(port.y >= 0.0 && port.y <= node.height)
  }
  for i = 0; i < node.edges.length(); i = i + 1 {
    let edge = node.edges[i]
    let source = original.edges[i]
    assert_eq(edge.id, source.id)
    assert_eq(edge.source, source.source)
    assert_eq(edge.target, source.target)
    assert_eq(edge.labels, source.labels)
    assert_true(edge.points.length() >= 2)
    for point in edge.points {
      assert_true(finite_coordinate(point.x))
      assert_true(finite_coordinate(point.y))
    }
  }
  for i = 0; i < node.children.length(); i = i + 1 {
    let child = node.children[i]
    assert_true(child.x >= -0.00001 && child.y >= -0.00001)
    assert_true(child.x + child.width <= node.width + 0.00001)
    assert_true(child.y + child.height <= node.height + 0.00001)
    if algorithm == "fixed" {
      assert_eq(child.x, original.children[i].x)
      assert_eq(child.y, original.children[i].y)
    }
    if algorithm != "fixed" {
      for j = i + 1; j < node.children.length(); j = j + 1 {
        let other = node.children[j]
        assert_true(
          child.x + child.width <= other.x + 0.00001 ||
          other.x + other.width <= child.x + 0.00001 ||
          child.y + child.height <= other.y + 0.00001 ||
          other.y + other.height <= child.y + 0.00001,
        )
      }
    }
    verify_geometry(child, original.children[i], algorithm)
  }
}

///|
fn check_scenario(
  algorithm : String,
  direction : String,
  family : String,
  variant : Int,
) -> Unit raise {
  let input = scenario_graph(algorithm, direction, family, variant)
  let before = @graph.graph_json(input)
  assert_eq(@graph.validate(input).length(), 0)
  let output = @graph.new_elk_engine().layout(input)
  assert_eq(@graph.graph_json(input), before)
  verify_geometry(output, input, algorithm)
  assert_eq(@graph.validate(output).length(), 0)
  let repeated = @graph.new_elk_engine().layout(input)
  assert_eq(@graph.graph_json(output), @graph.graph_json(repeated))
  // Returned nodes must be independent objects, not aliases into caller data.
  output.children[0].x = output.children[0].x + 1.0
  assert_eq(@graph.graph_json(input), before)
}

// BEGIN GENERATED SCENARIOS

///|
test "scenario layered RIGHT chain uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "chain", 0)
}

///|
test "scenario layered RIGHT chain varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "chain", 1)
}

///|
test "scenario layered RIGHT star uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "star", 0)
}

///|
test "scenario layered RIGHT star varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "star", 1)
}

///|
test "scenario layered RIGHT cycle uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "cycle", 0)
}

///|
test "scenario layered RIGHT cycle varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "cycle", 1)
}

///|
test "scenario layered RIGHT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "disconnected", 0)
}

///|
test "scenario layered RIGHT disconnected varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "disconnected", 1)
}

///|
test "scenario layered RIGHT binary uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "binary", 0)
}

///|
test "scenario layered RIGHT binary varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "binary", 1)
}

///|
test "scenario layered RIGHT diamond uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "diamond", 0)
}

///|
test "scenario layered RIGHT diamond varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "diamond", 1)
}

///|
test "scenario layered RIGHT ports uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "ports", 0)
}

///|
test "scenario layered RIGHT ports varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "ports", 1)
}

///|
test "scenario layered RIGHT compound uniform-small-seed7-orthogonal" {
  check_scenario("layered", "RIGHT", "compound", 0)
}

///|
test "scenario layered RIGHT compound varied-large-seed104729-polyline" {
  check_scenario("layered", "RIGHT", "compound", 1)
}

///|
test "scenario layered DOWN chain uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "chain", 0)
}

///|
test "scenario layered DOWN chain varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "chain", 1)
}

///|
test "scenario layered DOWN star uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "star", 0)
}

///|
test "scenario layered DOWN star varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "star", 1)
}

///|
test "scenario layered DOWN cycle uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "cycle", 0)
}

///|
test "scenario layered DOWN cycle varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "cycle", 1)
}

///|
test "scenario layered DOWN disconnected uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "disconnected", 0)
}

///|
test "scenario layered DOWN disconnected varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "disconnected", 1)
}

///|
test "scenario layered DOWN binary uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "binary", 0)
}

///|
test "scenario layered DOWN binary varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "binary", 1)
}

///|
test "scenario layered DOWN diamond uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "diamond", 0)
}

///|
test "scenario layered DOWN diamond varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "diamond", 1)
}

///|
test "scenario layered DOWN ports uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "ports", 0)
}

///|
test "scenario layered DOWN ports varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "ports", 1)
}

///|
test "scenario layered DOWN compound uniform-small-seed7-orthogonal" {
  check_scenario("layered", "DOWN", "compound", 0)
}

///|
test "scenario layered DOWN compound varied-large-seed104729-polyline" {
  check_scenario("layered", "DOWN", "compound", 1)
}

///|
test "scenario layered LEFT chain uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "chain", 0)
}

///|
test "scenario layered LEFT chain varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "chain", 1)
}

///|
test "scenario layered LEFT star uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "star", 0)
}

///|
test "scenario layered LEFT star varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "star", 1)
}

///|
test "scenario layered LEFT cycle uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "cycle", 0)
}

///|
test "scenario layered LEFT cycle varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "cycle", 1)
}

///|
test "scenario layered LEFT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "disconnected", 0)
}

///|
test "scenario layered LEFT disconnected varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "disconnected", 1)
}

///|
test "scenario layered LEFT binary uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "binary", 0)
}

///|
test "scenario layered LEFT binary varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "binary", 1)
}

///|
test "scenario layered LEFT diamond uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "diamond", 0)
}

///|
test "scenario layered LEFT diamond varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "diamond", 1)
}

///|
test "scenario layered LEFT ports uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "ports", 0)
}

///|
test "scenario layered LEFT ports varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "ports", 1)
}

///|
test "scenario layered LEFT compound uniform-small-seed7-orthogonal" {
  check_scenario("layered", "LEFT", "compound", 0)
}

///|
test "scenario layered LEFT compound varied-large-seed104729-polyline" {
  check_scenario("layered", "LEFT", "compound", 1)
}

///|
test "scenario layered UP chain uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "chain", 0)
}

///|
test "scenario layered UP chain varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "chain", 1)
}

///|
test "scenario layered UP star uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "star", 0)
}

///|
test "scenario layered UP star varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "star", 1)
}

///|
test "scenario layered UP cycle uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "cycle", 0)
}

///|
test "scenario layered UP cycle varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "cycle", 1)
}

///|
test "scenario layered UP disconnected uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "disconnected", 0)
}

///|
test "scenario layered UP disconnected varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "disconnected", 1)
}

///|
test "scenario layered UP binary uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "binary", 0)
}

///|
test "scenario layered UP binary varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "binary", 1)
}

///|
test "scenario layered UP diamond uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "diamond", 0)
}

///|
test "scenario layered UP diamond varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "diamond", 1)
}

///|
test "scenario layered UP ports uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "ports", 0)
}

///|
test "scenario layered UP ports varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "ports", 1)
}

///|
test "scenario layered UP compound uniform-small-seed7-orthogonal" {
  check_scenario("layered", "UP", "compound", 0)
}

///|
test "scenario layered UP compound varied-large-seed104729-polyline" {
  check_scenario("layered", "UP", "compound", 1)
}

///|
test "scenario force RIGHT chain uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "chain", 0)
}

///|
test "scenario force RIGHT chain varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "chain", 1)
}

///|
test "scenario force RIGHT star uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "star", 0)
}

///|
test "scenario force RIGHT star varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "star", 1)
}

///|
test "scenario force RIGHT cycle uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "cycle", 0)
}

///|
test "scenario force RIGHT cycle varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "cycle", 1)
}

///|
test "scenario force RIGHT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "disconnected", 0)
}

///|
test "scenario force RIGHT disconnected varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "disconnected", 1)
}

///|
test "scenario force RIGHT binary uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "binary", 0)
}

///|
test "scenario force RIGHT binary varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "binary", 1)
}

///|
test "scenario force RIGHT diamond uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "diamond", 0)
}

///|
test "scenario force RIGHT diamond varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "diamond", 1)
}

///|
test "scenario force RIGHT ports uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "ports", 0)
}

///|
test "scenario force RIGHT ports varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "ports", 1)
}

///|
test "scenario force RIGHT compound uniform-small-seed7-orthogonal" {
  check_scenario("force", "RIGHT", "compound", 0)
}

///|
test "scenario force RIGHT compound varied-large-seed104729-polyline" {
  check_scenario("force", "RIGHT", "compound", 1)
}

///|
test "scenario force DOWN chain uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "chain", 0)
}

///|
test "scenario force DOWN chain varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "chain", 1)
}

///|
test "scenario force DOWN star uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "star", 0)
}

///|
test "scenario force DOWN star varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "star", 1)
}

///|
test "scenario force DOWN cycle uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "cycle", 0)
}

///|
test "scenario force DOWN cycle varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "cycle", 1)
}

///|
test "scenario force DOWN disconnected uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "disconnected", 0)
}

///|
test "scenario force DOWN disconnected varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "disconnected", 1)
}

///|
test "scenario force DOWN binary uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "binary", 0)
}

///|
test "scenario force DOWN binary varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "binary", 1)
}

///|
test "scenario force DOWN diamond uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "diamond", 0)
}

///|
test "scenario force DOWN diamond varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "diamond", 1)
}

///|
test "scenario force DOWN ports uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "ports", 0)
}

///|
test "scenario force DOWN ports varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "ports", 1)
}

///|
test "scenario force DOWN compound uniform-small-seed7-orthogonal" {
  check_scenario("force", "DOWN", "compound", 0)
}

///|
test "scenario force DOWN compound varied-large-seed104729-polyline" {
  check_scenario("force", "DOWN", "compound", 1)
}

///|
test "scenario force LEFT chain uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "chain", 0)
}

///|
test "scenario force LEFT chain varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "chain", 1)
}

///|
test "scenario force LEFT star uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "star", 0)
}

///|
test "scenario force LEFT star varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "star", 1)
}

///|
test "scenario force LEFT cycle uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "cycle", 0)
}

///|
test "scenario force LEFT cycle varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "cycle", 1)
}

///|
test "scenario force LEFT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "disconnected", 0)
}

///|
test "scenario force LEFT disconnected varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "disconnected", 1)
}

///|
test "scenario force LEFT binary uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "binary", 0)
}

///|
test "scenario force LEFT binary varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "binary", 1)
}

///|
test "scenario force LEFT diamond uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "diamond", 0)
}

///|
test "scenario force LEFT diamond varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "diamond", 1)
}

///|
test "scenario force LEFT ports uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "ports", 0)
}

///|
test "scenario force LEFT ports varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "ports", 1)
}

///|
test "scenario force LEFT compound uniform-small-seed7-orthogonal" {
  check_scenario("force", "LEFT", "compound", 0)
}

///|
test "scenario force LEFT compound varied-large-seed104729-polyline" {
  check_scenario("force", "LEFT", "compound", 1)
}

///|
test "scenario force UP chain uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "chain", 0)
}

///|
test "scenario force UP chain varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "chain", 1)
}

///|
test "scenario force UP star uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "star", 0)
}

///|
test "scenario force UP star varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "star", 1)
}

///|
test "scenario force UP cycle uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "cycle", 0)
}

///|
test "scenario force UP cycle varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "cycle", 1)
}

///|
test "scenario force UP disconnected uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "disconnected", 0)
}

///|
test "scenario force UP disconnected varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "disconnected", 1)
}

///|
test "scenario force UP binary uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "binary", 0)
}

///|
test "scenario force UP binary varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "binary", 1)
}

///|
test "scenario force UP diamond uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "diamond", 0)
}

///|
test "scenario force UP diamond varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "diamond", 1)
}

///|
test "scenario force UP ports uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "ports", 0)
}

///|
test "scenario force UP ports varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "ports", 1)
}

///|
test "scenario force UP compound uniform-small-seed7-orthogonal" {
  check_scenario("force", "UP", "compound", 0)
}

///|
test "scenario force UP compound varied-large-seed104729-polyline" {
  check_scenario("force", "UP", "compound", 1)
}

///|
test "scenario radial RIGHT chain uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "chain", 0)
}

///|
test "scenario radial RIGHT chain varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "chain", 1)
}

///|
test "scenario radial RIGHT star uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "star", 0)
}

///|
test "scenario radial RIGHT star varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "star", 1)
}

///|
test "scenario radial RIGHT cycle uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "cycle", 0)
}

///|
test "scenario radial RIGHT cycle varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "cycle", 1)
}

///|
test "scenario radial RIGHT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "disconnected", 0)
}

///|
test "scenario radial RIGHT disconnected varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "disconnected", 1)
}

///|
test "scenario radial RIGHT binary uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "binary", 0)
}

///|
test "scenario radial RIGHT binary varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "binary", 1)
}

///|
test "scenario radial RIGHT diamond uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "diamond", 0)
}

///|
test "scenario radial RIGHT diamond varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "diamond", 1)
}

///|
test "scenario radial RIGHT ports uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "ports", 0)
}

///|
test "scenario radial RIGHT ports varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "ports", 1)
}

///|
test "scenario radial RIGHT compound uniform-small-seed7-orthogonal" {
  check_scenario("radial", "RIGHT", "compound", 0)
}

///|
test "scenario radial RIGHT compound varied-large-seed104729-polyline" {
  check_scenario("radial", "RIGHT", "compound", 1)
}

///|
test "scenario radial DOWN chain uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "chain", 0)
}

///|
test "scenario radial DOWN chain varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "chain", 1)
}

///|
test "scenario radial DOWN star uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "star", 0)
}

///|
test "scenario radial DOWN star varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "star", 1)
}

///|
test "scenario radial DOWN cycle uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "cycle", 0)
}

///|
test "scenario radial DOWN cycle varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "cycle", 1)
}

///|
test "scenario radial DOWN disconnected uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "disconnected", 0)
}

///|
test "scenario radial DOWN disconnected varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "disconnected", 1)
}

///|
test "scenario radial DOWN binary uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "binary", 0)
}

///|
test "scenario radial DOWN binary varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "binary", 1)
}

///|
test "scenario radial DOWN diamond uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "diamond", 0)
}

///|
test "scenario radial DOWN diamond varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "diamond", 1)
}

///|
test "scenario radial DOWN ports uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "ports", 0)
}

///|
test "scenario radial DOWN ports varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "ports", 1)
}

///|
test "scenario radial DOWN compound uniform-small-seed7-orthogonal" {
  check_scenario("radial", "DOWN", "compound", 0)
}

///|
test "scenario radial DOWN compound varied-large-seed104729-polyline" {
  check_scenario("radial", "DOWN", "compound", 1)
}

///|
test "scenario radial LEFT chain uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "chain", 0)
}

///|
test "scenario radial LEFT chain varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "chain", 1)
}

///|
test "scenario radial LEFT star uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "star", 0)
}

///|
test "scenario radial LEFT star varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "star", 1)
}

///|
test "scenario radial LEFT cycle uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "cycle", 0)
}

///|
test "scenario radial LEFT cycle varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "cycle", 1)
}

///|
test "scenario radial LEFT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "disconnected", 0)
}

///|
test "scenario radial LEFT disconnected varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "disconnected", 1)
}

///|
test "scenario radial LEFT binary uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "binary", 0)
}

///|
test "scenario radial LEFT binary varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "binary", 1)
}

///|
test "scenario radial LEFT diamond uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "diamond", 0)
}

///|
test "scenario radial LEFT diamond varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "diamond", 1)
}

///|
test "scenario radial LEFT ports uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "ports", 0)
}

///|
test "scenario radial LEFT ports varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "ports", 1)
}

///|
test "scenario radial LEFT compound uniform-small-seed7-orthogonal" {
  check_scenario("radial", "LEFT", "compound", 0)
}

///|
test "scenario radial LEFT compound varied-large-seed104729-polyline" {
  check_scenario("radial", "LEFT", "compound", 1)
}

///|
test "scenario radial UP chain uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "chain", 0)
}

///|
test "scenario radial UP chain varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "chain", 1)
}

///|
test "scenario radial UP star uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "star", 0)
}

///|
test "scenario radial UP star varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "star", 1)
}

///|
test "scenario radial UP cycle uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "cycle", 0)
}

///|
test "scenario radial UP cycle varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "cycle", 1)
}

///|
test "scenario radial UP disconnected uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "disconnected", 0)
}

///|
test "scenario radial UP disconnected varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "disconnected", 1)
}

///|
test "scenario radial UP binary uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "binary", 0)
}

///|
test "scenario radial UP binary varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "binary", 1)
}

///|
test "scenario radial UP diamond uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "diamond", 0)
}

///|
test "scenario radial UP diamond varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "diamond", 1)
}

///|
test "scenario radial UP ports uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "ports", 0)
}

///|
test "scenario radial UP ports varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "ports", 1)
}

///|
test "scenario radial UP compound uniform-small-seed7-orthogonal" {
  check_scenario("radial", "UP", "compound", 0)
}

///|
test "scenario radial UP compound varied-large-seed104729-polyline" {
  check_scenario("radial", "UP", "compound", 1)
}

///|
test "scenario box RIGHT chain uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "chain", 0)
}

///|
test "scenario box RIGHT chain varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "chain", 1)
}

///|
test "scenario box RIGHT star uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "star", 0)
}

///|
test "scenario box RIGHT star varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "star", 1)
}

///|
test "scenario box RIGHT cycle uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "cycle", 0)
}

///|
test "scenario box RIGHT cycle varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "cycle", 1)
}

///|
test "scenario box RIGHT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "disconnected", 0)
}

///|
test "scenario box RIGHT disconnected varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "disconnected", 1)
}

///|
test "scenario box RIGHT binary uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "binary", 0)
}

///|
test "scenario box RIGHT binary varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "binary", 1)
}

///|
test "scenario box RIGHT diamond uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "diamond", 0)
}

///|
test "scenario box RIGHT diamond varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "diamond", 1)
}

///|
test "scenario box RIGHT ports uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "ports", 0)
}

///|
test "scenario box RIGHT ports varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "ports", 1)
}

///|
test "scenario box RIGHT compound uniform-small-seed7-orthogonal" {
  check_scenario("box", "RIGHT", "compound", 0)
}

///|
test "scenario box RIGHT compound varied-large-seed104729-polyline" {
  check_scenario("box", "RIGHT", "compound", 1)
}

///|
test "scenario box DOWN chain uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "chain", 0)
}

///|
test "scenario box DOWN chain varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "chain", 1)
}

///|
test "scenario box DOWN star uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "star", 0)
}

///|
test "scenario box DOWN star varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "star", 1)
}

///|
test "scenario box DOWN cycle uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "cycle", 0)
}

///|
test "scenario box DOWN cycle varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "cycle", 1)
}

///|
test "scenario box DOWN disconnected uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "disconnected", 0)
}

///|
test "scenario box DOWN disconnected varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "disconnected", 1)
}

///|
test "scenario box DOWN binary uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "binary", 0)
}

///|
test "scenario box DOWN binary varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "binary", 1)
}

///|
test "scenario box DOWN diamond uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "diamond", 0)
}

///|
test "scenario box DOWN diamond varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "diamond", 1)
}

///|
test "scenario box DOWN ports uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "ports", 0)
}

///|
test "scenario box DOWN ports varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "ports", 1)
}

///|
test "scenario box DOWN compound uniform-small-seed7-orthogonal" {
  check_scenario("box", "DOWN", "compound", 0)
}

///|
test "scenario box DOWN compound varied-large-seed104729-polyline" {
  check_scenario("box", "DOWN", "compound", 1)
}

///|
test "scenario box LEFT chain uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "chain", 0)
}

///|
test "scenario box LEFT chain varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "chain", 1)
}

///|
test "scenario box LEFT star uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "star", 0)
}

///|
test "scenario box LEFT star varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "star", 1)
}

///|
test "scenario box LEFT cycle uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "cycle", 0)
}

///|
test "scenario box LEFT cycle varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "cycle", 1)
}

///|
test "scenario box LEFT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "disconnected", 0)
}

///|
test "scenario box LEFT disconnected varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "disconnected", 1)
}

///|
test "scenario box LEFT binary uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "binary", 0)
}

///|
test "scenario box LEFT binary varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "binary", 1)
}

///|
test "scenario box LEFT diamond uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "diamond", 0)
}

///|
test "scenario box LEFT diamond varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "diamond", 1)
}

///|
test "scenario box LEFT ports uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "ports", 0)
}

///|
test "scenario box LEFT ports varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "ports", 1)
}

///|
test "scenario box LEFT compound uniform-small-seed7-orthogonal" {
  check_scenario("box", "LEFT", "compound", 0)
}

///|
test "scenario box LEFT compound varied-large-seed104729-polyline" {
  check_scenario("box", "LEFT", "compound", 1)
}

///|
test "scenario box UP chain uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "chain", 0)
}

///|
test "scenario box UP chain varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "chain", 1)
}

///|
test "scenario box UP star uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "star", 0)
}

///|
test "scenario box UP star varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "star", 1)
}

///|
test "scenario box UP cycle uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "cycle", 0)
}

///|
test "scenario box UP cycle varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "cycle", 1)
}

///|
test "scenario box UP disconnected uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "disconnected", 0)
}

///|
test "scenario box UP disconnected varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "disconnected", 1)
}

///|
test "scenario box UP binary uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "binary", 0)
}

///|
test "scenario box UP binary varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "binary", 1)
}

///|
test "scenario box UP diamond uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "diamond", 0)
}

///|
test "scenario box UP diamond varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "diamond", 1)
}

///|
test "scenario box UP ports uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "ports", 0)
}

///|
test "scenario box UP ports varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "ports", 1)
}

///|
test "scenario box UP compound uniform-small-seed7-orthogonal" {
  check_scenario("box", "UP", "compound", 0)
}

///|
test "scenario box UP compound varied-large-seed104729-polyline" {
  check_scenario("box", "UP", "compound", 1)
}

///|
test "scenario fixed RIGHT chain uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "chain", 0)
}

///|
test "scenario fixed RIGHT chain varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "chain", 1)
}

///|
test "scenario fixed RIGHT star uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "star", 0)
}

///|
test "scenario fixed RIGHT star varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "star", 1)
}

///|
test "scenario fixed RIGHT cycle uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "cycle", 0)
}

///|
test "scenario fixed RIGHT cycle varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "cycle", 1)
}

///|
test "scenario fixed RIGHT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "disconnected", 0)
}

///|
test "scenario fixed RIGHT disconnected varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "disconnected", 1)
}

///|
test "scenario fixed RIGHT binary uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "binary", 0)
}

///|
test "scenario fixed RIGHT binary varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "binary", 1)
}

///|
test "scenario fixed RIGHT diamond uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "diamond", 0)
}

///|
test "scenario fixed RIGHT diamond varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "diamond", 1)
}

///|
test "scenario fixed RIGHT ports uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "ports", 0)
}

///|
test "scenario fixed RIGHT ports varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "ports", 1)
}

///|
test "scenario fixed RIGHT compound uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "RIGHT", "compound", 0)
}

///|
test "scenario fixed RIGHT compound varied-large-seed104729-polyline" {
  check_scenario("fixed", "RIGHT", "compound", 1)
}

///|
test "scenario fixed DOWN chain uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "chain", 0)
}

///|
test "scenario fixed DOWN chain varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "chain", 1)
}

///|
test "scenario fixed DOWN star uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "star", 0)
}

///|
test "scenario fixed DOWN star varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "star", 1)
}

///|
test "scenario fixed DOWN cycle uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "cycle", 0)
}

///|
test "scenario fixed DOWN cycle varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "cycle", 1)
}

///|
test "scenario fixed DOWN disconnected uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "disconnected", 0)
}

///|
test "scenario fixed DOWN disconnected varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "disconnected", 1)
}

///|
test "scenario fixed DOWN binary uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "binary", 0)
}

///|
test "scenario fixed DOWN binary varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "binary", 1)
}

///|
test "scenario fixed DOWN diamond uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "diamond", 0)
}

///|
test "scenario fixed DOWN diamond varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "diamond", 1)
}

///|
test "scenario fixed DOWN ports uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "ports", 0)
}

///|
test "scenario fixed DOWN ports varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "ports", 1)
}

///|
test "scenario fixed DOWN compound uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "DOWN", "compound", 0)
}

///|
test "scenario fixed DOWN compound varied-large-seed104729-polyline" {
  check_scenario("fixed", "DOWN", "compound", 1)
}

///|
test "scenario fixed LEFT chain uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "chain", 0)
}

///|
test "scenario fixed LEFT chain varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "chain", 1)
}

///|
test "scenario fixed LEFT star uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "star", 0)
}

///|
test "scenario fixed LEFT star varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "star", 1)
}

///|
test "scenario fixed LEFT cycle uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "cycle", 0)
}

///|
test "scenario fixed LEFT cycle varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "cycle", 1)
}

///|
test "scenario fixed LEFT disconnected uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "disconnected", 0)
}

///|
test "scenario fixed LEFT disconnected varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "disconnected", 1)
}

///|
test "scenario fixed LEFT binary uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "binary", 0)
}

///|
test "scenario fixed LEFT binary varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "binary", 1)
}

///|
test "scenario fixed LEFT diamond uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "diamond", 0)
}

///|
test "scenario fixed LEFT diamond varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "diamond", 1)
}

///|
test "scenario fixed LEFT ports uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "ports", 0)
}

///|
test "scenario fixed LEFT ports varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "ports", 1)
}

///|
test "scenario fixed LEFT compound uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "LEFT", "compound", 0)
}

///|
test "scenario fixed LEFT compound varied-large-seed104729-polyline" {
  check_scenario("fixed", "LEFT", "compound", 1)
}

///|
test "scenario fixed UP chain uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "chain", 0)
}

///|
test "scenario fixed UP chain varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "chain", 1)
}

///|
test "scenario fixed UP star uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "star", 0)
}

///|
test "scenario fixed UP star varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "star", 1)
}

///|
test "scenario fixed UP cycle uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "cycle", 0)
}

///|
test "scenario fixed UP cycle varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "cycle", 1)
}

///|
test "scenario fixed UP disconnected uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "disconnected", 0)
}

///|
test "scenario fixed UP disconnected varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "disconnected", 1)
}

///|
test "scenario fixed UP binary uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "binary", 0)
}

///|
test "scenario fixed UP binary varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "binary", 1)
}

///|
test "scenario fixed UP diamond uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "diamond", 0)
}

///|
test "scenario fixed UP diamond varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "diamond", 1)
}

///|
test "scenario fixed UP ports uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "ports", 0)
}

///|
test "scenario fixed UP ports varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "ports", 1)
}

///|
test "scenario fixed UP compound uniform-small-seed7-orthogonal" {
  check_scenario("fixed", "UP", "compound", 0)
}

///|
test "scenario fixed UP compound varied-large-seed104729-polyline" {
  check_scenario("fixed", "UP", "compound", 1)
}
