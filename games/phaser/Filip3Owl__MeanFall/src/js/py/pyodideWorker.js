/* MeanFall — Web Worker que hospeda o interpretador Python (Pyodide).
 *
 * Roda fora da thread principal por um motivo específico: o jogador escreve
 * o código, e código de jogador entra em loop infinito. Num worker, a thread
 * principal só precisa chamar worker.terminate() — o jogo não congela.
 * O preço é que o interpretador morre junto e precisa ser rebootado.
 *
 * Worker clássico (não módulo): pyodide.js é carregado com importScripts,
 * que é a forma suportada pelo próprio Pyodide fora de bundlers.
 */

const PYODIDE_VERSION = '0.27.7';
const INDEX_URL = `https://cdn.jsdelivr.net/pyodide/v${PYODIDE_VERSION}/full/`;

let pyodide = null;
const loaded = new Set();   // pacotes já carregados nesta instância

// ─── Harness Python ───────────────────────────────────────────────────────
// Definido uma vez no boot. Recebe um JSON com { setup, code, cases } e
// devolve um JSON com o resultado caso a caso. Tudo que o jogador imprime
// com print() é capturado e volta para o console do editor.
const HARNESS = String.raw`
import json, io, sys, math, traceback
from contextlib import redirect_stdout

_MF_LIMIT = 400   # tamanho máximo de um valor exibido no relatório


def _mf_mod(name):
    return sys.modules.get(name)


def _mf_repr(v):
    pd = _mf_mod('pandas')
    try:
        if pd is not None and isinstance(v, (pd.DataFrame, pd.Series)):
            s = v.head(8).to_string()
        else:
            s = repr(v)
    except Exception:
        s = '<objeto sem repr>'
    return s if len(s) <= _MF_LIMIT else s[:_MF_LIMIT] + ' …'


def _mf_exc():
    """Traceback curto e em português, só com o frame do jogador."""
    etype, evalue, tb = sys.exc_info()
    if isinstance(evalue, SyntaxError):
        linha = f' (linha {evalue.lineno})' if evalue.lineno else ''
        return f'SyntaxError{linha}: {evalue.msg}'
    frames = [f for f in traceback.extract_tb(tb) if f.filename in ('<string>', '<exec>')]
    linha = f' (linha {frames[-1].lineno})' if frames else ''
    return f'{etype.__name__}{linha}: {evalue}'


def _mf_eq(a, b, tol=1e-6):
    """Igualdade tolerante: float com margem, e ciente de numpy/pandas."""
    pd = _mf_mod('pandas')
    np = _mf_mod('numpy')

    if pd is not None and isinstance(b, pd.DataFrame):
        if not isinstance(a, pd.DataFrame):
            return False
        try:
            pd.testing.assert_frame_equal(a, b, check_dtype=False, check_like=True,
                                          rtol=1e-5, atol=1e-8)
            return True
        except Exception:
            return False

    if pd is not None and isinstance(b, pd.Series):
        if not isinstance(a, pd.Series):
            return False
        try:
            pd.testing.assert_series_equal(a, b, check_dtype=False, check_names=False,
                                           rtol=1e-5, atol=1e-8)
            return True
        except Exception:
            return False

    if np is not None and isinstance(b, np.ndarray):
        a_arr = a if (np is not None and isinstance(a, np.ndarray)) else None
        if a_arr is None:
            try:
                a_arr = np.asarray(a)
            except Exception:
                return False
        if a_arr.shape != b.shape:
            return False
        try:
            if np.issubdtype(b.dtype, np.number):
                return bool(np.allclose(a_arr, b, rtol=1e-5, atol=1e-8, equal_nan=True))
        except Exception:
            pass
        return bool(np.array_equal(a_arr, b))

    if isinstance(b, bool) or isinstance(a, bool):
        return a is b or a == b

    if isinstance(b, float) or isinstance(a, float):
        try:
            if math.isnan(a) and math.isnan(b):
                return True
            return math.isclose(float(a), float(b), rel_tol=tol, abs_tol=1e-9)
        except Exception:
            return False

    if isinstance(b, (list, tuple)):
        if not isinstance(a, (list, tuple)) or len(a) != len(b):
            return False
        return all(_mf_eq(x, y, tol) for x, y in zip(a, b))

    if isinstance(b, dict):
        if not isinstance(a, dict) or set(a.keys()) != set(b.keys()):
            return False
        return all(_mf_eq(a[k], b[k], tol) for k in b)

    if isinstance(b, set):
        return isinstance(a, set) and a == b

    try:
        return bool(a == b)
    except Exception:
        return False


def _mf_run(payload_json):
    payload = json.loads(payload_json)
    setup   = payload.get('setup') or ''
    code    = payload.get('code') or ''
    cases   = payload.get('cases') or []

    out    = io.StringIO()
    report = {'ok': False, 'error': None, 'errorStage': None, 'stdout': '', 'results': []}

    base = {'__name__': '__meanfall__'}
    try:
        with redirect_stdout(out):
            if setup:
                exec(setup, base)
    except Exception:
        report['error'] = _mf_exc()
        report['errorStage'] = 'setup'
        report['stdout'] = out.getvalue()
        return json.dumps(report)

    # O código do jogador roda no mesmo escopo do setup: ele enxerga o dataset.
    try:
        with redirect_stdout(out):
            exec(code, base)
    except Exception:
        report['error'] = _mf_exc()
        report['errorStage'] = 'code'
        report['stdout'] = out.getvalue()
        return json.dumps(report)

    for case in cases:
        r = {
            'name':     case.get('name') or case.get('call'),
            'call':     case.get('call'),
            'hidden':   bool(case.get('hidden')),
            'passed':   False,
            'got':      None,
            'expected': None,
            'error':    None,
        }
        # Cada caso recebe uma cópia limpa do dataset: se o jogador mutar a
        # entrada, o caso seguinte não herda o estrago.
        scope = dict(base)
        try:
            if setup:
                with redirect_stdout(out):
                    exec(setup, scope)
            with redirect_stdout(out):
                got = eval(case['call'], scope)
                exp = eval(case['expected'], scope)
            r['passed']   = _mf_eq(got, exp)
            r['got']      = _mf_repr(got)
            r['expected'] = _mf_repr(exp)
        except Exception:
            r['error'] = _mf_exc()
        report['results'].append(r)

    report['ok']     = all(x['passed'] for x in report['results']) and len(report['results']) > 0
    report['stdout'] = out.getvalue()
    return json.dumps(report)
`;

async function boot() {
    if (pyodide) return pyodide;
    self.importScripts(INDEX_URL + 'pyodide.js');
    pyodide = await self.loadPyodide({
        indexURL: INDEX_URL,
        stdout: () => {},
        stderr: () => {},
    });
    pyodide.runPython(HARNESS);
    return pyodide;
}

async function ensurePackages(names = []) {
    const missing = names.filter(n => !loaded.has(n));
    if (!missing.length) return;
    await pyodide.loadPackage(missing);
    missing.forEach(n => loaded.add(n));
}

self.onmessage = async (ev) => {
    const { id, type, payload } = ev.data || {};
    const reply = (msg) => self.postMessage({ id, ...msg });

    try {
        if (type === 'init') {
            self.postMessage({ id, type: 'progress', stage: 'interpreter' });
            await boot();
            reply({ type: 'ready', version: PYODIDE_VERSION });
            return;
        }

        if (type === 'packages') {
            await boot();
            const names = payload?.names || [];
            if (names.some(n => !loaded.has(n))) {
                self.postMessage({ id, type: 'progress', stage: 'packages', names });
            }
            await ensurePackages(names);
            reply({ type: 'packages-ready' });
            return;
        }

        if (type === 'run') {
            await boot();
            await ensurePackages(payload?.packages || []);
            const json = pyodide.runPython('_mf_run')(JSON.stringify({
                setup: payload?.setup || '',
                code:  payload?.code  || '',
                cases: payload?.cases || [],
            }));
            reply({ type: 'result', report: JSON.parse(json) });
            return;
        }

        reply({ type: 'error', message: `Mensagem desconhecida: ${type}` });
    } catch (err) {
        reply({ type: 'error', message: String(err?.message || err) });
    }
};
