// Prelude: initialize the global `MC` namespace and module namespaces exactly once.
// Invariant: other modules attach to these objects (no defensive `MC.x = MC.x || {}`).
var MC = MC || {};

// Module namespaces: created once here, never defensively elsewhere.
MC.controls = {};
MC.render = {};
MC.ui = {};
MC.anim = {};
MC.fmt = {};
MC.layout = {};
MC.moves = {};
MC.cmd = {};
MC.cmdProfiles = {};
MC.ai = {};
MC.state = {};
MC.engine = {};
MC.rules = {};
MC.util = {};
MC.shuffle = {};
MC.rng = {};
MC.seed = {};
MC.scenarios = {};
MC.debug = {};
MC.debug.toolsOn = false;
MC.title = {};
MC.howto = {};
MC.about = {};

