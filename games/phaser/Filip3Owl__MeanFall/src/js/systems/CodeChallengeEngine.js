/* MeanFall — Seleção e correção dos desafios de código.
 *
 * Espelha a API do QuestionEngine (getQuestion/checkAnswer) para que a
 * CombatScene trate uma questão de estatística e um desafio de código pelo
 * mesmo caminho. A diferença é que a correção aqui é assíncrona: o código
 * precisa rodar antes de virar dano.
 */

import { PY_CHALLENGES, PY_TOPICS } from '../data/pyChallenges.js';
import { PythonRuntime } from './PythonRuntime.js';

const DIFFICULTY_MAP = {
    easy:       ['easy'],
    medium:     ['easy', 'medium'],
    hard:       ['medium', 'hard'],
    very_hard:  ['hard'],
    improbable: ['hard'],
};

export const CodeChallengeEngine = {

    topics() { return PY_TOPICS; },

    elementOfTopic(topic) { return PY_TOPICS[topic]?.element || 'normal'; },

    /**
     * Escolhe um desafio do tópico, respeitando a dificuldade do monstro e
     * evitando repetir os últimos. Mantém o viés adaptativo do jogo: 60% de
     * chance de reapresentar algo que o jogador já errou.
     */
    getChallenge(topic, monsterDifficulty, mastery, recentIds = []) {
        const allowed = Array.isArray(monsterDifficulty)
            ? monsterDifficulty
            : (DIFFICULTY_MAP[monsterDifficulty] || DIFFICULTY_MAP.medium);

        const all  = PY_CHALLENGES[topic] || [];
        const pool = all.filter(c => allowed.includes(c.difficulty) && !recentIds.includes(c.id));
        const base = pool.length ? pool : all.filter(c => allowed.includes(c.difficulty));
        const ch   = this._pickFrom(base.length ? base : all, mastery);
        if (!ch) return null;

        // Formato de "questão" que a CombatScene entende.
        return {
            ...ch,
            type: 'code',
            questionText: ch.questionText,
            correctAnswer: null,
            options: null,
        };
    },

    _pickFrom(pool, mastery) {
        if (!pool.length) return null;
        const wrongIds = mastery?.wrongIds || [];
        const wrong = pool.filter(c => wrongIds.includes(c.id));
        const fresh = pool.filter(c => !wrongIds.includes(c.id));
        const usePool = (wrong.length && Math.random() < 0.6) ? wrong
            : fresh.length ? fresh : pool;
        return usePool[Math.floor(Math.random() * usePool.length)];
    },

    visibleCases(challenge) {
        return (challenge?.cases || []).filter(c => !c.hidden);
    },

    hiddenCount(challenge) {
        return (challenge?.cases || []).filter(c => c.hidden).length;
    },

    /**
     * Executa o código do jogador.
     * @param {object} challenge
     * @param {string} code       código escrito pelo jogador
     * @param {boolean} onlyVisible  true no botão "Rodar" (só os exemplos),
     *                               false no "Enviar" (inclui os ocultos)
     */
    async run(challenge, code, { onlyVisible = false } = {}) {
        const cases = onlyVisible ? this.visibleCases(challenge) : (challenge.cases || []);
        const report = await PythonRuntime.run({
            setup:    challenge.setup || '',
            code,
            cases,
            packages: challenge.packages || [],
        });
        return this.score(report);
    },

    /** Anexa o placar ao relatório bruto do runtime. */
    score(report) {
        const results = report.results || [];
        const passed  = results.filter(r => r.passed).length;
        const total   = results.length;
        return {
            ...report,
            passed,
            total,
            ratio: total ? passed / total : 0,
            allPassed: total > 0 && passed === total && !report.error,
        };
    },

    /** Espelha QuestionEngine.checkAnswer para o tipo 'code'. */
    checkAnswer(_challenge, submission) {
        return !!submission?.allPassed;
    },
};
