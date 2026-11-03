
// ================= 收尾：手機 bottom sheet、說明、reduced-motion、雙語 =================
const HELP_KEY = 'policyIsland.helpSeen.v1';
function openHelp() { $('help').hidden = false; $('helpGo').focus(); }
function closeHelp() {
  if ($('help').hidden) return false;
  $('help').hidden = true; store.set(HELP_KEY, '1'); return true;
}

// 手機：卡片與側欄變 bottom sheet，可拖曳撐滿全螢幕或往下關閉
function makeSheet(panel, onClose) {
  const h = document.createElement('div');
  h.className = 'handle'; h.setAttribute('aria-hidden', 'true');
  panel.prepend(h);
  let y0 = 0, h0 = 0, dragging = false;
  h.addEventListener('pointerdown', (e) => {
    dragging = true; y0 = e.clientY; h0 = panel.getBoundingClientRect().height;
    panel.classList.add('dragging');
    try { h.setPointerCapture(e.pointerId); } catch (err) { /* 非作用中的 pointer 無法 capture，拖曳仍可運作 */ }
  });
  h.addEventListener('pointermove', (e) => { if (dragging) panel.style.height = clamp(h0 + y0 - e.clientY, 80, innerHeight) + 'px'; });
  const end = (e) => {
    if (!dragging) return;
    dragging = false; panel.classList.remove('dragging');
    const hh = h0 + y0 - e.clientY, H = innerHeight;
    panel.style.height = '';
    if (hh > H * .7) panel.classList.add('full');
    else if (hh < H * .18) { panel.classList.remove('full'); onClose(); }
    else panel.classList.remove('full');
  };
  h.addEventListener('pointerup', end); h.addEventListener('pointercancel', end);
}

function onCardOpen() { if (!isDesktop()) setSideOpen(false); }
function onCardClose() { $('card').classList.remove('full'); }

function refreshLang() {
  readLang(); applyStaticLang();
  S.islands.forEach((isl) => { isl.labelEl.innerHTML = `<b>${isl.data.no}</b><span>${esc(isleName(isl))}</span>`; });
  renderSide(); updateClockUI();
  $('logFilter').innerHTML = `<option value="">${tr('全部牽連線', 'All links')}</option>` + DATA.flows.map((f) => `<option value="${f.id}">${esc(flowName(f))}</option>`).join('');
  if (!$('log').hidden) renderLog();
  if (S.sel) openCard(S.sel);
  $('langBtn').textContent = LANG === 'en' ? '中文' : 'EN';
  S.renderer.domElement.setAttribute('aria-label', tr('3D 議題城市，方向鍵旋轉鏡頭', '3D issue city, arrow keys rotate'));
  markDirty();
}

function afterBoot() {
  // 語言切換鈕：寫入 #en（artifact 只傳 hash）
  const lb = document.createElement('button');
  lb.className = 'btn'; lb.id = 'langBtn'; lb.type = 'button';
  lb.textContent = LANG === 'en' ? '中文' : 'EN';
  lb.addEventListener('click', () => {
    if (LANG === 'en') { history.replaceState(null, '', location.pathname + location.search); refreshLang(); }
    else location.hash = 'en';
  });
  $('brand').appendChild(lb);
  addEventListener('hashchange', refreshLang);

  // 手機：HUD 收進「◷ 時間」
  const tb = document.createElement('button');
  tb.className = 'btn'; tb.id = 'bTime'; tb.type = 'button'; tb.setAttribute('aria-pressed', 'false');
  tb.innerHTML = `<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/></svg><span data-en="Time">時間</span>`;
  tb.addEventListener('click', () => {
    const open = !$('timeGroup').classList.contains('open');
    $('timeGroup').classList.toggle('open', open); tb.setAttribute('aria-pressed', String(open));
  });
  $('hud').prepend(tb);
  document.querySelectorAll('#hud [data-min]').forEach((b) => b.addEventListener('click', () => {
    $('timeGroup').classList.remove('open'); tb.setAttribute('aria-pressed', 'false');
  }));
  applyStaticLang();

  makeSheet($('card'), clearSelection);
  makeSheet($('side'), () => setSideOpen(false));

  $('bHelp').addEventListener('click', openHelp);
  $('helpGo').addEventListener('click', closeHelp);
  $('help').addEventListener('click', (e) => { if (e.target === $('help')) closeHelp(); });
  if (!store.get(HELP_KEY)) openHelp();

  // prefers-reduced-motion：即時切換
  const mq = matchMedia('(prefers-reduced-motion: reduce)');
  const onMq = () => { S.reduced = mq.matches; if (S.reduced) S.fly = null; markDirty(); };
  if (mq.addEventListener) mq.addEventListener('change', onMq); else mq.addListener(onMq);
}
