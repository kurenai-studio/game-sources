import getData from '../data.js';
import meta from '../meta.js';
import audio from '../audio.js';

const FONT = '"Microsoft YaHei", "PingFang SC", sans-serif';
const W = 1280, H = 720;

// 道具品阶定义（白/绿/蓝/紫/红 5 档品质框与售价倍率）
const TIERS = {
  1: { name: '普通', color: 0x94a3b8, hex: '#cbd5e1', tag: '【普通】', basePrice: 20 },
  2: { name: '精良', color: 0x22c55e, hex: '#4ade80', tag: '【精良】', basePrice: 38 },
  3: { name: '稀有', color: 0x0284c7, hex: '#38bdf8', tag: '【稀有】', basePrice: 68 },
  4: { name: '史诗', color: 0xa855f7, hex: '#c084fc', tag: '【史诗】', basePrice: 110 },
  5: { name: '传说', color: 0xef4444, hex: '#f87171', tag: '【传说】', basePrice: 175 }
};

// 进化模式专用 5 阶道具库（深度借鉴 Brotato：正向增益 + 负向惩罚取舍，覆盖 12 维战斗属性）
// 同一属性统一用百分比增减；吸血按"命中触发概率回 1 点"实现，文案与实现一致
const BROTO_ITEMS = [
  // ——— 1 阶：普通 (白/灰) 边框 0x94a3b8 ———
  { id: 't1_coffee', tier: 1, name: '香浓咖啡', pos: '移动速度 +4%', neg: '最大生命 -5', icon: 'icon-passive-boots',
    apply: p => { p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.04; p.extraMaxHp = (p.extraMaxHp || 0) - 5; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't1_bandage', tier: 1, name: '急救绷带', pos: '最大生命 +10，恢复 10 生命', neg: '全伤害 -2%', icon: 'icon-passive-heart',
    apply: p => { p.extraMaxHp = (p.extraMaxHp || 0) + 10; p.heal(10); p.extraDmgMul = (p.extraDmgMul || 1) * 0.98; } },
  { id: 't1_sharp_stone', tier: 1, name: '磨刀粗石', pos: '全伤害 +5%', neg: '移动速度 -2%', icon: 'icon-passive-bracelet',
    apply: p => { p.extraDmgMul = (p.extraDmgMul || 1) * 1.05; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.98; } },
  { id: 't1_iron_buckler', tier: 1, name: '铁皮圆盾', pos: '坚韧护甲 +1 点', neg: '移动速度 -2%', icon: 'icon-passive-armor',
    apply: p => { p.extraArmor = (p.extraArmor || 0) + 1; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.98; } },
  { id: 't1_lucky_clover', tier: 1, name: '幸运三叶草', pos: '攻击暴击率 +3%', neg: '最大生命 -5', icon: 'icon-passive-ring',
    apply: p => { p.extraCrit = (p.extraCrit || 0) + 0.03; p.extraMaxHp = (p.extraMaxHp || 0) - 5; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't1_feather', tier: 1, name: '轻灵羽毛', pos: '闪避几率 +2.5%', neg: '坚韧护甲 -1 点', icon: 'icon-passive-boots',
    apply: p => { p.dodgeRate = (p.dodgeRate || 0) + 0.025; p.extraArmor = (p.extraArmor || 0) - 1; } },
  { id: 't1_scope', tier: 1, name: '聚焦镜片', pos: '攻击范围 +8%', neg: '移动速度 -2%', icon: 'icon-passive-bracelet',
    apply: p => { p.attackArea = (p.attackArea || 1.0) + 0.08; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.98; } },
  { id: 't1_whetstone', tier: 1, name: '精磨砥石', pos: '暴击伤害 +12%', neg: '全伤害 -2%', icon: 'icon-passive-ring',
    apply: p => { p.critDmgMul = (p.critDmgMul || 1.5) + 0.12; p.extraDmgMul = (p.extraDmgMul || 1.0) * 0.98; } },
  { id: 't1_leech', tier: 1, name: '吸血微蛭', pos: '命中 1% 概率回 1 点生命', neg: '最大生命 -5', icon: 'icon-passive-heart',
    apply: p => { p.lifeSteal = (p.lifeSteal || 0) + 0.01; p.extraMaxHp = (p.extraMaxHp || 0) - 5; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't1_magnet_coin', tier: 1, name: '微型吸铁石', pos: '拾取范围 +16%', neg: null, icon: 'icon-passive-magnet',
    apply: p => { p.extraPickupMul = (p.extraPickupMul || 1) * 1.16; } },
  { id: 't1_herb', tier: 1, name: '回春苦草', pos: '生命回复 +0.25/秒', neg: '移动速度 -2%', icon: 'icon-passive-coin',
    apply: p => { p.regenBps = (p.regenBps || 0) + 0.25; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.98; } },
  { id: 't1_pocket_watch', tier: 1, name: '发条怀表', pos: '武器冷却时间 -4%', neg: '全伤害 -2%', icon: 'icon-passive-hourglass',
    apply: p => { p.extraCdMul = (p.extraCdMul || 1) * 0.96; p.extraDmgMul = (p.extraDmgMul || 1) * 0.98; } },

  // ——— 2 阶：精良 (绿) 边框 0x22c55e ———
  { id: 't2_combat_boots', tier: 2, name: '轻便作战靴', pos: '移动速度 +8%', neg: '受击护甲 -1 点', icon: 'icon-passive-boots',
    apply: p => { p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.08; p.extraArmor = (p.extraArmor || 0) - 1; } },
  { id: 't2_heavy_mace', tier: 2, name: '狂徒战锤', pos: '全伤害 +10%', neg: '武器冷却时间 +5%', icon: 'icon-passive-bracelet',
    apply: p => { p.extraDmgMul = (p.extraDmgMul || 1) * 1.10; p.extraCdMul = (p.extraCdMul || 1) * 1.05; } },
  { id: 't2_turtle_shell', tier: 2, name: '玄龟重甲', pos: '坚韧护甲 +2 点', neg: '移动速度 -4%', icon: 'icon-passive-armor',
    apply: p => { p.extraArmor = (p.extraArmor || 0) + 2; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.96; } },
  { id: 't2_ninja_tabi', tier: 2, name: '忍者轻履', pos: '闪避几率 +5%', neg: '最大生命 -10', icon: 'icon-passive-boots',
    apply: p => { p.dodgeRate = (p.dodgeRate || 0) + 0.05; p.extraMaxHp = (p.extraMaxHp || 0) - 10; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't2_hunting_knife', tier: 2, name: '处决刺刀', pos: '暴击伤害 +22%', neg: '移动速度 -3%', icon: 'icon-passive-bracelet',
    apply: p => { p.critDmgMul = (p.critDmgMul || 1.5) + 0.22; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.97; } },
  { id: 't2_expansion_lens', tier: 2, name: '扩束水晶', pos: '攻击范围 +16%', neg: '武器冷却时间 +4%', icon: 'icon-passive-ring',
    apply: p => { p.attackArea = (p.attackArea || 1.0) + 0.16; p.extraCdMul = (p.extraCdMul || 1) * 1.04; } },
  { id: 't2_vampire_fang', tier: 2, name: '恶蝠尖牙', pos: '命中 2.5% 概率回 1 点生命', neg: '坚韧护甲 -1 点', icon: 'icon-passive-heart',
    apply: p => { p.lifeSteal = (p.lifeSteal || 0) + 0.025; p.extraArmor = (p.extraArmor || 0) - 1; } },
  { id: 't2_vitality_ring', tier: 2, name: '涌泉护符', pos: '生命回复 +0.5/秒', neg: '全伤害 -4%', icon: 'icon-passive-coin',
    apply: p => { p.regenBps = (p.regenBps || 0) + 0.5; p.extraDmgMul = (p.extraDmgMul || 1) * 0.96; } },
  { id: 't2_falcon_eye', tier: 2, name: '锐利鹰眼', pos: '攻击暴击率 +6%', neg: '生命回复 -0.2/秒', icon: 'icon-passive-ring',
    apply: p => { p.extraCrit = (p.extraCrit || 0) + 0.06; p.regenBps = Math.max(0, (p.regenBps || 0) - 0.2); } },
  { id: 't2_blood_chalice', tier: 2, name: '血宴圣杯', pos: '最大生命 +22，恢复 22 生命', neg: '拾取范围 -12%', icon: 'icon-passive-heart',
    apply: p => { p.extraMaxHp = (p.extraMaxHp || 0) + 22; p.heal(22); p.extraPickupMul = (p.extraPickupMul || 1) * 0.88; } },
  { id: 't2_gravity_core', tier: 2, name: '引力核心', pos: '拾取范围 +32%', neg: '移动速度 -3%', icon: 'icon-passive-magnet',
    apply: p => { p.extraPickupMul = (p.extraPickupMul || 1) * 1.32; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.97; } },
  { id: 't2_quick_gloves', tier: 2, name: '灵巧刺客手套', pos: '武器冷却时间 -6%', neg: '受击护甲 -1 点', icon: 'icon-passive-hourglass',
    apply: p => { p.extraCdMul = (p.extraCdMul || 1) * 0.94; p.extraArmor = (p.extraArmor || 0) - 1; } },

  // ——— 3 阶：稀有 (蓝) 边框 0x0284c7 ———
  { id: 't3_adrenaline', tier: 3, name: '肾上腺素针', pos: '移动速度 +13%', neg: '最大生命 -20', icon: 'icon-passive-boots',
    apply: p => { p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.13; p.extraMaxHp = (p.extraMaxHp || 0) - 20; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't3_titan_might', tier: 3, name: '泰坦神力手甲', pos: '全伤害 +16%', neg: '武器冷却时间 +8%', icon: 'icon-passive-bracelet',
    apply: p => { p.extraDmgMul = (p.extraDmgMul || 1) * 1.16; p.extraCdMul = (p.extraCdMul || 1) * 1.08; } },
  { id: 't3_smoke_bomb', tier: 3, name: '隐匿烟幕弹', pos: '闪避几率 +9%', neg: '坚韧护甲 -2 点', icon: 'icon-passive-boots',
    apply: p => { p.dodgeRate = (p.dodgeRate || 0) + 0.09; p.extraArmor = (p.extraArmor || 0) - 2; } },
  { id: 't3_executioner', tier: 3, name: '断头台重刃', pos: '暴击伤害 +35%', neg: '武器冷却时间 +7%', icon: 'icon-passive-bracelet',
    apply: p => { p.critDmgMul = (p.critDmgMul || 1.5) + 0.35; p.extraCdMul = (p.extraCdMul || 1) * 1.07; } },
  { id: 't3_giant_lens', tier: 3, name: '超界广域核心', pos: '攻击范围 +28%', neg: '全伤害 -6%', icon: 'icon-passive-ring',
    apply: p => { p.attackArea = (p.attackArea || 1.0) + 0.28; p.extraDmgMul = (p.extraDmgMul || 1.0) * 0.94; } },
  { id: 't3_blood_fount', tier: 3, name: '血神圣餐金杯', pos: '命中 3.5% 概率回 1 点生命', neg: '最大生命 -20', icon: 'icon-passive-heart',
    apply: p => { p.lifeSteal = (p.lifeSteal || 0) + 0.035; p.extraMaxHp = (p.extraMaxHp || 0) - 20; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't3_plate_armor', tier: 3, name: '精铸龙钢板甲', pos: '坚韧护甲 +3 点', neg: '移动速度 -8%', icon: 'icon-passive-armor',
    apply: p => { p.extraArmor = (p.extraArmor || 0) + 3; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.92; } },
  { id: 't3_colossus_heart', tier: 3, name: '远古巨像之心', pos: '最大生命 +40，恢复 40 生命', neg: '移动速度 -6%', icon: 'icon-passive-heart',
    apply: p => { p.extraMaxHp = (p.extraMaxHp || 0) + 40; p.heal(40); p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.94; } },
  { id: 't3_assassin_mask', tier: 3, name: '影袭者面具', pos: '攻击暴击率 +10%', neg: '坚韧护甲 -2 点', icon: 'icon-passive-ring',
    apply: p => { p.extraCrit = (p.extraCrit || 0) + 0.10; p.extraArmor = (p.extraArmor || 0) - 2; } },
  { id: 't3_chrono_gear', tier: 3, name: '时空齿轮', pos: '武器冷却时间 -10%', neg: '全伤害 -6%', icon: 'icon-passive-hourglass',
    apply: p => { p.extraCdMul = (p.extraCdMul || 1) * 0.90; p.extraDmgMul = (p.extraDmgMul || 1) * 0.94; } },
  { id: 't3_leech_fountain', tier: 3, name: '生机泉涌', pos: '生命回复 +1.1/秒', neg: '最大生命 -15', icon: 'icon-passive-coin',
    apply: p => { p.regenBps = (p.regenBps || 0) + 1.1; p.extraMaxHp = (p.extraMaxHp || 0) - 15; if (p.hp > p.maxHp) p.hp = p.maxHp; } },

  // ——— 4 阶：史诗 (紫) 边框 0xa855f7 ———
  { id: 't4_berserker', tier: 4, name: '狂暴血契', pos: '全伤害 +24%', neg: '受击护甲 -3 点', icon: 'icon-passive-bracelet',
    apply: p => { p.extraDmgMul = (p.extraDmgMul || 1) * 1.24; p.extraArmor = (p.extraArmor || 0) - 3; } },
  { id: 't4_ghost_veil', tier: 4, name: '虚空幽灵斗篷', pos: '闪避几率 +13%，移速 +13%', neg: '最大生命 -35', icon: 'icon-passive-boots',
    apply: p => { p.dodgeRate = (p.dodgeRate || 0) + 0.13; p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.13; p.extraMaxHp = (p.extraMaxHp || 0) - 35; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't4_death_whisper', tier: 4, name: '死神低语之刃', pos: '暴击伤害 +55%，暴击率 +5%', neg: '受击护甲 -3 点', icon: 'icon-passive-bracelet',
    apply: p => { p.critDmgMul = (p.critDmgMul || 1.5) + 0.55; p.extraCrit = (p.extraCrit || 0) + 0.05; p.extraArmor = (p.extraArmor || 0) - 3; } },
  { id: 't4_super_nova', tier: 4, name: '灭世超新星核', pos: '攻击范围 +42%，伤害 +10%', neg: '移动速度 -10%', icon: 'icon-passive-ring',
    apply: p => { p.attackArea = (p.attackArea || 1.0) + 0.42; p.extraDmgMul = (p.extraDmgMul || 1.0) * 1.10; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.90; } },
  { id: 't4_vampiric_lust', tier: 4, name: '真祖血裔狂宴', pos: '命中 5% 概率回 1 点生命，全伤害 +12%', neg: '生命回复 -1.0/秒', icon: 'icon-passive-heart',
    apply: p => { p.lifeSteal = (p.lifeSteal || 0) + 0.05; p.extraDmgMul = (p.extraDmgMul || 1.0) * 1.12; p.regenBps = Math.max(0, (p.regenBps || 0) - 1.0); } },
  { id: 't4_dragon_scale', tier: 4, name: '灭世黑龙逆鳞', pos: '坚韧护甲 +4 点', neg: '移动速度 -12%', icon: 'icon-passive-armor',
    apply: p => { p.extraArmor = (p.extraArmor || 0) + 4; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.88; } },
  { id: 't4_immortal_essence', tier: 4, name: '不朽巨人精髓', pos: '最大生命 +65，生命回复 +1.5/秒', neg: '移动速度 -10%', icon: 'icon-passive-heart',
    apply: p => { p.extraMaxHp = (p.extraMaxHp || 0) + 65; p.heal(65); p.regenBps = (p.regenBps || 0) + 1.5; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.90; } },
  { id: 't4_chronos_mirror', tier: 4, name: '克罗诺斯魔镜', pos: '武器冷却时间 -15%', neg: '全伤害 -10%', icon: 'icon-passive-hourglass',
    apply: p => { p.extraCdMul = (p.extraCdMul || 1) * 0.85; p.extraDmgMul = (p.extraDmgMul || 1) * 0.90; } },

  // ——— 5 阶：传说 (红) 边框 0xef4444 ———
  { id: 't5_abyssal_crown', tier: 5, name: '深渊弑神皇冠', pos: '全伤害 +35%，暴击 +14%', neg: '最大生命 -45，护甲 -3 点', icon: 'icon-passive-bracelet',
    apply: p => { p.extraDmgMul = (p.extraDmgMul || 1) * 1.35; p.extraCrit = (p.extraCrit || 0) + 0.14; p.extraMaxHp = (p.extraMaxHp || 0) - 45; p.extraArmor = (p.extraArmor || 0) - 3; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't5_phantom_god', tier: 5, name: '幻影虚空神格', pos: '闪避几率 +18%，移速 +22%', neg: '最大生命 -50，护甲 -3 点', icon: 'icon-passive-boots',
    apply: p => { p.dodgeRate = (p.dodgeRate || 0) + 0.18; p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.22; p.extraMaxHp = (p.extraMaxHp || 0) - 50; p.extraArmor = (p.extraArmor || 0) - 3; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't5_cosmic_shatter', tier: 5, name: '寰宇湮灭重锤', pos: '攻击范围 +55%，暴伤 +70%', neg: '武器冷却时间 +15%，移动速度 -15%', icon: 'icon-passive-bracelet',
    apply: p => { p.attackArea = (p.attackArea || 1.0) + 0.55; p.critDmgMul = (p.critDmgMul || 1.5) + 0.70; p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.85; p.extraCdMul = (p.extraCdMul || 1) * 1.15; } },
  { id: 't5_aegis_bastion', tier: 5, name: '终焉神圣堡垒', pos: '坚韧护甲 +5 点，最大生命 +75', neg: '移动速度 -17%，伤害 -15%', icon: 'icon-passive-armor',
    apply: p => { p.extraArmor = (p.extraArmor || 0) + 5; p.extraMaxHp = (p.extraMaxHp || 0) + 75; p.heal(75); p.extraSpeedMul = (p.extraSpeedMul || 1) * 0.83; p.extraDmgMul = (p.extraDmgMul || 1) * 0.85; } },
  { id: 't5_hermes_wings', tier: 5, name: '赫尔墨斯飞天神翼', pos: '移动速度 +28%，拾取范围 +60%', neg: '最大生命 -40', icon: 'icon-passive-boots',
    apply: p => { p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.28; p.extraPickupMul = (p.extraPickupMul || 1) * 1.60; p.extraMaxHp = (p.extraMaxHp || 0) - 40; if (p.hp > p.maxHp) p.hp = p.maxHp; } },
  { id: 't5_infinity_hourglass', tier: 5, name: '无穷因果之沙漏', pos: '武器冷却时间 -22%', neg: '全伤害 -15%，生命回复 -0.8/秒', icon: 'icon-passive-hourglass',
    apply: p => { p.extraCdMul = (p.extraCdMul || 1) * 0.78; p.extraDmgMul = (p.extraDmgMul || 1) * 0.85; p.regenBps = Math.max(0, (p.regenBps || 0) - 0.8); } }
];

// 免费属性加点选项（数值适度，契合属性上限机制）
const FREE_STAT_EVOS = [
  { id: 'hp',        name: '坚韧之躯', desc: '最大生命 +10，并恢复 10 生命', icon: 'icon-passive-heart',     apply: p => { p.extraMaxHp = (p.extraMaxHp || 0) + 10; p.heal(10); } },
  { id: 'atk',       name: '力量突破', desc: '全武器伤害 +4%',               icon: 'icon-passive-bracelet',  apply: p => { p.extraDmgMul = (p.extraDmgMul || 1) * 1.04; } },
  { id: 'spd',       name: '疾风步伐', desc: '移动速度 +4%',                 icon: 'icon-passive-boots',     apply: p => { p.extraSpeedMul = (p.extraSpeedMul || 1) * 1.04; } },
  { id: 'armor',     name: '精钢重铠', desc: '受击伤害减免 +1 点',           icon: 'icon-passive-armor',     apply: p => { p.extraArmor = (p.extraArmor || 0) + 1; } },
  { id: 'crit',      name: '致命聚焦', desc: '攻击暴击率 +3%',               icon: 'icon-passive-ring',      apply: p => { p.extraCrit = (p.extraCrit || 0) + 0.03; } },
  { id: 'critdmg',   name: '重击精通', desc: '暴击伤害 +10%',                icon: 'icon-passive-ring',      apply: p => { p.critDmgMul = (p.critDmgMul || 1.5) + 0.10; } },
  { id: 'dodge',     name: '敏捷身法', desc: '闪避几率 +2.5%',               icon: 'icon-passive-boots',     apply: p => { p.dodgeRate = (p.dodgeRate || 0) + 0.025; } },
  { id: 'area',      name: '广域爆发', desc: '攻击范围 +6%',                 icon: 'icon-passive-bracelet',  apply: p => { p.attackArea = (p.attackArea || 1.0) + 0.06; } },
  { id: 'lifesteal', name: '嗜血本能', desc: '命中 1% 概率回 1 点生命',      icon: 'icon-passive-heart',     apply: p => { p.lifeSteal = (p.lifeSteal || 0) + 0.01; } },
  { id: 'pickup',    name: '磁力领域', desc: '拾取范围 +12%',                icon: 'icon-passive-magnet',    apply: p => { p.extraPickupMul = (p.extraPickupMul || 1) * 1.12; } },
  { id: 'regen',     name: '回春泉涌', desc: '生命自动回复 +0.25/秒',        icon: 'icon-passive-coin',      apply: p => { p.regenBps = (p.regenBps || 0) + 0.25; } },
  { id: 'cd',        name: '极速灵光', desc: '所有武器冷却时间 -3.5%',       icon: 'icon-passive-hourglass', apply: p => { p.extraCdMul = (p.extraCdMul || 1) * 0.965; } }
];

// 随着波次提升，高阶道具刷新几率动态提升
function rollItemTier(wave) {
  const r = Math.random();
  if (wave <= 3) {
    if (r < 0.78) return 1;
    if (r < 0.96) return 2;
    return 3;
  } else if (wave <= 7) {
    if (r < 0.52) return 1;
    if (r < 0.84) return 2;
    if (r < 0.96) return 3;
    return 4;
  } else if (wave <= 12) {
    if (r < 0.32) return 1;
    if (r < 0.68) return 2;
    if (r < 0.90) return 3;
    if (r < 0.98) return 4;
    return 5;
  } else if (wave <= 17) {
    if (r < 0.18) return 1;
    if (r < 0.48) return 2;
    if (r < 0.80) return 3;
    if (r < 0.95) return 4;
    return 5;
  } else {
    // 18-20 波
    if (r < 0.10) return 1;
    if (r < 0.34) return 2;
    if (r < 0.66) return 3;
    if (r < 0.88) return 4;
    return 5;
  }
}

// 进化模式波次休整商店（深度借鉴 Brotato / 土豆兄弟）
export default class WaveShopOverlay extends Phaser.Scene {
  constructor() { super('WaveShopOverlay'); }

  create(data) {
    // 商店接管全部输入：遮罩期间关掉 HUD 场景，避免 P/结束本局 穿透到战斗层
    this.scene.stop('UIScene');
    this.waveData = data || {};
    this.wave = data.wave || 1;
    this.maxWave = data.maxWave || 20;
    this.coins = data.coins || 0;
    this.lockedSlots = Array.isArray(data.lockedSlots) ? [...data.lockedSlots] : [false, false, false, false];
    this.lockedItems = Array.isArray(data.lockedItems) ? [...data.lockedItems] : [null, null, null, null];
    this.shopItems = [];
    this.statOptions = [];
    this.rerollCost = 12 + this.wave * 3;
    this.weaponsData = getData(this, 'weapons');
    this.gs = this.scene.get('GameScene');

    this._buildPools();
    this._generateShopSlots();
    this._buildStatOptions();

    // 背景全屏遮罩
    this.add.rectangle(W / 2, H / 2, W, H, 0x0a0c16, 0.98).setDepth(0);

    // 顶栏
    this._drawTopBar();
    // 左栏：当前状态与武器库
    this._drawLeftArsenalPanel();
    // 右上：属性进化加点
    this._drawStatPanel();
    // 右下：商品货架
    this._drawShopPanel();
    // 底栏：下一波按钮与波次指示
    this._drawBottomBar();
  }

  _buildPools() {
    // 过滤掉武器配置中的 passives 字段以及无名字项，彻底杜绝空白卡片 Bug
    this._weaponPool = Object.keys(this.weaponsData).filter(
      k => k !== 'passives' && this.weaponsData[k] && this.weaponsData[k].name
    );
  }

  _rollSingleShopItem(curWpIds) {
    // 35% 几率刷出武器，65% 几率刷出属性被动道具
    const rollWp = Math.random() < 0.35;
    if (rollWp && this._weaponPool.length > 0) {
      // 50% 几率优先刷出已持有的武器，帮助凑 3/6 羁绊或合成升阶
      let wpId;
      if (curWpIds.length > 0 && Math.random() < 0.5) {
        wpId = Phaser.Utils.Array.GetRandom(curWpIds);
      } else {
        wpId = Phaser.Utils.Array.GetRandom(this._weaponPool);
      }
      const def = this.weaponsData[wpId] || {};
      const price = Math.max(15, Math.round(20 + this.wave * 2.5 + Phaser.Math.Between(-3, 3)));
      return {
        kind: 'weapon',
        id: wpId,
        tier: 1,
        tierDef: TIERS[1],
        name: def.name || wpId,
        icon: def.icon || 'item-coin',
        desc: def.desc || '强力作战武器',
        price: price
      };
    } else {
      const tier = rollItemTier(this.wave);
      const tierDef = TIERS[tier];
      const itemsInTier = BROTO_ITEMS.filter(it => it.tier === tier);
      const pool = itemsInTier.length > 0 ? itemsInTier : BROTO_ITEMS;
      const itemDef = Phaser.Utils.Array.GetRandom(pool);
      const price = Math.max(12, Math.round(tierDef.basePrice + this.wave * (tier * 1.5) + Phaser.Math.Between(-2, 3)));
      return {
        kind: 'item',
        tier: tier,
        tierDef: tierDef,
        ...itemDef,
        price: price
      };
    }
  }

  _generateShopSlots() {
    const gs = this.gs;
    const curWpIds = gs ? gs.weapons.map(w => w.id) : [];
    const newShop = [];

    for (let i = 0; i < 4; i++) {
      if (this.lockedSlots[i] && (this.shopItems[i] || this.lockedItems[i])) {
        newShop.push(this.shopItems[i] || this.lockedItems[i]);
      } else {
        newShop.push(this._rollSingleShopItem(curWpIds));
      }
    }
    this.shopItems = newShop;
  }

  _buildStatOptions() {
    const pool = [...FREE_STAT_EVOS];
    const usable = (this.gs && this.gs.player) ? pool.filter(opt => this._wouldGain(opt)) : pool;
    this.statAllCapped = usable.length === 0;
    // 全是已满属性时不再发牌，避免"选了等于没选"
    this.statOptions = this.statAllCapped ? [] : Phaser.Utils.Array.Shuffle(usable).slice(0, 3);
    this.statChosen = false;
  }

  // ——— 顶栏 ———
  _drawTopBar() {
    if (this._topBar) this._topBar.destroy();
    this._topBar = this.add.container(0, 0).setDepth(5);

    const p = this.gs ? this.gs.player : null;
    const hpCur = p ? Math.ceil(p.hp) : 100;
    const hpMax = p ? p.maxHp : 100;

    const title = this.add.text(W / 2, 28, '⚡ 进 化 强 化 · 第 ' + this.wave + ' / ' + this.maxWave + ' 波', {
      fontFamily: FONT, fontSize: '26px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5);

    const hpCont = this.add.container(40, 28);
    const hpBg = this.add.rectangle(0, 0, 160, 20, 0x14151f).setOrigin(0, 0.5);
    const hpFill = this.add.rectangle(0, 0, Math.max(2, 160 * (hpCur / hpMax)), 20, 0x38b764).setOrigin(0, 0.5);
    const hpTxt = this.add.text(80, 0, '❤️ ' + hpCur + ' / ' + hpMax, {
      fontFamily: FONT, fontSize: '12px', color: '#f4f4f4', fontStyle: 'bold'
    }).setOrigin(0.5);
    hpCont.add([hpBg, hpFill, hpTxt]);

    this.coinsText = this.add.text(W - 40, 28, '💰 金币  ' + this.coins, {
      fontFamily: FONT, fontSize: '22px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(1, 0.5);

    this._topBar.add([title, hpCont, this.coinsText]);
  }

  // ——— 左栏：角色军械库、同名合成、武器羁绊与战斗属性（已修正重叠 Bug）———
  _drawLeftArsenalPanel() {
    if (this._leftArsenal) this._leftArsenal.destroy();
    this._leftArsenal = this.add.container(0, 0).setDepth(4);

    const bx = 160, panelW = 270;
    const bg = this.add.rectangle(bx, 350, panelW, 610, 0x10131e).setStrokeStyle(1.5, 0x2a3048);
    this._leftArsenal.add(bg);

    const gs = this.gs;
    const weaps = gs ? gs.weapons : [];
    const wpTitle = this.add.text(bx, 66, '⚔ 军备库 (' + weaps.length + '/6)', {
      fontFamily: FONT, fontSize: '15px', color: '#41a6f6', fontStyle: 'bold'
    }).setOrigin(0.5);
    this._leftArsenal.add(wpTitle);

    // 渲染 6 个武器槽位（2 列 x 3 行，精准布局消除重叠）
    for (let slot = 0; slot < 6; slot++) {
      const col = slot % 2, row = Math.floor(slot / 2);
      const sx = bx - 62 + col * 124;
      const sy = 96 + row * 34; // row 0: 96, row 1: 130, row 2: 164
      const w = weaps[slot];

      // 检查当前武器是否可以与另一把同 ID、同等级的武器合成
      let canSynth = false;
      if (w && w.level < 8) {
        canSynth = weaps.filter(other => other.id === w.id && other.level === w.level).length >= 2;
      }

      const slotBorder = w ? (canSynth ? 0xffcd75 : (w.evolved ? 0xd46c99 : 0x3d4b73)) : 0x202434;
      const slotBg = this.add.rectangle(sx, sy, 118, 30, w ? (canSynth ? 0x1d2238 : 0x151926) : 0x10121a)
        .setStrokeStyle(1.5, slotBorder);
      this._leftArsenal.add(slotBg);

      if (w) {
        const icon = this.add.image(sx - 40, sy, w.def.icon).setDisplaySize(22, 22);
        const nameT = this.add.text(sx - 24, sy - 6, w.def.name, {
          fontFamily: FONT, fontSize: '11px', color: '#f4f4f4', fontStyle: 'bold'
        }).setOrigin(0, 0.5);

        const lvColors = ['#f4f4f4', '#38b764', '#41a6f6', '#d46c99', '#ffcd75', '#ff7043', '#e040fb', '#00e5ff'];
        const lvCol = lvColors[Math.min(w.level - 1, lvColors.length - 1)] || '#ffcd75';
        const lvT = this.add.text(sx - 24, sy + 6, w.evolved ? '✦ 进化' : ('Lv ' + w.level), {
          fontFamily: FONT, fontSize: '10px', color: lvCol, fontStyle: 'bold'
        }).setOrigin(0, 0.5);
        this._leftArsenal.add([icon, nameT, lvT]);

        // 若可合成，显示明亮的【✦合】互动按钮
        if (canSynth) {
          const sBtnBg = this.add.rectangle(sx + 21, sy, 24, 18, 0x3a2818)
            .setStrokeStyle(1.2, 0xffcd75).setInteractive({ useHandCursor: true });
          const sBtnTxt = this.add.text(sx + 21, sy, '✦合', {
            fontFamily: FONT, fontSize: '9px', color: '#ffcd75', fontStyle: 'bold'
          }).setOrigin(0.5);
          sBtnBg.on('pointerdown', () => {
            const curLv = w.level;
            const ok = gs.synthesizeWeapons(w.id, curLv);
            if (ok) {
              this._toast('✦ 合成成功！' + w.def.name + ' 升至 Lv ' + (curLv + 1) + '！');
              this._drawLeftArsenalPanel();
              this._drawShopPanel();
            }
          });
          this._leftArsenal.add([sBtnBg, sBtnTxt]);
        }

        // 武器变卖回收（当武器 >= 2 时可变卖换取金币并腾出栏位）
        if (weaps.length > 1) {
          const sellX = canSynth ? (sx + 44) : (sx + 36);
          const sellW = canSynth ? 20 : 34;
          const sellLabel = canSynth ? '售' : '出售';
          const sellBtnBg = this.add.rectangle(sellX, sy, sellW, 18, 0x2e1418)
            .setStrokeStyle(1.2, 0xef4444).setInteractive({ useHandCursor: true });
          const sellBtnTxt = this.add.text(sellX, sy, sellLabel, {
            fontFamily: FONT, fontSize: '9px', color: '#f87171', fontStyle: 'bold'
          }).setOrigin(0.5);
          sellBtnBg.on('pointerdown', () => {
            const res = gs.sellWeapon(slot);
            if (res) {
              this.coins += res.price;
              this._toast('已变卖 ' + res.name + '，回收 +' + res.price + ' 金币！');
              this._drawTopBar();
              this._drawLeftArsenalPanel();
              this._drawShopPanel();
            }
          });
          this._leftArsenal.add([sellBtnBg, sellBtnTxt]);
        }
      } else {
        const emptyT = this.add.text(sx, sy, '[空栏位]', {
          fontFamily: FONT, fontSize: '11px', color: '#3a3d52'
        }).setOrigin(0.5);
        this._leftArsenal.add(emptyT);
      }
    }

    // 分隔线 1（y = 188，完全脱离武器槽范围）
    const line1 = this.add.rectangle(bx, 188, panelW - 30, 1, 0x252b40);
    this._leftArsenal.add(line1);

    // ⚡ 武器专属羁绊展示区（y = 204）
    const synTitle = this.add.text(bx, 204, '⚡ 武器专属羁绊 (同名3件/6件)', {
      fontFamily: FONT, fontSize: '12px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0.5);
    this._leftArsenal.add(synTitle);

    const activeSynergies = gs ? gs.getActiveSynergies() : [];
    if (activeSynergies.length > 0) {
      activeSynergies.slice(0, 2).forEach((syn, i) => {
        const sy = 230 + i * 36;
        const synBg = this.add.rectangle(bx, sy, panelW - 24, 32, 0x171f32)
          .setStrokeStyle(1.5, syn.tier === 2 ? 0xffcd75 : 0x41a6f6);
        const iconDef = this.weaponsData[syn.id];
        const synIcon = this.add.image(bx - 105, sy, iconDef ? iconDef.icon : 'item-coin').setDisplaySize(20, 20);
        const synTxt = this.add.text(bx - 86, sy, syn.desc, {
          fontFamily: FONT, fontSize: '10px', color: syn.tier === 2 ? '#ffcd75' : '#e0f2fe', wordWrap: { width: panelW - 55 }
        }).setOrigin(0, 0.5);
        this._leftArsenal.add([synBg, synIcon, synTxt]);
      });
    } else {
      const tipBg = this.add.rectangle(bx, 236, panelW - 24, 38, 0x121522).setStrokeStyle(1, 0x202434);
      const tipTxt = this.add.text(bx, 236, '💡 装备 3 把同名武器激活初级羁绊\n装备 6 把激活终极羁绊（不同武器无羁绊）', {
        fontFamily: FONT, fontSize: '10px', color: '#687890', align: 'center', lineSpacing: 3
      }).setOrigin(0.5);
      this._leftArsenal.add([tipBg, tipTxt]);
    }

    // 分隔线 2（y = 282）
    const line2 = this.add.rectangle(bx, 282, panelW - 30, 1, 0x252b40);
    this._leftArsenal.add(line2);

    // 战斗属性面板（12 维深度属性，2 列 × 6 行对齐，带属性上限指示）
    const statTitle = this.add.text(bx, 298, '📊 战斗属性 (12维属性·带上限)', {
      fontFamily: FONT, fontSize: '12px', color: '#38b764', fontStyle: 'bold'
    }).setOrigin(0.5);
    this._leftArsenal.add(statTitle);

    const p = gs ? gs.player : null;
    const dmgPct = p ? Math.round(((p.dmgBonus || 1) - 1) * 100) : 0;
    const critPct = p ? Math.round((p.critChance || 0.05) * 100) : 5;
    const critDmgVal = p ? Math.round((p.critDmgMul || 1.5) * 100) : 150;
    const dodgeVal = p ? Math.round((p.dodgeRate || 0) * 100) : 0;
    const areaPct = p ? Math.round(((p.attackArea || 1.0) - 1) * 100) : 0;
    const lifeStealVal = p ? Math.round((p.lifeSteal || 0) * 100) : 0;
    const spdVal = p ? Math.round(p.speed) : 180;
    const armVal = p ? (p.armor || 0) : 0;
    const regVal = p ? (p.regenBps || 0).toFixed(1) : '0.0';
    const pickVal = p ? Math.round(p.pickupRadius) : 120;
    const cdVal = p ? Math.round((p.cooldownMult - 1) * 100) : 0;

    const leftStats = [
      { label: '生命上限', val: (p && p.maxHp >= 320 ? '320 (MAX)' : '' + (p ? p.maxHp : 100)), col: '#ffcd75' },
      { label: '全部伤害', val: (dmgPct >= 140 ? '+140% (MAX)' : (dmgPct >= 0 ? '+' + dmgPct + '%' : dmgPct + '%')), col: '#ff7043' },
      { label: '坚韧护甲', val: (armVal >= 7 ? '+7 (MAX)' : '+' + armVal), col: '#41a6f6' },
      { label: '攻击暴击', val: (critPct >= 50 ? '50% (MAX)' : critPct + '%'), col: '#ffd166' },
      { label: '暴击伤害', val: (critDmgVal >= 230 ? '230% (MAX)' : critDmgVal + '%'), col: '#f59e0b' },
      { label: '攻击吸血', val: (lifeStealVal >= 8 ? '8% (MAX)' : lifeStealVal + '%'), col: '#ec4899' }
    ];

    const rightStats = [
      { label: '闪避几率', val: (dodgeVal >= 40 ? '40% (MAX)' : dodgeVal + '%'), col: '#38bdf8' },
      { label: '攻击范围', val: (areaPct >= 65 ? '+65% (MAX)' : (areaPct >= 0 ? '+' + areaPct + '%' : areaPct + '%')), col: '#a78bfa' },
      { label: '移动速度', val: (spdVal >= 280 ? '280 (MAX)' : '' + spdVal), col: '#06d6a0' },
      { label: '拾取磁力', val: (pickVal >= 200 ? '200 (MAX)' : '' + pickVal), col: '#a8dadc' },
      { label: '生命回复', val: '+' + regVal + '/s', col: '#48cae4' },
      { label: '武器冷却', val: (cdVal <= -40 ? '-40% (MAX)' : cdVal + '%'), col: '#b5838d' }
    ];

    for (let row = 0; row < 6; row++) {
      const sy = 320 + row * 25;

      // 左列属性
      const lx = bx - 64;
      const lBg = this.add.rectangle(lx, sy, 122, 21, row % 2 === 0 ? 0x141826 : 0x10131e);
      const lSt = leftStats[row];
      const lLbl = this.add.text(lx - 54, sy, lSt.label, { fontFamily: FONT, fontSize: '10px', color: '#94b0c2' }).setOrigin(0, 0.5);
      const lVal = this.add.text(lx + 54, sy, lSt.val, { fontFamily: FONT, fontSize: '10px', color: lSt.col, fontStyle: 'bold' }).setOrigin(1, 0.5);

      // 右列属性
      const rx = bx + 64;
      const rBg = this.add.rectangle(rx, sy, 122, 21, row % 2 === 0 ? 0x141826 : 0x10131e);
      const rSt = rightStats[row];
      const rLbl = this.add.text(rx - 54, sy, rSt.label, { fontFamily: FONT, fontSize: '10px', color: '#94b0c2' }).setOrigin(0, 0.5);
      const rVal = this.add.text(rx + 54, sy, rSt.val, { fontFamily: FONT, fontSize: '10px', color: rSt.col, fontStyle: 'bold' }).setOrigin(1, 0.5);

      this._leftArsenal.add([lBg, lLbl, lVal, rBg, rLbl, rVal]);
    }
  }

  // ——— 右上：属性进化加点（免费选一项）———
  _drawStatPanel() {
    if (this._statSection) this._statSection.destroy();
    this._statSection = this.add.container(0, 0).setDepth(4);

    const n = this.statOptions.length;
    const titleStr = this.statAllCapped
      ? '✨ 本波免费属性进化（属性已全部达到上限）'
      : `✨ 本波免费属性进化（${n} 选 1）`;
    const title = this.add.text(320, 68, titleStr, {
      fontFamily: FONT, fontSize: '15px', color: '#41a6f6', fontStyle: 'bold'
    }).setOrigin(0, 0.5);
    this._statSection.add(title);

    if (this.statAllCapped) {
      const tip = this.add.text(320, 152, '本波所有可加属性均已满，可直接点击下方「进入下一波」。', {
        fontFamily: FONT, fontSize: '13px', color: '#565a73'
      }).setOrigin(0, 0.5);
      this._statSection.add(tip);
      return;
    }

    const cardW = 296, cardH = 126;
    this.statOptions.forEach((opt, i) => {
      const cx = 320 + cardW / 2 + i * (cardW + 16);
      const cy = 144;
      const card = this._makeStatCard(cx, cy, cardW, cardH, opt, i);
      this._statSection.add(card);
    });
  }

  _makeStatCard(x, y, w, h, opt, idx) {
    const c = this.add.container(x, y);
    const canPick = !this.statChosen;
    const bg = this.add.rectangle(0, 0, w, h, canPick ? 0x171c2c : 0x10121c)
      .setStrokeStyle(2, canPick ? 0x41a6f6 : 0x222638);
    const icon = this.add.image(-w / 2 + 34, -18, opt.icon).setDisplaySize(38, 38);
    const nm = this.add.text(-w / 2 + 62, -20, opt.name, {
      fontFamily: FONT, fontSize: '14px', color: canPick ? '#f4f4f4' : '#565a73', fontStyle: 'bold'
    }).setOrigin(0, 0.5);
    const dc = this.add.text(-w / 2 + 16, 20, opt.desc, {
      fontFamily: FONT, fontSize: '11px', color: '#94b0c2', wordWrap: { width: w - 32 }
    }).setOrigin(0, 0.5);

    const btnBg = this.add.rectangle(w / 2 - 45, -20, 64, 26, canPick ? 0x1e3052 : 0x14151f)
      .setStrokeStyle(1, canPick ? 0x41a6f6 : 0x222638);
    const btnTxt = this.add.text(w / 2 - 45, -20, canPick ? '选择' : '—', {
      fontFamily: FONT, fontSize: '12px', color: canPick ? '#41a6f6' : '#3a3d52', fontStyle: 'bold'
    }).setOrigin(0.5);

    c.add([bg, icon, nm, dc, btnBg, btnTxt]);

    if (canPick) {
      bg.setInteractive({ useHandCursor: true }).on('pointerdown', () => this._pickStat(idx, opt));
      btnBg.setInteractive({ useHandCursor: true }).on('pointerdown', () => this._pickStat(idx, opt));
    }
    return c;
  }

  _pickStat(idx, opt) {
    if (this.statChosen || !this.gs || !this.gs.player) return;
    if (!this._wouldGain(opt)) {
      this._toast('该项属性已达上限，请选择其它项');
      return;
    }
    this.statChosen = true;
    try { audio.click(); } catch (e) {}
    try { opt.apply(this.gs.player, this.gs); } catch (e) {}
    this._drawTopBar();
    this._drawLeftArsenalPanel();
    this._drawStatPanel();
    this._toast('属性进化成功：' + opt.name + '！');
  }

  // ——— 右下：军备与道具货架（4 个商品栏位）———
  _drawShopPanel() {
    if (this._shopSection) this._shopSection.destroy();
    this._shopSection = this.add.container(0, 0).setDepth(4);

    const title = this.add.text(320, 236, '🛒 军备与道具货架 (白/绿/蓝/紫/红 5阶品质)', {
      fontFamily: FONT, fontSize: '15px', color: '#ffcd75', fontStyle: 'bold'
    }).setOrigin(0, 0.5);

    const rCost = this.rerollCost;
    const canReroll = this.coins >= rCost;
    const rBg = this.add.rectangle(W - 100, 236, 134, 32, canReroll ? 0x22283a : 0x141620)
      .setStrokeStyle(1.5, canReroll ? 0xffcd75 : 0x3a3d52).setInteractive({ useHandCursor: true });
    const rTxt = this.add.text(W - 100, 236, '↻ 刷新货架 (' + rCost + '金)', {
      fontFamily: FONT, fontSize: '12px', color: canReroll ? '#ffcd75' : '#565a73', fontStyle: 'bold'
    }).setOrigin(0.5);
    rBg.on('pointerdown', () => this._doReroll());

    this._shopSection.add([title, rBg, rTxt]);

    const cardW = 452, cardH = 160;
    this.shopItems.forEach((item, idx) => {
      const col = idx % 2, row = Math.floor(idx / 2);
      const cx = 320 + cardW / 2 + col * (cardW + 16);
      const cy = 340 + row * (cardH + 16);
      const card = this._makeShopCard(cx, cy, cardW, cardH, item, idx);
      this._shopSection.add(card);
    });
  }

  _makeShopCard(x, y, w, h, item, idx) {
    const c = this.add.container(x, y);
    const locked = this.lockedSlots[idx];

    if (!item) {
      const emptyBg = this.add.rectangle(0, 0, w, h, 0x0f111a).setStrokeStyle(1, 0x222533);
      const emptyTxt = this.add.text(0, 0, '[此商品已售空]', {
        fontFamily: FONT, fontSize: '13px', color: '#3a3d52'
      }).setOrigin(0.5);
      c.add([emptyBg, emptyTxt]);
      return c;
    }

    const gs = this.gs;
    const curWeaps = gs ? gs.weapons : [];
    const count = item.kind === 'weapon' ? curWeaps.filter(wp => wp.id === item.id).length : 0;
    const hasLv1 = item.kind === 'weapon' ? curWeaps.some(wp => wp.id === item.id && wp.level === 1) : false;
    const isFull = curWeaps.length >= 6;

    const canAfford = this.coins >= item.price;
    const canBuy = canAfford && (item.kind !== 'weapon' || !isFull || hasLv1);

    // 边框颜色与标签
    let borderCol = 0x94a3b8;
    let tag = '【道具】';
    let tagCol = '#94a3b8';

    if (locked) {
      borderCol = 0xd46c99;
    } else if (item.kind === 'weapon') {
      if (hasLv1) {
        borderCol = 0xffcd75;
        tag = '【持有 ' + count + ' 把 · 可合成升阶】';
        tagCol = '#ffcd75';
      } else if (count > 0) {
        borderCol = 0x00b4d8;
        tag = '【已持有 ' + count + ' 把 · 凑羁绊】';
        tagCol = '#00b4d8';
      } else {
        borderCol = 0x3b82f6;
        tag = '【新武器】';
        tagCol = '#60a5fa';
      }
    } else if (item.kind === 'item') {
      const tdef = item.tierDef || TIERS[item.tier] || TIERS[1];
      borderCol = tdef.color;
      tag = tdef.tag;
      tagCol = tdef.hex;
    }

    const bg = this.add.rectangle(0, 0, w, h, 0x161928).setStrokeStyle(2, borderCol);
    const icon = this.add.image(-w / 2 + 42, -26, item.icon).setDisplaySize(44, 44);

    const nm = this.add.text(-w / 2 + 76, -38, item.name, {
      fontFamily: FONT, fontSize: '15px', color: '#f4f4f4', fontStyle: 'bold'
    }).setOrigin(0, 0.5);

    const tagTxt = this.add.text(-w / 2 + 76, -18, tag, {
      fontFamily: FONT, fontSize: '11px', color: tagCol, fontStyle: 'bold'
    }).setOrigin(0, 0.5);

    c.add([bg, icon, nm, tagTxt]);

    // 属性与描述呈现
    if (item.kind === 'weapon') {
      let descText = item.desc;
      if (hasLv1) {
        descText = '已有 Lv 1 同类武器！购买后自动合成升级为 Lv 2，强化属性并节省栏位。';
      } else if (count > 0) {
        descText = '已拥有 ' + count + ' 把此武器（持有 3 把或 6 把激活专属羁绊效果）。';
      }
      const dc = this.add.text(-w / 2 + 20, 16, descText, {
        fontFamily: FONT, fontSize: '12px', color: '#94b0c2', wordWrap: { width: w - 40 }
      }).setOrigin(0, 0.5);
      c.add(dc);
    } else {
      // 道具呈现正向加成（绿色）与负向代价（红色）
      const posTxt = this.add.text(-w / 2 + 20, 10, '▲ ' + item.pos, {
        fontFamily: FONT, fontSize: '12px', color: '#4ade80', fontStyle: 'bold'
      }).setOrigin(0, 0.5);
      c.add(posTxt);

      if (item.neg) {
        const negTxt = this.add.text(-w / 2 + 20, 28, '▼ ' + item.neg, {
          fontFamily: FONT, fontSize: '11px', color: '#f87171'
        }).setOrigin(0, 0.5);
        c.add(negTxt);
      }
    }

    // 价格框
    const priceBg = this.add.rectangle(-60, 54, 104, 26, canAfford ? 0x1e2840 : 0x12141c)
      .setStrokeStyle(1, canAfford ? 0xffcd75 : 0x3a3d52);
    const priceTxt = this.add.text(-60, 54, item.price + ' 金币', {
      fontFamily: FONT, fontSize: '12px', color: canAfford ? '#ffcd75' : '#565a73', fontStyle: 'bold'
    }).setOrigin(0.5);

    // 购买按钮
    let buyLabel = '购买';
    if (item.kind === 'weapon' && isFull) {
      buyLabel = hasLv1 ? '✦ 合成购买' : '栏位已满';
    }

    const buyBg = this.add.rectangle(70, 54, 104, 26, canBuy ? 0x1d3a5a : 0x12141c)
      .setStrokeStyle(1.5, canBuy ? (hasLv1 ? 0xffcd75 : 0x41a6f6) : 0x3a3d52);
    const buyTxt = this.add.text(70, 54, buyLabel, {
      fontFamily: FONT, fontSize: '12px', color: canBuy ? (hasLv1 ? 0xffcd75 : '#41a6f6') : '#565a73', fontStyle: 'bold'
    }).setOrigin(0.5);

    // 锁定按钮
    const lockBg = this.add.rectangle(w / 2 - 42, -50, 60, 24, locked ? 0x3a1944 : 0x1c1f2e)
      .setStrokeStyle(1, locked ? 0xd46c99 : 0x3a3d52);
    const lockTxt = this.add.text(w / 2 - 42, -50, locked ? '🔒 锁定' : '锁', {
      fontFamily: FONT, fontSize: '11px', color: locked ? '#d46c99' : '#6b7280'
    }).setOrigin(0.5);

    c.add([priceBg, priceTxt, buyBg, buyTxt, lockBg, lockTxt]);

    if (canBuy) {
      buyBg.setInteractive({ useHandCursor: true }).on('pointerdown', () => this._buyItem(idx, item));
    } else if (canAfford && item.kind === 'weapon' && isFull && !hasLv1) {
      buyBg.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
        this._toast('武器栏已满（6/6）！请先在左侧点击【✦合】合并同级武器！');
      });
    }

    lockBg.setInteractive({ useHandCursor: true }).on('pointerdown', () => {
      this.lockedSlots[idx] = !this.lockedSlots[idx];
      this._drawShopPanel();
    });

    return c;
  }

  // ——— 道具上限保护 ———
  // 背景：正向属性会被 Player 的 cap() 截断而静默失效，但道具的负向代价（扣血/扣甲/降回复）照常生效，
  // 于是高波次可能买到"只吃惩罚、不吃收益"的传说道具。这里做一次"试应用 → 比较 → 无收益则回滚"。
  _snapshotStats(p, gs) {
    return {
      extraMaxHp: p.extraMaxHp, extraSpeedMul: p.extraSpeedMul, extraDmgMul: p.extraDmgMul,
      extraArmor: p.extraArmor, extraCrit: p.extraCrit, extraPickupMul: p.extraPickupMul,
      regenBps: p.regenBps, extraDodge: p.extraDodge, extraCritDmg: p.extraCritDmg,
      extraArea: p.extraArea, extraLifeSteal: p.extraLifeSteal, extraCdMul: p.extraCdMul,
      hp: p.hp,
      weaponCd: gs.weapons.map(w => w.cooldownMul)
    };
  }

  _restoreStats(p, gs, s) {
    p.extraMaxHp = s.extraMaxHp; p.extraSpeedMul = s.extraSpeedMul; p.extraDmgMul = s.extraDmgMul;
    p.extraArmor = s.extraArmor; p.extraCrit = s.extraCrit; p.extraPickupMul = s.extraPickupMul;
    p.regenBps = s.regenBps; p.extraDodge = s.extraDodge; p.extraCritDmg = s.extraCritDmg;
    p.extraArea = s.extraArea; p.extraLifeSteal = s.extraLifeSteal; p.extraCdMul = s.extraCdMul;
    p.hp = s.hp;
    gs.weapons.forEach((w, i) => { if (s.weaponCd[i] !== undefined) w.cooldownMul = s.weaponCd[i]; });
  }

  // 12 项会被上限截断的正向属性；冷却取负值（越小越好，越大越优）
  _statVector(p) {
    return [
      p.damageMult, p.critChance, p.armor, p.dodgeRate, p.attackArea, p.lifeSteal,
      p.critDmgMul, p.speed, p.maxHp, p.pickupRadius, p.regenBps, -p.cooldownMult
    ];
  }

  // 试应用一次，判断是否真的有属性提升（用于免费加点：避免三张卡全到上限时白选）
  _wouldGain(opt) {
    const p = this.gs && this.gs.player;
    if (!p) return true;
    const before = this._statVector(p);
    const snap = this._snapshotStats(p, this.gs);
    try { opt.apply(p, this.gs); } catch (e) { this._restoreStats(p, this.gs, snap); return false; }
    const after = this._statVector(p);
    this._restoreStats(p, this.gs, snap);
    return after.some((v, i) => v > before[i] + 1e-6);
  }

  _buyItem(idx, item) {
    if (this.coins < item.price) return;
    const gs = this.gs;
    if (!gs) return;

    if (item.kind === 'weapon') {
      const curWeaps = gs.weapons;
      if (curWeaps.length < 6) {
        gs.addWeapon(item.id, 1);
        this._toast('获得武器：' + item.name + ' (Lv 1)！');
      } else {
        const hasLv1 = curWeaps.some(w => w.id === item.id && w.level === 1);
        if (hasLv1) {
          gs.addWeapon(item.id, 1);
          gs.synthesizeWeapons(item.id, 1);
          this._toast('自动合成升阶：' + item.name + ' 升至 Lv 2！');
        } else {
          this._toast('武器栏已满（6/6）！请先在左侧点击【✦合】合并同级武器！');
          return;
        }
      }
    } else if (item.kind === 'item' && gs.player) {
      const p = gs.player;
      const before = this._statVector(p);
      const snap = this._snapshotStats(p, gs);
      let ok = true;
      try { item.apply(p, gs); } catch (e) { ok = false; console.warn(e); }
      const after = this._statVector(p);
      // 任意一项正向属性有实际提升才算"买到了东西"
      const gained = after.some((v, i) => v > before[i] + 1e-6);
      if (!ok || !gained) {
        this._restoreStats(p, gs, snap);
        this._toast('该道具的属性增益已全部达到上限，购买已取消（不扣金币）');
        return;
      }
      this._toast('获得道具：' + item.name + '！');
    }

    this.coins -= item.price;
    this.coinsText.setText('💰 金币  ' + this.coins);
    try { audio.coin(); } catch (e) {}

    this.shopItems[idx] = null;
    this.lockedSlots[idx] = false;

    this._drawTopBar();
    this._drawLeftArsenalPanel();
    this._drawShopPanel();
  }

  _doReroll() {
    if (this.coins < this.rerollCost) {
      this._toast('金币不足，刷新需要 ' + this.rerollCost + ' 金币！');
      return;
    }
    this.coins -= this.rerollCost;
    this.rerollCost += 5;
    this.coinsText.setText('💰 金币  ' + this.coins);

    const gs = this.gs;
    const curWpIds = gs ? gs.weapons.map(w => w.id) : [];

    for (let i = 0; i < 4; i++) {
      if (this.lockedSlots[i]) continue;
      this.shopItems[i] = this._rollSingleShopItem(curWpIds);
    }

    this._drawShopPanel();
    try { audio.reroll(); } catch (e) {}
  }

  // ——— 底栏：进入下一波与进度 ———
  _drawBottomBar() {
    const isLast = (this.wave >= this.maxWave);
    const label = isLast ? ('⚔ 决战第 ' + this.maxWave + ' 波终幕 Boss！') : ('▶ 进入第 ' + (this.wave + 1) + ' 波（决战倒计时）');
    const col = isLast ? 0xb13e53 : 0x38b764;
    const colHex = '#' + col.toString(16).padStart(6, '0');

    const btnBg = this.add.rectangle(W / 2 + 100, H - 42, 360, 48, 0x161a28)
      .setStrokeStyle(3, col).setDepth(10).setInteractive({ useHandCursor: true });
    this.add.text(W / 2 + 100, H - 42, label, {
      fontFamily: FONT, fontSize: '20px', color: colHex, fontStyle: 'bold'
    }).setOrigin(0.5).setDepth(11);
    btnBg.on('pointerdown', () => this._startNextWave());

    const barX = 40, barW = 240;
    const segW = (barW / this.maxWave) - 2;
    for (let i = 0; i < this.maxWave; i++) {
      const px = barX + i * (barW / this.maxWave) + segW / 2;
      const fill = i < this.wave ? 0x38b764 : (i === this.wave ? 0xffcd75 : 0x222638);
      this.add.rectangle(px, H - 42, segW, 8, fill).setDepth(5).setOrigin(0.5);
    }
    this.add.text(barX + barW + 14, H - 42, this.wave + '/' + this.maxWave, {
      fontFamily: FONT, fontSize: '13px', color: '#94b0c2', fontStyle: 'bold'
    }).setOrigin(0, 0.5).setDepth(5);
  }

  _startNextWave() {
    try { audio.click(); } catch (e) {}
    if (this.gs) {
      this.gs.coins = this.coins;
      this.gs.brotoLockedSlots = [...this.lockedSlots];
      this.gs.brotoLockedItems = [...this.shopItems];
      this.gs.startNextBrotoWave(this.wave + 1);
    }
    this.scene.stop();
  }

  _toast(msg) {
    // 三条循环槽位：同槽位的旧提示先销毁，避免多条堆叠重叠或飞出屏幕
    if (!this._toastSlots) this._toastSlots = [null, null, null];
    const slot = this._toastSlot = ((this._toastSlot === undefined ? 2 : this._toastSlot) + 1) % 3;
    const prev = this._toastSlots[slot];
    if (prev && prev.active) prev.destroy();
    const y0 = H / 2 - slot * 44;
    const t = this.add.text(W / 2 + 100, y0, msg, {
      fontFamily: FONT, fontSize: '20px', color: '#ffcd75', fontStyle: 'bold',
      stroke: '#000', strokeThickness: 5,
      backgroundColor: 'rgba(13,16,28,0.88)', padding: { x: 18, y: 10 }
    }).setOrigin(0.5).setDepth(70);
    this._toastSlots[slot] = t;
    this.tweens.add({ targets: t, alpha: 0, y: y0 - 50, delay: 1400, duration: 500, onComplete: () => { if (t.active) t.destroy(); if (this._toastSlots[slot] === t) this._toastSlots[slot] = null; } });
  }
}