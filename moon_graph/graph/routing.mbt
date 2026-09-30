///|
/// Endpoint-aware Manhattan routing. Only the two endpoint rectangles are
/// obstacles; avoiding every other node is deliberately outside this kernel.
fn route_side(node : Node, endpoint : String, point : Point) -> Int {
  for port in node.ports {
    if port.id == endpoint {
      return match port.side {
        "NORTH" => 0
        "EAST" => 1
        "SOUTH" => 2
        _ => 3
      }
    }
  }
  if absd(point.y - node.y) < 0.000001 {
    0
  } else if absd(point.x - node.x - node.width) < 0.000001 {
    1
  } else if absd(point.y - node.y - node.height) < 0.000001 {
    2
  } else {
    3
  }
}

///|
fn route_lead(
  node : Node,
  other : Node,
  point : Point,
  side : Int,
  distance : Double,
) -> Point {
  let mut step = distance
  // Leave a positive gap between leads of facing, closely spaced endpoints.
  if node.id != other.id {
    if point.y > other.y && point.y < other.y + other.height {
      if side == 1 && other.x >= point.x {
        step = mind(step, (other.x - point.x) / 3.0)
      }
      if side == 3 && other.x + other.width <= point.x {
        step = mind(step, (point.x - other.x - other.width) / 3.0)
      }
    }
    if point.x > other.x && point.x < other.x + other.width {
      if side == 2 && other.y >= point.y {
        step = mind(step, (other.y - point.y) / 3.0)
      }
      if side == 0 && other.y + other.height <= point.y {
        step = mind(step, (point.y - other.y - other.height) / 3.0)
      }
    }
  }
  match side {
    0 => { x: point.x, y: maxd(0.0, point.y - step), }
    1 => { x: point.x + step, y: point.y, }
    2 => { x: point.x, y: point.y + step, }
    _ => { x: maxd(0.0, point.x - step), y: point.y, }
  }
}

///|
fn crosses_rectangle(a : Point, b : Point, node : Node) -> Bool {
  let eps = 0.000001
  if absd(a.x - b.x) < eps {
    a.x > node.x + eps &&
    a.x < node.x + node.width - eps &&
    maxd(a.y, b.y) > node.y + eps &&
    mind(a.y, b.y) < node.y + node.height - eps
  } else if absd(a.y - b.y) < eps {
    a.y > node.y + eps &&
    a.y < node.y + node.height - eps &&
    maxd(a.x, b.x) > node.x + eps &&
    mind(a.x, b.x) < node.x + node.width - eps
  } else {
    true
  }
}

///|
/// A 4x4 visibility grid gives bounded shortest-path work per edge.
fn endpoint_path(
  start : Point,
  end : Point,
  source : Node,
  target : Node,
  clearance : Double,
) -> Array[Point] {
  let xs = [
    start.x,
    end.x,
    maxd(0.0, mind(source.x, target.x) - clearance),
    maxd(source.x + source.width, target.x + target.width) + clearance,
  ]
  let ys = [
    start.y,
    end.y,
    maxd(0.0, mind(source.y, target.y) - clearance),
    maxd(source.y + source.height, target.y + target.height) + clearance,
  ]
  let points : Array[Point] = Array::makei(16, i => {
    x: xs[i % 4],
    y: ys[i / 4],
  })
  let distances = Array::make(16, 1.0e100)
  let previous = Array::make(16, -1)
  let visited = Array::make(16, false)
  distances[0] = 0.0
  for _ in 0..<16 {
    let mut selected = -1
    for i in 0..<16 {
      if !visited[i] && (selected < 0 || distances[i] < distances[selected]) {
        selected = i
      }
    }
    if selected < 0 || distances[selected] >= 1.0e100 {
      break
    }
    if selected == 5 {
      break
    }
    visited[selected] = true
    for j in 0..<16 {
      if visited[j] || (selected % 4 != j % 4 && selected / 4 != j / 4) {
        continue
      }
      let a = points[selected]
      let b = points[j]
      if crosses_rectangle(a, b, source) || crosses_rectangle(a, b, target) {
        continue
      }
      let cost = distances[selected] + absd(a.x - b.x) + absd(a.y - b.y)
      if cost < distances[j] {
        distances[j] = cost
        previous[j] = selected
      }
    }
  }
  // Fixed layouts may intentionally overlap endpoint rectangles. No router
  // can promise interior-free paths for an endpoint buried inside another.
  if distances[5] >= 1.0e100 {
    return [start, { x: start.x, y: end.y, }, end]
  }
  let reverse : Array[Point] = []
  let mut index = 5
  while index >= 0 {
    reverse.push(points[index])
    index = previous[index]
  }
  let path : Array[Point] = []
  for i in 0..<reverse.length() {
    path.push(reverse[reverse.length() - 1 - i])
  }
  path
}

///|
fn push_distinct(path : Array[Point], point : Point) -> Unit {
  if path.is_empty() || path[path.length() - 1] != point {
    path.push(point)
  }
}

///|
fn self_route(
  node : Node,
  start : Point,
  end : Point,
  start_side : Int,
  end_side : Int,
  distance : Double,
) -> Array[Point] {
  let left = maxd(0.0, node.x - distance)
  let top = maxd(0.0, node.y - distance)
  let right = node.x + node.width + distance
  let bottom = node.y + node.height + distance
  let start_ring = match start_side {
    0 => { x: start.x, y: top, }
    1 => { x: right, y: start.y, }
    2 => { x: start.x, y: bottom, }
    _ => { x: left, y: start.y, }
  }
  let end_ring = match end_side {
    0 => { x: end.x, y: top, }
    1 => { x: right, y: end.y, }
    2 => { x: end.x, y: bottom, }
    _ => { x: left, y: end.y, }
  }
  let corners : Array[Point] = [
    { x: right, y: top, },
    { x: right, y: bottom, },
    { x: left, y: bottom, },
    { x: left, y: top, },
  ]
  let path = [start]
  push_distinct(path, start_ring)
  let steps = if start_side == end_side {
    4
  } else {
    (end_side - start_side + 4) % 4
  }
  for i in 0..<steps {
    push_distinct(path, corners[(start_side + i) % 4])
  }
  push_distinct(path, end_ring)
  push_distinct(path, end)
  path
}

///|
fn routed_points(
  edge : Edge,
  source : Node,
  target : Node,
  cfg : Config,
  lane : Int,
) -> Array[Point] {
  let start = anchor(source, edge.source, {
    x: target.x + target.width / 2.0,
    y: target.y + target.height / 2.0,
  })
  let end = if source.id == target.id && edge.target == target.id {
    { x: target.x + target.width / 2.0, y: target.y + target.height, }
  } else {
    anchor(target, edge.target, {
      x: source.x + source.width / 2.0,
      y: source.y + source.height / 2.0,
    })
  }
  let start_side = route_side(source, edge.source, start)
  let end_side = route_side(target, edge.target, end)
  if source.id == target.id {
    return self_route(
      source,
      start,
      end,
      start_side,
      end_side,
      20.0 + lane.to_double() * 12.0,
    )
  }
  if cfg.routing == "POLYLINE" &&
    lane == 0 &&
    edge.source == source.id &&
    edge.target == target.id {
    return [start, end]
  }
  let first = route_lead(source, target, start, start_side, 12.0)
  let last = route_lead(target, source, end, end_side, 12.0)
  let path = [start]
  push_distinct(path, first)
  if lane == 0 {
    for point in endpoint_path(first, last, source, target, 12.0) {
      push_distinct(path, point)
    }
  } else {
    // Perpendicular outer lanes remain visibly distinct even for aligned nodes.
    let waypoint : Point = if cfg.direction == "DOWN" || cfg.direction == "UP" {
      {
        x: maxd(source.x + source.width, target.x + target.width) +
        12.0 * lane.to_double(),
        y: (first.y + last.y) / 2.0,
      }
    } else {
      {
        x: (first.x + last.x) / 2.0,
        y: maxd(source.y + source.height, target.y + target.height) +
        12.0 * lane.to_double(),
      }
    }
    for point in endpoint_path(first, waypoint, source, target, 12.0) {
      push_distinct(path, point)
    }
    for point in endpoint_path(waypoint, last, source, target, 12.0) {
      push_distinct(path, point)
    }
  }
  push_distinct(path, end)
  if path.length() == 1 {
    path.push(end)
  }
  path
}
