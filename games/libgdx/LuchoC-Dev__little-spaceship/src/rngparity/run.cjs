// Node entry point for the TeaVM output. TeaVM's generateJavaScript task produces the module
// itself, not a way to invoke it — the spike's threadprobe/run.cjs is the precedent for a
// hand-written runner like this one.
require('./build/generated/teavm/js/rngparity.js').main([]);
