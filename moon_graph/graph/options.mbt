///|
priv struct Config {
  algorithm : String
  direction : String
  spacing : Double
  layer_spacing : Double
  padding : Double
  iterations : Int
  seed : Int
  routing : String
}

///|
pub fn algorithms() -> Array[String] {
  ["layered", "force", "radial", "box", "fixed"]
}

///|
fn option_number(
  options : Map[String, String],
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double raise GraphError {
  match options.get(key) {
    None => fallback
    Some(value) => {
      let parsed = @json.parse(value) catch {
        _ => raise GraphError("Invalid numeric option: " + key)
      }
      match parsed {
        Number(n, ..) if !n.is_nan() && !n.is_inf() && n >= min && n <= max => n
        _ => raise GraphError("Option out of range: " + key)
      }
    }
  }
}

///|
fn config(options : Map[String, String]) -> Config raise GraphError {
  for key, _ in options {
    if key != "elk.algorithm" &&
      key != "elk.direction" &&
      key != "elk.spacing.nodeNode" &&
      key != "elk.layered.spacing.nodeNodeBetweenLayers" &&
      key != "moon.padding" &&
      key != "moon.force.iterations" &&
      key != "moon.seed" &&
      key != "elk.edgeRouting" {
      raise GraphError("Unsupported layout option: " + key)
    }
  }
  let raw = options.get("elk.algorithm").unwrap_or("layered")
  let algorithm = if raw.has_prefix("org.eclipse.elk.") {
    raw.replace(old="org.eclipse.elk.", new="")
  } else {
    raw
  }
  if !algorithms().contains(algorithm) {
    raise GraphError("Unsupported algorithm: " + raw)
  }
  let direction = options.get("elk.direction").unwrap_or("RIGHT")
  if !["RIGHT", "DOWN", "LEFT", "UP"].contains(direction) {
    raise GraphError("Invalid direction: " + direction)
  }
  let routing = options.get("elk.edgeRouting").unwrap_or("ORTHOGONAL")
  if routing != "ORTHOGONAL" && routing != "POLYLINE" {
    raise GraphError("Unsupported edge routing: " + routing)
  }
  let iterations = option_number(
    options, "moon.force.iterations", 120.0, 1.0, 1000.0,
  )
  let seed = option_number(options, "moon.seed", 1.0, 0.0, 1000000.0)
  if iterations != iterations.to_int().to_double() ||
    seed != seed.to_int().to_double() {
    raise GraphError("Iterations and seed must be integers")
  }
  {
    algorithm,
    direction,
    routing,
    spacing: option_number(options, "elk.spacing.nodeNode", 30.0, 0.0, 10000.0),
    layer_spacing: option_number(
      options, "elk.layered.spacing.nodeNodeBetweenLayers", 60.0, 0.0, 10000.0,
    ),
    padding: option_number(options, "moon.padding", 24.0, 0.0, 10000.0),
    iterations: iterations.to_int(),
    seed: seed.to_int(),
  }
}
