///|
pub struct Engine {}

///|
pub fn new_elk_engine() -> Engine {
  Engine::{ }
}

///|
fn place_ports(node : Node) -> Unit {
  for side in ["NORTH", "SOUTH", "WEST", "EAST"] {
    let mut count = 0
    for port in node.ports {
      if port.side == side {
        count += 1
      }
    }
    let mut position = 0
    for port in node.ports {
      if port.side != side {
        continue
      }
      position += 1
      let ratio = position.to_double() / (count + 1).to_double()
      port.x = if side == "WEST" {
        0.0
      } else if side == "EAST" {
        node.width
      } else {
        node.width * ratio
      }
      port.y = if side == "NORTH" {
        0.0
      } else if side == "SOUTH" {
        node.height
      } else {
        node.height * ratio
      }
    }
  }
}

///|
fn boundary(node : Node, toward : Point) -> Point {
  let cx = node.x + node.width / 2.0
  let cy = node.y + node.height / 2.0
  let dx = toward.x - cx
  let dy = toward.y - cy
  if absd(dx) + absd(dy) < 0.000001 {
    return { x: node.x + node.width, y: cy, }
  }
  let tx = if absd(dx) < 0.000001 {
    1.0e100
  } else {
    node.width / 2.0 / absd(dx)
  }
  let ty = if absd(dy) < 0.000001 {
    1.0e100
  } else {
    node.height / 2.0 / absd(dy)
  }
  let scale = mind(tx, ty)
  { x: cx + dx * scale, y: cy + dy * scale, }
}

///|
fn anchor(node : Node, endpoint : String, toward : Point) -> Point {
  for port in node.ports {
    if port.id == endpoint {
      return { x: node.x + port.x, y: node.y + port.y, }
    }
  }
  boundary(node, toward)
}

///|
fn route_edges(graph : Node, cfg : Config) -> Unit {
  let indices = endpoint_indices(graph)
  let lanes : Map[String, Int] = Map([])
  for edge in graph.edges {
    let source = graph.children[indices[edge.source]]
    let target = graph.children[indices[edge.target]]
    let pair = indices[edge.source].to_string() +
      ":" +
      indices[edge.target].to_string()
    let lane = lanes.get(pair).unwrap_or(0)
    lanes[pair] = lane + 1
    edge.points = routed_points(edge, source, target, cfg, lane)
    for point in edge.points {
      graph.width = maxd(graph.width, point.x + cfg.padding)
      graph.height = maxd(graph.height, point.y + cfg.padding)
    }
  }
}

///|
fn normalize_and_size(graph : Node, cfg : Config) -> Unit {
  if cfg.algorithm != "fixed" && !graph.children.is_empty() {
    let mut min_x = graph.children[0].x
    let mut min_y = graph.children[0].y
    for node in graph.children {
      min_x = mind(min_x, node.x)
      min_y = mind(min_y, node.y)
    }
    for node in graph.children {
      node.x += cfg.padding - min_x
      node.y += cfg.padding - min_y
    }
  }
  let mut width = cfg.padding * 2.0
  let mut height = cfg.padding * 2.0
  for node in graph.children {
    width = maxd(width, node.x + node.width + cfg.padding)
    height = maxd(height, node.y + node.height + cfg.padding)
  }
  graph.width = maxd(graph.width, width)
  graph.height = maxd(graph.height, height)
  if cfg.algorithm != "fixed" {
    if cfg.direction == "LEFT" {
      for node in graph.children {
        node.x = graph.width - cfg.padding - node.x - node.width + cfg.padding
      }
    } else if cfg.direction == "UP" {
      for node in graph.children {
        node.y = graph.height - cfg.padding - node.y - node.height + cfg.padding
      }
    }
  }
}

///|
fn layout_container(
  graph : Node,
  inherited : Map[String, String],
) -> Unit raise GraphError {
  let options = inherited.copy()
  for key, value in graph.options {
    options[key] = value
  }
  let cfg = config(options)
  for child in graph.children {
    if !child.children.is_empty() {
      layout_container(child, options)
    }
    place_ports(child)
  }
  match cfg.algorithm {
    "layered" => layered(graph, cfg)
    "force" => force_layout(graph, cfg)
    "radial" => radial(graph, cfg)
    "box" => box_layout(graph, cfg)
    "fixed" => ()
    _ => raise GraphError("Unsupported algorithm: " + cfg.algorithm)
  }
  if cfg.algorithm != "layered" &&
    cfg.algorithm != "fixed" &&
    (cfg.direction == "DOWN" || cfg.direction == "UP") {
    for node in graph.children {
      let old_x = node.x
      node.x = node.y
      node.y = old_x
    }
  }
  if cfg.algorithm == "force" ||
    cfg.algorithm == "radial" ||
    cfg.algorithm == "box" {
    remove_overlaps(graph.children, cfg.spacing)
  }
  normalize_and_size(graph, cfg)
  route_edges(graph, cfg)
  place_ports(graph)
}

///|
/// Return a laid-out deep copy. Invalid input never partially mutates callers.
pub fn Engine::layout(_self : Engine, graph : Node) -> Node raise GraphError {
  let errors = validate(graph)
  if !errors.is_empty() {
    raise GraphError(errors.join("; "))
  }
  let result = clone_graph(graph)
  layout_container(result, {})
  let output_errors = validate(result)
  if !output_errors.is_empty() {
    raise GraphError(
      "Layout exceeds supported bounds: " + output_errors.join("; "),
    )
  }
  result
}
