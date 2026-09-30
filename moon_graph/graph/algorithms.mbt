///|
fn maxd(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn mind(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn absd(a : Double) -> Double {
  if a < 0.0 {
    -a
  } else {
    a
  }
}

///|
fn endpoint_indices(graph : Node) -> Map[String, Int] {
  let result : Map[String, Int] = Map([])
  for i, child in graph.children {
    result[child.id] = i
    for port in child.ports {
      result[port.id] = i
    }
  }
  result
}

///|
fn links(graph : Node) -> Array[(Int, Int)] {
  let indices = endpoint_indices(graph)
  graph.edges.map(e => (indices[e.source], indices[e.target]))
}

///|
/// Deterministic greedy feedback ordering, followed by longest-path ranks.
/// Original edge direction is retained for routing and serialization.
fn layer_ranks(count : Int, edges : Array[(Int, Int)]) -> Array[Int] {
  let remaining = Array::make(count, true)
  let order : Array[Int] = []
  for _ in 0..<count {
    let mut selected = -1
    let mut best = -100000
    for i in 0..<count {
      if !remaining[i] {
        continue
      }
      let mut incoming = 0
      let mut outgoing = 0
      for (a, b) in edges {
        if a == b || !remaining[a] || !remaining[b] {
          continue
        }
        if a == i {
          outgoing += 1
        }
        if b == i {
          incoming += 1
        }
      }
      if incoming == 0 {
        selected = i
        break
      }
      if outgoing - incoming > best {
        best = outgoing - incoming
        selected = i
      }
    }
    if selected >= 0 {
      remaining[selected] = false
      order.push(selected)
    }
  }
  let positions = Array::make(count, 0)
  for pos, index in order {
    positions[index] = pos
  }
  let ranks = Array::make(count, 0)
  for index in order {
    for (a, b) in edges {
      if a == b {
        continue
      }
      let (source, target) = if positions[a] < positions[b] {
        (a, b)
      } else {
        (b, a)
      }
      if source == index && ranks[target] <= ranks[source] {
        ranks[target] = ranks[source] + 1
      }
    }
  }
  ranks
}

///|
fn layered(graph : Node, cfg : Config) -> Unit {
  let nodes = graph.children
  let count = nodes.length()
  if count == 0 {
    return
  }
  let edges = links(graph)
  let ranks = layer_ranks(count, edges)
  let mut max_rank = 0
  for rank in ranks {
    if rank > max_rank {
      max_rank = rank
    }
  }
  let layers : Array[Array[Int]] = Array::makei(max_rank + 1, _ => [])
  for index, rank in ranks {
    layers[rank].push(index)
  }
  let positions = Array::make(count, 0.0)
  // Alternating barycenter sweeps reduce crossings while keeping stable ties.
  for sweep in 0..<8 {
    for layer in layers {
      for pos, index in layer {
        positions[index] = pos.to_double()
      }
    }
    for step in 0..<(max_rank + 1) {
      let rank = if sweep % 2 == 0 { step } else { max_rank - step }
      let scores = Array::make(count, 0.0)
      for index in layers[rank] {
        let mut sum = 0.0
        let mut num = 0
        for (a, b) in edges {
          let other = if a == index { b } else if b == index { a } else { -1 }
          if other >= 0 &&
            (if sweep % 2 == 0 {
              ranks[other] < rank
            } else {
              ranks[other] > rank
            }) {
            sum += positions[other]
            num += 1
          }
        }
        scores[index] = if num == 0 {
          positions[index]
        } else {
          sum / num.to_double()
        }
      }
      layers[rank].sort_by(fn(a, b) {
        let compare = scores[a].compare(scores[b])
        if compare == 0 {
          a.compare(b)
        } else {
          compare
        }
      })
      for pos, index in layers[rank] {
        positions[index] = pos.to_double()
      }
    }
  }
  let vertical = cfg.direction == "DOWN" || cfg.direction == "UP"
  let mut main = cfg.padding
  for layer in layers {
    let mut cross = cfg.padding
    let mut extent = 0.0
    for index in layer {
      let node = nodes[index]
      node.x = if vertical { cross } else { main }
      node.y = if vertical { main } else { cross }
      cross += (if vertical { node.width } else { node.height }) + cfg.spacing
      extent = maxd(extent, if vertical { node.height } else { node.width })
    }
    main += extent + cfg.layer_spacing
  }
}

///|
fn box_layout(graph : Node, cfg : Config) -> Unit {
  let mut area = 0.0
  let mut widest = 0.0
  for node in graph.children {
    area += (node.width + cfg.spacing) * (node.height + cfg.spacing)
    widest = maxd(widest, node.width)
  }
  let target = maxd(widest, area.sqrt() * 1.3)
  let mut x = cfg.padding
  let mut y = cfg.padding
  let mut row_height = 0.0
  for node in graph.children {
    if x > cfg.padding && x + node.width > cfg.padding + target {
      x = cfg.padding
      y += row_height + cfg.spacing
      row_height = 0.0
    }
    node.x = x
    node.y = y
    x += node.width + cfg.spacing
    row_height = maxd(row_height, node.height)
  }
}

///|
fn radial(graph : Node, cfg : Config) -> Unit {
  let count = graph.children.length()
  if count == 0 {
    return
  }
  let edges = links(graph)
  let ranks = Array::make(count, -1)
  let mut max_rank = 0
  let mut next_base = 0
  // Directed roots first; undirected BFS still handles cycles/disconnected graphs.
  let incoming = Array::make(count, 0)
  for (a, b) in edges {
    if a != b {
      incoming[b] += 1
    }
  }
  let roots : Array[Int] = []
  for i in 0..<count {
    if incoming[i] == 0 {
      roots.push(i)
    }
  }
  for i in 0..<count {
    if incoming[i] != 0 {
      roots.push(i)
    }
  }
  for root in roots {
    if ranks[root] >= 0 {
      continue
    }
    let queue = [root]
    ranks[root] = next_base
    let mut head = 0
    while head < queue.length() {
      let index = queue[head]
      head += 1
      max_rank = if ranks[index] > max_rank { ranks[index] } else { max_rank }
      for (a, b) in edges {
        let other = if a == index { b } else if b == index { a } else { -1 }
        if other >= 0 && ranks[other] < 0 {
          ranks[other] = ranks[index] + 1
          queue.push(other)
        }
      }
    }
    next_base = max_rank + 1
  }
  let rings : Array[Array[Int]] = Array::makei(max_rank + 1, _ => [])
  for index, rank in ranks {
    rings[rank].push(index)
  }
  let mut diameter = 0.0
  for node in graph.children {
    diameter = maxd(
      diameter,
      (node.width * node.width + node.height * node.height).sqrt(),
    )
  }
  let step = diameter + maxd(cfg.spacing, cfg.layer_spacing)
  let mut radius = 0.0
  for ring in rings {
    let min_radius = ring.length().to_double() *
      (diameter + cfg.spacing) /
      (2.0 * @math.PI)
    radius = maxd(radius, min_radius)
    if ring.length() == 1 && radius < step {
      radius = 0.0
    }
    for pos, index in ring {
      let angle = 2.0 * @math.PI * pos.to_double() / ring.length().to_double()
      let node = graph.children[index]
      node.x = radius * @math.cos(angle) - node.width / 2.0
      node.y = radius * @math.sin(angle) - node.height / 2.0
    }
    radius += step
  }
}

///|
fn force_layout(graph : Node, cfg : Config) -> Unit {
  let nodes = graph.children
  let count = nodes.length()
  if count == 0 {
    return
  }
  let edges = links(graph)
  let xs = Array::make(count, 0.0)
  let ys = Array::make(count, 0.0)
  let mut state = cfg.seed + 1
  let mut typical = 80.0
  for node in nodes {
    typical = maxd(typical, maxd(node.width, node.height))
  }
  let k = typical + cfg.spacing
  for i in 0..<count {
    // Bounded integer generator avoids platform-dependent overflow.
    state = (state * 97 + 17) % 1000003
    let angle = 2.0 *
      @math.PI *
      (i.to_double() + state.to_double() / 1000003.0) /
      count.to_double()
    xs[i] = @math.cos(angle) * k * count.to_double().sqrt()
    ys[i] = @math.sin(angle) * k * count.to_double().sqrt()
  }
  for iteration in 0..<cfg.iterations {
    let dx = Array::make(count, 0.0)
    let dy = Array::make(count, 0.0)
    for i in 0..<count {
      for j in (i + 1)..<count {
        let mut vx = xs[i] - xs[j]
        let vy = ys[i] - ys[j]
        if absd(vx) + absd(vy) < 0.001 {
          vx = 0.1
        }
        let distance = maxd(0.1, (vx * vx + vy * vy).sqrt())
        let force = k * k / distance
        let fx = vx / distance * force
        let fy = vy / distance * force
        dx[i] += fx
        dy[i] += fy
        dx[j] -= fx
        dy[j] -= fy
      }
    }
    for (a, b) in edges {
      if a == b {
        continue
      }
      let vx = xs[a] - xs[b]
      let vy = ys[a] - ys[b]
      let distance = maxd(0.1, (vx * vx + vy * vy).sqrt())
      let force = distance * distance / k
      let fx = vx / distance * force
      let fy = vy / distance * force
      dx[a] -= fx
      dy[a] -= fy
      dx[b] += fx
      dy[b] += fy
    }
    let temperature = k *
      (1.0 - iteration.to_double() / cfg.iterations.to_double()) *
      0.3
    for i in 0..<count {
      dx[i] -= xs[i] * 0.01
      dy[i] -= ys[i] * 0.01
      let length = maxd(0.01, (dx[i] * dx[i] + dy[i] * dy[i]).sqrt())
      xs[i] += dx[i] / length * mind(temperature, length)
      ys[i] += dy[i] / length * mind(temperature, length)
    }
  }
  for i, node in nodes {
    node.x = xs[i] - node.width / 2.0
    node.y = ys[i] - node.height / 2.0
  }
}

///|
/// A deterministic projection guarantees separated rectangles after soft layouts.
/// Previously placed nodes remain fixed; moving right past a conflict terminates.
fn remove_overlaps(nodes : Array[Node], gap : Double) -> Unit {
  for i, node in nodes {
    let mut changed = true
    while changed {
      changed = false
      for j in 0..<i {
        let other = nodes[j]
        if node.x < other.x + other.width + gap &&
          node.x + node.width + gap > other.x &&
          node.y < other.y + other.height + gap &&
          node.y + node.height + gap > other.y {
          node.x = other.x + other.width + gap
          changed = true
        }
      }
    }
  }
}
