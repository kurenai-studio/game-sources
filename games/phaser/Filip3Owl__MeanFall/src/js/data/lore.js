// MeanFall — Lore & Story
// The narrative spine of the game. Statistics is the lost art that once
// kept the world balanced; now the Distorção (the Distortion) corrupts
// reality by breaking distributions. The hero must restore the curves.

export const STORY = {
    title: 'A Queda da Média',
    subtitle: 'Uma jornada estatística contra o caos',
    prologueLines: [
        'Há eras, o mundo seguia a {{accent:Curva}} — toda criatura, toda chuva, toda guerra obedecia a leis precisas.',
        'A {{accent:Sociedade dos Estatísticos}} mantinha o equilíbrio: mediam, projetavam, previam.',
        'Então veio a {{bad:Distorção}}. Eventos impossíveis começaram a se repetir. {{rare:P-valores}} enlouqueceram.',
        'Os {{bad:monstros}}, antes raros, agora seguem distribuições corrompidas. Os {{rare:outliers}} tomaram o trono.',
        'Você é o {{good:último aprendiz}} da Ordem. Sua missão: derrotar a {{bad:Distorção}} usando a única arma que sobrou — o {{accent:conhecimento estatístico}}.',
        'Cada criatura derrotada é uma {{good:equação resolvida}}. Cada livro lido, um {{good:teorema recuperado}}.',
        'O destino do mundo está na sua {{accent:amostra}}...',
    ],

    chapters: [
        {
            id: 'ch_village',
            area: 'village',
            title: 'I — O Despertar na Vila',
            text: 'A Vila dos Dados foi a primeira a cair. Wisps Tipológicos vagam confusos, sem saber se são qualitativos ou quantitativos. Restaure a ordem aprendendo a CLASSIFICAR.',
        },
        {
            id: 'ch_meadows',
            area: 'meadows',
            title: 'II — Os Prados sem Centro',
            text: 'As Medidas Centrais foram esquecidas. Sem média, mediana ou moda, as criaturas não sabem onde está o centro de si mesmas. Reencontre o equilíbrio.',
        },
        {
            id: 'ch_forest',
            area: 'forest',
            title: 'III — A Floresta Dispersa',
            text: 'Tudo aqui se espalha sem controle. A Variância tornou-se um prisma vivo que fragmenta qualquer ordem. Domine a DISPERSÃO antes que ela te domine.',
        },
        {
            id: 'ch_plains',
            area: 'plains',
            title: 'IV — As Planícies do Acaso',
            text: 'A Probabilidade enlouqueceu. Eventos impossíveis acontecem; eventos certos falham. Restaure as leis do acaso.',
        },
        {
            id: 'ch_mountains',
            area: 'mountains',
            title: 'V — As Montanhas Tortas',
            text: 'A curva normal se quebrou em assimetrias monstruosas. As Montanhas guardam o segredo da padronização — encontre o Z perdido.',
        },
        {
            id: 'ch_dungeon',
            area: 'dungeon',
            title: 'VI — O Calabouço da Distorção',
            text: 'Aqui dorme o Lich do P-valor, fonte da Distorção. Apenas quem dominou a Inferência pode julgar suas hipóteses. Vença, e o mundo voltará à curva.',
        },
    ],

    epilogue: [
        'A Distorção foi rejeitada. p < α.',
        'A curva volta a se desenhar nos céus.',
        'Você se tornou o novo Mestre Estatístico.',
    ],
};

export const ANCIENT_SCROLLS = {
    'scroll_1': {
        title: 'Fragmento do Parâmetro',
        text: 'No início, não havia dados, apenas o {{accent:Parâmetro}}. Dele fluíram as primeiras leis. Se você vê caos, é apenas uma amostra enviesada do sagrado.'
    },
    'scroll_2': {
        title: 'A Profecia do valor-p',
        text: 'Quando o {{bad:P-valor}} cair abaixo do limiar do destino, a verdade oculta será revelada. Rejeite a nula, pois ela é o véu que cobre o místico.'
    },
    'scroll_3': {
        title: 'O Canto da Gaussiana',
        text: 'A perfeição habita no centro, mas a vida respira nas caudas. Quem teme os {{rare:Outliers}} nunca conhecerá a amplitude total da alma.'
    },
    'scroll_4': {
        title: 'Tratado da Incerteza',
        text: 'O sábio não busca a certeza, mas o controle do {{bad:Erro}}. A confiança é uma ponte de 95%; os outros 5% pertencem aos deuses.'
    },
    'scroll_5': {
        title: 'A Maldição da Dimensionalidade',
        text: 'Muitos caminhos levam à perdição. Quanto mais perguntas você faz ao universo, mais fácil é encontrar respostas que não significam nada.'
    },

    // ── Pergaminhos das Profundezas — crípticos, apontam para os segredos ──
    'scroll_depths_village': {
        title: 'Diário do Coveiro',
        text: 'Cavei este porão antes da Distorção. Escondi minha poupança atrás de uma parede no sul — marquei-a com uma {{accent:rachadura fina}} que só quem observa de perto enxerga. Se você toca a pedra e ela {{hint:respira}}, empurre.'
    },
    'scroll_depths_meadows': {
        title: 'Nota Molhada',
        text: 'A água aqui embaixo não vem da chuva. Vem de um veio que a Sociedade selou. Perto do teto do norte, uma parede foi erguida às pressas — {{accent:a argamassa dela chora}}. O que choram, escondem.'
    },
    'scroll_depths_forest': {
        title: 'Última Fogueira',
        text: 'Acampamos aqui na noite em que a Curva quebrou. T. desapareceu atrás de uma parede no coração da toca e nunca voltou. Juro que ouvi o {{bad:eco dos passos dele}} continuar... do outro lado da pedra rachada.'
    },
    'scroll_depths_plains': {
        title: 'Aposta Perdida',
        text: 'Vex me disse: aposto 100 moedas que você não acha o cofre da fornalha. P de encontrar? {{hint:1/36}}, ele riu. Mentira. É {{accent:1 para quem lê as paredes}} — a do norte tem uma cicatriz que não pertence a ela.'
    },
    'scroll_depths_mountains': {
        title: 'Registro de Mergulho nº 7',
        text: 'O abismo engole a luz e devolve segredos. Entre os lagos, uma parede soa {{accent:oca}} quando o gelo estala. A Sociedade selou ali o que não podia flutuar. Rejeite a hipótese de que toda parede é parede.'
    },
    'scroll_depths_dungeon': {
        title: 'Confissão Rasgada',
        text: 'Eu, Grão-Mestre, escondi nesta cripta a prova do meu erro. Atrás da {{bad:pedra que sangra rachaduras}}, ao sul, deixei o que restou. Se o Lich cair um dia, que encontrem — e que o p-valor me perdoe.'
    },

    // ── A Câmara da Hipótese Nula ────────────────────────────────────────────
    'scroll_null_chamber': {
        title: 'Ata do Último Concílio',
        text: 'Por decreto unânime, a {{accent:Câmara da Hipótese Nula}} foi selada e sua entrada {{hint:enterrada no canto sudeste}} deste salão. Que nenhum aprendiz desça sem uma {{accent:pá}} — e que nenhum desça despreparado. Lá embaixo, quatro guardiões julgam. Não há poções que valham diante deles, e o veredito é definitivo.'
    },
    // ── A Cripta do Interpretador ────────────────────────────────────────────
    'scroll_codex_entrance': {
        title: 'Bilhete Preso na Grade',
        text: 'Descobri o que há atrás da grade sul do Calabouço: uma {{accent:cripta que não pergunta}}. As criaturas de lá não querem que você escolha entre quatro alternativas — querem que você {{hint:escreva o feitiço e o execute na frente delas}}. Errar a sintaxe dói igual a errar a conta. Traga paciência.'
    },
    'scroll_codex_interpreter': {
        title: 'Fragmento de um Manual',
        text: 'O Intérprete não julga intenção, só resultado: ele {{bad:roda o que você escreveu}}, não o que você quis escrever. Um teste que passa por acidente ainda é um teste que passa — por isso metade dos crivos permanece {{accent:oculta}} até o envio. Rode os exemplos à vontade; o veredito vem depois.'
    },
    'scroll_sanctum_altar': {
        title: 'Inscrição na Pedra',
        text: 'Aqui a Sociedade julgava seus mestres. {{bad:Quatro guardiões, um após o outro, sem descanso e sem itens}} — apenas o que você sabe. A mochila será selada; a fuga encerra o Julgamento. Aos aprovados, o {{legend:Anel da Significância}}: a tolerância de quem entende que todo julgamento honesto perdoa um erro. {{hint:Venha descansado. Venha inteiro.}}'
    },
};

export const TUTORIAL_TIPS = [
    { id: 't_move',     trigger: 'start',          text: 'Use WASD ou setas para se mover. Aproxime-se de NPCs e pressione ESPAÇO para conversar.' },
    { id: 't_combat',   trigger: 'first_monster',  text: 'Para atacar uma criatura, encoste nela. Você responderá perguntas de estatística — acerte para causar dano!' },
    { id: 't_books',    trigger: 'first_book',     text: 'Você encontrou um LIVRO! Pressione B para abrir a Biblioteca e estudá-lo. Livros lidos concedem XP e bônus permanentes.' },
    { id: 't_portal',   trigger: 'near_portal',    text: 'Portais conectam regiões, mas exigem MAESTRIA mínima na área anterior e nível suficiente. Continue derrotando monstros e respondendo corretamente para subir de nível e desbloquear o próximo portal.' },
    { id: 't_quest',    trigger: 'quest_received', text: 'Você recebeu uma missão! Pressione Q para ver o diário. Missões concluídas concedem grandes recompensas.' },
    { id: 't_levelup',  trigger: 'first_levelup',  text: 'Subiu de nível! A cada 3 níveis você recebe um ponto de atributo. Pressione C para distribuir.' },
    { id: 't_shop',     trigger: 'near_merchant',  text: 'Comerciantes (avental verde, $) compram seus itens e vendem novos. Espaço perto deles abre a loja.' },
];
