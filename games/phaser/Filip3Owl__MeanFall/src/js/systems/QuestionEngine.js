import { QUESTIONS } from '../data/questions.js';
import { ELEMENTS, TOPIC_TO_ELEMENT } from '../constants.js';
import { GENERATORS } from './QuestionGenerator.js';

export const QuestionEngine = {

    getQuestion(topic, playerDifficulty, mastery, recentIds = []) {
        // Map global difficulty to question difficulty filters
        const DIFFICULTY_MAP = {
            easy:       ['easy', 'medium'],
            medium:     ['easy', 'medium', 'hard'],
            hard:       ['medium', 'hard'],
            very_hard:  ['hard'],
            improbable: ['hard'],
        };
        const allowed = Array.isArray(playerDifficulty)
            ? playerDifficulty
            : (DIFFICULTY_MAP[playerDifficulty] || DIFFICULTY_MAP.medium);

        const pool = (QUESTIONS[topic] || []).filter(q =>
            allowed.includes(q.difficulty) &&
            !recentIds.includes(q.id)
        );

        const q = pool.length === 0
            ? this._pickFrom(QUESTIONS[topic] || [], mastery)
            : this._pickFrom(pool, mastery);

        return this._applyGenerator(q);
    },

    // Element-driven selection: routes by elemental affinity to the right topic.
    getQuestionByElement(element, playerDifficulty, mastery, recentIds = []) {
        const elem  = ELEMENTS[element];
        const topic = elem?.topic;
        if (!topic) return null;
        return this.getQuestion(topic, playerDifficulty, mastery, recentIds);
    },

    elementOfTopic(topic) {
        return TOPIC_TO_ELEMENT[topic] || null;
    },

    _applyGenerator(q) {
        if (!q) return null;
        const gen = GENERATORS[q.id];
        if (!gen) return q;
        try {
            return { ...q, ...gen() };
        } catch (e) {
            return q;
        }
    },

    _pickFrom(pool, mastery) {
        if (pool.length === 0) return null;
        const wrongIds = mastery?.wrongIds || [];
        const wrong  = pool.filter(q => wrongIds.includes(q.id));
        const fresh  = pool.filter(q => !wrongIds.includes(q.id));

        // 60% bias toward previously wrong questions
        const usePool = (wrong.length > 0 && Math.random() < 0.6) ? wrong
            : fresh.length > 0 ? fresh : pool;

        return usePool[Math.floor(Math.random() * usePool.length)];
    },

    checkAnswer(question, userAnswer) {
        if (question.type === 'fill_numeric') {
            const parsed = parseFloat(String(userAnswer).replace(',', '.'));
            if (isNaN(parsed)) return false;
            return Math.abs(parsed - question.correctAnswer) <= (question.tolerance ?? 0);
        }
        return String(userAnswer).trim() === String(question.correctAnswer).trim();
    },

    shuffleOptions(question) {
        if (!question.options) return question;
        const shuffled = [...question.options].sort(() => Math.random() - 0.5);
        return { ...question, options: shuffled };
    },
};
