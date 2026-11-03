/* MeanFall — Ponte entre o jogo e o interpretador Python.
 *
 * Toda execução acontece no worker (js/py/pyodideWorker.js). Aqui ficam só a
 * fila de mensagens, o timeout e o reboot: se o código do jogador travar, o
 * worker é morto e recriado — o jogo segue rodando.
 *
 * O interpretador só é baixado quando o jogador entra num desafio de código:
 * quem nunca pisar na Cripta do Interpretador não paga o download.
 */

const WORKER_URL   = new URL('../py/pyodideWorker.js', import.meta.url);
const BOOT_TIMEOUT = 90_000;   // primeira carga do Pyodide em rede lenta
const RUN_TIMEOUT  = 10_000;   // tempo máximo de execução do código do jogador

export const PythonRuntime = {

    _worker:   null,
    _seq:      0,
    _pending:  new Map(),
    _bootPromise: null,
    _progressHandlers: new Set(),

    status: 'idle',            // idle | booting | ready | failed
    lastError: null,
    packagesLoaded: new Set(),

    isSupported() {
        return typeof Worker !== 'undefined';
    },

    onProgress(fn) {
        this._progressHandlers.add(fn);
        return () => this._progressHandlers.delete(fn);
    },

    _emit(stage, extra = {}) {
        for (const fn of this._progressHandlers) {
            try { fn({ stage, ...extra }); } catch { /* handler do jogo, ignora */ }
        }
    },

    // ─── Worker ───────────────────────────────────────────────────────────

    _spawn() {
        if (this._worker) return this._worker;
        const w = new Worker(WORKER_URL);   // worker clássico: usa importScripts
        w.onmessage = (ev) => this._onMessage(ev.data || {});
        w.onerror = (err) => {
            const msg = err?.message || 'falha ao iniciar o interpretador';
            this.status    = 'failed';
            this.lastError = msg;
            for (const [, entry] of this._pending) entry.reject(new Error(msg));
            this._pending.clear();
            this._emit('failed', { message: msg });
        };
        this._worker = w;
        return w;
    },

    _onMessage(msg) {
        if (msg.type === 'progress') {
            this._emit(msg.stage, { names: msg.names });
            return;
        }
        const entry = this._pending.get(msg.id);
        if (!entry) return;
        this._pending.delete(msg.id);
        clearTimeout(entry.timer);
        if (msg.type === 'error') entry.reject(new Error(msg.message));
        else entry.resolve(msg);
    },

    _post(type, payload, timeoutMs, onTimeout) {
        const id = ++this._seq;
        const worker = this._spawn();
        return new Promise((resolve, reject) => {
            const timer = setTimeout(() => {
                this._pending.delete(id);
                onTimeout?.();
                reject(Object.assign(new Error('timeout'), { timeout: true }));
            }, timeoutMs);
            this._pending.set(id, { resolve, reject, timer });
            worker.postMessage({ id, type, payload });
        });
    },

    /** Mata o interpretador (loop infinito) — a próxima execução reboota. */
    kill() {
        this._worker?.terminate();
        this._worker = null;
        this._bootPromise = null;
        // Quem estava esperando resposta não vai receber nenhuma: rejeita agora,
        // senão a promessa fica pendurada para sempre.
        for (const [, entry] of this._pending) {
            clearTimeout(entry.timer);
            entry.reject(new Error('Interpretador reiniciado.'));
        }
        this._pending.clear();
        this.packagesLoaded.clear();
        this.status = 'idle';
    },

    // ─── API ──────────────────────────────────────────────────────────────

    /** Baixa e inicializa o Pyodide. Idempotente e seguro de chamar cedo. */
    boot() {
        if (this.status === 'ready') return Promise.resolve(true);
        if (this._bootPromise) return this._bootPromise;
        if (!this.isSupported()) {
            this.status    = 'failed';
            this.lastError = 'Seu navegador não suporta Web Workers.';
            return Promise.resolve(false);
        }

        this.status = 'booting';
        this._emit('booting');
        this._bootPromise = this._post('init', null, BOOT_TIMEOUT, () => this.kill())
            .then(() => {
                this.status = 'ready';
                this._emit('ready');
                return true;
            })
            .catch((err) => {
                this.status    = 'failed';
                this.lastError = err.timeout
                    ? 'O interpretador demorou demais para carregar.'
                    : (err.message || 'Falha ao carregar o interpretador.');
                this._bootPromise = null;
                this._emit('failed', { message: this.lastError });
                return false;
            });
        return this._bootPromise;
    },

    /** Garante que numpy/pandas estejam disponíveis antes de um desafio. */
    async loadPackages(names = []) {
        if (!names.length) return true;
        const ok = await this.boot();
        if (!ok) return false;
        const missing = names.filter(n => !this.packagesLoaded.has(n));
        if (!missing.length) return true;
        try {
            await this._post('packages', { names: missing }, BOOT_TIMEOUT, () => this.kill());
            missing.forEach(n => this.packagesLoaded.add(n));
            this._emit('packages-ready', { names: missing });
            return true;
        } catch (err) {
            this.lastError = err.timeout
                ? 'Demorou demais para carregar as bibliotecas.'
                : (err.message || 'Falha ao carregar as bibliotecas.');
            return false;
        }
    },

    /**
     * Executa o código do jogador contra uma lista de casos de teste.
     * Nunca lança: devolve sempre um relatório que a UI sabe exibir.
     *
     * @returns {{ok:boolean, error:?string, errorStage:?string, stdout:string,
     *            results:Array, timeout?:boolean, unavailable?:boolean}}
     */
    async run({ setup = '', code = '', cases = [], packages = [] } = {}, { timeoutMs = RUN_TIMEOUT } = {}) {
        const booted = await this.boot();
        if (!booted) {
            return this._failReport(this.lastError || 'Interpretador indisponível.', { unavailable: true });
        }
        if (packages.length) {
            const ok = await this.loadPackages(packages);
            if (!ok) return this._failReport(this.lastError || 'Bibliotecas indisponíveis.', { unavailable: true });
        }

        try {
            const msg = await this._post('run', { setup, code, cases, packages }, timeoutMs, () => {
                // Loop infinito ou código pesado demais: derruba o interpretador.
                this.kill();
            });
            return msg.report;
        } catch (err) {
            if (err.timeout) {
                return this._failReport(
                    `Tempo esgotado (${Math.round(timeoutMs / 1000)}s). Seu código pode ter entrado em laço infinito.`,
                    { timeout: true },
                );
            }
            return this._failReport(err.message || 'Erro inesperado ao executar.');
        }
    },

    _failReport(message, extra = {}) {
        return { ok: false, error: message, errorStage: 'runtime', stdout: '', results: [], ...extra };
    },
};
