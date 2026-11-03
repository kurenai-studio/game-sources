// QuestionGenerator — randomised fill_numeric variants
// Each entry is keyed by question ID and returns partial overrides
// { questionText?, context?, correctAnswer, tolerance?, explanation? }
// that are merged onto the base question from questions.js.
// A explanation É obrigatória aqui: a da questão base cita os números
// originais e ficaria errada para o dataset gerado.
// Multiple-choice questions are NOT generated here — shuffleOptions() handles those.

// ── Helpers ────────────────────────────────────────────────────────────────
const ri = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const r2 = x => Math.round(x * 100) / 100;
const r1 = x => Math.round(x * 10) / 10;
const br = x => String(x).replace('.', ','); // decimal em vírgula (PT-BR)

function mean(a)   { return a.reduce((s, v) => s + v, 0) / a.length; }
function sum(a)    { return a.reduce((s, v) => s + v, 0); }
function median(a) {
    const s = [...a].sort((x, y) => x - y), m = s.length >> 1;
    return s.length & 1 ? s[m] : r2((s[m - 1] + s[m]) / 2);
}
function sorted(a) { return [...a].sort((x, y) => x - y); }
function popVar(a) {
    const m = mean(a);
    return r2(a.reduce((s, v) => s + (v - m) ** 2, 0) / a.length);
}
function sampleVar(a) {
    const m = mean(a);
    return r2(a.reduce((s, v) => s + (v - m) ** 2, 0) / (a.length - 1));
}

// ── MÉDIA / MEDIANA / MODA ─────────────────────────────────────────────────

export const GENERATORS = {

    // mean of 10 random values
    mmm_001: () => {
        const vals = Array.from({ length: 10 }, () => ri(1, 15));
        const ans = r2(mean(vals));
        return {
            context: `Danos: [${vals.join(', ')}]. Calcule a MÉDIA de dano por batalha.`,
            correctAnswer: ans,
            tolerance: 0.1,
            explanation: `Soma ${sum(vals)}, dividida por 10 → ${br(ans)} de dano médio.`,
        };
    },

    // mean of 5 values in arithmetic sequence (always exact integer)
    mmm_004: () => {
        const a = ri(5, 20), d = ri(5, 20);
        const vals = [a, a + d, a + 2 * d, a + 3 * d, a + 4 * d];
        return {
            questionText: `Cinco amuletos custam: ${vals.join(', ')} gemas. Qual é o preço MÉDIO?`,
            correctAnswer: a + 2 * d,   // exact mean of arithmetic sequence
            tolerance: 0.01,
            explanation: `Soma ${sum(vals)} ÷ 5 = ${a + 2 * d}. Em uma sequência com passo constante, a média é o valor central.`,
        };
    },

    // median of 5 strictly ascending values
    mmm_005: () => {
        const base = ri(5, 15);
        const vals = [base, base + ri(1, 4), base + ri(5, 9), base + ri(10, 14), base + ri(15, 20)];
        return {
            questionText: `Os HPs dos 5 inimigos derrotados foram: [${vals.join(', ')}]. Qual é a MEDIANA?`,
            correctAnswer: vals[2],
            tolerance: 0,
            explanation: `Os valores já estão em ordem; com 5 valores, a mediana é o 3º: ${vals[2]}.`,
        };
    },

    // median of 7 unsorted values
    mmm_007: () => {
        const vals = Array.from({ length: 7 }, () => ri(1, 15));
        const ans = median(vals);
        return {
            context: `Danos: [${vals.join(', ')}]`,
            correctAnswer: ans,
            tolerance: 0,
            explanation: `Ordenando: [${sorted(vals).join(', ')}]. Com 7 valores, a mediana é o 4º: ${br(ans)}.`,
        };
    },

    // mean with strong outlier — shows distortion
    mmm_010: () => {
        const base = ri(800, 1800), step = ri(150, 400);
        const outlier = ri(8000, 20000);
        const vals = [base, base + step, base + 2 * step, base + 3 * step, outlier];
        const ans = r2(mean(vals));
        return {
            questionText: `A guilda paga em ouro: [${vals.join(', ')}]. Qual é a MÉDIA paga?`,
            correctAnswer: ans,
            tolerance: 2,
            explanation: `Soma ${sum(vals)} ÷ 5 = ${br(ans)}. Note como o outlier ${outlier} puxa a média para cima.`,
        };
    },

    // mean of 6 values
    mmm_012: () => {
        const vals = Array.from({ length: 6 }, () => ri(8, 28));
        const ans = r2(mean(vals));
        return {
            questionText: `Em 6 batalhas, seus tempos (em segundos) foram: [${vals.join(', ')}]. Calcule a MÉDIA.`,
            correctAnswer: ans,
            tolerance: 0.1,
            explanation: `Soma ${sum(vals)} ÷ 6 = ${br(ans)} segundos.`,
        };
    },

    // median of 4 values (even count → average of two middle)
    mmm_013: () => {
        const vals = Array.from({ length: 4 }, () => ri(1, 10)).sort((a, b) => a - b);
        const ans = median(vals);
        return {
            questionText: `A guilda recrutou 4 magos de níveis [${vals.join(', ')}]. Qual é a MEDIANA?`,
            correctAnswer: ans,
            tolerance: 0.1,
            explanation: `Com 4 valores, a mediana é a média dos dois centrais: (${vals[1]} + ${vals[2]}) ÷ 2 = ${br(ans)}.`,
        };
    },

    // mode of 6 values — one value appears 3×, others appear less
    mmm_014: () => {
        const mv = ri(6, 14) * 10; // mode value: 60, 70, 80 ... 140
        const a = mv - ri(1, 3) * 10, b = mv + ri(1, 3) * 10;
        const vals = [a, mv, b, mv, mv, a];  // mv appears 3×
        return {
            questionText: `O ferreiro vendeu 6 espadas por: [${vals.join(', ')}] gemas. Qual é a MODA?`,
            correctAnswer: mv,
            tolerance: 0,
            explanation: `${mv} aparece 3 vezes — mais que qualquer outro valor. A moda é o valor mais frequente.`,
        };
    },

    // weighted mean of two groups
    mmm_016: () => {
        const nA = ri(2, 5), dmgA = ri(8, 15);
        const nB = ri(1, 4), dmgB = dmgA + ri(5, 15);
        const wm = r1((nA * dmgA + nB * dmgB) / (nA + nB));
        return {
            questionText: `Sua equipe tem ${nA} guerreiros com dano médio ${dmgA} e ${nB} magos com dano médio ${dmgB}. Qual o dano médio de TODA a equipe?`,
            correctAnswer: wm,
            tolerance: 0.1,
            explanation: `Média ponderada: (${nA}×${dmgA} + ${nB}×${dmgB}) ÷ ${nA + nB} = ${nA * dmgA + nB * dmgB} ÷ ${nA + nB} ≈ ${br(wm)}.`,
        };
    },

    // median of 4 arithmetic values
    mmm_019: () => {
        const a = ri(3, 10), d = ri(3, 8);
        const vals = [a, a + d, a + 2 * d, a + 3 * d];
        const ans = median(vals);
        return {
            questionText: `Quatro poções custam ${vals.join(', ')} gemas. Qual é a MEDIANA?`,
            correctAnswer: ans,
            tolerance: 0.1,
            explanation: `Mediana dos dois centrais: (${vals[1]} + ${vals[2]}) ÷ 2 = ${br(ans)}.`,
        };
    },

    // mode of 6 drops
    mmm_021: () => {
        const mv = ri(2, 8) * 5; // 10, 15, 20 ... 40
        const x = mv - ri(1, 2) * 5, y = mv + ri(1, 2) * 5;
        const vals = [mv, x, mv, y, mv, y];  // mv appears 3×
        return {
            questionText: `Um bando deixou cair bolsas de ouro com os valores: ${vals.join(', ')}. Qual é a MODA de ouro por bolsa?`,
            correctAnswer: mv,
            tolerance: 0,
            explanation: `${mv} aparece 3 vezes, mais que qualquer outro valor — é a moda.`,
        };
    },

    // mean of 5 values
    mmm_022: () => {
        const vals = Array.from({ length: 5 }, () => ri(20, 100));
        const ans = r2(mean(vals));
        return {
            questionText: `Você encontrou 5 poções de mana. Seus volumes em ml são: ${vals.join(', ')}. Qual é a MÉDIA de volume?`,
            correctAnswer: ans,
            tolerance: 0.5,
            explanation: `Soma ${sum(vals)} ÷ 5 = ${br(ans)} ml.`,
        };
    },

    // median of 6 unsorted values
    mmm_023: () => {
        const vals = Array.from({ length: 6 }, () => ri(1, 12));
        const ans = median(vals);
        const s = sorted(vals);
        return {
            questionText: `Um grupo de 6 Golems tem os seguintes pesos em toneladas: ${vals.join(', ')}. Qual é a MEDIANA de peso?`,
            correctAnswer: ans,
            tolerance: 0.1,
            explanation: `Ordenando: [${s.join(', ')}]. Mediana = (${s[2]} + ${s[3]}) ÷ 2 = ${br(ans)}.`,
        };
    },

    // find missing value given target mean
    mmm_026: () => {
        const base = Array.from({ length: 4 }, () => ri(1, 8));
        const baseSum = sum(base);
        const targetMean = ri(4, 8);
        const missing = targetMean * 5 - baseSum;
        if (missing < 1 || missing > 20) {
            // regenerate with safe values
            const safeBase = [1, 2, 4, 5]; // original question values
            return {
                questionText: `O Pastor tem 4 ovelhas de níveis ${safeBase.join(', ')}. Ele compra uma 5ª e a MÉDIA de nível sobe para 4. Qual o nível da nova ovelha?`,
                correctAnswer: 8, tolerance: 0,
                explanation: 'Para média 4 com 5 ovelhas, a soma deve ser 4×5 = 20. Já existem 1+2+4+5 = 12 → a nova ovelha tem nível 8.',
            };
        }
        return {
            questionText: `O Pastor tem 4 ovelhas de níveis ${base.join(', ')}. Ele compra uma 5ª e a MÉDIA sobe para ${targetMean}. Qual o nível da nova ovelha?`,
            correctAnswer: missing,
            tolerance: 0,
            explanation: `Para média ${targetMean} com 5 ovelhas, a soma deve ser ${targetMean}×5 = ${targetMean * 5}. Já existem ${baseSum} → a nova ovelha tem nível ${missing}.`,
        };
    },

    // ── VARIÂNCIA / DESVIO PADRÃO ──────────────────────────────────────────

    // amplitude of 6 values
    spr_001: () => {
        const vals = Array.from({ length: 6 }, () => ri(1, 30));
        const max = Math.max(...vals), min = Math.min(...vals);
        return {
            questionText: `Os HPs dos monstros encontrados foram: [${vals.join(', ')}]. Qual é a AMPLITUDE?`,
            correctAnswer: max - min,
            tolerance: 0,
            explanation: `Amplitude = máximo − mínimo = ${max} − ${min} = ${max - min}.`,
        };
    },

    // amplitude of 5 values
    spr_003: () => {
        const vals = Array.from({ length: 5 }, () => ri(1, 20));
        const max = Math.max(...vals), min = Math.min(...vals);
        return {
            questionText: `Preços de poções na loja: [${vals.join(', ')}]. Qual é a AMPLITUDE?`,
            correctAnswer: max - min,
            tolerance: 0,
            explanation: `Amplitude = máximo − mínimo = ${max} − ${min} = ${max - min}.`,
        };
    },

    // population variance — symmetric pairs ensure exact mean
    spr_005: () => {
        const m = ri(3, 8);
        const devs = [ri(1, 3), ri(1, 3), ri(1, 4), ri(2, 4)]; // 4 positive deviations
        const vals = [...devs.map(d => m - d), ...devs.map(d => m + d)].sort((a, b) => a - b);
        const ss = devs.reduce((s, d) => s + 2 * d * d, 0);
        const v = r2(ss / 8);
        return {
            context: `Danos: [${vals.join(', ')}]. A média é ${m}. Calcule a VARIÂNCIA POPULACIONAL.`,
            correctAnswer: v,
            tolerance: 0.1,
            explanation: `Os desvios ao quadrado somam ${ss}; dividindo por N = 8 → variância = ${br(v)}.`,
        };
    },

    // population std dev = sqrt(variance from spr_005 logic)
    spr_006: () => {
        const m = ri(3, 8);
        const devs = [ri(1, 3), ri(1, 3), ri(1, 4), ri(2, 4)];
        const vals = [...devs.map(d => m - d), ...devs.map(d => m + d)].sort((a, b) => a - b);
        const v = devs.reduce((s, d) => s + 2 * d * d, 0) / 8;
        const ans = r2(Math.sqrt(v));
        return {
            context: `Danos: [${vals.join(', ')}]. A média é ${m}. Calcule o DESVIO PADRÃO POPULACIONAL.`,
            correctAnswer: ans,
            tolerance: 0.1,
            explanation: `Variância = ${br(r2(v))}; desvio padrão = √${br(r2(v))} ≈ ${br(ans)}.`,
        };
    },

    // sample variance of 5 values (divisor n−1)
    spr_009: () => {
        const m = ri(3, 8);
        const d1 = ri(1, 3), d2 = ri(1, 3);
        const vals = [m - d2, m - d1, m, m + d1, m + d2]; // simétricos: média = m
        const ss = 2 * d1 * d1 + 2 * d2 * d2;
        const sv = r2(sampleVar(vals));
        return {
            questionText: `Calcule a VARIÂNCIA AMOSTRAL dos seus drops: [${vals.join(', ')}] (use n−1).`,
            correctAnswer: sv,
            tolerance: 0.1,
            explanation: `Média = ${m}. Os desvios ao quadrado somam ${ss}; dividindo por n−1 = 4 → ${br(sv)}.`,
        };
    },

    // population std dev of 5 values with known mean
    spr_011: () => {
        const m = ri(3, 8);
        const d1 = ri(1, 3), d2 = ri(2, 4);
        const vals = [m - d2, m - d1, m, m + d1, m + d2];
        const ss = 2 * d1 * d1 + 2 * d2 * d2;
        const v = ss / 5;
        const ans = r2(Math.sqrt(v));
        return {
            questionText: `Os tempos de conjuração (em segundos) de 5 magias foram: [${vals.join(', ')}]. Média = ${m}. Calcule o DESVIO PADRÃO POPULACIONAL.`,
            correctAnswer: ans,
            tolerance: 0.05,
            explanation: `Desvios² somam ${ss}; variância = ${ss}/5 = ${br(r2(v))}; desvio = √${br(r2(v))} ≈ ${br(ans)}.`,
        };
    },

    // CV = (sigma / mean) * 100
    spr_014: () => {
        const m2 = ri(5, 20) * 10;         // mean 50–200
        const s2 = ri(1, Math.floor(m2 / 5)); // sigma < mean/5
        const cv = r1((s2 / m2) * 100);
        return {
            questionText: `Uma poção tem cura média ${m2} com desvio padrão ${s2}. Qual o COEFICIENTE DE VARIAÇÃO (em %)?`,
            correctAnswer: cv,
            tolerance: 0.2,
            explanation: `CV = (σ ÷ média) × 100 = (${s2} ÷ ${m2}) × 100 = ${br(cv)}%.`,
        };
    },

    // amplitude of 5 values (easy)
    spr_018: () => {
        const vals = Array.from({ length: 5 }, () => ri(3, 18));
        const max = Math.max(...vals), min = Math.min(...vals);
        return {
            questionText: `Os danos dos seus 5 últimos ataques foram: [${vals.join(', ')}]. Qual é a AMPLITUDE desse conjunto?`,
            correctAnswer: max - min,
            tolerance: 0,
            explanation: `Amplitude = máximo − mínimo = ${max} − ${min} = ${max - min}.`,
        };
    },

    // population variance of 3 values
    spr_022: () => {
        const m = ri(5, 12);
        const d = ri(1, 4);
        const vals = [m - d, m, m + d]; // mean exactly m
        const v = r2(2 * d * d / 3);
        return {
            questionText: `Você testou uma nova varinha. Os danos foram: ${vals.join(', ')}. A média é ${m}. Qual é a VARIÂNCIA POPULACIONAL desse conjunto?`,
            correctAnswer: v,
            tolerance: 0.1,
            explanation: `Desvios: −${d}, 0, +${d}. Quadrados somam ${2 * d * d}; dividindo por N = 3 → ${br(v)}.`,
        };
    },

    // stddev = sqrt(variance) — uses a perfect square
    spr_023: () => {
        const sqrts  = [1, 2, 3, 4, 5, 6, 7, 8];
        const sd     = sqrts[ri(0, sqrts.length - 1)];
        const v      = sd * sd;
        const nMonst = ri(3, 8);
        return {
            questionText: `Um grupo de ${nMonst} Specters tem variância de HP igual a ${v}. Qual é o DESVIO PADRÃO de HP desse grupo?`,
            correctAnswer: sd,
            tolerance: 0,
            explanation: `O desvio padrão é a raiz quadrada da variância: √${v} = ${sd}.`,
        };
    },

    // IQR of 4 ascending values: Q1 = avg(v[0],v[1]), Q3 = avg(v[2],v[3])
    spr_025: () => {
        const a = ri(1, 4), d = ri(1, 4);
        const vals = [a, a + d, a + 2 * d, a + 3 * d]; // arithmetic seq
        const q1   = r2((vals[0] + vals[1]) / 2);
        const q3   = r2((vals[2] + vals[3]) / 2);
        const iqr  = r2(q3 - q1);
        return {
            questionText: `Os níveis de perigo de 4 trilhas são: ${vals.join(', ')}. Qual é o INTERVALO INTERQUARTIL (IQR)?`,
            correctAnswer: iqr,
            tolerance: 0.1,
            explanation: `Q1 = (${vals[0]} + ${vals[1]}) ÷ 2 = ${br(q1)}; Q3 = (${vals[2]} + ${vals[3]}) ÷ 2 = ${br(q3)}. IQR = Q3 − Q1 = ${br(iqr)}.`,
        };
    },

    // ── PROBABILIDADE ──────────────────────────────────────────────────────

    // P = red / total (gem bag)
    prob_001: () => {
        const total = ri(6, 15);
        const red   = ri(1, total - 1);
        const ans = r2(red / total);
        return {
            questionText: `Um baú contém ${red} gemas vermelhas e ${total - red} azuis. Qual a probabilidade de tirar uma VERMELHA?`,
            correctAnswer: ans,
            tolerance: 0.01,
            explanation: `${red} casos favoráveis ÷ ${total} possíveis = ${red}/${total} ≈ ${br(ans)}.`,
        };
    },

    // P = 1/n (equal-sector spinner)
    prob_002: () => {
        const sectors = ri(3, 8);
        const sector  = ['poção', 'ouro', 'gema', 'vazio', 'espada', 'chave', 'mapa'][ri(0, 6)];
        const ans = r2(1 / sectors);
        return {
            questionText: `Você gira a Roda da Sorte com ${sectors} setores iguais. Qual a chance de cair no setor "${sector}"?`,
            correctAnswer: ans,
            tolerance: 0.01,
            explanation: `Setores iguais → cada um tem probabilidade 1/${sectors} ≈ ${br(ans)}.`,
        };
    },

    // P(even on d6 or similar die)
    prob_005: () => {
        const faces   = [4, 6, 8, 10, 12][ri(0, 4)];
        const favored = Math.floor(faces / 2);
        const ans = r2(favored / faces);
        return {
            questionText: `Você lança um dado de ${faces} faces. Qual a probabilidade de tirar um número PAR?`,
            correctAnswer: ans,
            tolerance: 0.01,
            explanation: `Há ${favored} números pares entre ${faces} faces: ${favored}/${faces} = ${br(ans)}.`,
        };
    },

    // P(A∪B) = P(A) + P(B) - P(A∩B)
    // Aritmética em % inteiros: 0.3 * 100 em ponto flutuante viraria
    // "30.000000000000004%" no texto exibido ao jogador.
    prob_006: () => {
        const a  = ri(2, 5) * 10;                      // 20% – 50%
        const b  = ri(2, 5) * 10;
        const ab = ri(0, Math.min(a, b) / 10) * 10;    // múltiplo de 10, ≤ min(a,b)
        const pUnion = r2((a + b - ab) / 100);
        return {
            questionText: `O dragão tem ${a}% de chance de cuspir fogo (A) e ${b}% de bater asas (B). Há ${ab}% de fazer AMBOS. Qual P(A∪B)?`,
            correctAnswer: pUnion,
            tolerance: 0.01,
            explanation: `P(A∪B) = P(A) + P(B) − P(A∩B) = ${a}% + ${b}% − ${ab}% = ${a + b - ab}% = ${br(pUnion)}.`,
        };
    },

    // Conditional probability without replacement
    prob_008: () => {
        const fire = ri(3, 7), ice = ri(2, 5);
        const total = fire + ice;
        const pCond = r2(ice / (total - 1)); // P(ice on 2nd | fire on 1st)
        return {
            questionText: `Você tira 2 cartas SEM reposição de ${total} cartas (${fire} de fogo, ${ice} de gelo). Qual P(gelo na 2ª | fogo na 1ª)?`,
            correctAnswer: pCond,
            tolerance: 0.01,
            explanation: `Saiu uma de fogo: restam ${total - 1} cartas, das quais ${ice} são de gelo → ${ice}/${total - 1} ≈ ${br(pCond)}.`,
        };
    },
};
