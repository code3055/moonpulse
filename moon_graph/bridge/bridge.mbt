///|
/// String-only JS boundary: all expected input errors become JSON envelopes.
pub fn transform(
  input : String,
  input_format : String,
  output_format : String,
  algorithm : String,
  direction : String,
  pretty : String,
) -> String {
  try {
    let graph = match input_format {
      "json" => @graph.parse_graph(input)
      "text" => @graph.parse_text(input)
      _ => raise @graph.GraphError("input format must be json or text")
    }
    if algorithm != "" {
      graph.options["elk.algorithm"] = algorithm
    }
    if direction != "" {
      graph.options["elk.direction"] = direction
    }
    let laid_out = @graph.new_elk_engine().layout(graph)
    let result = match output_format {
      "json" => @graph.graph_json(laid_out, pretty=pretty == "true")
      "svg" => @graph.render_svg(laid_out)
      _ => raise @graph.GraphError("output format must be json or svg")
    }
    Json::object({ "ok": true, "data": result.to_json() }).stringify()
  } catch {
    @graph.GraphError(message) =>
      Json::object({ "ok": false, "error": message.to_json() }).stringify()
  }
}

///|
pub fn list_algorithms() -> String {
  @graph.algorithms().to_json().stringify()
}
