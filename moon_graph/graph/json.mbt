///|
/// JSON import deliberately supports a small, explicit ELK-compatible subset.
fn io_object(
  value : Json,
  context : String,
) -> Map[String, Json] raise GraphError {
  match value {
    Object(obj) => obj
    _ => raise GraphError("\{context}: expected an object")
  }
}

///|
fn io_keys(
  obj : Map[String, Json],
  allowed : Array[String],
  context : String,
) -> Unit raise GraphError {
  for key, _ in obj {
    if !allowed.contains(key) {
      raise GraphError("\{context}: unsupported field '\{key}'")
    }
  }
}

///|
fn io_string(
  obj : Map[String, Json],
  key : String,
  context : String,
) -> String raise GraphError {
  match obj.get(key) {
    Some(String(value)) => value
    _ => raise GraphError("\{context}.\{key}: expected a string")
  }
}

///|
fn io_number(
  obj : Map[String, Json],
  key : String,
  fallback : Double,
  context : String,
  nonnegative? : Bool = true,
) -> Double raise GraphError {
  let value = match obj.get(key) {
    None => fallback
    Some(Number(n, ..)) => n
    _ => raise GraphError("\{context}.\{key}: expected a number")
  }
  if value.is_nan() ||
    value.is_inf() ||
    value < -1000000.0 ||
    value > 1000000.0 ||
    (nonnegative && value < 0.0) {
    raise GraphError(
      "\{context}.\{key}: coordinate or dimension outside supported bounds",
    )
  }
  value
}

///|
fn io_array(
  obj : Map[String, Json],
  key : String,
  context : String,
) -> Array[Json] raise GraphError {
  match obj.get(key) {
    None => []
    Some(Array(items)) => items
    _ => raise GraphError("\{context}.\{key}: expected an array")
  }
}

///|
fn io_labels(
  obj : Map[String, Json],
  context : String,
) -> Array[Label] raise GraphError {
  let result : Array[Label] = []
  for item in io_array(obj, "labels", context) {
    let label = io_object(item, "label")
    io_keys(label, ["text"], "label")
    result.push({ text: io_string(label, "text", "label"), })
  }
  result
}

///|
fn io_options(
  obj : Map[String, Json],
  context : String,
) -> Map[String, String] raise GraphError {
  let options : Map[String, String] = Map([])
  if obj.get("layoutOptions") is Some(value) {
    for key, item in io_object(value, "\{context}.layoutOptions") {
      let option = match item {
        String(s) => s
        Number(n, ..) => {
          if n.is_nan() || n.is_inf() {
            raise GraphError("invalid numeric option '\{key}'")
          }
          item.stringify()
        }
        True => "true"
        False => "false"
        _ =>
          raise GraphError(
            "layout option '\{key}' must be a scalar string, number or boolean",
          )
      }
      options.set(key, option)
    }
  }
  options
}

///|
fn io_point(value : Json) -> Point raise GraphError {
  let obj = io_object(value, "point")
  io_keys(obj, ["x", "y"], "point")
  if obj.get("x") is None || obj.get("y") is None {
    raise GraphError("point requires x and y")
  }
  {
    x: io_number(obj, "x", 0.0, "point"),
    y: io_number(obj, "y", 0.0, "point"),
  }
}

///|
fn io_endpoint(
  obj : Map[String, Json],
  key : String,
) -> String raise GraphError {
  let items = io_array(obj, key, "edge")
  if items.length() != 1 {
    raise GraphError(
      "edge.\{key}: exactly one endpoint required; hyperedges are unsupported",
    )
  }
  match items[0] {
    String(id) => id
    _ => raise GraphError("edge.\{key}: endpoint must be a string")
  }
}

///|
fn io_edge(value : Json) -> Edge raise GraphError {
  let obj = io_object(value, "edge")
  io_keys(obj, ["id", "sources", "targets", "labels", "sections"], "edge")
  let points : Array[Point] = []
  let sections = io_array(obj, "sections", "edge")
  if sections.length() > 1 {
    raise GraphError("multiple edge sections are unsupported")
  }
  for item in sections {
    let section = io_object(item, "section")
    io_keys(section, ["id", "startPoint", "endPoint", "bendPoints"], "section")
    if section.get("id") is Some(_) {
      ignore(io_string(section, "id", "section"))
    }
    match section.get("startPoint") {
      Some(point) => points.push(io_point(point))
      None => raise GraphError("section.startPoint is required")
    }
    for point in io_array(section, "bendPoints", "section") {
      points.push(io_point(point))
    }
    match section.get("endPoint") {
      Some(point) => points.push(io_point(point))
      None => raise GraphError("section.endPoint is required")
    }
  }
  {
    id: io_string(obj, "id", "edge"),
    source: io_endpoint(obj, "sources"),
    target: io_endpoint(obj, "targets"),
    labels: io_labels(obj, "edge"),
    points,
  }
}

///|
fn io_node(
  value : Json,
  depth : Int,
  counters : Array[Int],
) -> Node raise GraphError {
  if depth > 32 {
    raise GraphError("graph hierarchy exceeds 32 levels")
  }
  counters[0] += 1
  if counters[0] > 500 {
    raise GraphError("graph exceeds 500 nodes")
  }
  let obj = io_object(value, "node")
  io_keys(
    obj,
    [
      "id", "x", "y", "width", "height", "children", "edges", "ports", "labels",
      "layoutOptions",
    ],
    "node",
  )
  let children : Array[Node] = []
  for child in io_array(obj, "children", "node") {
    children.push(io_node(child, depth + 1, counters))
  }
  let edges : Array[Edge] = []
  for edge in io_array(obj, "edges", "node") {
    counters[1] += 1
    if counters[1] > 3000 {
      raise GraphError("graph exceeds 3000 edges")
    }
    edges.push(io_edge(edge))
  }
  let ports : Array[Port] = []
  for value in io_array(obj, "ports", "node") {
    let port = io_object(value, "port")
    io_keys(port, ["id", "x", "y", "layoutOptions"], "port")
    let options = io_options(port, "port")
    for key, _ in options {
      if key != "elk.port.side" {
        raise GraphError("unsupported port option '\{key}'")
      }
    }
    ports.push({
      id: io_string(port, "id", "port"),
      side: options.get("elk.port.side").unwrap_or("EAST"),
      x: io_number(port, "x", 0.0, "port"),
      y: io_number(port, "y", 0.0, "port"),
    })
  }
  let default_width = if depth == 0 { 0.0 } else { 100.0 }
  let default_height = if depth == 0 { 0.0 } else { 48.0 }
  {
    id: io_string(obj, "id", "node"),
    x: io_number(obj, "x", 0.0, "node"),
    y: io_number(obj, "y", 0.0, "node"),
    width: io_number(obj, "width", default_width, "node", nonnegative=true),
    height: io_number(obj, "height", default_height, "node", nonnegative=true),
    children,
    edges,
    ports,
    labels: io_labels(obj, "node"),
    options: io_options(obj, "node"),
  }
}

///|
fn io_check_size(text : String) -> Unit raise GraphError {
  // UTF-8 byte count without allocating a second input-sized buffer.
  let mut bytes = 0
  for c in text {
    let n = c.to_int()
    bytes += if n <= 0x7f {
      1
    } else if n <= 0x7ff {
      2
    } else if n <= 0xffff {
      3
    } else {
      4
    }
    if bytes > 1048576 {
      raise GraphError("input exceeds 1 MiB UTF-8 limit")
    }
  }
}

///|
// This installed core version flags its explicit nesting-limit label as deprecated.
// Keep the bound; suppress only that compatibility warning on this function.
#warnings("-deprecated")
pub fn parse_graph(text : String) -> Node raise GraphError {
  io_check_size(text)
  let json = @json.parse(text, max_nesting_depth=128) catch {
    error => raise GraphError("invalid JSON: \{error}")
  }
  let graph = io_node(json, 0, [0, 0])
  let problems = validate(graph)
  if !problems.is_empty() {
    raise GraphError(problems.join("; "))
  }
  graph
}

///|
fn io_labels_json(labels : Array[Label]) -> Json {
  Json::array(
    labels.map(label => Json::object({ "text": Json::string(label.text) })),
  )
}

///|
fn io_point_json(point : Point) -> Json {
  Json::object({ "x": Json::number(point.x), "y": Json::number(point.y) })
}

///|
fn io_node_json(node : Node) -> Json {
  let options : Map[String, Json] = Map([])
  for key, value in node.options {
    options.set(key, Json::string(value))
  }
  let edges = node.edges.map(edge => {
    let obj : Map[String, Json] = {
      "id": Json::string(edge.id),
      "sources": Json::array([Json::string(edge.source)]),
      "targets": Json::array([Json::string(edge.target)]),
      "labels": io_labels_json(edge.labels),
    }
    if edge.points.length() >= 2 {
      let bends : Array[Json] = []
      for i = 1; i + 1 < edge.points.length(); i = i + 1 {
        bends.push(io_point_json(edge.points[i]))
      }
      obj.set(
        "sections",
        Json::array([
          Json::object({
            "id": Json::string(edge.id + "_section"),
            "startPoint": io_point_json(edge.points[0]),
            "endPoint": io_point_json(edge.points[edge.points.length() - 1]),
            "bendPoints": Json::array(bends),
          }),
        ]),
      )
    }
    Json::object(obj)
  })
  Json::object({
    "id": Json::string(node.id),
    "x": Json::number(node.x),
    "y": Json::number(node.y),
    "width": Json::number(node.width),
    "height": Json::number(node.height),
    "children": Json::array(node.children.map(io_node_json)),
    "edges": Json::array(edges),
    "ports": Json::array(
      node.ports.map(port => {
        Json::object({
          "id": Json::string(port.id),
          "x": Json::number(port.x),
          "y": Json::number(port.y),
          "layoutOptions": Json::object({
            "elk.port.side": Json::string(port.side),
          }),
        })
      }),
    ),
    "labels": io_labels_json(node.labels),
    "layoutOptions": Json::object(options),
  })
}

///|
pub fn graph_json(graph : Node, pretty? : Bool = false) -> String {
  let json = io_node_json(graph)
  if pretty {
    json.stringify(indent=2)
  } else {
    json.stringify()
  }
}

///|
pub fn layout_json(
  text : String,
  pretty? : Bool = false,
) -> String raise GraphError {
  graph_json(new_elk_engine().layout(parse_graph(text)), pretty~)
}
