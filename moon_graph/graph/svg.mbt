///|
fn svg_min(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn svg_max(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// XML 1.0 safe escaping, including invalid control characters.
fn svg_escape(value : String) -> String {
  let out = StringBuilder()
  for c in value {
    match c {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '"' => out.write_string("&quot;")
      '\'' => out.write_string("&apos;")
      _ => {
        let code = c.to_int()
        if code == 9 ||
          code == 10 ||
          code == 13 ||
          (code >= 32 && code <= 0xd7ff) ||
          (code >= 0xe000 && code <= 0xfffd) ||
          (code >= 0x10000 && code <= 0x10ffff) {
          out.write_char(c)
        } else {
          out.write_char('�')
        }
      }
    }
  }
  out.to_string()
}

///|
/// Choose a segment midpoint rather than the middle vertex index.
/// Rendering and bounds share this position so offset labels are not clipped.
fn svg_edge_label_position(edge : Edge) -> Point {
  let mut start = edge.points[0]
  let mut end = edge.points[1]
  let mut best_length = -1.0
  let mut best_horizontal = false
  for i in 1..<edge.points.length() {
    let a = edge.points[i - 1]
    let b = edge.points[i]
    let dx = absd(b.x - a.x)
    let dy = absd(b.y - a.y)
    let horizontal = dy < 0.000001 && dx > 0.000001
    let length = (dx * dx + dy * dy).sqrt()
    if (horizontal && !best_horizontal) ||
      (horizontal == best_horizontal && length > best_length) {
      start = a
      end = b
      best_length = length
      best_horizontal = horizontal
    }
  }
  let x = (start.x + end.x) / 2.0
  let y = (start.y + end.y) / 2.0
  if absd(start.x - end.x) < 0.000001 && absd(start.y - end.y) > 0.000001 {
    let mut half_width = 0.0
    for label in edge.labels {
      half_width = maxd(half_width, label.text.char_length().to_double() * 6.0)
    }
    { x: x + half_width + 8.0, y: y + 4.0, }
  } else {
    { x, y: y - 6.0, }
  }
}

///|
fn svg_bounds(
  node : Node,
  ox : Double,
  oy : Double,
  bounds : Array[Double],
  root? : Bool = false,
) -> Unit {
  let x = ox + node.x
  let y = oy + node.y
  bounds[0] = svg_min(bounds[0], x)
  bounds[1] = svg_min(bounds[1], y)
  bounds[2] = svg_max(bounds[2], x + node.width)
  bounds[3] = svg_max(bounds[3], y + node.height)
  if !root {
    let label_y = if node.children.is_empty() {
      y + node.height / 2.0 + 4.0
    } else {
      y + 16.0
    }
    if node.labels.is_empty() {
      svg_label_bounds(node.id, x + node.width / 2.0, label_y, bounds)
    } else {
      for index, label in node.labels {
        svg_label_bounds(
          label.text,
          x + node.width / 2.0,
          label_y + index.to_double() * 14.0,
          bounds,
        )
      }
    }
  }
  for port in node.ports {
    bounds[0] = svg_min(bounds[0], x + port.x - 4.0)
    bounds[1] = svg_min(bounds[1], y + port.y - 4.0)
    bounds[2] = svg_max(bounds[2], x + port.x + 4.0)
    bounds[3] = svg_max(bounds[3], y + port.y + 4.0)
  }
  for edge in node.edges {
    for p in edge.points {
      bounds[0] = svg_min(bounds[0], x + p.x)
      bounds[1] = svg_min(bounds[1], y + p.y)
      bounds[2] = svg_max(bounds[2], x + p.x)
      bounds[3] = svg_max(bounds[3], y + p.y)
    }
    if edge.points.length() >= 2 {
      let position = svg_edge_label_position(edge)
      for index, label in edge.labels {
        svg_label_bounds(
          label.text,
          x + position.x,
          y + position.y - index.to_double() * 14.0,
          bounds,
        )
      }
    }
  }
  for child in node.children {
    svg_bounds(child, x, y, bounds)
  }
}

///|
fn svg_label_bounds(
  text : String,
  x : Double,
  y : Double,
  bounds : Array[Double],
) -> Unit {
  let half_width = text.char_length().to_double() * 6.0
  bounds[0] = svg_min(bounds[0], x - half_width)
  bounds[1] = svg_min(bounds[1], y - 12.0)
  bounds[2] = svg_max(bounds[2], x + half_width)
  bounds[3] = svg_max(bounds[3], y + 4.0)
}

///|
fn svg_label(
  out : StringBuilder,
  text : String,
  x : Double,
  y : Double,
) -> Unit {
  out.write_string(
    "<text x=\"\{x}\" y=\"\{y}\" text-anchor=\"middle\" font-family=\"system-ui,sans-serif\" font-size=\"12\" fill=\"#172b4d\">\{svg_escape(text)}</text>\n",
  )
}

///|
fn svg_node(
  out : StringBuilder,
  node : Node,
  ox : Double,
  oy : Double,
  root : Bool,
) -> Unit {
  let x = ox + node.x
  let y = oy + node.y
  if !root {
    let fill = if node.children.is_empty() { "#eef4ff" } else { "#f6f8fc" }
    out.write_string(
      "<g data-node=\"\{svg_escape(node.id)}\"><title>\{svg_escape(node.id)}</title><rect x=\"\{x}\" y=\"\{y}\" width=\"\{node.width}\" height=\"\{node.height}\" rx=\"6\" fill=\"\{fill}\" stroke=\"#5174a5\"/>\n",
    )
    let label_y = if node.children.is_empty() {
      y + node.height / 2.0 + 4.0
    } else {
      y + 16.0
    }
    if node.labels.is_empty() {
      svg_label(out, node.id, x + node.width / 2.0, label_y)
    } else {
      for index, label in node.labels {
        svg_label(
          out,
          label.text,
          x + node.width / 2.0,
          label_y + index.to_double() * 14.0,
        )
      }
    }
  }
  for child in node.children {
    svg_node(out, child, x, y, false)
  }
  for edge in node.edges {
    if edge.points.length() >= 2 {
      let path = StringBuilder()
      for index, p in edge.points {
        let command = if index == 0 { "M" } else { "L" }
        path.write_string("\{command} \{x + p.x} \{y + p.y} ")
      }
      out.write_string(
        "<path data-edge=\"\{svg_escape(edge.id)}\" d=\"\{path}\" fill=\"none\" stroke=\"#607088\" stroke-width=\"1.5\" marker-end=\"url(#moon-graph-arrow)\"><title>\{svg_escape(edge.id)}</title></path>\n",
      )
      let position = svg_edge_label_position(edge)
      for index, label in edge.labels {
        svg_label(
          out,
          label.text,
          x + position.x,
          y + position.y - index.to_double() * 14.0,
        )
      }
    }
  }
  for port in node.ports {
    out.write_string(
      "<circle data-port=\"\{svg_escape(port.id)}\" cx=\"\{x + port.x}\" cy=\"\{y + port.y}\" r=\"3\" fill=\"#305c99\"><title>\{svg_escape(port.id)}</title></circle>\n",
    )
  }
  if !root {
    out.write_string("</g>\n")
  }
}

///|
/// Render an already laid-out graph; no browser scripts or external assets.
pub fn render_svg(graph : Node) -> String {
  let bounds = [0.0, 0.0, 0.0, 0.0]
  svg_bounds(graph, 0.0, 0.0, bounds, root=true)
  let width = svg_max(1.0, bounds[2] - bounds[0] + 32.0)
  let height = svg_max(1.0, bounds[3] - bounds[1] + 32.0)
  let out = StringBuilder()
  out.write_string(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"\{bounds[0] - 16.0} \{bounds[1] - 16.0} \{width} \{height}\" width=\"\{width}\" height=\"\{height}\" role=\"img\" aria-label=\"\{svg_escape(graph.id)}\">\n<title>\{svg_escape(graph.id)}</title>\n<defs><marker id=\"moon-graph-arrow\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"#607088\"/></marker></defs>\n",
  )
  svg_node(out, graph, 0.0, 0.0, true)
  out.write_string("</svg>\n")
  out.to_string()
}
