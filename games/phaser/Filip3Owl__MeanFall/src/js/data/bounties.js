// Daily bounty templates per area.
// 3 bounties are picked each day from the pool of areas the player has unlocked.
// IDs here are template IDs (not unique per day instance).

export const BOUNTY_POOLS = {
    village: [
        { id: 'bv1', type: 'kill_area',    objectiveArea: 'village',      count: 5, label: 'Purgar a Aldeia',      desc: 'Derrote 5 criaturas na Aldeia.',               reward: { xp: 50,  gold: 25  } },
        { id: 'bv2', type: 'kill',         monsterId: 'air_wisp',         count: 3, label: 'Caçador de Wisps',     desc: 'Derrote 3 Wisps Tipológicos.',                 reward: { xp: 60,  gold: 30  } },
        { id: 'bv3', type: 'kill',         monsterId: 'data_imp',         count: 3, label: 'Extermínio de Imps',   desc: 'Derrote 3 Imps de Dados.',                    reward: { xp: 55,  gold: 28  } },
        { id: 'bv4', type: 'kill_element', element: 'normal',             count: 6, label: 'Pureza Normal',        desc: 'Derrote 6 criaturas do elemento Normal.',      reward: { xp: 70,  gold: 35  } },
    ],
    meadows: [
        { id: 'bm1', type: 'kill_area',    objectiveArea: 'meadows',      count: 4, label: 'Guardião dos Prados',  desc: 'Derrote 4 criaturas nos Prados.',              reward: { xp: 100, gold: 50  } },
        { id: 'bm2', type: 'kill_element', element: 'earth',              count: 4, label: 'Força da Terra',       desc: 'Derrote 4 criaturas do elemento Terra.',       reward: { xp: 110, gold: 55  } },
        { id: 'bm3', type: 'kill',         monsterId: 'earth_golem',      count: 2, label: 'Abate de Golems',      desc: 'Derrote 2 Golems Medianos.',                   reward: { xp: 120, gold: 60  } },
        { id: 'bm4', type: 'kill',         monsterId: 'mode_treant',      count: 2, label: 'Derrube as Treants',   desc: 'Derrote 2 Treants da Moda.',                   reward: { xp: 115, gold: 58  } },
    ],
    forest: [
        { id: 'bf1', type: 'kill_area',    objectiveArea: 'forest',       count: 5, label: 'Limpeza da Floresta',  desc: 'Derrote 5 criaturas na Floresta.',             reward: { xp: 150, gold: 75  } },
        { id: 'bf2', type: 'kill_element', element: 'ice',                count: 4, label: 'Gelo Partido',         desc: 'Derrote 4 criaturas do elemento Gelo.',        reward: { xp: 160, gold: 80  } },
        { id: 'bf3', type: 'kill',         monsterId: 'std_wisp',         count: 3, label: 'Wisps Desviantes',     desc: 'Derrote 3 Wisps do Desvio Padrão.',            reward: { xp: 170, gold: 85  } },
        { id: 'bf4', type: 'kill',         monsterId: 'range_crystal',    count: 2, label: 'Cristais Fragmentados', desc: 'Derrote 2 Cristais do Intervalo.',             reward: { xp: 175, gold: 88  } },
    ],
    plains: [
        { id: 'bp1', type: 'kill_area',    objectiveArea: 'plains',       count: 5, label: 'Patrulha das Planícies', desc: 'Derrote 5 criaturas nas Planícies.',         reward: { xp: 220, gold: 110 } },
        { id: 'bp2', type: 'kill_element', element: 'fire',               count: 4, label: 'Extinguir o Fogo',     desc: 'Derrote 4 criaturas do elemento Fogo.',        reward: { xp: 240, gold: 120 } },
        { id: 'bp3', type: 'kill',         monsterId: 'fire_salamander',  count: 2, label: 'Caçador de Salamandras', desc: 'Derrote 2 Salamandras de Fogo.',             reward: { xp: 260, gold: 130 } },
        { id: 'bp4', type: 'kill',         monsterId: 'bayes_harpy',      count: 2, label: 'Silêncio das Harpias', desc: 'Derrote 2 Harpias de Bayes.',                  reward: { xp: 250, gold: 125 } },
    ],
    mountains: [
        { id: 'bmt1', type: 'kill_area',   objectiveArea: 'mountains',    count: 4, label: 'Escalada Perigosa',    desc: 'Derrote 4 criaturas nas Montanhas.',           reward: { xp: 350, gold: 175 } },
        { id: 'bmt2', type: 'kill_element', element: 'water',             count: 4, label: 'Controle das Águas',   desc: 'Derrote 4 criaturas do elemento Água.',        reward: { xp: 380, gold: 190 } },
        { id: 'bmt3', type: 'kill',        monsterId: 'water_serpent',    count: 3, label: 'Serpentes Afundadas',  desc: 'Derrote 3 Serpentes das Profundezas.',         reward: { xp: 370, gold: 185 } },
        { id: 'bmt4', type: 'kill',        monsterId: 'poisson_jellyfish', count: 2, label: 'Medusas de Poisson',  desc: 'Derrote 2 Medusas de Poisson.',                reward: { xp: 400, gold: 200 } },
    ],
    dungeon: [
        { id: 'bd1', type: 'kill_area',    objectiveArea: 'dungeon',      count: 3, label: 'Mergulho no Abismo',   desc: 'Derrote 3 criaturas na Masmorra.',             reward: { xp: 600, gold: 300 } },
        { id: 'bd2', type: 'kill_element', element: 'shadow',             count: 3, label: 'Sombras Dispersas',    desc: 'Derrote 3 criaturas do elemento Sombra.',      reward: { xp: 650, gold: 325 } },
        { id: 'bd3', type: 'kill',         monsterId: 'shadow_specter',   count: 2, label: 'Espectros Apagados',   desc: 'Derrote 2 Espectros das Sombras.',             reward: { xp: 620, gold: 310 } },
        { id: 'bd4', type: 'kill',         monsterId: 'alpha_vampire',    count: 1, label: 'O Vampiro Alfa',       desc: 'Derrote o Vampiro Alfa do Erro Tipo I.',       reward: { xp: 700, gold: 350 } },
    ],
    codex: [
        { id: 'bcx1', type: 'kill_area',    objectiveArea: 'codex',        count: 3, label: 'Sessão de Depuração',  desc: 'Derrote 3 criaturas na Cripta do Interpretador.', reward: { xp: 1400, gold: 700 } },
        { id: 'bcx2', type: 'kill',         monsterId: 'pandas_serpent',   count: 2, label: 'Índice Reiniciado',    desc: 'Derrote 2 Serpentes de Pandas.',                 reward: { xp: 1500, gold: 750 } },
        { id: 'bcx3', type: 'kill',         monsterId: 'numpy_golem',      count: 2, label: 'Eixo Correto',         desc: 'Derrote 2 Golems de NumPy.',                     reward: { xp: 1500, gold: 750 } },
        { id: 'bcx4', type: 'kill',         monsterId: 'hashmap_hydra',    count: 2, label: 'Colisão de Chaves',    desc: 'Derrote 2 Hidras de Hashmap.',                   reward: { xp: 1550, gold: 780 } },
    ],
};

export const DAILY_BOUNTY_COUNT = 3;
