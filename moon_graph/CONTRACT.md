# Implementation contract

Module local/moon_graph; library package local/moon_graph/graph.
Original MoonBit implementation inspired by the ELK JSON data shape, NOT a full ELK port. MIT. No third-party dependencies.

Public model in graph/model.mbt is the shared interface. Node is both root and compound node. Edges belong to their enclosing Node and connect direct children or their ports, globally unique identifiers across nodes/edges/ports. Cross-container edges and hyperedges are rejected explicitly. Labels contain text. Points are container-local.

Parent owns model.mbt, options.mbt, validation.mbt, algorithms.mbt, engine.mbt. Supported algorithms: layered (default, cycle breaking and barycenter ordering), force (deterministic), radial (BFS rings), box (shelf packing), fixed. Directions RIGHT/DOWN/LEFT/UP. Options: elk.algorithm; elk.direction; elk.spacing.nodeNode (default 30); elk.layered.spacing.nodeNodeBetweenLayers (60); moon.padding (24); moon.force.iterations (120, 1..1000); moon.seed (1, 0..1000000); elk.edgeRouting (ORTHOGONAL or POLYLINE). Aliases org.eclipse.elk.<algorithm> accepted. Unknown algorithm/known bad option rejected. Unsupported option keys rejected (explicit subset). Fixed preserves x/y, all algorithms preserve dimensions except compound nodes auto-size to fit children.

API: new_elk_engine() -> Engine; Engine::layout(Self, Node) -> Node raise GraphError; validate(Node) -> Array[String]; algorithms() -> Array[String]; layout_json(String, pretty? : Bool = false) -> String raise GraphError; parse_graph(String) -> Node raise GraphError; graph_json(Node, pretty? : Bool = false) -> String; render_svg(Node) -> String; parse_text(String) -> Node raise GraphError. Engine clones input.

Text grammar: `node ID [label words...]`; `edge ID SOURCE TARGET [label words...]`; `option KEY VALUE`; empty lines and # comments ignored. Edges may precede nodes. Duplicate IDs rejected by validate/layout.

Limits: 500 nodes total, 3000 edges total, hierarchy depth 32, finite dimensions/coordinates up to 1000000, bounded input text and JSON. Layout is synchronous. SVG escapes all user strings.

CLI host: Node.js standard library handles file/stdin/output; layout/serialization/rendering all MoonBit via compiled JS exports. Module package.json type module. No npm install needed.

Acceptance: independent folder; moon check/fmt/build/test on wasm-gc and JS; 300+ meaningful MoonBit scenario tests; CLI subprocess checks incl errors and Unicode; example JSON/text; SVG artifact; README and truthful Chinese project proposal; reference format comparison documentation, no invented elkjs equivalence.
