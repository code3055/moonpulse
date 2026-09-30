///|
fn main {
  let graph = @graph.new_graph(id="api-example")
  graph.children.push(@graph.new_node("compile"))
  graph.children.push(@graph.new_node("test"))
  graph.children.push(@graph.new_node("release"))
  graph.edges.push(@graph.new_edge("compile-test", "compile", "test"))
  graph.edges.push(@graph.new_edge("test-release", "test", "release"))
  graph.options["elk.algorithm"] = "layered"
  let output = @graph.new_elk_engine().layout(graph) catch {
    @graph.GraphError(message) => {
      println("Layout failed: \{message}")
      return
    }
  }
  println(@graph.graph_json(output, pretty=true))
}
