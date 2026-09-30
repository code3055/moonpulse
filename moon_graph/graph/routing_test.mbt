///|
fn segment_hits_node(
  a : @graph.Point,
  b : @graph.Point,
  node : @graph.Node,
) -> Bool {
  let left = if a.x < b.x { a.x } else { b.x }
  let right = if a.x > b.x { a.x } else { b.x }
  let top = if a.y < b.y { a.y } else { b.y }
  let bottom = if a.y > b.y { a.y } else { b.y }
  if a.x == b.x {
    a.x > node.x + 0.000001 &&
    a.x < node.x + node.width - 0.000001 &&
    bottom > node.y + 0.000001 &&
    top < node.y + node.height - 0.000001
  } else {
    a.y > node.y + 0.000001 &&
    a.y < node.y + node.height - 0.000001 &&
    right > node.x + 0.000001 &&
    left < node.x + node.width - 0.000001
  }
}

///|
fn check_route_geometry(graph : @graph.Node) -> Unit raise {
  for edge in graph.edges {
    assert_true(edge.points.length() >= 2)
    for point in edge.points {
      assert_true(point.x >= 0.0 && point.y >= 0.0)
      assert_true(point.x <= graph.width && point.y <= graph.height)
    }
    for i in 1..<edge.points.length() {
      let a = edge.points[i - 1]
      let b = edge.points[i]
      assert_true(a.x == b.x || a.y == b.y)
      for node in graph.children {
        assert_false(segment_hits_node(a, b, node))
      }
    }
  }
}

///|
fn check_port_departure(
  start : @graph.Point,
  next : @graph.Point,
  side : String,
) -> Unit raise {
  match side {
    "WEST" => assert_true(next.x < start.x && next.y == start.y)
    "EAST" => assert_true(next.x > start.x && next.y == start.y)
    "NORTH" => assert_true(next.y < start.y && next.x == start.x)
    _ => assert_true(next.y > start.y && next.x == start.x)
  }
}

///|
test "routing respects all sixteen port side pairs in all directions" {
  for direction in ["RIGHT", "LEFT", "DOWN", "UP"] {
    for source_side in ["NORTH", "EAST", "SOUTH", "WEST"] {
      for target_side in ["NORTH", "EAST", "SOUTH", "WEST"] {
        let graph = @graph.new_graph()
        graph.options["elk.direction"] = direction
        let a = @graph.new_node("a")
        let b = @graph.new_node("b")
        a.ports.push(@graph.new_port("ap", side=source_side))
        b.ports.push(@graph.new_port("bp", side=target_side))
        graph.children.push(a)
        graph.children.push(b)
        graph.edges.push(@graph.new_edge("e", "ap", "bp"))
        let output = @graph.new_elk_engine().layout(graph)
        check_route_geometry(output)
        let points = output.edges[0].points
        check_port_departure(points[0], points[1], source_side)
        check_port_departure(
          points[points.length() - 1],
          points[points.length() - 2],
          target_side,
        )
      }
    }
  }
}

///|
test "self loops preserve outward port directions without crossing the node" {
  for source_side in ["NORTH", "EAST", "SOUTH", "WEST"] {
    for target_side in ["NORTH", "EAST", "SOUTH", "WEST"] {
      let graph = @graph.new_graph()
      let a = @graph.new_node("a")
      a.ports.push(@graph.new_port("ap", side=source_side))
      a.ports.push(@graph.new_port("bp", side=target_side))
      graph.children.push(a)
      graph.edges.push(@graph.new_edge("loop", "ap", "bp"))
      let output = @graph.new_elk_engine().layout(graph)
      check_route_geometry(output)
      let points = output.edges[0].points
      check_port_departure(points[0], points[1], source_side)
      check_port_departure(
        points[points.length() - 1],
        points[points.length() - 2],
        target_side,
      )
    }
  }
}

///|
test "aligned parallel edges have distinct visible lanes and safe endpoints" {
  for direction in ["RIGHT", "LEFT", "DOWN", "UP"] {
    let graph = @graph.new_graph()
    graph.options["elk.direction"] = direction
    graph.children.push(@graph.new_node("a"))
    graph.children.push(@graph.new_node("b"))
    for i in 0..<6 {
      graph.edges.push(@graph.new_edge("e\{i}", "a", "b"))
    }
    let output = @graph.new_elk_engine().layout(graph)
    check_route_geometry(output)
    for i in 0..<output.edges.length() {
      for j in (i + 1)..<output.edges.length() {
        assert_true(output.edges[i].points != output.edges[j].points)
      }
    }
  }
}

///|
test "zero padding routes remain within nonnegative geometry" {
  for side in ["NORTH", "EAST", "SOUTH", "WEST"] {
    let graph = @graph.new_graph()
    graph.options["moon.padding"] = "0"
    let a = @graph.new_node("a")
    a.ports.push(@graph.new_port("ap", side~))
    graph.children.push(a)
    graph.children.push(@graph.new_node("b"))
    graph.edges.push(@graph.new_edge("loop", "ap", "ap"))
    graph.edges.push(@graph.new_edge("e", "ap", "b"))
    let output = @graph.new_elk_engine().layout(graph)
    check_route_geometry(output)
    assert_true(@graph.validate(output).is_empty())
  }
}

///|
test "reciprocal edges receive separate lanes for both routing styles" {
  for direction in ["RIGHT", "LEFT", "DOWN", "UP"] {
    for routing in ["ORTHOGONAL", "POLYLINE"] {
      let graph = @graph.new_graph()
      graph.options["elk.direction"] = direction
      graph.options["elk.edgeRouting"] = routing
      graph.children.push(@graph.new_node("draft"))
      graph.children.push(@graph.new_node("review"))
      let forward = @graph.new_edge("submit", "draft", "review")
      forward.labels.push({ text: "提交", })
      let reverse = @graph.new_edge("revise", "review", "draft")
      reverse.labels.push({ text: "修改", })
      graph.edges.push(forward)
      graph.edges.push(reverse)
      let output = @graph.new_elk_engine().layout(graph)
      let straight = output.edges[0].points[0]
      let mut separate_lane = false
      for point in output.edges[1].points {
        if direction == "RIGHT" || direction == "LEFT" {
          if point.y != straight.y {
            separate_lane = true
          }
        } else if point.x != straight.x {
          separate_lane = true
        }
      }
      assert_true(separate_lane)
      check_route_geometry(output)
      assert_eq(output.edges[0].source, "draft")
      assert_eq(output.edges[1].source, "review")
    }
  }
}

///|
test "workflow return edge uses a clear overhead lane with separate anchors" {
  let input = @graph.parse_text(
    "edge submit draft review 提交\nedge accept review publish 通过\nedge revise review draft 修改\nnode draft 撰写文档\nnode review 内容评审\nnode publish 发布归档",
  )
  let output = @graph.new_elk_engine().layout(input)
  let draft = output.children[0]
  let review = output.children[1]
  let points = output.edges[2].points
  assert_eq(points.length(), 4)
  assert_eq(points[0].y, review.y)
  assert_eq(points[3].y, draft.y)
  assert_true(points[1].y < review.y && points[1].y < draft.y)
  assert_eq(points[1].y, points[2].y)
  assert_true(points[1].x != points[2].x)
  check_route_geometry(output)
}

///|
test "overlapping fixed nodes retain positions with finite fallback routes" {
  let graph = @graph.new_graph()
  graph.options["elk.algorithm"] = "fixed"
  graph.children.push(@graph.new_node("a"))
  graph.children.push(@graph.new_node("b", width=150.0, height=150.0))
  graph.edges.push(@graph.new_edge("e", "a", "b"))
  let output = @graph.new_elk_engine().layout(graph)
  assert_true(@graph.validate(output).is_empty())
  assert_eq(output.children[0].x, 0.0)
  assert_eq(output.children[1].x, 0.0)
}
