// Ciclo dia/noite acelerado, derivado do relógio real — sem estado salvo,
// consistente entre sessões e áreas. Ciclo de 12 minutos:
// ~7min de dia, ~1,5min de anoitecer, ~3min de noite, ~30s de amanhecer.
const CYCLE_MS    = 12 * 60 * 1000;
const DAY_END     = 0.58;
const NIGHT_START = 0.70;
const NIGHT_END   = 0.96;

// Cor da luz ambiente ao longo do ciclo — aplicada com blend MULTIPLY sobre
// a cena (branco = luz neutra, sem efeito; azul escuro = noite)
const LIGHT_STOPS = [
    [0.00, 0xffe2c2], // amanhecer dourado
    [0.10, 0xffffff], // manhã — luz neutra
    [0.45, 0xfff4e2], // tarde levemente quente
    [0.58, 0xffc890], // fim de tarde âmbar
    [0.64, 0xbb7d80], // crepúsculo
    [0.70, 0x5566aa], // noite azul
    [0.94, 0x5566aa],
    [0.98, 0x9c7fa8], // madrugada arroxeada
    [1.00, 0xffe2c2],
];

function lerpColor(a, b, t) {
    const r = Math.round((a >> 16 & 255) + ((b >> 16 & 255) - (a >> 16 & 255)) * t);
    const g = Math.round((a >> 8  & 255) + ((b >> 8  & 255) - (a >> 8  & 255)) * t);
    const bl = Math.round((a & 255) + ((b & 255) - (a & 255)) * t);
    return (r << 16) | (g << 8) | bl;
}

export const DayNight = {
    phase() {
        return (Date.now() % CYCLE_MS) / CYCLE_MS;
    },

    isNight() {
        const p = this.phase();
        return p >= NIGHT_START && p < NIGHT_END;
    },

    // 0 (dia claro) → 1 (noite fechada), com transições suaves
    darkness() {
        const p = this.phase();
        if (p < DAY_END) return 0;
        if (p < NIGHT_START) return (p - DAY_END) / (NIGHT_START - DAY_END);
        if (p < NIGHT_END) return 1;
        return 1 - (p - NIGHT_END) / (1 - NIGHT_END);
    },

    lightColor() {
        const p = this.phase();
        for (let i = 1; i < LIGHT_STOPS.length; i++) {
            const [t1, c1] = LIGHT_STOPS[i];
            if (p <= t1) {
                const [t0, c0] = LIGHT_STOPS[i - 1];
                return lerpColor(c0, c1, (p - t0) / (t1 - t0));
            }
        }
        return LIGHT_STOPS[0][1];
    },

    // Sombra das entidades acompanha o "sol": comprida e deslocada de
    // manhã/tarde, curta ao meio-dia, quase apagada à noite
    shadowParams() {
        const d    = this.darkness();
        const sun  = 1 - d;
        const dayT = Math.min(this.phase() / DAY_END, 1); // 0 manhã → 1 fim de tarde
        return {
            ox:    (dayT - 0.5) * 12 * sun,
            sx:    1 + Math.abs(dayT - 0.5) * 0.7 * sun,
            alpha: 1 - 0.65 * d,
        };
    },
};
