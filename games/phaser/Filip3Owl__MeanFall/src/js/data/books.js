// MeanFall — Codex of Books
// Books are special items dropped by creatures. When read, they teach a
// statistics concept and grant a small permanent stat reward (one-time).
// Importance tiers: 'normal', 'important', 'very_important', 'essential', 'forbidden'.

export const BOOK_IMPORTANCE = {
    normal:         { id: 'normal',         name: 'Comum',           color: 0xaaaaaa, hex: '#aaaaaa', xp: 30,   bonus: null },
    important:      { id: 'important',      name: 'Importante',      color: 0x44cc88, hex: '#44cc88', xp: 60,   bonus: { intelligence: 1 } },
    very_important: { id: 'very_important', name: 'Muito Importante', color: 0x4488ff, hex: '#4488ff', xp: 120,  bonus: { intelligence: 2 } },
    essential:      { id: 'essential',      name: 'Essencial',       color: 0xbb44ff, hex: '#bb44ff', xp: 240,  bonus: { intelligence: 3, maxFocus: 5 } },
    forbidden:      { id: 'forbidden',      name: 'Proibido',        color: 0xffaa22, hex: '#ffaa22', xp: 500,  bonus: { intelligence: 5, maxFocus: 10 } },
};

// Each book teaches a single concept. Pages render as plain prose for the
// reader UI. Reading rewards XP + a small stat bump (one-time per book).
export const BOOKS = {
    // ── ELEMENT: NORMAL — DATA TYPES ──────────────────────────────────────────
    book_data_kinds: {
        id: 'book_data_kinds',
        title: 'Tratado dos Tipos de Dados',
        author: 'Anciã da Vila',
        importance: 'normal',
        topic: 'data_types',
        element: 'normal',
        pages: [
            'Os DADOS são a matéria-prima da estatística. Em MeanFall, cada criatura derrotada revela uma faceta de sua natureza.',
            'Dados QUALITATIVOS (categóricos) descrevem qualidades: cor de uma poção, classe de um monstro, raridade de um item.',
            'Dados QUANTITATIVOS descrevem quantidades. Dividem-se em DISCRETOS (contáveis: nº de inimigos derrotados) e CONTÍNUOS (mensuráveis: peso de um cajado em kg).',
            'Dados ORDINAIS são qualitativos com ordem (ruim < bom < ótimo). Comuns em escalas de avaliação.',
        ],
    },
    book_classification: {
        id: 'book_classification',
        title: 'A Arte de Classificar',
        author: 'Estudioso da Vila',
        importance: 'important',
        topic: 'data_types',
        element: 'normal',
        pages: [
            'Classificar bem é meio caminho andado. Um aventureiro que não distingue dados nominais de ordinais comete erros graves em batalha.',
            'Lembre-se: você pode calcular MÉDIA apenas com dados numéricos. Não faz sentido tirar a média de "vermelho, azul, verde".',
            'Para dados ordinais, prefira a MEDIANA — ela respeita a ordem sem pressupor distâncias iguais entre as categorias.',
        ],
    },

    // ── ELEMENT: EARTH — CENTRAL TENDENCY ─────────────────────────────────────
    book_central_tendency: {
        id: 'book_central_tendency',
        title: 'Os Três Pilares do Centro',
        author: 'Sábio dos Prados',
        importance: 'important',
        topic: 'mean_median_mode',
        element: 'earth',
        pages: [
            'Toda distribuição tem um centro. Três pilares o medem: MÉDIA, MEDIANA e MODA.',
            'A MÉDIA é a soma dividida pela quantidade. Sensível a valores extremos.',
            'A MEDIANA é o valor que divide os dados ao meio quando ordenados. Robusta a outliers.',
            'A MODA é o valor mais frequente. Pode haver várias modas (bimodal, multimodal) ou nenhuma.',
            'Quando MÉDIA > MEDIANA, há cauda longa à direita (assimetria positiva). O contrário indica cauda esquerda.',
        ],
    },
    book_outliers: {
        id: 'book_outliers',
        title: 'Demônios Estatísticos: Outliers',
        author: 'Dríade Anciã',
        importance: 'very_important',
        topic: 'mean_median_mode',
        element: 'earth',
        pages: [
            'Há criaturas chamadas OUTLIERS — valores que destoam violentamente do restante.',
            'Um único outlier pode arrastar a média para longe da realidade. Este é seu poder e seu perigo.',
            'Em distribuições com outliers, mestres da estatística preferem a mediana, mais resistente.',
            'Para detectá-los, use o critério IQR: pontos abaixo de Q1 − 1.5·IQR ou acima de Q3 + 1.5·IQR são suspeitos.',
        ],
    },

    // ── ELEMENT: ICE — SPREAD ─────────────────────────────────────────────────
    book_dispersion: {
        id: 'book_dispersion',
        title: 'O Cristal da Dispersão',
        author: 'Eremita da Floresta',
        importance: 'important',
        topic: 'spread',
        element: 'ice',
        pages: [
            'O centro não conta a história toda. A DISPERSÃO revela a forma da batalha.',
            'AMPLITUDE = max − min. Simples, mas frágil: depende apenas de extremos.',
            'VARIÂNCIA = média dos quadrados dos desvios da média. Mede espalhamento ao quadrado.',
            'DESVIO PADRÃO = √variância. Mesma unidade dos dados, mais interpretável.',
            'Variância populacional divide por N; variância amostral divide por N−1 (correção de Bessel).',
        ],
    },
    book_quartiles: {
        id: 'book_quartiles',
        title: 'Quartis e o Intervalo Interquartil',
        author: 'Prisma do Desvio',
        importance: 'very_important',
        topic: 'spread',
        element: 'ice',
        pages: [
            'Quartis dividem os dados ordenados em quatro partes iguais. Q1 é o 25º percentil, Q2 a mediana, Q3 o 75º percentil.',
            'O INTERVALO INTERQUARTIL (IQR) = Q3 − Q1 mede a dispersão dos 50% centrais. Imune a outliers extremos.',
            'BOX PLOTS visualizam quartis e outliers. Aprenda a lê-los e você verá o esqueleto de qualquer batalha.',
        ],
    },

    // ── ELEMENT: FIRE — PROBABILITY ───────────────────────────────────────────
    book_probability_basics: {
        id: 'book_probability_basics',
        title: 'Fundamentos do Acaso',
        author: 'Apostador das Planícies',
        importance: 'important',
        topic: 'probability',
        element: 'fire',
        pages: [
            'Probabilidade mede a chance de um evento. Vai de 0 (impossível) a 1 (certo).',
            'P(A) = casos favoráveis / casos possíveis (em eventos equiprováveis).',
            'O complementar de A: P(¬A) = 1 − P(A).',
            'Eventos MUTUAMENTE EXCLUSIVOS não podem ocorrer juntos. Se forem: P(A∪B) = P(A) + P(B).',
            'Caso geral: P(A∪B) = P(A) + P(B) − P(A∩B).',
        ],
    },
    book_conditional: {
        id: 'book_conditional',
        title: 'Probabilidade Condicional',
        author: 'Salamandra Anciã',
        importance: 'very_important',
        topic: 'probability',
        element: 'fire',
        pages: [
            'P(A|B) = "probabilidade de A dado que B ocorreu".',
            'Fórmula: P(A|B) = P(A∩B) / P(B), desde que P(B) > 0.',
            'Eventos INDEPENDENTES: P(A|B) = P(A). Saber B não muda a chance de A.',
            'Para independentes: P(A∩B) = P(A) × P(B).',
            'O Teorema de Bayes inverte a condição: P(A|B) = P(B|A) × P(A) / P(B). Pedra angular da inferência.',
        ],
    },

    // ── ELEMENT: WATER — DISTRIBUTIONS ────────────────────────────────────────
    book_normal: {
        id: 'book_normal',
        title: 'A Curva Sagrada',
        author: 'Astrônomo das Montanhas',
        importance: 'very_important',
        topic: 'distributions',
        element: 'water',
        pages: [
            'A DISTRIBUIÇÃO NORMAL é a curva em forma de sino, simétrica em torno da média μ.',
            'Definida por dois parâmetros: μ (centro) e σ (desvio padrão).',
            'REGRA EMPÍRICA 68-95-99,7: aproximadamente 68% dos dados caem em [μ−σ, μ+σ], 95% em [μ−2σ, μ+2σ], 99,7% em [μ−3σ, μ+3σ].',
            'Em qualquer normal: média = mediana = moda = μ.',
        ],
    },
    book_zscores: {
        id: 'book_zscores',
        title: 'Padronização: O Selo Z',
        author: 'Leviatã das Profundezas',
        importance: 'essential',
        topic: 'distributions',
        element: 'water',
        pages: [
            'O Z-SCORE mede quantos desvios padrões um valor está da média.',
            'z = (X − μ) / σ.',
            'z = 0 significa "exatamente na média". z = +2 significa "dois desvios acima".',
            'Padronizar permite comparar valores de distribuições diferentes (notas de provas distintas, alturas em populações diferentes).',
            'Para qualquer distribuição normal padronizada, é possível consultar a tabela Z para encontrar probabilidades.',
        ],
    },

    // ── ELEMENT: SHADOW — INFERENCE ───────────────────────────────────────────
    book_hypothesis: {
        id: 'book_hypothesis',
        title: 'O Tribunal das Hipóteses',
        author: 'Oráculo do Calabouço',
        importance: 'very_important',
        topic: 'inference',
        element: 'shadow',
        pages: [
            'Em estatística inferencial, julgamos hipóteses. H₀ (nula) é "inocente até prova em contrário".',
            'H₁ (alternativa) afirma que algo mudou: há diferença, há efeito.',
            'O p-valor mede a chance de observar dados tão extremos quanto os seus, SUPONDO H₀ verdadeira.',
            'Se p-valor < α (geralmente 0,05), rejeita H₀: há evidência suficiente para H₁.',
            'Não rejeitar H₀ NÃO prova H₀. Apenas não há evidência suficiente contra ela.',
        ],
    },
    book_errors: {
        id: 'book_errors',
        title: 'Os Dois Erros Fatais',
        author: 'Lich do P-valor',
        importance: 'essential',
        topic: 'inference',
        element: 'shadow',
        pages: [
            'Erro TIPO I: rejeitar H₀ quando ela é verdadeira (falso positivo). Probabilidade = α.',
            'Erro TIPO II: não rejeitar H₀ quando ela é falsa (falso negativo). Probabilidade = β.',
            'O PODER do teste é 1 − β: a chance de detectar um efeito real.',
            'Aumentar o tamanho amostral n é a forma mais comum de aumentar o poder.',
            'Diminuir α reduz erro Tipo I mas aumenta erro Tipo II — há sempre um trade-off.',
        ],
    },
    book_grimoire: {
        id: 'book_grimoire',
        title: 'Grimório do Arquimago Estatístico',
        author: 'Anônimo',
        importance: 'forbidden',
        topic: 'inference',
        element: 'shadow',
        pages: [
            'Este tomo proibido reúne segredos finais da inferência estatística.',
            'INTERVALO DE CONFIANÇA: faixa que, na repetição do procedimento, conteria o parâmetro real ~95% das vezes.',
            'TEOREMA CENTRAL DO LIMITE: a distribuição amostral da média tende à normal conforme n cresce, qualquer que seja a distribuição original.',
            'CORRELAÇÃO ≠ CAUSALIDADE. Duas variáveis podem dançar juntas sem que uma cause a outra.',
            'BOOTSTRAP: reamostre seus próprios dados para estimar incertezas sem assumir distribuições.',
            'Que estes saberes guiem suas batalhas estatísticas, aventureiro.',
        ],
    },
};

// Map: monsterId → array of { bookId, chance }. Books drop separately from
// the existing equipment/consumable loot.
export const BOOK_DROPS = {
    air_wisp:        [{ bookId: 'book_data_kinds',     chance: 0.30 }],
    air_sylph:       [{ bookId: 'book_data_kinds',     chance: 0.20 }, { bookId: 'book_classification', chance: 0.20 }],

    earth_golem:     [{ bookId: 'book_central_tendency', chance: 0.25 }],
    earth_dryad:     [{ bookId: 'book_central_tendency', chance: 0.20 }, { bookId: 'book_outliers', chance: 0.15 }],

    light_spark:     [{ bookId: 'book_dispersion',       chance: 0.30 }],
    light_prism:     [{ bookId: 'book_dispersion',       chance: 0.20 }, { bookId: 'book_quartiles',  chance: 0.18 }],

    fire_phoenix:    [{ bookId: 'book_probability_basics', chance: 0.30 }],
    fire_salamander: [{ bookId: 'book_probability_basics', chance: 0.20 }, { bookId: 'book_conditional', chance: 0.18 }],

    water_serpent:   [{ bookId: 'book_normal',  chance: 0.30 }],
    water_leviathan: [{ bookId: 'book_normal',  chance: 0.20 }, { bookId: 'book_zscores',    chance: 0.15 }],

    shadow_specter:  [{ bookId: 'book_hypothesis', chance: 0.25 }],
    shadow_lich:     [{ bookId: 'book_hypothesis', chance: 0.15 }, { bookId: 'book_errors', chance: 0.20 }, { bookId: 'book_grimoire', chance: 0.05 }],
};
