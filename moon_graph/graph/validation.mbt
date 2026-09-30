///|
fn valid_scalar(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf() && value >= 0.0 && value <= 1000000.0
}

///|
fn register_id(
  id : String,
  ids : Map[String, Bool],
  errors : Array[String],
) -> Unit {
  if id.trim().is_empty() || id.length() > 256 {
    errors.push("ID must contain 1..256 characters")
  }
  if ids.contains(id) {
    errors.push("Duplicate ID: " + id)
  }
  ids[id] = true
}

///|
fn validate_node(
  node : Node,
  depth : Int,
  ids : Map[String, Bool],
  counts : Array[Int],
  errors : Array[String],
) -> Unit {
  // Return early on excess depth/count; public mutable records can contain cycles.
  if depth > 32 {
    errors.push("Hierarchy depth exceeds 32")
    return
  }
  counts[0] += 1
  if counts[0] > 500 {
    errors.push("Graph exceeds 500 nodes (including root)")
    return
  }
  register_id(node.id, ids, errors)
  if !valid_scalar(node.x) ||
    !valid_scalar(node.y) ||
    !valid_scalar(node.width) ||
    !valid_scalar(node.height) {
    errors.push("Invalid geometry on node: " + node.id)
  }
  if depth > 0 &&
    node.children.is_empty() &&
    (node.width <= 0.0 || node.height <= 0.0) {
    errors.push("Leaf node dimensions must be positive: " + node.id)
  }
  ignore(config(node.options)) catch {
    GraphError(message) => errors.push(message)
  }
  for port in node.ports {
    counts[2] += 1
    if counts[2] > 5000 {
      errors.push("Graph exceeds 5000 ports")
      break
    }
    register_id(port.id, ids, errors)
    if !["NORTH", "SOUTH", "EAST", "WEST"].contains(port.side) {
      errors.push("Invalid port side: " + port.side)
    }
    if !valid_scalar(port.x) || !valid_scalar(port.y) {
      errors.push("Invalid port geometry: " + port.id)
    }
  }
  let endpoints : Map[String, Bool] = Map([])
  for child in node.children {
    endpoints[child.id] = true
    for port in child.ports {
      endpoints[port.id] = true
    }
  }
  for edge in node.edges {
    counts[1] += 1
    if counts[1] > 3000 {
      errors.push("Graph exceeds 3000 edges")
      break
    }
    register_id(edge.id, ids, errors)
    if !endpoints.contains(edge.source) || !endpoints.contains(edge.target) {
      errors.push(
        "Edge endpoints must be direct siblings or their ports: " + edge.id,
      )
    }
    if edge.points.length() > 1000 {
      errors.push("Too many points on edge: " + edge.id)
    }
    for point in edge.points {
      if !valid_scalar(point.x) || !valid_scalar(point.y) {
        errors.push("Invalid edge point: " + edge.id)
        break
      }
    }
  }
  for child in node.children {
    if counts[0] >= 500 {
      errors.push("Graph exceeds 500 nodes (including root)")
      break
    }
    validate_node(child, depth + 1, ids, counts, errors)
  }
}

///|
/// Validate structure and supported options without mutating the graph.
pub fn validate(graph : Node) -> Array[String] {
  let errors : Array[String] = []
  validate_node(graph, 0, {}, [0, 0, 0], errors)
  errors
}
