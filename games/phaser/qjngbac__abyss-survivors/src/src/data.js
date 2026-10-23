// 统一数据读取：优先走 Phaser 缓存；缓存里没有（file:// 等极端环境注入失败）时直接用内嵌数据兜底。
export default function getData(scene, key) {
  try {
    const fromCache = scene.cache.json.get(key);
    if (fromCache) return fromCache;
  } catch (e) { /* 忽略缓存异常，走内嵌兜底 */ }
  const embed = typeof window !== 'undefined' && window.ABYSS_EMBED;
  if (embed && embed.json && embed.json[key]) return embed.json[key];
  throw new Error('缺少游戏数据: ' + key);
}
