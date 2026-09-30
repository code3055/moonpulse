///|
pub(all) suberror GraphError {
  GraphError(String)
}

///|
pub(all) struct Point {
  x : Double
  y : Double
} derive(Debug, Eq)

///|
pub(all) struct Label {
  text : String
} derive(Debug, Eq)

///|
pub(all) struct Port {
  id : String
  side : String
  mut x : Double
  mut y : Double
} derive(Debug)

///|
pub(all) struct Edge {
  id : String
  source : String
  target : String
  labels : Array[Label]
  mut points : Array[Point]
} derive(Debug)

///|
/// The root and compound nodes share the same ELK-style representation.
/// Coordinates and edge sections are relative to the enclosing container.
pub(all) struct Node {
  id : String
  mut x : Double
  mut y : Double
  mut width : Double
  mut height : Double
  children : Array[Node]
  edges : Array[Edge]
  ports : Array[Port]
  labels : Array[Label]
  options : Map[String, String]
} derive(Debug)

///|
pub fn new_node(
  id : String,
  width? : Double = 100.0,
  height? : Double = 48.0,
) -> Node {
  {
    id,
    x: 0.0,
    y: 0.0,
    width,
    height,
    children: [],
    edges: [],
    ports: [],
    labels: [],
    options: {},
  }
}

///|
pub fn new_graph(id? : String = "root") -> Node {
  new_node(id, width=0.0, height=0.0)
}

///|
pub fn new_edge(id : String, source : String, target : String) -> Edge {
  { id, source, target, labels: [], points: [], }
}

///|
pub fn new_port(id : String, side? : String = "EAST") -> Port {
  { id, side, x: 0.0, y: 0.0, }
}

///|
pub fn clone_graph(node : Node) -> Node {
  {
    id: node.id,
    x: node.x,
    y: node.y,
    width: node.width,
    height: node.height,
    children: node.children.map(clone_graph),
    edges: node.edges.map(e => {
      id: e.id,
      source: e.source,
      target: e.target,
      labels: e.labels.copy(),
      points: e.points.copy(),
    }),
    ports: node.ports.map(p => { id: p.id, side: p.side, x: p.x, y: p.y, }),
    labels: node.labels.copy(),
    options: node.options.copy(),
  }
}

///|
pub extend Point with @debug.Debug::{to_repr}

///|
pub extend Label with @debug.Debug::{to_repr}

///|
pub extend Port with @debug.Debug::{to_repr}

///|
pub extend Edge with @debug.Debug::{to_repr}

///|
pub extend Node with @debug.Debug::{to_repr}

///|
pub extend Point with Eq::{equal, not_equal}

///|
pub extend Label with Eq::{equal, not_equal}
