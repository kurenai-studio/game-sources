(() => {
  "use strict";

  const SAVE_KEY = "qixing-isle-save-v1";
  const SAVE_VERSION = 1;
  const PLOT_COUNT = 16;
  const PLOT_UNLOCK_FAME = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 25, 45, 70];

  const CROPS = {
    dewberry: {
      id: "dewberry",
      name: "露莓",
      english: "DEWBERRY",
      description: "晨露凝成的小浆果，甜里带着一点云的味道。",
      cost: 10,
      days: 2,
      yield: 18,
      fame: 2,
      unlock: 0,
      accent: "#e39576",
      tokenBg: "#f1dfd0",
      glow: "rgba(226, 145, 111, .18)",
      soil: "#bb9a72"
    },
    moonbell: {
      id: "moonbell",
      name: "月铃花",
      english: "MOONBELL",
      description: "入夜才肯开放的铃兰，会把风染成淡紫色。",
      cost: 18,
      days: 3,
      yield: 35,
      fame: 4,
      unlock: 6,
      accent: "#b195c8",
      tokenBg: "#e8e0ef",
      glow: "rgba(169, 139, 204, .2)",
      soil: "#ad9877"
    },
    sunwheat: {
      id: "sunwheat",
      name: "日穗",
      english: "SUNWHEAT",
      description: "顺着阳光生长的金色谷穗，是岛上最好的面包材料。",
      cost: 28,
      days: 4,
      yield: 58,
      fame: 7,
      unlock: 18,
      accent: "#e3b967",
      tokenBg: "#f3e8ca",
      glow: "rgba(221, 179, 93, .2)",
      soil: "#b49a6e"
    },
    starflower: {
      id: "starflower",
      name: "栖星花",
      english: "STARFLOWER",
      description: "一年只开五日的星花，花瓣里藏着一小片夜空。",
      cost: 44,
      days: 5,
      yield: 92,
      fame: 11,
      unlock: 40,
      accent: "#f0c477",
      tokenBg: "#f5e5bd",
      glow: "rgba(239, 196, 112, .23)",
      soil: "#b3a078"
    }
  };

  const CROP_ORDER = ["dewberry", "moonbell", "sunwheat", "starflower"];

  const WEATHER = {
    sunny: {
      id: "sunny",
      name: "晴岚",
      phase: "晨光正好",
      effect: "收获星露 +10%",
      summary: "阳光把每一片叶子都照得发亮。",
      icon: "晴"
    },
    rain: {
      id: "rain",
      name: "细雨",
      phase: "雨声很轻",
      effect: "夜晚自动浇灌全部田圃",
      summary: "细雨替你照料了整座田圃。",
      icon: "雨"
    },
    breeze: {
      id: "breeze",
      name: "微风",
      phase: "风从云间来",
      effect: "湿润作物额外生长 1 日",
      summary: "温柔的风推着新芽，多长了一小截。",
      icon: "风"
    },
    mist: {
      id: "mist",
      name: "薄雾",
      phase: "雾里有光",
      effect: "星愿月辉 +1",
      summary: "薄雾让旅人的心事变得更慷慨。",
      icon: "雾"
    }
  };

  const LEVELS = [
    { at: 0, name: "初见微光" },
    { at: 12, name: "草叶苏醒" },
    { at: 35, name: "风铃有声" },
    { at: 75, name: "星栖满庭" },
    { at: 130, name: "云海灯塔" }
  ];

  const SPIRITS = {
    lutu: {
      id: "lutu",
      name: "露团",
      title: "采露的小灵",
      unlock: 0,
      cost: 8,
      buffName: "落叶归露",
      description: "所有作物收获时，星露 +20%。",
      imageBg: "#dcebdc",
      color: "#789f8b"
    },
    fengling: {
      id: "fengling",
      name: "风翎",
      title: "顺风的信使",
      unlock: 8,
      cost: 12,
      buffName: "轻风代劳",
      description: "每次浇水有 35% 概率不消耗精力。",
      imageBg: "#efe3cd",
      color: "#b68552"
    },
    ashi: {
      id: "ashi",
      name: "阿拾",
      title: "拾愿的旅伴",
      unlock: 18,
      cost: 18,
      buffName: "多做一件好事",
      description: "星愿月辉奖励 +2，每日额外获得 2 星露。",
      imageBg: "#e4e2cf",
      color: "#778761"
    }
  };

  const UPGRADES = {
    well: {
      id: "well",
      name: "月泉井",
      description: "每日结算时额外获得 2 星露。",
      costs: [6, 10, 16],
      max: 3,
      color: "#d9ecea",
      icon: "well"
    },
    greenhouse: {
      id: "greenhouse",
      name: "晨露温室",
      description: "最大精力 +1，当天立即恢复 1 点。",
      costs: [8, 13, 20],
      max: 3,
      color: "#e6ecd5",
      icon: "greenhouse"
    },
    market: {
      id: "market",
      name: "岛民集市",
      description: "作物收获星露 +12%。",
      costs: [10, 16, 24],
      max: 3,
      color: "#f1e3c7",
      icon: "market"
    }
  };

  const VISITORS = [
    { name: "采药人 阿澈", initial: "澈", line: "山下的村落，很久没见过会发光的花了。" },
    { name: "迷路的小灯", initial: "灯", line: "我想带一点岛上的光，照亮回家的石阶。" },
    { name: "面包师 米娅", initial: "米", line: "如果明早能吃上岛上的谷物，旅店一定很热闹。" },
    { name: "云邮差 青禾", initial: "禾", line: "这封信要在日落前送到，我得先麻烦你一件事。" },
    { name: "画家 雫", initial: "雫", line: "我想画下这里的光，可画布还缺一点颜色。" }
  ];

  const PLANT_ART = {
    dewberry: `
      <svg viewBox="0 0 100 112" aria-hidden="true">
        <defs>
          <linearGradient id="dewStem" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#91ae75"/><stop offset="1" stop-color="#4d7e5e"/></linearGradient>
          <radialGradient id="dewBerry" cx=".32" cy=".2" r=".82"><stop stop-color="#ffc4a5"/><stop offset=".48" stop-color="#e58a72"/><stop offset="1" stop-color="#b95862"/></radialGradient>
          <radialGradient id="dewLeaf" cx=".28" cy=".18" r=".9"><stop stop-color="#bfd49d"/><stop offset="1" stop-color="#5b8d64"/></radialGradient>
        </defs>
        <ellipse cx="50" cy="105" rx="31" ry="5" fill="#2b523e" opacity=".18"/>
        <path d="M49 102C47 81 49 56 55 44" fill="none" stroke="url(#dewStem)" stroke-width="4" stroke-linecap="round"/>
        <path d="M52 71C39 65 28 68 20 77c13 7 25 6 35-1" fill="url(#dewLeaf)"/>
        <path d="M54 61c13-8 25-8 34 0-9 9-21 12-36 6" fill="url(#dewLeaf)"/>
        <path d="M49 82c-12-4-21 1-25 10 11 5 20 2 29-5" fill="url(#dewLeaf)" opacity=".9"/>
        <path d="M54 44c-9-10-8-22 1-30 9 7 12 18 5 29" fill="url(#dewLeaf)"/>
        <path d="M57 47c9-10 21-13 30-7-3 12-14 19-29 16" fill="url(#dewLeaf)" opacity=".9"/>
        <path d="M27 31c-1-9 5-16 13-19 3 8-1 16-10 21Z" fill="#79a376"/>
        <circle cx="33" cy="75" r="12" fill="url(#dewBerry)"/>
        <circle cx="62" cy="71" r="10.5" fill="url(#dewBerry)"/>
        <circle cx="48" cy="57" r="12.5" fill="url(#dewBerry)"/>
        <circle cx="67" cy="51" r="8.7" fill="url(#dewBerry)"/>
        <g fill="#fff" opacity=".46">
          <ellipse cx="29" cy="70" rx="3" ry="2" transform="rotate(-35 29 70)"/>
          <ellipse cx="44" cy="52" rx="3.4" ry="2.1" transform="rotate(-34 44 52)"/>
          <ellipse cx="59" cy="67" rx="2.6" ry="1.7" transform="rotate(-35 59 67)"/>
        </g>
        <path d="M44 43c1 4 3 7 6 10M59 40c2 4 3 7 3 11" fill="none" stroke="#4f765b" stroke-width="1.2" stroke-linecap="round"/>
        <path d="m81 29 .9 3.1L85 33l-3.1.9L81 37l-.9-3.1L77 33l3.1-.9L81 29Z" fill="#f7dda1" opacity=".9"/>
      </svg>`,
    moonbell: `
      <svg viewBox="0 0 100 112" aria-hidden="true">
        <defs>
          <linearGradient id="moonStem" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#91b892"/><stop offset="1" stop-color="#4a7b68"/></linearGradient>
          <linearGradient id="moonBloom" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#e9d9f7"/><stop offset=".48" stop-color="#bda1d7"/><stop offset="1" stop-color="#836da8"/></linearGradient>
          <linearGradient id="moonLeaf" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#a7c997"/><stop offset="1" stop-color="#527d64"/></linearGradient>
        </defs>
        <ellipse cx="50" cy="105" rx="30" ry="5" fill="#2b523e" opacity=".18"/>
        <path d="M48 103C47 82 49 58 53 40M51 81c-10-3-19-8-25-18M52 67c10-4 17-11 21-21M50 54c-7-4-12-10-14-18" fill="none" stroke="url(#moonStem)" stroke-width="3.2" stroke-linecap="round"/>
        <path d="M30 59c-10-6-13-15-10-24 9 2 15 10 15 21" fill="url(#moonLeaf)"/>
        <path d="M65 44c11-2 19-8 22-18-9-1-17 5-23 15" fill="url(#moonLeaf)"/>
        <path d="M34 51c-9-5-13-13-11-21 8 1 14 8 16 18" fill="url(#moonLeaf)" opacity=".85"/>
        <path d="M61 58c10-1 17-7 20-15-8-2-16 3-21 11" fill="url(#moonLeaf)" opacity=".82"/>
        <path d="M53 40c-9 0-15 7-17 17 7 1 13-4 17-13" fill="#6d9a74"/>
        <g>
          <path d="M33 31c9 2 15 8 17 17-7 7-16 8-23 2-6-6-4-14 6-19Z" fill="url(#moonBloom)"/>
          <path d="M65 21c9 1 15 7 18 16-7 8-16 10-23 4-7-6-6-14 5-20Z" fill="url(#moonBloom)"/>
          <path d="M71 47c7 2 11 7 12 14-6 5-13 5-19 0-5-5-3-11 7-14Z" fill="url(#moonBloom)"/>
        </g>
        <path d="M40 39c1 5 0 9-2 12M71 30c0 5-2 8-4 10M78 54c-1 4-3 7-6 9" fill="none" stroke="#f4e7ff" stroke-width="1.2" stroke-linecap="round" opacity=".7"/>
        <g fill="#f7ebc0">
          <circle cx="31" cy="38" r="1.5"/><circle cx="63" cy="29" r="1.4"/><circle cx="74" cy="55" r="1.2"/>
        </g>
        <path d="m21 26 .7 2.3L24 29l-2.3.7L21 32l-.7-2.3L18 29l2.3-.7L21 26Z" fill="#f3dfaa" opacity=".8"/>
      </svg>`,
    sunwheat: `
      <svg viewBox="0 0 100 112" aria-hidden="true">
        <defs>
          <linearGradient id="wheatStem" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#aebc78"/><stop offset="1" stop-color="#6f8853"/></linearGradient>
          <linearGradient id="wheatGold" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#f7dfa0"/><stop offset=".5" stop-color="#dab05f"/><stop offset="1" stop-color="#ad7e3c"/></linearGradient>
          <linearGradient id="wheatLeaf" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#b5c77e"/><stop offset="1" stop-color="#607c50"/></linearGradient>
        </defs>
        <ellipse cx="50" cy="106" rx="33" ry="5" fill="#2b523e" opacity=".18"/>
        <path d="M47 104c-2-29 1-54 5-78M49 93c-9-5-15-12-18-22M53 80c10-4 17-12 21-23M46 69c-9-5-14-12-16-21M55 54c8-4 14-11 17-20" fill="none" stroke="url(#wheatStem)" stroke-width="2.8" stroke-linecap="round"/>
        <path d="M31 73c-12 1-20-5-24-15 9-4 18-1 25 8" fill="url(#wheatLeaf)"/>
        <path d="M73 60c11-3 18-10 20-20-9-1-17 4-22 13" fill="url(#wheatLeaf)"/>
        <path d="M30 54c-9 0-15-5-18-12 7-2 13 1 19 8" fill="url(#wheatLeaf)" opacity=".85"/>
        <g fill="url(#wheatGold)" stroke="#b88d47" stroke-width=".7">
          <ellipse cx="53" cy="28" rx="6" ry="10" transform="rotate(-9 53 28)"/>
          <ellipse cx="47" cy="38" rx="6" ry="9.5" transform="rotate(-28 47 38)"/>
          <ellipse cx="59" cy="39" rx="6" ry="9.5" transform="rotate(28 59 39)"/>
          <ellipse cx="52" cy="48" rx="6.2" ry="9.5" transform="rotate(-14 52 48)"/>
          <ellipse cx="45" cy="55" rx="5.7" ry="9" transform="rotate(-33 45 55)"/>
          <ellipse cx="58" cy="57" rx="5.8" ry="9" transform="rotate(32 58 57)"/>
          <ellipse cx="53" cy="65" rx="5.5" ry="8.5" transform="rotate(-8 53 65)"/>
          <ellipse cx="36" cy="47" rx="5" ry="8" transform="rotate(-31 36 47)"/>
          <ellipse cx="70" cy="45" rx="5" ry="8" transform="rotate(28 70 45)"/>
        </g>
        <path d="M53 19c-1 5-1 10 0 15" fill="none" stroke="#e9d594" stroke-width="1.2" stroke-linecap="round" opacity=".8"/>
        <g fill="#ffe9ac" opacity=".85">
          <circle cx="53" cy="23" r="1.2"/><circle cx="44" cy="39" r="1"/><circle cx="61" cy="36" r="1.1"/>
        </g>
        <path d="m79 28 1 3.4L83.4 33 80 34l-1 3.4-1-3.4-3.4-1 3.4-1.6 1-3.4Z" fill="#ffe1a0" opacity=".8"/>
      </svg>`,
    starflower: `
      <svg viewBox="0 0 100 112" aria-hidden="true">
        <defs>
          <linearGradient id="starStem" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#94b88b"/><stop offset="1" stop-color="#4d7d5c"/></linearGradient>
          <linearGradient id="starPetal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#fff0b9"/><stop offset=".45" stop-color="#edc673"/><stop offset="1" stop-color="#c38b45"/></linearGradient>
          <radialGradient id="starCore" cx=".35" cy=".25" r=".8"><stop stop-color="#617e5b"/><stop offset="1" stop-color="#2f584a"/></radialGradient>
          <linearGradient id="starLeaf" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#b8d69e"/><stop offset="1" stop-color="#5f8e65"/></linearGradient>
        </defs>
        <ellipse cx="50" cy="106" rx="32" ry="5" fill="#2b523e" opacity=".18"/>
        <path d="M50 104C47 83 50 60 53 42" fill="none" stroke="url(#starStem)" stroke-width="4" stroke-linecap="round"/>
        <path d="M51 76C39 67 25 68 16 78c10 10 24 10 36 2" fill="url(#starLeaf)"/>
        <path d="M53 65c12-8 25-7 34 3-10 8-23 9-35 1" fill="url(#starLeaf)"/>
        <path d="M51 89c-10-4-20-2-26 6 9 5 18 3 27-2" fill="url(#starLeaf)" opacity=".8"/>
        <path d="M52 47c-6-12-3-23 8-31 6 10 3 21-6 30" fill="url(#starLeaf)" opacity=".92"/>
        <g fill="url(#starPetal)" stroke="#c8994d" stroke-width=".65">
          <path d="M52 39C43 27 47 14 58 7c8 12 5 23-4 32Z"/>
          <path d="M55 38C68 31 80 35 87 46 76 54 64 51 54 42Z"/>
          <path d="M55 42c13 3 20 13 19 26-13 1-22-7-24-20Z"/>
          <path d="M51 44c2 14-5 24-17 28-5-12 2-23 14-28Z"/>
          <path d="M47 41C35 45 24 39 20 28 32 22 43 27 49 38Z"/>
          <path d="M47 38C39 28 41 16 50 7c8 10 7 22-1 32Z" opacity=".85"/>
          <path d="M53 38C61 27 73 23 84 28 80 40 68 46 55 43Z" opacity=".9"/>
          <path d="M53 43c12 0 21 8 24 20-12 4-23-2-27-14Z" opacity=".9"/>
        </g>
        <circle cx="51" cy="37" r="9" fill="url(#starCore)"/>
        <circle cx="51" cy="37" r="4.3" fill="#f7d98e"/>
        <g fill="#fff8d0">
          <circle cx="53.2" cy="34" r="1.2"/><circle cx="49.8" cy="35.4" r=".9"/><circle cx="54" cy="39" r=".9"/>
        </g>
        <path d="m18 19 .9 3.2 3.1.8-3.1.9L18 27l-.9-3.1-3.1-.9 3.1-.8L18 19ZM82 11l.8 2.7 2.7.8-2.7.8-.8 2.7-.8-2.7-2.7-.8 2.7-.8.8-2.7Z" fill="#f8e3a8" opacity=".9"/>
        <circle cx="81" cy="72" r="1.8" fill="#f8dda0" opacity=".75"/>
      </svg>`
  };

  const UI_ICONS = {
    sprout: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21v-8m0 1C10 9 5.5 8.5 3 11c.4-5 5.5-7 9-3m0 3c2-4 6.5-4.5 9-2-.4 4.8-5.4 6.8-9 3" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    lock: `<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="5.5" y="10" width="13" height="10" rx="2.5" fill="none" stroke="currentColor" stroke-width="1.5"/><path d="M8.5 10V7.5a3.5 3.5 0 1 1 7 0V10" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>`,
    water: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.8S5.8 9.8 5.8 14a6.2 6.2 0 0 0 12.4 0C18.2 9.8 12 2.8 12 2.8Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="M9 14.2c.2 1.5 1.1 2.5 2.5 3" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg>`,
    harvest: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3c.8 4.1 3.1 6.4 7.2 7.2C15.1 11 12.8 13.3 12 17.4 11.2 13.3 8.9 11 4.8 10.2 8.9 9.4 11.2 7.1 12 3Z" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/><path d="M5 21c4.5-5 9.5-6.7 14-5" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>`,
    well: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 20h16M6 20v-8h12v8M5 12h14M8 8c0-2.2 1.8-4 4-4s4 1.8 4 4M9 15.5h6" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>`,
    greenhouse: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 20V9l8-5 8 5v11M4 20h16M9 20v-6h6v6M8 10h8M12 4v6" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
    market: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 9h16l-1-4H5L4 9Zm1 0v11h14V9M9 20v-6h6v6M8 9c0 1.2 1 2 2 2s2-.8 2-2c0 1.2 1 2 2 2s2-.8 2-2" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`
  };

  const SPIRIT_ART = {
    lutu: `
      <svg viewBox="0 0 110 128" aria-hidden="true">
        <defs><radialGradient id="slBody" cx=".38" cy=".16" r=".9"><stop stop-color="#f4ffe8"/><stop offset=".65" stop-color="#d0e9cf"/><stop offset="1" stop-color="#9ec8ad"/></radialGradient></defs>
        <ellipse cx="55" cy="113" rx="29" ry="7" fill="#315a49" opacity=".17"/>
        <path d="M34 50c-13 1-21 14-17 26 2 7 8 12 15 11l8-4-6-33ZM76 50c13 1 21 14 17 26-2 7-8 12-15 11l-8-4 6-33Z" fill="#cce5cb"/>
        <path d="M37 54c-8 7-11 18-6 27l9 20h30l9-20c5-9 2-20-6-27-7-7-15-10-18-10s-11 3-18 10Z" fill="url(#slBody)"/>
        <path d="M45 101c4-9 16-9 20 0v11c-4 4-16 4-20 0v-11Z" fill="#6b9e8d"/>
        <circle cx="46" cy="72" r="3.2" fill="#36594e"/><circle cx="64" cy="72" r="3.2" fill="#36594e"/>
        <circle cx="47" cy="71" r=".9" fill="#fff"/><circle cx="65" cy="71" r=".9" fill="#fff"/>
        <path d="M53 79c1.5 1.4 3 1.4 4.5 0" fill="none" stroke="#557c6c" stroke-width="1.4" stroke-linecap="round"/>
        <path d="M55 29c-3 7-3 14 0 21" fill="none" stroke="#dabc72" stroke-width="2" stroke-linecap="round"/>
        <path d="m55 14 4.5 10.8L70 29l-10.5 4.4L55 44l-4.5-10.6L40 29l10.5-4.2L55 14Z" fill="#f5d895"/>
        <circle cx="55" cy="29" r="3" fill="#fff4c8"/>
        <path d="m15 74 1 3.5L19.5 79 16 80l-1 3.5-1-3.5-3.5-1 3.5-1.5 1-3.5Z" fill="#f4d792" opacity=".8"/>
      </svg>`,
    fengling: `
      <svg viewBox="0 0 110 128" aria-hidden="true">
        <defs><linearGradient id="sfBody" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#f8e6bb"/><stop offset=".6" stop-color="#dbaf71"/><stop offset="1" stop-color="#ae7546"/></linearGradient></defs>
        <ellipse cx="55" cy="114" rx="28" ry="7" fill="#315a49" opacity=".17"/>
        <path d="M36 79c-16 7-25 22-21 36 12-3 22-13 29-27l-8-9Z" fill="#75a79a"/>
        <path d="M72 75c12 1 23 9 27 20-12 8-24 2-33-10l6-10Z" fill="#4f837b"/>
        <path d="M53 48c14-5 27 2 32 17 6 17-2 37-19 44-15 6-32-1-38-16-6-16 2-35 16-43 3-2 6-2 9-2Z" fill="url(#sfBody)"/>
        <path d="M48 61c-13 15-18 30-13 43 7-1 15-12 21-27l-8-16Z" fill="#8cb9a9" opacity=".9"/>
        <path d="M46 50c-1-14 7-24 19-27-2 13-7 22-14 29" fill="#e6bd7d"/>
        <path d="M61 28c9-10 20-13 31-8-6 11-16 17-29 16" fill="#f3d89d"/>
        <path d="M79 82c9 4 16 12 18 22-10 0-19-6-24-16" fill="#e4be7f"/>
        <path d="M48 84c-8 4-15 5-23 2 4-8 11-12 20-13" fill="#a4784c"/>
        <circle cx="59" cy="69" r="3.2" fill="#3b574c"/><circle cx="60" cy="68" r=".9" fill="#fff"/>
        <path d="M79 70c7-6 15-8 23-5l-9 8-14-3Z" fill="#d89055"/>
        <path d="M84 77c6 1 11 4 15 9-7 3-13 0-19-5l4-4Z" fill="#ba7143"/>
        <path d="m17 37 1 3.6 3.5 1-3.5 1-1 3.6-1-3.6-3.5-1 3.5-1 1-3.6Z" fill="#f3d693" opacity=".8"/>
        <path d="M22 73c10-3 17-10 23-21" fill="none" stroke="#f9e7bb" stroke-width="1" stroke-linecap="round" opacity=".32"/>
      </svg>`,
    ashi: `
      <svg viewBox="0 0 110 128" aria-hidden="true">
        <defs><radialGradient id="saBody" cx=".38" cy=".18" r=".9"><stop stop-color="#f4efd7"/><stop offset=".6" stop-color="#d7d3b7"/><stop offset="1" stop-color="#a8aa88"/></radialGradient></defs>
        <ellipse cx="55" cy="114" rx="29" ry="7" fill="#315a49" opacity=".17"/>
        <path d="M28 71c-12 5-18 17-16 29 2 9 11 12 18 8l8-7-10-30Z" fill="#8a9476"/>
        <path d="M82 71c12 5 18 17 16 29-2 9-11 12-18 8l-8-7 10-30Z" fill="#8a9476"/>
        <path d="M37 51c-10 9-13 24-6 36l11 19h26l11-19c7-12 4-27-6-36-7-7-14-10-18-10s-11 3-18 10Z" fill="url(#saBody)"/>
        <path d="M34 42c-8 5-13 13-11 20 2 6 9 8 16 4l7-4-12-20Z" fill="#c1c09b"/>
        <path d="M76 42c8 5 13 13 11 20-2 6-9 8-16 4l-7-4 12-20Z" fill="#c1c09b"/>
        <path d="M42 41c4-14 23-14 27 0" fill="none" stroke="#7d8a69" stroke-width="3" stroke-linecap="round"/>
        <path d="M41 41h29l-5 6H46l-5-6Z" fill="#68775c"/>
        <path d="M42 53c4-4 9-5 13-2 4 3 9 3 13 0v11c-4 4-8 4-13 1-4-3-9-3-13 1V53Z" fill="#a9ad8b" opacity=".65"/>
        <path d="M43 102c5-7 19-7 24 0v15c-5 5-19 5-24 0v-15Z" fill="#718764"/>
        <path d="M46 107c4-4 13-4 18 0" fill="none" stroke="#f2d79a" stroke-width="1.5" stroke-linecap="round"/>
        <circle cx="46" cy="68" r="2.7" fill="#46594d"/><circle cx="65" cy="68" r="2.7" fill="#46594d"/>
        <path d="M52 75c2 1.6 4 1.6 6 0" fill="none" stroke="#677767" stroke-width="1.4" stroke-linecap="round"/>
        <path d="M82 92c5-3 9-2 12 2-4 4-8 5-13 2" fill="#967c56"/>
        <path d="M79 86c4-1 7 1 8 5" fill="none" stroke="#f3dfb4" stroke-width="1.5" stroke-linecap="round"/>
        <path d="m18 34 1 3.5 3.5 1-3.5 1-1 3.5-1-3.5-3.5-1 3.5-1 1-3.5Z" fill="#f3d693" opacity=".75"/>
      </svg>`
  };

  let state = loadGame();
  let activeTab = ["seeds", "spirits", "journal"].includes(state.activeTab) ? state.activeTab : "seeds";
  let selectedPlot = Number.isInteger(state.selectedPlot) ? state.selectedPlot : null;
  let pendingClear = null;
  let pendingClearTimer = null;
  let processingDay = false;
  let saveTimer = null;
  let lastSummary = null;
  let audioContext = null;
  let ambientMaster = null;
  let ambientStarted = false;

  const els = {
    scene: document.getElementById("scene"),
    garden: document.getElementById("garden"),
    inspector: document.getElementById("inspector"),
    inspectorTitle: document.getElementById("inspectorTitle"),
    panelContext: document.getElementById("panelContext"),
    dailyWish: document.getElementById("dailyWish"),
    tabContent: document.getElementById("tabContent"),
    dewValue: document.getElementById("dewValue"),
    moonValue: document.getElementById("moonValue"),
    fameValue: document.getElementById("fameValue"),
    dayValue: document.getElementById("dayValue"),
    sealDay: document.getElementById("sealDay"),
    dayPhase: document.getElementById("dayPhase"),
    levelName: document.getElementById("levelName"),
    levelValue: document.getElementById("levelValue"),
    levelProgressText: document.getElementById("levelProgressText"),
    levelFill: document.getElementById("levelFill"),
    weatherPill: document.getElementById("weatherPill"),
    weatherIcon: document.getElementById("weatherIcon"),
    weatherName: document.getElementById("weatherName"),
    weatherEffect: document.getElementById("weatherEffect"),
    energyValue: document.getElementById("energyValue"),
    maxEnergyValue: document.getElementById("maxEnergyValue"),
    energyPips: document.getElementById("energyPips"),
    statusLabel: document.getElementById("statusLabel"),
    islandStatus: document.getElementById("islandStatus"),
    endDayButton: document.getElementById("endDayButton"),
    toastStack: document.getElementById("toastStack"),
    mascotBubble: document.getElementById("mascotBubble"),
    mascot: document.getElementById("mascot"),
    soundButton: document.getElementById("soundButton"),
    welcomeModal: document.getElementById("welcomeModal"),
    welcomeClose: document.getElementById("welcomeClose"),
    startButton: document.getElementById("startButton"),
    startButtonLabel: document.getElementById("startButtonLabel"),
    summaryModal: document.getElementById("summaryModal"),
    summaryClose: document.getElementById("summaryClose"),
    summaryTitle: document.getElementById("summaryTitle"),
    summarySubtitle: document.getElementById("summarySubtitle"),
    summaryList: document.getElementById("summaryList"),
    nextDayPreview: document.getElementById("nextDayPreview"),
    summaryContinue: document.getElementById("summaryContinue"),
    helpModal: document.getElementById("helpModal"),
    helpButton: document.getElementById("helpButton"),
    helpClose: document.getElementById("helpClose"),
    helpDone: document.getElementById("helpDone"),
    resetButton: document.getElementById("resetButton"),
    tabButtons: Array.from(document.querySelectorAll(".panel-tab"))
  };

  applyLoadedSelection();
  ensureWish();
  bindEvents();
  syncSoundButton();
  renderAll({ bump: false });
  maybeOpenWelcome();
  document.addEventListener(
    "pointerdown",
    () => {
      if (state.sound) {
        ensureAudio();
        startAmbient();
      }
    },
    { once: true }
  );

  function defaultState() {
    return {
      version: SAVE_VERSION,
      started: false,
      day: 1,
      dew: 60,
      moon: 3,
      fame: 0,
      energy: 8,
      weather: "sunny",
      plots: Array.from({ length: PLOT_COUNT }, () => ({
        cropId: null,
        growth: 0,
        wet: false,
        health: 100
      })),
      activeSpirit: null,
      spirits: {
        lutu: false,
        fengling: false,
        ashi: false
      },
      upgrades: {
        well: 0,
        greenhouse: 0,
        market: 0
      },
      stats: {
        planted: 0,
        watered: 0,
        harvested: 0,
        wishes: 0,
        totalDew: 0,
        totalMoon: 0
      },
      discovered: {
        dewberry: 0,
        moonbell: 0,
        sunwheat: 0,
        starflower: 0
      },
      wish: null,
      selectedPlot: null,
      activeTab: "seeds",
      sound: false,
      lighthouseShown: false,
      lastPlayed: Date.now()
    };
  }

  function loadGame() {
    const fresh = defaultState();
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return fresh;
      const saved = JSON.parse(raw);
      if (!saved || saved.version !== SAVE_VERSION) return fresh;

      const merged = {
        ...fresh,
        ...saved,
        plots: fresh.plots.map((plot, index) => {
          const loaded = Array.isArray(saved.plots) ? saved.plots[index] : null;
          if (!loaded) return plot;
          return {
            cropId: CROPS[loaded.cropId] ? loaded.cropId : null,
            growth: Number.isFinite(loaded.growth) ? Math.max(0, loaded.growth) : 0,
            wet: Boolean(loaded.wet),
            health: Number.isFinite(loaded.health) ? clamp(loaded.health, 0, 100) : 100
          };
        }),
        activeSpirit: SPIRITS[saved.activeSpirit] ? saved.activeSpirit : null,
        spirits: { ...fresh.spirits, ...(saved.spirits || {}) },
        upgrades: { ...fresh.upgrades, ...(saved.upgrades || {}) },
        stats: { ...fresh.stats, ...(saved.stats || {}) },
        discovered: { ...fresh.discovered, ...(saved.discovered || {}) }
      };
      merged.day = Math.max(1, Number(merged.day) || 1);
      merged.dew = Math.max(0, Number(merged.dew) || 0);
      merged.moon = Math.max(0, Number(merged.moon) || 0);
      merged.fame = Math.max(0, Number(merged.fame) || 0);
      merged.energy = Math.max(0, Number(merged.energy) || 0);
      merged.weather = WEATHER[merged.weather] ? merged.weather : "sunny";
      return merged;
    } catch (error) {
      console.warn("无法读取栖星岛存档，将使用新存档。", error);
      return fresh;
    }
  }

  function applyLoadedSelection() {
    if (selectedPlot === null) return;
    if (!Number.isInteger(selectedPlot) || selectedPlot < 0 || selectedPlot >= PLOT_COUNT) {
      selectedPlot = null;
    }
  }

  function ensureWish() {
    if (!state.wish || !isValidWish(state.wish)) {
      state.wish = generateWish();
    }
  }

  function isValidWish(wish) {
    if (!wish || !["harvest", "plant", "water"].includes(wish.type)) return false;
    return Number(wish.amount) > 0 && Number(wish.progress) >= 0;
  }

  function bindEvents() {
    els.garden.addEventListener("click", handleGardenClick);
    els.inspector.addEventListener("click", handleInspectorClick);
    els.dailyWish.addEventListener("click", handleWishClick);
    els.tabContent.addEventListener("click", handleTabContentClick);
    els.endDayButton.addEventListener("click", endDay);
    els.summaryContinue.addEventListener("click", closeSummary);
    els.summaryClose.addEventListener("click", closeSummary);
    els.summaryModal.addEventListener("click", (event) => {
      if (event.target === els.summaryModal) closeSummary();
    });
    els.startButton.addEventListener("click", startGame);
    els.welcomeClose.addEventListener("click", startGame);
    els.helpButton.addEventListener("click", openHelp);
    els.helpClose.addEventListener("click", closeHelp);
    els.helpDone.addEventListener("click", closeHelp);
    els.helpModal.addEventListener("click", (event) => {
      if (event.target === els.helpModal) closeHelp();
    });
    els.resetButton.addEventListener("click", resetGame);
    els.soundButton.addEventListener("click", toggleSound);
    els.mascot.addEventListener("click", talkToMascot);
    els.mascot.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        talkToMascot();
      }
    });
    els.tabButtons.forEach((button) => {
      button.addEventListener("click", () => switchTab(button.dataset.tab));
    });
    document.addEventListener("keydown", handleKeyboardShortcuts);
    window.addEventListener("beforeunload", () => saveNow());
  }

  function handleKeyboardShortcuts(event) {
    if (event.key === "Escape") {
      if (els.helpModal.classList.contains("is-open")) {
        closeHelp();
      } else if (els.summaryModal.classList.contains("is-open")) {
        closeSummary();
      }
    }
  }

  function maybeOpenWelcome() {
    if (!state.started) {
      els.welcomeModal.classList.add("is-open");
      els.startButtonLabel.textContent = "唤醒小岛";
    } else {
      els.welcomeModal.classList.remove("is-open");
    }
  }

  function startGame() {
    const wasNew = !state.started;
    state.started = true;
    ensureWish();
    els.welcomeModal.classList.remove("is-open");
    setMascotMessage("先选一块田，再种下露莓吧。两天后就能收获第一束光。");
    if (wasNew) {
      playChime("start");
      showToast("小岛醒来了。先完成第一位旅人的星愿吧。", "gold", "✦");
    }
    renderAll();
    saveNow();
  }

  function renderAll(options = {}) {
    const bump = options.bump !== false;
    renderResources(bump);
    renderDayAndWeather();
    renderLevel();
    renderGarden();
    renderInspector();
    renderTabs();
    renderWish();
    renderEnergy();
    renderStatus();
    updateTabButtons();
    scheduleSave();
  }

  function renderResources(bump = true) {
    updateValue(els.dewValue, state.dew, bump);
    updateValue(els.moonValue, state.moon, bump);
    updateValue(els.fameValue, state.fame, bump);
  }

  function updateValue(element, value, bump) {
    const next = String(value);
    const changed = element.textContent !== next;
    element.textContent = next;
    if (changed && bump) {
      element.classList.remove("is-bumping");
      void element.offsetWidth;
      element.classList.add("is-bumping");
    }
  }

  function renderDayAndWeather() {
    const weather = WEATHER[state.weather];
    els.dayValue.textContent = state.day;
    els.sealDay.textContent = String(state.day).padStart(2, "0");
    els.dayPhase.textContent = weather.phase;
    els.weatherPill.dataset.weather = weather.id;
    els.weatherIcon.dataset.weather = weather.id;
    els.weatherName.textContent = weather.name;
    els.weatherEffect.textContent = weather.effect;
    els.weatherPill.title = `${weather.name}：${weather.effect}`;
    els.scene.dataset.weather = weather.id;
  }

  function getLevelInfo() {
    let index = 0;
    for (let i = 0; i < LEVELS.length; i += 1) {
      if (state.fame >= LEVELS[i].at) index = i;
    }
    const current = LEVELS[index];
    const next = LEVELS[index + 1] || null;
    return {
      index,
      number: index + 1,
      name: current.name,
      start: current.at,
      nextAt: next ? next.at : null,
      nextName: next ? next.name : null,
      progress: next ? clamp((state.fame - current.at) / (next.at - current.at), 0, 1) : 1,
      range: next ? `${state.fame - current.at} / ${next.at - current.at}` : "MAX"
    };
  }

  function renderLevel() {
    const level = getLevelInfo();
    els.levelName.textContent = level.name;
    els.levelValue.textContent = level.number;
    els.levelProgressText.textContent = level.nextAt ? level.range : "MAX";
    els.levelFill.style.width = `${Math.round(level.progress * 100)}%`;
    els.scene.dataset.level = level.number;
  }

  function renderGarden() {
    const fragment = document.createDocumentFragment();
    for (let index = 0; index < PLOT_COUNT; index += 1) {
      const plot = state.plots[index];
      const unlocked = isPlotUnlocked(index);
      const crop = plot.cropId ? CROPS[plot.cropId] : null;
      const button = document.createElement("button");
      button.type = "button";
      button.className = "plot";
      button.dataset.plot = String(index);
      button.setAttribute("role", "gridcell");

      if (selectedPlot === index) button.classList.add("is-selected");

      if (!unlocked) {
        button.classList.add("is-locked");
        button.innerHTML = `
          <span class="plot-index">${String(index + 1).padStart(2, "0")}</span>
          <span class="plot-lock">${UI_ICONS.lock}<span>声望 ${PLOT_UNLOCK_FAME[index]}</span></span>
        `;
        button.setAttribute("aria-label", `第 ${index + 1} 块田圃，尚未唤醒，需要声望 ${PLOT_UNLOCK_FAME[index]}`);
        fragment.appendChild(button);
        continue;
      }

      if (!crop) {
        button.innerHTML = `
          <span class="plot-index">${String(index + 1).padStart(2, "0")}</span>
          <span class="soil-marker" aria-hidden="true">＋</span>
        `;
        button.setAttribute("aria-label", `第 ${index + 1} 块田圃，空闲，点击选择`);
        fragment.appendChild(button);
        continue;
      }

      const mature = plot.growth >= crop.days;
      const stage = getPlantStage(plot, crop);
      button.dataset.crop = crop.id;
      button.style.setProperty("--crop-accent", crop.accent);
      button.classList.add("is-growing");
      if (plot.health < 55) button.classList.add("is-withered");
      if (mature) button.classList.remove("is-growing");

      let badge = "";
      if (mature) {
        badge = `<span class="plot-badge badge-mature" title="可以收获">✦</span>`;
      } else if (!plot.wet) {
        badge = `<span class="plot-badge badge-dry" title="需要浇水">滴</span>`;
      }

      const progress = clamp(plot.growth / crop.days, 0, 1);
      const healthDots = Array.from({ length: 3 }, (_, dot) => {
        const threshold = (dot + 1) * 33;
        return `<i class="${plot.health <= threshold ? "is-low" : ""}"></i>`;
      }).join("");
      const label = mature
        ? `第 ${index + 1} 块田圃，${crop.name}已经成熟，点击收获`
        : `第 ${index + 1} 块田圃，${crop.name}，生长 ${plot.growth} / ${crop.days}，${plot.wet ? "土壤湿润" : "需要浇水"}`;

      button.innerHTML = `
        <span class="plot-index">${String(index + 1).padStart(2, "0")}</span>
        <span class="plot-health" aria-hidden="true">${healthDots}</span>
        ${badge}
        <span class="crop-plant plant-stage-${stage}">${PLANT_ART[crop.id]}</span>
        <span class="plant-progress" aria-hidden="true"><span style="width:${progress * 100}%"></span></span>
      `;
      button.setAttribute("aria-label", label);
      fragment.appendChild(button);
    }
    els.garden.replaceChildren(fragment);
  }

  function getPlantStage(plot, crop) {
    if (plot.growth >= crop.days) return 3;
    const ratio = plot.growth / crop.days;
    if (ratio >= 0.68) return 2;
    if (ratio >= 0.32) return 1;
    return 0;
  }

  function renderInspector() {
    const selected = selectedPlot;
    if (selected === null) {
      els.panelContext.textContent = "岛上手记";
      els.inspectorTitle.textContent = tabTitle(activeTab);
      els.inspector.innerHTML = `
        <div class="inspector-placeholder">
          <span class="inspector-placeholder-icon">${UI_ICONS.sprout}</span>
          <div>
            <strong>田圃正等着第一颗种子</strong>
            <p>点击画面中的一块田圃，再选择想种下的星植。</p>
          </div>
        </div>
      `;
      return;
    }

    const plot = state.plots[selected];
    if (!plot) {
      selectedPlot = null;
      renderInspector();
      return;
    }

    if (!isPlotUnlocked(selected)) {
      const need = PLOT_UNLOCK_FAME[selected];
      els.panelContext.textContent = `田圃 ${String(selected + 1).padStart(2, "0")} · 沉睡中`;
      els.inspectorTitle.textContent = "一小片尚未醒来的土地";
      els.inspector.innerHTML = `
        <div class="unlock-panel">
          <div class="selection-head">
            <span class="selection-token is-empty">${UI_ICONS.lock}</span>
            <div class="selection-copy">
              <small>云根仍旧沉睡</small>
              <strong>等待星光把土地接回主岛</strong>
            </div>
          </div>
          <p>继续收获星植、完成星愿，岛上的声望会把这一块田重新托上云海。</p>
          <div class="unlock-need"><span>唤醒条件</span><strong>声望 ${state.fame} / ${need}</strong></div>
          <div class="selection-progress"><span style="width:${clamp(state.fame / need, 0, 1) * 100}%"></span></div>
        </div>
      `;
      return;
    }

    const crop = plot.cropId ? CROPS[plot.cropId] : null;
    if (!crop) {
      els.panelContext.textContent = `田圃 ${String(selected + 1).padStart(2, "0")} · 空闲`;
      els.inspectorTitle.textContent = "这块土地正在等你";
      els.inspector.innerHTML = `
        <div class="selection-head">
          <span class="selection-token is-empty">${UI_ICONS.sprout}</span>
          <div class="selection-copy">
            <small>土壤松软 · 阳光适宜</small>
            <strong>第 ${selected + 1} 块 · 空闲田圃</strong>
            <p>从下方选一颗种子。种植会消耗 1 点精力。</p>
          </div>
          <div class="selection-meta"><strong>4 × 4</strong><small>月见圃</small></div>
        </div>
        <div class="inspector-actions">
          <span class="tip-strip" style="margin:0;padding:0;background:none">种下后会先保持湿润，今晚就能开始生长。</span>
        </div>
      `;
      return;
    }

    const mature = plot.growth >= crop.days;
    const progress = clamp(plot.growth / crop.days, 0, 1);
    const remaining = Math.max(0, crop.days - plot.growth);
    const clearLabel = pendingClear === selected ? "再点一次确认" : "移除";
    const soilState = mature ? "已成熟" : plot.wet ? "湿润" : "需浇水";
    const soilClass = !plot.wet && !mature ? "is-alert" : "";
    els.panelContext.textContent = `田圃 ${String(selected + 1).padStart(2, "0")} · ${crop.english}`;
    els.inspectorTitle.textContent = mature ? `${crop.name}把夜点亮了` : `${crop.name}正在慢慢长大`;
    els.inspector.innerHTML = `
      <div class="selection-head">
        <span class="selection-token" style="--token-bg:${crop.tokenBg}">${PLANT_ART[crop.id]}</span>
        <div class="selection-copy">
          <small>${mature ? "星光已经饱满" : remaining === 1 ? "距成熟还有一晚" : `距成熟还有 ${remaining} 晚`}</small>
          <strong>${crop.name}</strong>
          <p>${mature ? "再过一会儿也不会多长一颗，现在就带它回家吧。" : crop.description}</p>
        </div>
        <div class="selection-meta"><strong>${plot.growth} / ${crop.days}</strong><small>生长日</small></div>
      </div>
      <div class="selection-progress" style="--crop-accent:${crop.accent}"><span style="width:${progress * 100}%"></span></div>
      <div class="selection-metrics">
        <div class="metric"><span>土壤</span><strong class="${soilClass}">${soilState}</strong></div>
        <div class="metric"><span>活力</span><strong>${Math.round(plot.health)}%</strong></div>
        <div class="metric"><span>预计</span><strong>约 ${estimateHarvestDew(crop)} 星露</strong></div>
      </div>
      <div class="inspector-actions">
        ${
          mature
            ? `<button class="action-button action-button--gold" type="button" data-action="harvest">${UI_ICONS.harvest}收获星植</button>`
            : `<button class="action-button action-button--primary" type="button" data-action="water" ${plot.wet || state.energy < 1 ? "disabled" : ""}>${UI_ICONS.water}${plot.wet ? "土壤已湿润" : "浇水 · 1 精力"}</button>`
        }
        <button class="action-button action-button--ghost" type="button" data-action="clear">${clearLabel}</button>
      </div>
    `;
  }

  function tabTitle(tab) {
    if (tab === "spirits") return "谁陪你走过今天？";
    if (tab === "journal") return "小岛正在慢慢长大";
    return "今天想种些什么？";
  }

  function renderTabs() {
    els.tabContent.innerHTML =
      activeTab === "spirits"
        ? renderSpiritTab()
        : activeTab === "journal"
          ? renderJournalTab()
          : renderSeedTab();
  }

  function renderSeedTab() {
    const emptySelected =
      selectedPlot !== null &&
      isPlotUnlocked(selectedPlot) &&
      state.plots[selectedPlot] &&
      !state.plots[selectedPlot].cropId;
    const unlockedCount = CROP_ORDER.filter((id) => state.fame >= CROPS[id].unlock).length;

    const cards = CROP_ORDER.map((id) => {
      const crop = CROPS[id];
      const locked = state.fame < crop.unlock;
      const affordable = state.dew >= crop.cost;
      const classes = ["seed-card"];
      if (locked) classes.push("is-locked");
      else if (!affordable) classes.push("is-unaffordable");
      const disabled = locked ? "disabled" : "";
      const status = locked
        ? `<span class="seed-lock">声望 ${crop.unlock} 解锁</span>`
        : `<span class="seed-ready">可种</span>`;
      return `
        <button class="${classes.join(" ")}" type="button" data-crop-choice="${id}" style="--seed-glow:${crop.glow};--seed-soil:${crop.soil}" ${disabled}>
          <span class="seed-top">
            <span class="seed-art">${PLANT_ART[id]}</span>
            <span class="seed-copy"><strong>${crop.name}</strong><small>${crop.english}</small></span>
          </span>
          <p>${crop.description}</p>
          <span class="seed-bottom">
            <span class="seed-cost">${crop.cost} 星露</span>
            <span class="seed-days">${crop.days} 晚成熟</span>
            ${status}
          </span>
        </button>
      `;
    }).join("");

    let tip = "选一块空闲田圃，再点击种子即可栽种。";
    if (emptySelected) {
      tip = `第 ${selectedPlot + 1} 块田已选好。种子会在这里生根。`;
    } else if (selectedPlot !== null && state.plots[selectedPlot]?.cropId) {
      tip = "当前田圃已经种下了星植。换一块空闲田，或完成这株的照料。";
    } else if (selectedPlot !== null && !isPlotUnlocked(selectedPlot)) {
      tip = "这块田还在沉睡。先积累声望，再去唤醒它。";
    }

    return `
      <div class="section-label"><strong>星植图鉴</strong><small>${unlockedCount} / 4 已唤醒</small></div>
      <div class="seed-grid">${cards}</div>
      <div class="tip-strip">${tip}</div>
    `;
  }

  function renderSpiritTab() {
    const active = state.activeSpirit ? SPIRITS[state.activeSpirit] : null;
    const hero = active
      ? `
        <div class="spirit-hero">
          <span class="spirit-hero-avatar">${SPIRIT_ART[active.id]}</span>
          <div class="spirit-hero-copy">
            <small>${active.title} · 此刻同行</small>
            <strong>${active.name}</strong>
            <p>${active.buffName}：${active.description}</p>
          </div>
          <span class="spirit-hero-state">祝福生效中</span>
        </div>
      `
      : `
        <div class="spirit-hero">
          <span class="spirit-hero-avatar" style="background:rgba(255,255,255,.25);color:#769085">${UI_ICONS.sprout}</span>
          <div class="spirit-hero-copy">
            <small>云上独行 · 暂无同行者</small>
            <strong>风从小岛经过</strong>
            <p>结识一位岛灵，让它常驻月见圃，带来一项温柔而实用的祝福。</p>
          </div>
        </div>
      `;

    const list = Object.values(SPIRITS)
      .map((spirit) => {
        const recruited = Boolean(state.spirits[spirit.id]);
        const isActive = state.activeSpirit === spirit.id;
        const fameLocked = state.fame < spirit.unlock;
        let action;
        let disabled = "";
        if (isActive) {
          action = `<button class="spirit-action is-active" type="button" disabled>同行中</button>`;
        } else if (recruited) {
          action = `<button class="spirit-action" type="button" data-spirit-action="activate" data-spirit-id="${spirit.id}">请它同行</button>`;
        } else if (fameLocked) {
          action = `<button class="spirit-action" type="button" disabled>声望 ${spirit.unlock}</button>`;
          disabled = " disabled";
        } else {
          action = `<button class="spirit-action" type="button" data-spirit-action="recruit" data-spirit-id="${spirit.id}" ${state.moon < spirit.cost ? "disabled" : ""}>${spirit.cost} 月辉</button>`;
          disabled = state.moon < spirit.cost ? " disabled" : "";
        }
        return `
          <article class="spirit-card ${isActive ? "is-active" : ""}">
            <span class="spirit-mini" style="--spirit-bg:${spirit.imageBg}">${SPIRIT_ART[spirit.id]}</span>
            <div class="spirit-card-copy">
              <strong>${spirit.name}${recruited ? "<small>已结识</small>" : ""}</strong>
              <p>${spirit.buffName}：${spirit.description}</p>
            </div>
            ${action}
          </article>
        `;
      })
      .join("");

    return `
      <div class="section-label"><strong>岛灵小筑</strong><small>同一时间一位相伴</small></div>
      ${hero}
      <div class="spirit-list">${list}</div>
      <div class="tip-strip">岛灵的祝福不需要精力维持。声望提高后，会遇见新的岛灵。</div>
    `;
  }

  function renderJournalTab() {
    const discovered = CROP_ORDER.filter((id) => (state.discovered[id] || 0) > 0).length;
    const upgrades = Object.values(UPGRADES)
      .map((upgrade) => {
        const level = Number(state.upgrades[upgrade.id]) || 0;
        const maxed = level >= upgrade.max;
        const cost = maxed ? null : upgrade.costs[level];
        const canAfford = cost === null || state.moon >= cost;
        const levels = Array.from({ length: upgrade.max }, (_, i) => `<i class="${i < level ? "is-filled" : ""}"></i>`).join("");
        return `
          <article class="upgrade-card">
            <span class="upgrade-icon" style="--upgrade-bg:${upgrade.color}">${UI_ICONS[upgrade.icon]}</span>
            <div class="upgrade-copy">
              <strong>${upgrade.name} · Lv.${level}</strong>
              <p>${upgrade.description}</p>
              <span class="upgrade-levels">${levels}</span>
            </div>
            <button class="upgrade-action" type="button" data-upgrade="${upgrade.id}" ${maxed || !canAfford ? "disabled" : ""}>
              ${maxed ? "已满级" : `${cost} 月辉`}
            </button>
          </article>
        `;
      })
      .join("");

    const dots = CROP_ORDER.map((id) => {
      const count = state.discovered[id] || 0;
      return `<span class="collection-dot ${count > 0 ? "is-found" : ""}" title="${CROPS[id].name} · 已收获 ${count} 次">${count > 0 ? CROPS[id].name.slice(0, 1) : "?"}</span>`;
    }).join("");

    return `
      <div class="journal-stats">
        <div class="journal-stat"><strong>${state.stats.harvested}</strong><small>收获次数</small></div>
        <div class="journal-stat"><strong>${state.stats.wishes}</strong><small>完成星愿</small></div>
        <div class="journal-stat"><strong>${state.day}</strong><small>相伴天数</small></div>
      </div>
      <div class="section-label"><strong>小岛建设</strong><small>永久生效</small></div>
      <div class="upgrade-grid">${upgrades}</div>
      <div class="collection-row">
        <div class="collection-heading"><span>星植手札</span><strong>${discovered} / 4 已发现</strong></div>
        <div class="collection-dots">${dots}</div>
      </div>
      <div class="tip-strip">月辉来自星愿与小岛升级，是扩建小岛最珍贵的资源。</div>
    `;
  }

  function renderWish() {
    const wish = state.wish;
    if (!wish) return;
    const progress = clamp(wish.progress / wish.amount, 0, 1);
    const ready = wish.progress >= wish.amount;
    const claimed = Boolean(wish.claimed);
    const rewardText = `${wish.dewReward} 星露 · ${wish.moonReward} 月辉`;
    const requirement = wishRequirementText(wish);
    const statusText = claimed ? "已交付" : ready ? "可以交付" : `${Math.min(wish.progress, wish.amount)} / ${wish.amount}`;

    els.dailyWish.className = `wish-card${claimed ? " is-claimed" : ""}`;
    els.dailyWish.innerHTML = `
      <div class="wish-top">
        <span class="wish-avatar">${wish.visitorInitial}</span>
        <div><strong>${wish.visitorName}</strong><small>今日星愿 · 日落前完成</small></div>
        <span class="wish-time">${claimed ? "已化作星光" : ready ? "等你交付" : "第 " + state.day + " 日"}</span>
      </div>
      <p class="wish-copy">${wish.text}</p>
      <div class="wish-footer">
        <div class="wish-progress-wrap">
          <div class="wish-progress-label"><span>${requirement}</span><strong>${statusText}</strong></div>
          <div class="wish-progress"><span style="width:${progress * 100}%"></span></div>
          <div class="wish-reward" style="margin-top:4px">${claimed ? "这段心愿留在了手札里" : `交付可得 ${rewardText}`}</div>
        </div>
        <button class="wish-claim" type="button" data-wish-action="claim" ${!ready || claimed ? "disabled" : ""}>
          ${claimed ? "已交付" : ready ? "交付" : "未完成"}
        </button>
      </div>
    `;
  }

  function wishRequirementText(wish) {
    if (wish.type === "harvest") {
      const crop = CROPS[wish.cropId];
      return `采摘 ${crop.name} × ${wish.amount}`;
    }
    if (wish.type === "plant") return `种下星植 × ${wish.amount}`;
    return `为田圃浇水 × ${wish.amount}`;
  }

  function renderEnergy() {
    const maxEnergy = getMaxEnergy();
    state.energy = clamp(state.energy, 0, maxEnergy);
    els.energyValue.textContent = Math.floor(state.energy);
    els.maxEnergyValue.textContent = maxEnergy;
    els.energyPips.innerHTML = Array.from(
      { length: maxEnergy },
      (_, i) => `<i class="${i < state.energy ? "is-filled" : "is-spent"}"></i>`
    ).join("");
  }

  function renderStatus() {
    const crops = state.plots.filter((plot) => plot.cropId);
    const dry = crops.filter((plot) => {
      const crop = CROPS[plot.cropId];
      return crop && plot.growth < crop.days && !plot.wet && state.weather !== "rain";
    }).length;
    const mature = crops.filter((plot) => {
      const crop = CROPS[plot.cropId];
      return crop && plot.growth >= crop.days;
    }).length;
    const empty = state.plots.filter((plot, index) => !plot.cropId && isPlotUnlocked(index)).length;
    const weather = WEATHER[state.weather];

    els.statusLabel.textContent = weather.summary;
    if (mature > 0) {
      els.islandStatus.textContent = `${mature} 株星植已经成熟${dry > 0 ? ` · ${dry} 块需要浇水` : ""}`;
    } else if (dry > 0) {
      els.islandStatus.textContent = `${dry} 块田圃正在等一场浇灌`;
    } else if (empty > 0 && crops.length === 0) {
      els.islandStatus.textContent = `${empty} 块田圃等待被唤醒`;
    } else if (crops.length > 0) {
      els.islandStatus.textContent = `${crops.length} 株星植正安静地生长`;
    } else {
      els.islandStatus.textContent = "云海很轻，小岛也在呼吸";
    }
  }

  function updateTabButtons() {
    els.tabButtons.forEach((button) => {
      const active = button.dataset.tab === activeTab;
      button.classList.toggle("is-active", active);
      button.setAttribute("aria-selected", String(active));
    });
  }

  function switchTab(tab) {
    if (!["seeds", "spirits", "journal"].includes(tab) || activeTab === tab) return;
    activeTab = tab;
    state.activeTab = tab;
    pendingClear = null;
    playChime("soft");
    els.tabContent.style.animation = "none";
    void els.tabContent.offsetWidth;
    els.tabContent.style.animation = "";
    els.inspectorTitle.textContent = selectedPlot === null ? tabTitle(tab) : els.inspectorTitle.textContent;
    updateTabButtons();
    renderTabs();
    renderInspector();
  }

  function handleGardenClick(event) {
    const target = event.target.closest("[data-plot]");
    if (!target) return;
    const index = Number(target.dataset.plot);
    selectedPlot = index;
    state.selectedPlot = index;
    pendingClear = null;
    activeTab = "seeds";
    state.activeTab = "seeds";
    playChime("soft");
    renderAll();
  }

  function handleInspectorClick(event) {
    const target = event.target.closest("[data-action]");
    if (!target || selectedPlot === null) return;
    if (target.dataset.action === "water") waterPlot(selectedPlot);
    if (target.dataset.action === "harvest") harvestPlot(selectedPlot);
    if (target.dataset.action === "clear") requestClearPlot(selectedPlot);
  }

  function handleWishClick(event) {
    const target = event.target.closest("[data-wish-action]");
    if (!target) return;
    if (target.dataset.wishAction === "claim") claimWish();
  }

  function handleTabContentClick(event) {
    const cropButton = event.target.closest("[data-crop-choice]");
    if (cropButton && !cropButton.disabled) {
      tryPlantCrop(cropButton.dataset.cropChoice);
      return;
    }

    const spiritButton = event.target.closest("[data-spirit-action]");
    if (spiritButton) {
      handleSpiritAction(spiritButton.dataset.spiritAction, spiritButton.dataset.spiritId);
      return;
    }

    const upgradeButton = event.target.closest("[data-upgrade]");
    if (upgradeButton) {
      buyUpgrade(upgradeButton.dataset.upgrade);
    }
  }

  function tryPlantCrop(cropId) {
    const crop = CROPS[cropId];
    if (!crop) return;
    if (state.fame < crop.unlock) {
      showToast(`${crop.name}还在星光深处沉睡，声望 ${crop.unlock} 时才会醒来。`);
      return;
    }
    if (selectedPlot === null || !state.plots[selectedPlot]) {
      showToast("先在画面里选一块空闲田圃，再选择种子。");
      return;
    }
    if (!isPlotUnlocked(selectedPlot)) {
      showToast("这块田还没有被星光唤醒。");
      return;
    }
    const plot = state.plots[selectedPlot];
    if (plot.cropId) {
      showToast("这块田里已经有星植了，换一块空闲田试试。");
      return;
    }
    if (state.dew < crop.cost) {
      showToast(`星露不够啦，还差 ${crop.cost - state.dew} 点。完成星愿或收获作物会得到更多。`);
      return;
    }
    if (state.energy < 1) {
      showToast("今天的精力用完了。结束今日，睡一觉就会恢复。");
      return;
    }

    state.dew -= crop.cost;
    state.energy -= 1;
    state.stats.planted += 1;
    plot.cropId = crop.id;
    plot.growth = 0;
    plot.wet = true;
    plot.health = 100;
    updateWishProgress("plant");
    setMascotMessage(`${crop.name}已经住进第 ${selectedPlot + 1} 块田了。记得在它需要时浇水。`);
    playChime("plant");
    showToast(`种下 ${crop.name} · 用了 1 点精力`, "default", "芽");
    renderAll();
    saveNow();
  }

  function waterPlot(index) {
    const plot = state.plots[index];
    if (!plot || !plot.cropId) return;
    const crop = CROPS[plot.cropId];
    if (plot.growth >= crop.days) {
      showToast("它已经成熟了，直接收获就好。");
      return;
    }
    if (plot.wet || state.weather === "rain") {
      showToast("土壤已经很湿润，给它一点时间慢慢长大吧。");
      return;
    }
    if (state.energy < 1) {
      showToast("今天的精力用完了。结束今日，明天再来照料它。");
      return;
    }

    let energyCost = 1;
    const savedByWind = state.activeSpirit === "fengling" && Math.random() < 0.35;
    if (savedByWind) energyCost = 0;
    state.energy -= energyCost;
    state.stats.watered += 1;
    plot.wet = true;
    plot.health = Math.min(100, plot.health + 10);
    updateWishProgress("water");
    setMascotMessage(savedByWind ? "风翎悄悄替你浇好了水，一点精力也没用。" : "水渗进了土里，今晚它会多长一小截。");
    playChime("water");
    showToast(savedByWind ? "风翎替你浇了水 · 未消耗精力" : "浇水完成 · 消耗 1 点精力", "default", "水");
    renderAll();
    saveNow();
  }

  function harvestPlot(index) {
    const plot = state.plots[index];
    if (!plot || !plot.cropId) return;
    const crop = CROPS[plot.cropId];
    if (plot.growth < crop.days) {
      showToast("再等等，它还没有把星光收进叶子里。");
      return;
    }

    const harvested = getHarvestDew(crop);
    const oldFame = state.fame;
    state.dew += harvested;
    state.stats.harvested += 1;
    state.stats.totalDew += harvested;
    state.discovered[crop.id] = (state.discovered[crop.id] || 0) + 1;
    plot.cropId = null;
    plot.growth = 0;
    plot.wet = false;
    plot.health = 100;
    updateWishProgress("harvest", crop.id);
    addFame(crop.fame);
    checkProgressUnlocks(oldFame);
    setMascotMessage(`一束${crop.name}，换来了 ${harvested} 点星露。旅人也会很高兴的。`);
    playChime("harvest");
    celebrate(12);
    showToast(`收获 ${crop.name} · +${harvested} 星露 · +${crop.fame} 声望`, "gold", "✦");
    renderAll();
    saveNow();
  }

  function requestClearPlot(index) {
    if (!state.plots[index]?.cropId) return;
    if (pendingClear !== index) {
      pendingClear = index;
      renderInspector();
      window.clearTimeout(pendingClearTimer);
      pendingClearTimer = window.setTimeout(() => {
        if (pendingClear === index) {
          pendingClear = null;
          if (selectedPlot === index) renderInspector();
        }
      }, 3200);
      return;
    }

    const plot = state.plots[index];
    const crop = CROPS[plot.cropId];
    const refund = Math.floor(crop.cost * 0.25);
    state.dew += refund;
    plot.cropId = null;
    plot.growth = 0;
    plot.wet = false;
    plot.health = 100;
    pendingClear = null;
    showToast(`清空了田圃，找回 ${refund} 点星露。`, "default", "土");
    playChime("soft");
    renderAll();
    saveNow();
  }

  function getHarvestDew(crop) {
    let multiplier = 1 + (Number(state.upgrades.market) || 0) * 0.12;
    if (state.weather === "sunny") multiplier += 0.1;
    if (state.activeSpirit === "lutu") multiplier += 0.2;
    return Math.round(crop.yield * multiplier);
  }

  function estimateHarvestDew(crop) {
    return getHarvestDew(crop);
  }

  function getMaxEnergy() {
    const levelEnergy = getLevelInfo().index;
    return 8 + (Number(state.upgrades.greenhouse) || 0) + levelEnergy;
  }

  function isPlotUnlocked(index) {
    return state.fame >= (PLOT_UNLOCK_FAME[index] ?? 0);
  }

  function generateWish(preferredType = null) {
    const unlocked = CROP_ORDER.filter((id) => state.fame >= CROPS[id].unlock);
    let type = preferredType;
    if (!type) {
      if (state.stats.planted === 0) {
        type = "plant";
      } else {
        const roll = Math.random();
        type = roll < 0.39 ? "harvest" : roll < 0.72 ? "plant" : "water";
      }
    }

    if (type === "water" && state.weather === "rain") {
      type = "plant";
    }

    const visitor = VISITORS[Math.floor(Math.random() * VISITORS.length)];
    let cropId = null;
    let amount = 2;
    let text = "";
    let dewReward = 14;
    let moonReward = 2;

    if (type === "harvest") {
      cropId = unlocked[Math.floor(Math.random() * unlocked.length)];
      const crop = CROPS[cropId];
      amount = crop.unlock === 0 || crop.unlock === 6 ? 2 : 1;
      dewReward = 12 + amount * 3 + Math.floor(crop.yield * 0.08);
      moonReward = 2 + (crop.id === "starflower" ? 1 : 0);
      text = `${visitor.line} 可以帮我采下 <b>${crop.name} × ${amount}</b> 吗？`;
    } else if (type === "plant") {
      amount = state.stats.planted < 4 ? 2 : Math.random() < 0.5 ? 2 : 3;
      dewReward = 10 + amount * 2;
      moonReward = 1 + (amount === 3 ? 1 : 0);
      text = `${visitor.line} 我想看看新芽冒出土壤。今天种下 <b>${amount} 颗星植</b>，好吗？`;
    } else {
      amount = Math.random() < 0.55 ? 3 : 4;
      dewReward = 8 + amount;
      moonReward = amount === 4 ? 2 : 1;
      text = `${visitor.line} 有几块田的土已经干了，替它们浇上 <b>${amount} 次水</b>吧。`;
    }

    return {
      id: `wish-${state.day}-${Date.now()}`,
      type,
      cropId,
      amount,
      progress: 0,
      dewReward,
      moonReward,
      visitorName: visitor.name,
      visitorInitial: visitor.initial,
      text,
      claimed: false
    };
  }

  function updateWishProgress(type, cropId = null) {
    const wish = state.wish;
    if (!wish || wish.claimed || wish.type !== type) return;
    if (type === "harvest" && wish.cropId !== cropId) return;
    if (wish.progress >= wish.amount) return;
    wish.progress += 1;
    if (wish.progress === wish.amount) {
      window.setTimeout(() => {
        showToast("今日星愿完成了，回去交付给旅人吧。", "gold", "愿");
        playChime("wish");
      }, 250);
    }
  }

  function claimWish() {
    const wish = state.wish;
    if (!wish || wish.claimed || wish.progress < wish.amount) return;

    let moonReward = wish.moonReward;
    if (state.weather === "mist") moonReward += 1;
    if (state.activeSpirit === "ashi") moonReward += 2;
    const oldFame = state.fame;
    state.dew += wish.dewReward;
    state.moon += moonReward;
    state.stats.wishes += 1;
    state.stats.totalDew += wish.dewReward;
    state.stats.totalMoon += moonReward;
    wish.claimed = true;
    addFame(1);
    checkProgressUnlocks(oldFame);
    setMascotMessage("旅人带走了一段小小的光，也把温柔留在了岛上。");
    playChime("wish");
    celebrate(20);
    showToast(`星愿交付 · +${wish.dewReward} 星露 · +${moonReward} 月辉`, "gold", "✦");
    renderAll();
    saveNow();
  }

  function addFame(amount) {
    if (amount <= 0) return;
    const oldLevel = getLevelInfo();
    state.fame += amount;
    const newLevel = getLevelInfo();
    if (newLevel.index > oldLevel.index) {
      const bonusMoon = (newLevel.index - oldLevel.index) * 2;
      state.moon += bonusMoon;
      state.stats.totalMoon += bonusMoon;
      state.energy = Math.min(getMaxEnergy(), state.energy + 1);
      window.setTimeout(() => {
        showToast(`小岛升至 Lv.${newLevel.number}「${newLevel.name}」 · +${bonusMoon} 月辉`, "gold", "星");
        celebrate(30);
        playChime("levelup");
      }, 350);
    }
    if (state.fame >= 130 && !state.lighthouseShown) {
      state.lighthouseShown = true;
      window.setTimeout(() => {
        showToast("云海灯塔重新亮起。栖星岛已被你完整唤醒。", "gold", "灯");
        celebrate(48);
      }, 800);
    }
  }

  function checkProgressUnlocks(oldFame) {
    CROP_ORDER.forEach((id) => {
      const unlock = CROPS[id].unlock;
      if (oldFame < unlock && state.fame >= unlock) {
        window.setTimeout(() => showToast(`新星植「${CROPS[id].name}」在苗圃中醒来了。`, "gold", "芽"), 500);
      }
    });
    PLOT_UNLOCK_FAME.forEach((unlock, index) => {
      if (unlock > 0 && oldFame < unlock && state.fame >= unlock) {
        window.setTimeout(() => showToast(`第 ${index + 1} 块田圃重新飘回了主岛。`, "gold", "田"), 650);
      }
    });
  }

  function handleSpiritAction(action, spiritId) {
    const spirit = SPIRITS[spiritId];
    if (!spirit) return;
    if (action === "recruit") {
      if (state.fame < spirit.unlock) {
        showToast(`${spirit.name}还在云海深处，声望 ${spirit.unlock} 时才能相遇。`);
        return;
      }
      if (state.moon < spirit.cost) {
        showToast(`月辉不够，还差 ${spirit.cost - state.moon} 点。星愿和升级会给更多。`);
        return;
      }
      state.moon -= spirit.cost;
      state.spirits[spirit.id] = true;
      state.activeSpirit = spirit.id;
      setMascotMessage(`${spirit.name}决定留下来。它的小小祝福已经落在岛上了。`);
      showToast(`结识了 ${spirit.name} · ${spirit.buffName}已生效`, "gold", "灵");
      playChime("wish");
      celebrate(16);
    } else if (action === "activate" && state.spirits[spirit.id]) {
      state.activeSpirit = spirit.id;
      showToast(`${spirit.name}来到你身边。${spirit.buffName}已生效。`, "default", "灵");
      setMascotMessage(`${spirit.name}的灯火挪到了月见圃旁。`);
      playChime("soft");
    }
    renderAll();
    saveNow();
  }

  function buyUpgrade(upgradeId) {
    const upgrade = UPGRADES[upgradeId];
    if (!upgrade) return;
    const currentLevel = Number(state.upgrades[upgradeId]) || 0;
    if (currentLevel >= upgrade.max) {
      showToast("这项建设已经达到最高等级。");
      return;
    }
    const cost = upgrade.costs[currentLevel];
    if (state.moon < cost) {
      showToast(`月辉不够，还差 ${cost - state.moon} 点。`);
      return;
    }

    state.moon -= cost;
    state.upgrades[upgradeId] = currentLevel + 1;
    if (upgradeId === "greenhouse") {
      state.energy = Math.min(getMaxEnergy(), state.energy + 1);
    }
    showToast(`${upgrade.name}升到 Lv.${currentLevel + 1} · ${upgrade.description}`, "gold", "建");
    setMascotMessage(`${upgrade.name}又添了一层暖光。明天的小岛会轻松一点。`);
    playChime("levelup");
    celebrate(18);
    renderAll();
    saveNow();
  }

  function endDay() {
    if (processingDay) return;
    processingDay = true;
    els.endDayButton.disabled = true;
    const previousDay = state.day;
    const previousWeather = WEATHER[state.weather];
    const previousWeatherId = state.weather;
    let grew = 0;
    let extraGrew = 0;
    let matured = 0;
    let thirsty = 0;
    let healthLost = 0;

    state.plots.forEach((plot) => {
      if (!plot.cropId) return;
      const crop = CROPS[plot.cropId];
      if (!crop || plot.growth >= crop.days) return;
      const wasMature = plot.growth >= crop.days;
      const effectiveWet = plot.wet || previousWeatherId === "rain";
      if (effectiveWet) {
        const growth = 1 + (previousWeatherId === "breeze" ? 1 : 0);
        const before = plot.growth;
        plot.growth = Math.min(crop.days, plot.growth + growth);
        grew += 1;
        if (growth > 1) extraGrew += 1;
        if (!wasMature && plot.growth >= crop.days) matured += 1;
        if (before === plot.growth) grew -= 1;
      } else {
        thirsty += 1;
        const loss = 18;
        plot.health = Math.max(20, plot.health - loss);
        healthLost += loss;
      }
      plot.wet = false;
    });

    let dailyDew = 3 + (Number(state.upgrades.well) || 0) * 2 + Math.floor(state.fame / 25);
    if (state.activeSpirit === "ashi") dailyDew += 2;
    state.dew += dailyDew;
    state.stats.totalDew += dailyDew;

    const previousWish = state.wish;
    state.day += 1;
    state.weather = chooseNextWeather(previousWeatherId);
    state.energy = getMaxEnergy();
    if (state.weather === "rain") {
      state.plots.forEach((plot) => {
        if (plot.cropId) plot.wet = true;
      });
    }
    state.wish = generateWish();
    state.selectedPlot = selectedPlot;

    lastSummary = {
      previousDay,
      previousWeather,
      grew,
      extraGrew,
      matured,
      thirsty,
      healthLost,
      dailyDew,
      previousWish,
      nextWeather: WEATHER[state.weather]
    };

    playChime("night");
    renderAll({ bump: true });
    saveNow();
    window.setTimeout(() => {
      showSummary(lastSummary);
      processingDay = false;
      els.endDayButton.disabled = false;
    }, 480);
  }

  function chooseNextWeather(previous) {
    const choices = [
      { id: "sunny", weight: 34 },
      { id: "rain", weight: 25 },
      { id: "breeze", weight: 23 },
      { id: "mist", weight: 18 }
    ].filter((choice) => choice.id !== previous);
    const total = choices.reduce((sum, choice) => sum + choice.weight, 0);
    let roll = Math.random() * total;
    for (const choice of choices) {
      roll -= choice.weight;
      if (roll <= 0) return choice.id;
    }
    return choices[0].id;
  }

  function showSummary(summary) {
    const items = [];
    if (summary.grew > 0) {
      items.push({
        icon: "芽",
        title: `${summary.grew} 株星植继续生长`,
        detail: summary.extraGrew > 0 ? `微风额外照拂了 ${summary.extraGrew} 株` : "湿润的土壤没有辜负今晚",
        value: `+${summary.grew} 晚`
      });
    } else {
      items.push({
        icon: "夜",
        title: "没有星植在今晚长大",
        detail: "记得在结束今日前给需要生长的田圃浇水",
        value: "—"
      });
    }
    if (summary.matured > 0) {
      items.push({ icon: "✦", title: `${summary.matured} 株星植成熟了`, detail: "明亮的果实正在等你采下", value: "可收获" });
    }
    if (summary.thirsty > 0) {
      items.push({ icon: "滴", title: `${summary.thirsty} 块田缺水`, detail: "它们在今晚少长了一点，也失去了一些活力", value: "留意" });
    }
    items.push({ icon: "露", title: `岛上赠予了 ${summary.dailyDew} 星露`, detail: "月泉与岛民的谢意化作了晨露", value: `+${summary.dailyDew}` });
    items.push({ icon: "力", title: "精力在睡梦中恢复", detail: `明天拥有 ${getMaxEnergy()} 点精力可用`, value: "已恢复" });
    if (summary.previousWish && !summary.previousWish.claimed) {
      items.push({ icon: "愿", title: "昨日的星愿随晚风散去", detail: "未交付的心愿不会带来损失，明天会有新的相遇", value: "已翻页" });
    }

    const title =
      summary.matured > 0
        ? "有几株星植，在夜色里悄悄成熟了。"
        : summary.nextWeather.id === "rain"
          ? "雨要来借宿一晚，田圃会喝饱水。"
          : summary.grew > 0
            ? "暮色收拢，小岛睡得很安稳。"
            : "月亮替你看守了一夜。";
    els.summaryTitle.textContent = title;
    els.summarySubtitle.textContent = `第 ${summary.previousDay} 日 · ${summary.previousWeather.name} · 已存档`;
    els.summaryList.innerHTML = items
      .map(
        (item) => `
          <div class="summary-item">
            <span class="summary-item-icon">${item.icon}</span>
            <div><strong>${item.title}</strong><p>${item.detail}</p></div>
            <em>${item.value}</em>
          </div>
        `
      )
      .join("");
    els.nextDayPreview.innerHTML = `
      <span class="preview-weather-icon">${summary.nextWeather.icon}</span>
      <div><strong>明日天象 · ${summary.nextWeather.name}</strong><br>${summary.nextWeather.effect}。新的旅人愿望已经在门外等你。</div>
    `;
    els.summaryModal.classList.add("is-open");
  }

  function closeSummary() {
    els.summaryModal.classList.remove("is-open");
    playChime("start");
    setMascotMessage("新的一天。先看看今天的天气，再决定把精力花在哪里。");
  }

  function openHelp() {
    els.helpModal.classList.add("is-open");
  }

  function closeHelp() {
    els.helpModal.classList.remove("is-open");
  }

  function resetGame() {
    const confirmed = window.confirm("要重新开始这段小岛旅程吗？当前存档会被清除，无法恢复。");
    if (!confirmed) return;
    try {
      localStorage.removeItem(SAVE_KEY);
    } catch (error) {
      console.warn(error);
    }
    state = defaultState();
    activeTab = "seeds";
    selectedPlot = null;
    pendingClear = null;
    processingDay = false;
    ensureWish();
    els.helpModal.classList.remove("is-open");
    els.summaryModal.classList.remove("is-open");
    els.welcomeModal.classList.add("is-open");
    els.startButtonLabel.textContent = "唤醒小岛";
    syncSoundButton();
    renderAll({ bump: false });
  }

  function talkToMascot() {
    const mature = state.plots.filter((plot) => plot.cropId && plot.growth >= CROPS[plot.cropId].days).length;
    const dry = state.plots.filter((plot) => plot.cropId && !plot.wet && plot.growth < CROPS[plot.cropId].days).length;
    const messages = mature
      ? [`${mature} 株星植已经亮晶晶的了，记得收获呀。`, "成熟的星光不会自己跳进口袋里。去田里看看吧。"]
      : dry
        ? [`${dry} 块田正在偷偷口渴。浇水会让它们今晚继续长大。`, "土壤的颜色变浅，就是星植在说“想喝水”。"]
        : state.energy <= 1
          ? ["精力快见底了。把今天的故事收好，月亮会替我们恢复力气。", "今天已经很努力啦。结束今日不算偷懒，是让小岛休息。"]
          : [
              "露莓成熟只要两晚，适合第一次试试看。",
              "雨天不需要浇水。读懂天气，就能把精力留给更长远的事。",
              "微风天的湿润作物会多长一晚，可以提前留好水。",
              "旅人的愿望每天都会换，记得在日落前交付。",
              "岛灵可以换着同行。露团适合积累星露，风翎适合勤快浇水。",
              "如果不知道种什么，就种自己喜欢的。小岛不会催你。"
            ];
    els.mascotBubble.textContent = messages[Math.floor(Math.random() * messages.length)];
    els.mascot.animate?.(
      [
        { transform: "translateY(0) scale(1)" },
        { transform: "translateY(-8px) scale(1.04)" },
        { transform: "translateY(0) scale(1)" }
      ],
      { duration: 480, easing: "ease-out" }
    );
    playChime("soft");
  }

  function setMascotMessage(message) {
    els.mascotBubble.textContent = message;
  }

  function showToast(message, tone = "default", icon = "✦") {
    const toast = document.createElement("div");
    toast.className = `toast${tone === "gold" ? " toast--gold" : ""}`;
    toast.innerHTML = `<span class="toast-icon">${icon}</span><span>${message}</span>`;
    els.toastStack.appendChild(toast);
    while (els.toastStack.children.length > 3) {
      els.toastStack.firstElementChild?.remove();
    }
    window.setTimeout(() => {
      toast.classList.add("is-leaving");
      window.setTimeout(() => toast.remove(), 260);
    }, 3300);
  }

  function celebrate(count = 18) {
    const colors = ["#f2cf87", "#a8cfb3", "#e9a28a", "#cdbbda", "#fff1bd"];
    const rect = els.scene.getBoundingClientRect();
    for (let i = 0; i < count; i += 1) {
      const piece = document.createElement("i");
      piece.className = "confetti";
      piece.style.left = `${rect.left + rect.width * (0.44 + Math.random() * 0.12)}px`;
      piece.style.top = `${rect.top + rect.height * (0.30 + Math.random() * 0.18)}px`;
      piece.style.background = colors[i % colors.length];
      piece.style.setProperty("--tx", `${(Math.random() - 0.5) * 300}px`);
      piece.style.setProperty("--ty", `${80 + Math.random() * 230}px`);
      piece.style.animationDelay = `${Math.random() * 0.12}s`;
      document.body.appendChild(piece);
      window.setTimeout(() => piece.remove(), 1200);
    }
  }

  function syncSoundButton() {
    els.soundButton.classList.toggle("is-on", Boolean(state.sound));
    els.soundButton.setAttribute("aria-label", state.sound ? "关闭环境音" : "开启环境音");
  }

  function toggleSound() {
    state.sound = !state.sound;
    syncSoundButton();
    if (state.sound) {
      ensureAudio();
      startAmbient();
      playChime("start");
      showToast("环境音已开启。云海和风会陪你耕作。");
    } else {
      stopAmbient();
      showToast("环境音已关闭。");
    }
    saveNow();
  }

  function ensureAudio() {
    const AudioCtor = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtor) return null;
    if (!audioContext) {
      audioContext = new AudioCtor();
      ambientMaster = audioContext.createGain();
      ambientMaster.gain.value = 0;
      ambientMaster.connect(audioContext.destination);
      const filter = audioContext.createBiquadFilter();
      filter.type = "lowpass";
      filter.frequency.value = 680;
      filter.Q.value = 0.8;
      filter.connect(ambientMaster);
      [174.61, 261.63, 349.23].forEach((frequency, index) => {
        const oscillator = audioContext.createOscillator();
        const gain = audioContext.createGain();
        oscillator.type = index === 2 ? "sine" : "triangle";
        oscillator.frequency.value = frequency;
        oscillator.detune.value = index === 1 ? -5 : index === 2 ? 4 : 0;
        gain.gain.value = index === 0 ? 0.06 : 0.035;
        oscillator.connect(gain).connect(filter);
        oscillator.start();
      });
    }
    if (audioContext.state === "suspended") {
      audioContext.resume().catch(() => {});
    }
    return audioContext;
  }

  function startAmbient() {
    if (!audioContext || !ambientMaster || ambientStarted) return;
    ambientStarted = true;
    const now = audioContext.currentTime;
    ambientMaster.gain.cancelScheduledValues(now);
    ambientMaster.gain.setValueAtTime(ambientMaster.gain.value, now);
    ambientMaster.gain.linearRampToValueAtTime(0.014, now + 2.2);
  }

  function stopAmbient() {
    if (!audioContext || !ambientMaster) return;
    const now = audioContext.currentTime;
    ambientMaster.gain.cancelScheduledValues(now);
    ambientMaster.gain.setValueAtTime(ambientMaster.gain.value, now);
    ambientMaster.gain.linearRampToValueAtTime(0, now + 0.8);
    ambientStarted = false;
  }

  function playChime(kind = "soft") {
    if (!state.sound) return;
    const ctx = ensureAudio();
    if (!ctx) return;
    const patterns = {
      soft: [[440, 0, 0.18]],
      plant: [[392, 0, 0.14], [523.25, 0.07, 0.23]],
      water: [[349.23, 0, 0.12], [440, 0.08, 0.2], [587.33, 0.17, 0.28]],
      harvest: [[523.25, 0, 0.14], [659.25, 0.08, 0.18], [783.99, 0.18, 0.35]],
      wish: [[440, 0, 0.16], [554.37, 0.1, 0.2], [659.25, 0.2, 0.3], [880, 0.34, 0.42]],
      levelup: [[392, 0, 0.2], [523.25, 0.12, 0.22], [659.25, 0.24, 0.25], [783.99, 0.38, 0.4]],
      night: [[261.63, 0, 0.3], [349.23, 0.22, 0.42], [523.25, 0.48, 0.55]],
      start: [[329.63, 0, 0.18], [440, 0.1, 0.22], [659.25, 0.25, 0.42]]
    };
    const notes = patterns[kind] || patterns.soft;
    const now = ctx.currentTime + 0.02;
    notes.forEach(([frequency, delay, duration]) => {
      const oscillator = ctx.createOscillator();
      const gain = ctx.createGain();
      oscillator.type = "sine";
      oscillator.frequency.value = frequency;
      gain.gain.setValueAtTime(0.0001, now + delay);
      gain.gain.exponentialRampToValueAtTime(0.09, now + delay + 0.018);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + delay + duration);
      oscillator.connect(gain).connect(ctx.destination);
      oscillator.start(now + delay);
      oscillator.stop(now + delay + duration + 0.04);
    });
  }

  function scheduleSave() {
    if (saveTimer) window.clearTimeout(saveTimer);
    saveTimer = window.setTimeout(saveNow, 220);
  }

  function saveNow() {
    if (saveTimer) {
      window.clearTimeout(saveTimer);
      saveTimer = null;
    }
    state.activeTab = activeTab;
    state.selectedPlot = selectedPlot;
    state.lastPlayed = Date.now();
    try {
      localStorage.setItem(SAVE_KEY, JSON.stringify(state));
    } catch (error) {
      console.warn("栖星岛存档失败。", error);
    }
  }

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }
})();
