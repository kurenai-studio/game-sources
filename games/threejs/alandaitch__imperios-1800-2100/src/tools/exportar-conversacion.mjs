/**
 * Extrae una conversación de Claude Code (.jsonl) a un JSON limpio y legible.
 *
 *   node tools/exportar-conversacion.mjs <archivo.jsonl> <salida.json>
 *
 * Qué se conserva y qué no:
 *  - Los turnos REALES del usuario. Se descartan los `<system-reminder>`, los
 *    avisos de tarea en segundo plano y los resultados de herramienta, que en el
 *    archivo viajan con `role: 'user'` pero no los escribió nadie.
 *  - El texto del asistente completo.
 *  - Las llamadas a herramienta reducidas a nombre + una línea de contexto: el
 *    archivo pesa 40 MB casi todo en imágenes base64 y en volcados de código que
 *    ya están en el repo.
 */
import fs from 'node:fs';

const [, , entrada, salida] = process.argv;
if (!entrada || !salida) {
  console.error('uso: node tools/exportar-conversacion.mjs <archivo.jsonl> <salida.json>');
  process.exit(1);
}

const lineas = fs.readFileSync(entrada, 'utf8').split('\n').filter(Boolean);

/** Saca los bloques que el runtime inyecta y que el usuario nunca escribió. */
function limpiarTextoUsuario(t) {
  if (typeof t !== 'string') return '';
  let s = t;
  s = s.replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, '');
  s = s.replace(/<task-notification>[\s\S]*?<\/task-notification>/g, '');
  s = s.replace(/\[SYSTEM NOTIFICATION[\s\S]*?(?=\n\n|$)/g, '');
  s = s.replace(/<local-command-[\s\S]*?>[\s\S]*?<\/local-command-[\s\S]*?>/g, '');
  s = s.replace(/<command-name>[\s\S]*?<\/command-args>/g, '');
  s = s.replace(/^\s*Caveat:[\s\S]*?<\/command-message>/m, '');
  s = s.trim();
  // nota que inserta el runtime cuando el asistente mira una imagen: no la
  // escribió el usuario y aparecería como un turno fantasma
  if (/^\[Image: original \d+x\d+/.test(s)) return '';
  if (/^\[Request interrupted/.test(s)) return '';
  return s;
}

/** Una línea de contexto por herramienta: qué hizo, no con qué payload. */
function resumirHerramienta(nombre, inp) {
  const p = inp || {};
  const corto = (v, n = 120) => (typeof v === 'string' ? (v.length > n ? v.slice(0, n) + '…' : v) : '');
  switch (nombre) {
    case 'Bash': return p.description || corto(p.command);
    case 'Write': return p.file_path || '';
    case 'Edit': return p.file_path || '';
    case 'Read': return p.file_path || '';
    case 'Workflow': return p.description || (p.script || '').match(/name:\s*'([^']+)'/)?.[1] || '';
    case 'Agent': return p.description || corto(p.prompt, 90);
    case 'SendUserFile': return (p.files || []).map((f) => f.split('/').pop()).join(', ');
    case 'Artifact': return p.description || p.file_path || '';
    case 'AskUserQuestion': return (p.questions || []).map((q) => q.question).join(' · ');
    case 'TaskStop': return p.task_id || '';
    default: {
      if (p.description) return corto(p.description);
      if (p.file_path) return p.file_path;
      if (p.url) return p.url;
      if (p.text) return corto(p.text, 90);
      if (p.query) return corto(p.query, 90);
      return '';
    }
  }
}

const turnos = [];
let acumAsistente = null;

const cerrarAsistente = () => {
  if (acumAsistente?.bloques.length) turnos.push(acumAsistente);
  acumAsistente = null;
};

for (const linea of lineas) {
  let o;
  try { o = JSON.parse(linea); } catch { continue; }
  if (o.isSidechain) continue;              // subagentes: tienen su propio journal
  const m = o.message;
  if (!m) continue;

  if (o.type === 'user' && m.role === 'user') {
    // contenido en array = resultados de herramienta, no un turno del usuario
    if (Array.isArray(m.content)) continue;
    const t = limpiarTextoUsuario(m.content);
    if (!t) continue;
    cerrarAsistente();
    turnos.push({ rol: 'usuario', texto: t, ts: o.timestamp });
    continue;
  }

  if (o.type === 'assistant' && m.role === 'assistant') {
    // Los mensajes del asistente vienen separados por resultados de herramienta,
    // que no son turnos de nadie. Se acumulan hasta el próximo turno real del
    // usuario, PERO conservando el orden: se lee "dije esto → corrí aquello →
    // dije lo otro", que es como pasó de verdad.
    if (!acumAsistente) acumAsistente = { rol: 'claude', bloques: [], ts: o.timestamp };
    for (const b of Array.isArray(m.content) ? m.content : []) {
      if (b.type === 'text' && b.text.trim()) {
        acumAsistente.bloques.push({ tipo: 'texto', texto: b.text.trim() });
      } else if (b.type === 'tool_use') {
        acumAsistente.bloques.push({ tipo: 'herramienta', nombre: b.name, detalle: resumirHerramienta(b.name, b.input) });
      }
    }
  }
}
cerrarAsistente();

const salidaObj = {
  generado: new Date().toISOString(),
  origen: entrada,
  turnos,
  resumen: {
    turnosUsuario: turnos.filter((t) => t.rol === 'usuario').length,
    turnosClaude: turnos.filter((t) => t.rol === 'claude').length,
    llamadasHerramienta: turnos.reduce(
      (a, t) => a + (t.bloques?.filter((b) => b.tipo === 'herramienta').length || 0), 0),
    mensajesClaude: turnos.reduce(
      (a, t) => a + (t.bloques?.filter((b) => b.tipo === 'texto').length || 0), 0),
  },
};

fs.writeFileSync(salida, JSON.stringify(salidaObj, null, 1));
console.log(`${turnos.length} turnos → ${salida}`);
console.log(salidaObj.resumen);
