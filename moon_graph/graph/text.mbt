///|
/// A deliberately small line-oriented graph language. Labels need no quoting.
pub fn parse_text(text : String) -> Node raise GraphError {
  io_check_size(text)
  let root = new_graph()
  let mut line_number = 0
  for raw in text.split("\n") {
    line_number += 1
    let line = raw.trim().to_owned()
    if line.is_empty() || line.has_prefix("#") {
      continue
    }
    let words : Array[String] = []
    let word = StringBuilder()
    for c in line {
      if c == ' ' || c == '\t' || c == '\r' {
        if !word.is_empty() {
          words.push(word.to_string())
          word.reset()
        }
      } else {
        word.write_char(c)
      }
    }
    if !word.is_empty() {
      words.push(word.to_string())
    }
    match words[0] {
      "node" => {
        if words.length() < 2 {
          raise GraphError("line \{line_number}: expected node ID [label]")
        }
        let node = new_node(words[1])
        if words.length() > 2 {
          node.labels.push({ text: words.exact_view(start=2).join(" "), })
        }
        root.children.push(node)
        if root.children.length() >= 500 {
          raise GraphError("graph exceeds 500 nodes including root")
        }
      }
      "edge" => {
        if words.length() < 4 {
          raise GraphError(
            "line \{line_number}: expected edge ID SOURCE TARGET [label]",
          )
        }
        let edge = new_edge(words[1], words[2], words[3])
        if words.length() > 4 {
          edge.labels.push({ text: words.exact_view(start=4).join(" "), })
        }
        root.edges.push(edge)
        if root.edges.length() > 3000 {
          raise GraphError("graph exceeds 3000 edges")
        }
      }
      "option" => {
        if words.length() != 3 {
          raise GraphError("line \{line_number}: expected option KEY VALUE")
        }
        if root.options.contains(words[1]) {
          raise GraphError(
            "line \{line_number}: duplicate option '\{words[1]}'",
          )
        }
        root.options.set(words[1], words[2])
      }
      command =>
        raise GraphError("line \{line_number}: unknown command '\{command}'")
    }
  }
  let problems = validate(root)
  if !problems.is_empty() {
    raise GraphError(problems.join("; "))
  }
  root
}
