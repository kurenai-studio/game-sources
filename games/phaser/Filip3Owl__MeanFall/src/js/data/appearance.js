// MeanFall — Player appearance options
// Three customization axes: body (gender), hair color, robe color.
// Sprites are regenerated at runtime when the player changes their look.

export const HAIR_COLORS = [
    { id: 'black',  name: 'Preto',     hex: 0x1a1a1a },
    { id: 'brown',  name: 'Castanho',  hex: 0x6b3a1a },
    { id: 'blond',  name: 'Loiro',     hex: 0xddbb44 },
    { id: 'red',    name: 'Ruivo',     hex: 0xc04020 },
    { id: 'white',  name: 'Branco',    hex: 0xeeeeee },
    { id: 'silver', name: 'Prateado',  hex: 0xaaccdd },
    { id: 'green',  name: 'Verde',     hex: 0x44aa66 },
    { id: 'purple', name: 'Roxo',      hex: 0x8855cc },
];

export const ROBE_COLORS = [
    { id: 'blue',    name: 'Azul Real',     hex: 0x223388 },
    { id: 'green',   name: 'Verde Floresta', hex: 0x2a6644 },
    { id: 'red',     name: 'Vermelho Sangue', hex: 0x882222 },
    { id: 'purple',  name: 'Roxo Mago',     hex: 0x553388 },
    { id: 'gold',    name: 'Dourado',       hex: 0xaa7711 },
    { id: 'black',   name: 'Negro',         hex: 0x222233 },
    { id: 'white',   name: 'Branco',        hex: 0xddddee },
    { id: 'cyan',    name: 'Ciano',         hex: 0x22aacc },
];

export const SKIN_TONES = [
    { id: 'pale',   name: 'Pálido',  hex: 0xf5d8a8 },
    { id: 'light',  name: 'Claro',   hex: 0xe8b886 },
    { id: 'medium', name: 'Médio',   hex: 0xc89060 },
    { id: 'tan',    name: 'Bronzeado', hex: 0x9c6840 },
    { id: 'dark',   name: 'Escuro',  hex: 0x6b4222 },
];

export const GENDERS = [
    { id: 'male',   name: 'Masculino' },
    { id: 'female', name: 'Feminino' },
];

export const APPEARANCE_DEFAULTS = {
    gender:   'male',
    skin:     'light',
    hair:     'brown',
    robe:     'blue',
};
