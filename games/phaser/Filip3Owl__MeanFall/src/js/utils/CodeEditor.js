/* MeanFall — Editor de código do combate.
 *
 * O canvas do jogo tem 544×480 e é escalado por transform: escrever código
 * ali dentro seria ilegível. Este editor é DOM puro, sobreposto à página em
 * position:fixed, do mesmo jeito que o HUD já é DOM.
 *
 * O overlay engole os eventos de teclado antes que eles cheguem à window,
 * senão o Phaser interpretaria cada letra digitada como atalho de combate.
 */

import { CodeChallengeEngine } from '../systems/CodeChallengeEngine.js';
import { PythonRuntime }       from '../systems/PythonRuntime.js';

const DRAFT_PREFIX = 'meanfall_code_draft_';

const DIFF_LABEL = {
    easy:   { txt: 'FÁCIL',   cls: 'mf-diff-easy' },
    medium: { txt: 'MÉDIO',   cls: 'mf-diff-medium' },
    hard:   { txt: 'DIFÍCIL', cls: 'mf-diff-hard' },
};

const esc = (s) => String(s ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

export const CodeEditor = {

    _root:      null,
    _challenge: null,
    _handlers:  {},
    _busy:      false,
    _submitted: false,
    _offProgress: null,

    isOpen() { return !!this._root; },

    // ─── Ciclo de vida ────────────────────────────────────────────────────

    open({ challenge, combat = {}, onSubmit, onGiveUp, onHint, onExit }) {
        if (this._root) this.close();

        this._challenge = challenge;
        this._handlers  = { onSubmit, onGiveUp, onHint, onExit };
        this._busy      = false;
        this._submitted = false;
        this._armed     = null;

        const root = document.createElement('div');
        root.className = 'mf-code-overlay';
        root.innerHTML = this._template(challenge, combat);
        document.body.appendChild(root);
        this._root = root;

        this._q('#mf-code-run')    .addEventListener('click', () => this._run(true));
        this._q('#mf-code-submit') .addEventListener('click', () => this._confirmSubmit());
        this._q('#mf-code-hint')   .addEventListener('click', () => this._hint());
        this._q('#mf-code-reset')  .addEventListener('click', () => this._resetCode());
        this._q('#mf-code-giveup') .addEventListener('click', () => this._giveUp());

        const ta = this._q('#mf-code-input');
        ta.value = this._loadDraft(challenge);
        ta.addEventListener('input',  () => { this._disarm(); this._syncGutter(); this._saveDraft(); });
        ta.addEventListener('scroll', () => this._syncGutter(true));
        ta.addEventListener('keydown', (e) => this._onEditorKey(e));

        // Barreira de teclado: o Phaser escuta na window, então tudo que for
        // digitado aqui dentro morre antes de subir.
        root.addEventListener('keydown', (e) => e.stopPropagation());
        root.addEventListener('keyup',   (e) => e.stopPropagation());
        root.addEventListener('keypress', (e) => e.stopPropagation());

        this._syncGutter();
        setTimeout(() => ta.focus(), 30);

        // Aquece o interpretador enquanto o jogador lê o enunciado.
        this._offProgress = PythonRuntime.onProgress((ev) => this._onRuntimeProgress(ev));
        if (PythonRuntime.status !== 'ready') {
            this._log('Preparando o interpretador Python…', 'mf-log-info');
            this._setBusy(true, 'carregando interpretador');
        }
        PythonRuntime.boot().then((ok) => {
            if (!this._root) return;
            if (!ok) {
                this._log(PythonRuntime.lastError || 'Interpretador indisponível.', 'mf-log-error');
                this._setBusy(false);
                return;
            }
            const pkgs = challenge.packages || [];
            if (!pkgs.length) {
                this._ready();
                return;
            }
            this._log(`Carregando ${pkgs.join(', ')}…`, 'mf-log-info');
            PythonRuntime.loadPackages(pkgs).then((okPkg) => {
                if (!this._root) return;
                if (!okPkg) {
                    this._log(PythonRuntime.lastError || 'Falha ao carregar bibliotecas.', 'mf-log-error');
                    this._setBusy(false);
                    return;
                }
                this._ready();
            });
        });
    },

    close() {
        clearTimeout(this._armTimer);
        this._armed = null;
        this._offProgress?.();
        this._offProgress = null;
        this._root?.remove();
        this._root = null;
        this._challenge = null;
        this._handlers = {};
    },

    /** Atualiza as barras do cabeçalho sem fechar o editor. */
    updateVitals(v = {}) {
        if (!this._root) return;
        const set = (sel, pct, txt) => {
            const bar = this._q(sel);
            if (bar) bar.style.width = `${Math.max(0, Math.min(100, pct))}%`;
            const label = this._q(`${sel}-txt`);
            if (label && txt != null) label.textContent = txt;
        };
        if (v.monsterHp != null && v.monsterMaxHp) {
            set('#mf-bar-monster', (v.monsterHp / v.monsterMaxHp) * 100, `${v.monsterHp}/${v.monsterMaxHp}`);
        }
        if (v.playerHp != null && v.playerMaxHp) {
            set('#mf-bar-hp', (v.playerHp / v.playerMaxHp) * 100, `${v.playerHp}/${v.playerMaxHp}`);
        }
        if (v.focus != null && v.maxFocus) {
            set('#mf-bar-focus', (v.focus / v.maxFocus) * 100, `${v.focus}/${v.maxFocus}`);
        }
        if (v.streak != null) {
            const s = this._q('#mf-code-streak');
            if (s) s.textContent = v.streak > 1 ? `${v.streak}× sequência` : '';
        }
    },

    // ─── Template ─────────────────────────────────────────────────────────

    _template(ch, combat) {
        const diff = DIFF_LABEL[ch.difficulty] || DIFF_LABEL.medium;
        const visiveis = CodeChallengeEngine.visibleCases(ch);
        const ocultos  = CodeChallengeEngine.hiddenCount(ch);

        const exemplos = visiveis.map(c => `
            <div class="mf-case">
                <code class="mf-case-call">${esc(c.call)}</code>
                <span class="mf-case-arrow">→</span>
                <code class="mf-case-exp">${esc(c.expected)}</code>
            </div>`).join('');

        const mHp = combat.monsterMaxHp || 1;
        const pHp = combat.playerMaxHp  || 1;
        const foc = combat.maxFocus     || 1;

        return `
        <div class="mf-code-window">
            <header class="mf-code-head">
                <div class="mf-code-vs">
                    <div class="mf-vs-block">
                        <span class="mf-vs-name">${esc(combat.monsterName || 'Desafio')}</span>
                        <div class="mf-vs-track"><div class="mf-vs-fill mf-fill-monster" id="mf-bar-monster"
                             style="width:${((combat.monsterHp ?? mHp) / mHp) * 100}%"></div></div>
                        <span class="mf-vs-txt" id="mf-bar-monster-txt">${combat.monsterHp ?? mHp}/${mHp}</span>
                    </div>
                    <div class="mf-vs-block">
                        <span class="mf-vs-name">Você <em id="mf-code-streak">${combat.streak > 1 ? `${combat.streak}× sequência` : ''}</em></span>
                        <div class="mf-vs-track"><div class="mf-vs-fill mf-fill-hp" id="mf-bar-hp"
                             style="width:${((combat.playerHp ?? pHp) / pHp) * 100}%"></div></div>
                        <span class="mf-vs-txt" id="mf-bar-hp-txt">${combat.playerHp ?? pHp}/${pHp}</span>
                        <div class="mf-vs-track mf-track-thin"><div class="mf-vs-fill mf-fill-focus" id="mf-bar-focus"
                             style="width:${((combat.focus ?? foc) / foc) * 100}%"></div></div>
                        <span class="mf-vs-txt" id="mf-bar-focus-txt">${combat.focus ?? foc}/${foc}</span>
                    </div>
                </div>
                <div class="mf-code-title">
                    <span class="mf-diff ${diff.cls}">${diff.txt}</span>
                    <h2>${esc(ch.title)}</h2>
                </div>
            </header>

            <div class="mf-code-body">
                <section class="mf-code-brief">
                    <div class="mf-brief-scroll">
                        <p class="mf-brief-text">${esc(ch.questionText)}</p>
                        ${ch.datasetPreview ? `<div class="mf-dataset"><span class="mf-label">Disponível no escopo</span><code>${esc(ch.datasetPreview)}</code></div>` : ''}
                        ${ch.setup ? `<details class="mf-setup"><summary>Ver o código que prepara os dados</summary><pre>${esc(ch.setup)}</pre></details>` : ''}
                        <div class="mf-label">Exemplos</div>
                        ${exemplos || '<div class="mf-case mf-case-none">sem exemplos visíveis</div>'}
                        ${ocultos ? `<div class="mf-hidden-note">🔒 ${ocultos} teste${ocultos > 1 ? 's' : ''} oculto${ocultos > 1 ? 's' : ''} — só rodam no envio</div>` : ''}
                        <div class="mf-hint-slot" id="mf-code-hint-slot"></div>
                    </div>
                </section>

                <section class="mf-code-work">
                    <div class="mf-editor">
                        <pre class="mf-gutter" id="mf-code-gutter">1</pre>
                        <textarea id="mf-code-input" spellcheck="false" autocomplete="off"
                                  autocapitalize="off" wrap="off"></textarea>
                    </div>
                    <div class="mf-console" id="mf-code-console"></div>
                </section>
            </div>

            <footer class="mf-code-foot">
                <div class="mf-foot-left">
                    <button id="mf-code-run"    class="mf-btn mf-btn-run">▶ Rodar exemplos <em>Ctrl+Enter</em></button>
                    <button id="mf-code-submit" class="mf-btn mf-btn-submit">✓ Enviar resposta${ocultos ? ` <em>+${ocultos} oculto${ocultos > 1 ? 's' : ''}</em>` : ''}</button>
                </div>
                <div class="mf-foot-right">
                    <button id="mf-code-hint"   class="mf-btn mf-btn-ghost">Dica (−10 Foco)</button>
                    <button id="mf-code-reset"  class="mf-btn mf-btn-ghost">Esqueleto</button>
                    <button id="mf-code-giveup" class="mf-btn mf-btn-danger">Desistir</button>
                </div>
            </footer>
        </div>`;
    },

    _q(sel) { return this._root?.querySelector(sel); },

    // ─── Editor ───────────────────────────────────────────────────────────

    _onEditorKey(e) {
        const ta = e.target;

        if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
            e.preventDefault();
            if (e.shiftKey) this._confirmSubmit(); else this._run(true);
            return;
        }

        if (e.key === 'Tab') {
            e.preventDefault();
            const { selectionStart: a, selectionEnd: b, value } = ta;
            if (e.shiftKey) {
                // Desindenta a linha atual em até 4 espaços
                const ini = value.lastIndexOf('\n', a - 1) + 1;
                const corte = value.slice(ini, ini + 4).match(/^ {1,4}/);
                if (corte) {
                    ta.value = value.slice(0, ini) + value.slice(ini + corte[0].length);
                    ta.selectionStart = ta.selectionEnd = Math.max(ini, a - corte[0].length);
                }
            } else {
                ta.value = value.slice(0, a) + '    ' + value.slice(b);
                ta.selectionStart = ta.selectionEnd = a + 4;
            }
            this._syncGutter();
            this._saveDraft();
            return;
        }

        if (e.key === 'Enter') {
            // Auto-indentação: repete a indentação da linha e entra um nível
            // depois de dois-pontos, como qualquer editor de Python faria.
            const { selectionStart: a, value } = ta;
            const ini    = value.lastIndexOf('\n', a - 1) + 1;
            const linha  = value.slice(ini, a);
            const indent = (linha.match(/^\s*/) || [''])[0];
            const extra  = /:\s*$/.test(linha) ? '    ' : '';
            e.preventDefault();
            const novo = '\n' + indent + extra;
            ta.value = value.slice(0, a) + novo + value.slice(ta.selectionEnd);
            ta.selectionStart = ta.selectionEnd = a + novo.length;
            this._syncGutter();
            this._saveDraft();
        }
    },

    _syncGutter(onlyScroll = false) {
        const ta = this._q('#mf-code-input');
        const g  = this._q('#mf-code-gutter');
        if (!ta || !g) return;
        if (!onlyScroll) {
            const linhas = ta.value.split('\n').length;
            g.textContent = Array.from({ length: linhas }, (_, i) => i + 1).join('\n');
        }
        g.scrollTop = ta.scrollTop;
    },

    _resetCode() {
        const ta = this._q('#mf-code-input');
        if (!ta) return;
        ta.value = this._challenge.starterCode || '';
        this._syncGutter();
        this._saveDraft();
        ta.focus();
    },

    _draftKey() { return DRAFT_PREFIX + this._challenge.id; },

    _loadDraft(ch) {
        try {
            return localStorage.getItem(DRAFT_PREFIX + ch.id) || ch.starterCode || '';
        } catch {
            return ch.starterCode || '';
        }
    },

    _saveDraft() {
        try { localStorage.setItem(this._draftKey(), this._q('#mf-code-input').value); }
        catch { /* cota cheia: rascunho é conveniência, não requisito */ }
    },

    // ─── Execução ─────────────────────────────────────────────────────────

    _onRuntimeProgress(ev) {
        if (!this._root) return;
        if (ev.stage === 'interpreter') this._log('Baixando o Python (só na primeira vez)…', 'mf-log-info');
        if (ev.stage === 'packages')    this._log(`Baixando ${(ev.names || []).join(', ')}…`, 'mf-log-info');
        if (ev.stage === 'failed')      this._log(ev.message || 'Falha no interpretador.', 'mf-log-error');
    },

    _ready() {
        this._setBusy(false);
        this._log('Interpretador pronto. Ctrl+Enter roda os exemplos.', 'mf-log-ok');
    },

    _setBusy(busy, motivo = '') {
        this._busy = busy;
        for (const id of ['#mf-code-run', '#mf-code-submit', '#mf-code-hint', '#mf-code-reset']) {
            const b = this._q(id);
            if (b) b.disabled = busy;
        }
        const run = this._q('#mf-code-run');
        if (run) run.innerHTML = busy
            ? `⏳ ${esc(motivo || 'executando')}…`
            : '▶ Rodar exemplos <em>Ctrl+Enter</em>';
    },

    async _run(onlyVisible) {
        if (this._busy || this._submitted) return;
        this._clearLog();
        this._setBusy(true, onlyVisible ? 'executando' : 'corrigindo');
        const code = this._q('#mf-code-input').value;

        const report = await CodeChallengeEngine.run(this._challenge, code, { onlyVisible });
        if (!this._root) return;
        this._setBusy(false);
        this._render(report, onlyVisible);
        return report;
    },

    /**
     * Confirmação em dois toques, no próprio botão. Nada de window.confirm:
     * diálogo nativo congela o jogo por trás e destoa da interface.
     */
    _arm(id, rotulo, acao) {
        // Não checa _busy: desistir não depende do interpretador, e quem quer
        // abandonar o desafio durante o download precisa conseguir.
        if (this._submitted) return;
        const btn = this._q(id);
        if (!btn) return;

        if (this._armed === id) {
            this._disarm();
            acao();
            return;
        }
        this._disarm();
        this._armed        = id;
        this._armedLabel   = btn.innerHTML;
        btn.innerHTML      = rotulo;
        btn.classList.add('mf-btn-armed');
        this._armTimer = setTimeout(() => this._disarm(), 6000);
    },

    _disarm() {
        clearTimeout(this._armTimer);
        if (!this._armed) return;
        const btn = this._q(this._armed);
        if (btn) {
            btn.innerHTML = this._armedLabel;
            btn.classList.remove('mf-btn-armed');
        }
        this._armed = null;
    },

    _confirmSubmit() {
        if (this._busy || this._submitted) return;
        this._disarm();
        this._submit();
    },

    async _submit() {
        this._submitted = true;
        this._clearLog();
        this._setBusy(true, 'corrigindo');
        const code   = this._q('#mf-code-input').value;
        const report = await CodeChallengeEngine.run(this._challenge, code, { onlyVisible: false });
        if (!this._root) return;
        this._setBusy(false);
        this._render(report, false);

        const passou = report.allPassed;
        this._log(
            passou ? '✓ Todos os testes passaram — o golpe acerta em cheio!'
                   : `✗ ${report.passed}/${report.total} testes passaram.`,
            passou ? 'mf-log-ok' : 'mf-log-error',
        );

        // Quem fecha o editor é o combate, depois de conclude(): o jogador
        // ainda precisa ver o dano e, quando erra, o gabarito.
        this._handlers.onSubmit?.({ ...report, code });
    },

    _giveUp() {
        this._arm('#mf-code-giveup', 'Confirmar — conta como erro', () => {
            this._submitted = true;
            const code = this._q('#mf-code-input')?.value || '';
            this._handlers.onGiveUp?.({ code });
        });
    },

    _hint() {
        const dica = this._handlers.onHint?.();
        if (!dica) return;
        const slot = this._q('#mf-code-hint-slot');
        if (slot) slot.innerHTML = `<div class="mf-hint">💡 ${esc(dica)}</div>`;
        this._q('#mf-code-hint').disabled = true;
    },

    /**
     * Fecha o turno dentro do editor: mostra veredito, explicação e — quando o
     * jogador errou — a solução de referência, com um único botão Continuar.
     */
    conclude({ passed, headline, detail, solution, onContinue }) {
        if (!this._root) { onContinue?.(); return; }

        this._submitted = true;
        this._setBusy(false);
        for (const id of ['#mf-code-run', '#mf-code-submit', '#mf-code-hint', '#mf-code-reset', '#mf-code-giveup']) {
            const b = this._q(id);
            if (b) b.disabled = true;
        }
        const ta = this._q('#mf-code-input');
        if (ta) ta.readOnly = true;

        const brief = this._q('.mf-brief-scroll');
        if (brief) {
            const bloco = document.createElement('div');
            bloco.className = `mf-verdict ${passed ? 'mf-verdict-ok' : 'mf-verdict-bad'}`;
            bloco.innerHTML = `
                <div class="mf-verdict-head">${esc(headline)}</div>
                ${detail ? `<p class="mf-verdict-text">${esc(detail)}</p>` : ''}
                ${solution ? `<div class="mf-label">Solução de referência</div><pre class="mf-solution">${esc(solution)}</pre>` : ''}`;
            brief.appendChild(bloco);
            bloco.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        }

        const foot = this._q('.mf-code-foot');
        if (foot) {
            foot.innerHTML = '<div class="mf-foot-left"></div><div class="mf-foot-right"></div>';
            const btn = document.createElement('button');
            btn.className = 'mf-btn mf-btn-submit';
            btn.textContent = 'Continuar ▶';
            btn.addEventListener('click', () => { this.close(); onContinue?.(); });
            foot.querySelector('.mf-foot-right').appendChild(btn);
            setTimeout(() => btn.focus(), 20);
        }
    },

    // ─── Console ──────────────────────────────────────────────────────────

    _clearLog() {
        const c = this._q('#mf-code-console');
        if (c) c.innerHTML = '';
    },

    _log(msg, cls = '') {
        const c = this._q('#mf-code-console');
        if (!c) return;
        const line = document.createElement('div');
        line.className = `mf-log ${cls}`;
        line.textContent = msg;
        c.appendChild(line);
        c.scrollTop = c.scrollHeight;
    },

    _render(report, onlyVisible) {
        if (report.error) {
            const rotulo = report.errorStage === 'setup' ? 'Erro ao preparar os dados' : 'Erro no seu código';
            this._log(`${rotulo}: ${report.error}`, 'mf-log-error');
        }

        for (const r of report.results || []) {
            const nome = r.hidden ? `teste oculto — ${r.name}` : r.name;
            if (r.passed) {
                this._log(`✓ ${nome}`, 'mf-log-ok');
            } else if (r.error) {
                this._log(`✗ ${nome} — ${r.error}`, 'mf-log-error');
            } else if (r.hidden) {
                // Teste oculto não revela a entrada; só o que saiu errado.
                this._log(`✗ ${nome} — obtido ${r.got}`, 'mf-log-error');
            } else {
                this._log(`✗ ${nome} — esperado ${r.expected} · obtido ${r.got}`, 'mf-log-error');
            }
        }

        if (report.stdout) {
            this._log('— saída do seu print() —', 'mf-log-dim');
            for (const l of report.stdout.replace(/\n$/, '').split('\n')) this._log(l, 'mf-log-dim');
        }

        if (!report.error && (report.results || []).length) {
            const escopo = onlyVisible ? 'exemplos' : 'testes';
            this._log(`${report.passed}/${report.total} ${escopo} passaram.`,
                report.allPassed ? 'mf-log-ok' : 'mf-log-warn');
            if (onlyVisible && report.allPassed) {
                this._log('Exemplos ok. Envie para valer contra os testes ocultos.', 'mf-log-info');
            }
        }
    },
};
