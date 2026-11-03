// Elemental status effects applied to the player on wrong answers.
// Each monster element has one effect lasting 1 question turn.

export const STATUS_DEFS = {
    queimadura: { element: 'fire',   name: 'Queimadura', color: '#ff6622', bg: 0x3a0800, desc: 'Próximo erro: +70% dano' },
    congelado:  { element: 'ice',    name: 'Congelado',  color: '#88ddff', bg: 0x001a2a, desc: 'Dica bloqueada neste turno' },
    enraizado:  { element: 'earth',  name: 'Enraizado',  color: '#88cc44', bg: 0x0a1a00, desc: 'Tolerância numérica = 0' },
    encharcado: { element: 'water',  name: 'Encharcado', color: '#4499ff', bg: 0x001025, desc: 'Próximo erro: +40% dano, tolerância = 0' },
    maldito:    { element: 'shadow', name: 'Maldição',   color: '#cc66ff', bg: 0x1a0030, desc: 'Próximo erro: dano dobrado' },
};

const ELEMENT_TO_STATUS = {
    fire:   'queimadura',
    ice:    'congelado',
    earth:  'enraizado',
    water:  'encharcado',
    shadow: 'maldito',
};

export const StatusEffectSystem = {

    apply(player, monsterElement) {
        const id = ELEMENT_TO_STATUS[monsterElement];
        if (!id) return null;
        player._statusEffect = { id, turnsLeft: 1 };
        return id;
    },

    getActive(player) {
        const e = player._statusEffect;
        if (!e || e.turnsLeft <= 0) return null;
        return { ...STATUS_DEFS[e.id], id: e.id, turnsLeft: e.turnsLeft };
    },

    tick(player) {
        if (!player._statusEffect) return;
        player._statusEffect.turnsLeft--;
        if (player._statusEffect.turnsLeft <= 0) delete player._statusEffect;
    },

    // Returns modified damage and whether the effect triggered
    modifyDamage(player, baseDamage) {
        const e = this.getActive(player);
        if (!e) return { damage: baseDamage, triggered: false, label: null };
        switch (e.id) {
            case 'queimadura': return { damage: Math.ceil(baseDamage * 1.7), triggered: true, label: '🔥 QUEIMADURA! +70%' };
            case 'encharcado': return { damage: Math.ceil(baseDamage * 1.4), triggered: true, label: '💧 ENCHARCADO! +40%' };
            case 'maldito':    return { damage: baseDamage * 2,              triggered: true, label: '☠ MALDIÇÃO! ×2' };
            default:           return { damage: baseDamage, triggered: false, label: null };
        }
    },

    isHintBlocked(player) {
        return this.getActive(player)?.id === 'congelado';
    },

    isToleranceZero(player) {
        const id = this.getActive(player)?.id;
        return id === 'enraizado' || id === 'encharcado';
    },

    clear(player) {
        delete player._statusEffect;
    },
};
