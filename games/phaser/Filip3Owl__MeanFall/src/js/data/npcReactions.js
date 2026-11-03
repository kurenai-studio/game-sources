import { masteryPercent } from '../systems/XPSystem.js';

// Linhas de diálogo reativas ao progresso do jogador. Cada reação dispara
// UMA vez (rastreada em playerData.seenReactions) e é exibida antes das
// linhas normais do NPC, fazendo o mundo comentar o que o jogador fez.
const bosses = p => Object.keys(p.defeatedMonsters || {}).filter(k => k.endsWith('_boss')).length;
const secrets = p => Object.keys(p.secretsFound || {}).length;

export const NPC_REACTIONS = [
    // ── Anciã da Vila ────────────────────────────────────────────────────────
    {
        id: 'elder_first_boss', npcId: 'elder',
        when: p => p.defeatedMonsters?.v_boss,
        line: 'Você derrotou o guardião corrompido da Vila... A Curva me mostrou este momento, mas vê-lo realizado enche este velho coração de esperança.',
    },
    {
        id: 'elder_secrets', npcId: 'elder',
        when: p => secrets(p) >= 1,
        line: 'Há poeira de passagens antigas em suas botas, aprendiz. A Sociedade murou aqueles corredores por um motivo... mas talvez os motivos de ontem não sirvam ao hoje.',
    },
    {
        id: 'elder_three_bosses', npcId: 'elder',
        when: p => bosses(p) >= 3,
        line: 'Três guardiões da Distorção caíram diante de você. Os sonhos que a Curva me envia estão cada vez mais nítidos — o Calabouço o aguarda.',
    },

    // ── Kael, o Estudioso ────────────────────────────────────────────────────
    {
        id: 'scholar_village_mastery', npcId: 'scholar',
        when: p => masteryPercent(p.mastery?.village) >= 60,
        line: 'Seus registros de classificação chegaram até mim — mais de sessenta por cento de precisão! Finalmente alguém que distingue o nominal do ordinal.',
    },
    {
        id: 'scholar_depths', npcId: 'scholar',
        when: p => Object.keys(p.discoveredTiles || {}).some(a => a.endsWith('_depths')),
        line: 'Você desceu às profundezas?! Os arquivos dizem que a Sociedade selou os subsolos quando a Distorção chegou. O que quer que tenha visto lá embaixo... anote. Tudo.',
    },

    // ── Mercador ─────────────────────────────────────────────────────────────
    {
        id: 'merchant_rich', npcId: 'merchant',
        when: p => (p.gold || 0) >= 800,
        line: 'Ora, ora... esses bolsos tilintam bem alto. Clientes prósperos merecem meu estoque especial — e meus preços continuam "justos", claro.',
    },

    // ── Ferreiro Brom ────────────────────────────────────────────────────────
    {
        id: 'smith_first_forge', npcId: 'smith',
        when: p => Object.values(p.upgrades || {}).some(v => v >= 1),
        line: 'Reconheço o brilho da minha forja nesse equipamento! Continue trazendo essências — aço bem temperado é estatística aplicada: reduz a variância dos seus golpes.',
    },
    {
        id: 'smith_max_forge', npcId: 'smith',
        when: p => Object.values(p.upgrades || {}).some(v => v >= 3),
        line: 'Um +3 completo... Poucos guerreiros têm a disciplina de forjar até o limite. Isso aí é obra-prima, e eu raramente elogio meu próprio trabalho.',
    },

    // ── Sábia da Floresta ────────────────────────────────────────────────────
    {
        id: 'sage_forest_boss', npcId: 'sage',
        when: p => p.defeatedMonsters?.fo_boss,
        line: 'A Cristal-Mãe silenciou... Sinto a dispersão da floresta convergindo novamente. As árvores sussurram seu nome com desvio padrão cada vez menor.',
    },

    // ── Eremita ──────────────────────────────────────────────────────────────
    {
        id: 'hermit_secrets', npcId: 'hermit',
        when: p => secrets(p) >= 2,
        line: 'Você também ouve as paredes ocas, não é? Poucos escutam. Quem encontra o que foi escondido de propósito entende que todo mapa mente um pouco.',
    },

    // ── Apostador Vex ────────────────────────────────────────────────────────
    {
        id: 'gambler_rich', npcId: 'gambler',
        when: p => (p.gold || 0) >= 500,
        line: 'Hmm, ouro novo no seu passo... Sabe qual é a diferença entre você e os outros? Os outros apostam na sorte. Você poderia apostar no valor esperado.',
    },

    // ── Comerciante ──────────────────────────────────────────────────────────
    {
        id: 'trader_plains_boss', npcId: 'trader',
        when: p => p.defeatedMonsters?.pl_boss,
        line: 'A Harpia-Rainha caiu?! As rotas de caravana vão reabrir! Você acaba de reduzir o risco do meu negócio a níveis aceitáveis, amigo.',
    },

    // ── Astrônoma ────────────────────────────────────────────────────────────
    {
        id: 'astronomer_mastery', npcId: 'astronomer',
        when: p => masteryPercent(p.mastery?.mountains) >= 60,
        line: 'Suas leituras da curva normal estão entre as melhores que já registrei. Se μ é o destino e σ é a dúvida, você caminha a menos de um desvio do centro.',
    },
    {
        id: 'astronomer_mountains_boss', npcId: 'astronomer',
        when: p => p.defeatedMonsters?.mo_boss,
        line: 'O Leviatã... derrotado? Ninguém jamais acertou questões suficientes. Esta noite recalibrarei todos os meus telescópios — e minhas expectativas.',
    },

    // ── Oráculo ──────────────────────────────────────────────────────────────
    {
        id: 'oracle_bosses', npcId: 'oracle',
        when: p => bosses(p) >= 4,
        line: 'Quatro guardiões rejeitados como hipóteses falsas... Seu p-valor contra a Distorção diminui a cada vitória. O Lich Primordial já sente sua significância.',
    },
    {
        id: 'oracle_final', npcId: 'oracle',
        when: p => p.defeatedMonsters?.du_boss,
        line: 'O Lich caiu. A crise de replicabilidade chegou ao fim... Você não rejeitou apenas a hipótese nula, aprendiz — rejeitou o próprio caos. A Ordem renasce.',
    },
    {
        id: 'oracle_sanctum', npcId: 'oracle',
        when: p => !!p.sanctumCleared,
        line: 'Esse anel no seu dedo... Você desenterrou a Câmara e sobreviveu ao Julgamento. Eu fui reprovado lá, há muitos anos. Foi o erro que me ensinou o que é α — carregue-o com respeito.',
    },
];
