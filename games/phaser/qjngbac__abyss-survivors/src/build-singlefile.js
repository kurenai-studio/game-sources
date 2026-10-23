// build-singlefile.js —— 打包单文件版（零依赖，Node 18+ 直接运行：node build-singlefile.js）
// 产物：项目根目录下的「深渊幸存者.html」，双击用浏览器打开即玩，不需要任何服务器或运行环境。
// 过程全部在内存中完成（Phaser 引擎从 CDN 拉取），除本脚本与最终产物外不产生任何文件。
const fs = require('fs');
const path = require('path');

const PHASER_URL = 'https://cdn.jsdelivr.net/npm/phaser@3.87.0/dist/phaser.min.js';
const ENTRY = 'src/main.js';
const OUTPUT = '深渊幸存者.html';

async function main() {
  // 1. 引擎：按顺序尝试多个 CDN（单个源抖动时自动切换）
  console.log('拉取 Phaser 引擎...');
  let phaser = null;
  for (const url of [
    'https://cdn.jsdelivr.net/npm/phaser@3.87.0/dist/phaser.min.js',
    'https://unpkg.com/phaser@3.87.0/dist/phaser.min.js',
    'https://cdnjs.cloudflare.com/ajax/libs/phaser/3.87.0/phaser.min.js'
  ]) {
    try {
      const res = await fetch(url);
      if (res.ok) { phaser = await res.text(); console.log('  来源:', url); break; }
    } catch (e) { /* 换下一个源 */ }
  }
  if (!phaser) throw new Error('所有 CDN 均拉取失败，请检查网络后重试');

  // 2. 模块打包：解析 import 依赖图，按依赖顺序拼成一个经典 script
  function norm(p) { return path.normalize(p).replace(/\\/g, '/'); }
  function resolveSpec(spec, fromFile) {
    return norm(path.join(path.dirname(fromFile), spec));
  }

  const modules = new Map(); // normPath -> {name, code, deps, isEntry}
  function visit(file, isEntry = false) {
    const p = norm(file);
    if (modules.has(p)) return;
    let code = fs.readFileSync(p, 'utf8');
    const deps = [];

    // 剥离默认导入：import Player from './xxx.js'
    code = code.replace(/^[ \t]*import\s+(\w+)\s+from\s+['"]([^'"]+)['"];?[ \t]*\r?\n?/gm, (m, local, spec) => {
      if (!spec.startsWith('.') && !spec.startsWith('/')) return m; // 外部包（如 phaser）保留原样
      const dep = resolveSpec(spec, p);
      deps.push({ local, path: dep });
      visit(dep);
      return '';
    });

    if (/import\s*\{/.test(code)) throw new Error(`不支持命名导入: ${p}`);
    const defMatch = code.match(/export\s+default\s+(?:class|function)?\s*([\w$]+)/);
    if (!isEntry && !defMatch && !/export\s+default\s+/.test(code)) {
      throw new Error(`模块缺少 export default: ${p}`);
    }
    if (!isEntry && /export\s+(?:const|function|class|let|var)\s/.test(code)) throw new Error(`不支持命名导出: ${p}`);

    const base = path.basename(p).replace(/\.js$/, '');
    const name = defMatch ? defMatch[1] : base; // 匿名导出用文件名作模块标识
    // 命名导出：剥离 export default（末尾统一 return name）
    // 匿名导出（对象字面量）：export default 替换为 return
    code = code.replace(/export\s+default\s+/, defMatch ? '' : 'return ');

    modules.set(p, { name, code, deps, isEntry, anonymous: !defMatch });
  }

visit(ENTRY, true);

  let bundle = '';
  for (const [p, m] of modules) {
    if (m.isEntry) continue; // 入口最后拼
    const id = 'M_' + m.name;
    const aliases = m.deps.map(d => {
      const depName = modules.get(d.path).name;
      if (!depName) throw new Error(`依赖模块缺少默认导出名: ${d.path}`);
      return `  const ${d.local} = M_${depName};`;
    }).join('\n');
    const body = m.anonymous ? m.code : m.code + `\nreturn ${m.name};`;
    bundle += `// ======== ${p} ========\nconst ${id} = (() => {\n${aliases}\n${body}\n})();\n\n`;
  }
  {
    const m = modules.get(ENTRY);
    const aliases = m.deps.map(d => `const ${d.local} = M_${modules.get(d.path).name};`).join('\n');
    bundle += `// ======== ${ENTRY}（入口） ========\n${aliases}\n${m.code}\n`;
  }

  // 3. 素材内嵌：从 BootScene 源码解析资源清单，读文件转 base64
  const bootSource = fs.readFileSync('src/scenes/BootScene.js', 'utf8');
  function parseList(varName) {
    const block = bootSource.match(new RegExp(`const ${varName} = \\[([\\s\\S]*?)\\];`));
    if (!block) throw new Error(`BootScene 中找不到 ${varName}`);
    const pairs = [];
    for (const m of block[1].matchAll(/\['([^']+)',\s*'([^']+)'\]/g)) pairs.push([m[1], m[2]]);
    return pairs;
  }
  const jsonFiles = parseList('JSON_FILES');
  const imageFiles = parseList('IMAGE_FILES');

  const embedJSON = {};
  for (const [key, file] of jsonFiles) embedJSON[key] = JSON.parse(fs.readFileSync(file, 'utf8'));

  const embedImages = {};
  let skipped = 0;
  for (const [key, file] of imageFiles) {
    if (!fs.existsSync(file)) { // 可选图标缺失时跳过，游戏内由 BootScene 生成代码占位
      console.warn('  跳过缺失素材（代码占位）:', file);
      skipped++;
      continue;
    }
    embedImages[key] = 'data:image/png;base64,' + fs.readFileSync(file).toString('base64');
  }
  if (Object.keys(embedImages).length < 50) {
    throw new Error(`内嵌图片数量异常: ${Object.keys(embedImages).length}`);
  }

  const embedPreamble =
    'window.ABYSS_EMBED = {\n' +
    `  json: ${JSON.stringify(embedJSON)},\n` +
    `  images: ${JSON.stringify(embedImages)}\n` +
    '};\n' +
    // 看门狗：个别环境（如嵌入式浏览器后台标签）会冻结 requestAnimationFrame，
    // 导致引擎一帧都跑不起来。此时每 200ms 手动代打一帧；正常前台运行（isRunning=true）时自动休眠。
    'setInterval(function () {\n' +
    '  var g = window.__game;\n' +
    '  if (g && g.loop && typeof g.loop.callback === "function" && !g.isRunning) {\n' +
    '    try { g.loop.callback(performance.now()); } catch (e) {}\n' +
    '  }\n' +
    '}, 200);';

  // 4. 组装单文件 HTML
  const html = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>深渊幸存者</title>
<style>
  html, body { margin: 0; padding: 0; height: 100%; background: #0d0e1a; overflow: hidden; touch-action: none; }
  #game { width: 100vw; height: 100vh; }
  canvas { display: block; }
</style>
<script>
// 全局错误横幅：任何启动异常都会显示在屏幕左下角（含堆栈首行），而不是无声黑屏
window.addEventListener('error', function (e) {
  var msg = e.message || e.type;
    if (e.error && e.error.stack) {
    msg += '  << ' + String(e.error.stack).split('\\n').slice(1, 3).join(' | ').slice(0, 220);
  }
  var d = document.createElement('div');
  d.style.cssText = 'position:fixed;left:8px;bottom:8px;color:#ff6b6b;background:rgba(0,0,0,.75);padding:6px 10px;font:12px monospace;z-index:9999;max-width:96vw';
  d.textContent = msg;
  document.body.appendChild(d);
});
</script>
</head>
<body>
<div id="game"></div>
<script>${phaser}</script>
<script>${embedPreamble}</script>
<script>${bundle}</script>
</body>
</html>
`;

  fs.writeFileSync(OUTPUT, html);
  const sizeMB = (fs.statSync(OUTPUT).size / 1024 / 1024).toFixed(1);
  console.log(`打包完成: ${OUTPUT}  (${sizeMB} MB, 图片 ${Object.keys(embedImages).length} 张, 模块 ${modules.size} 个)`);
  console.log('双击用 Chrome / Edge 打开即可游玩。');
}

main().catch(err => { console.error('打包失败:', err.message); process.exit(1); });
