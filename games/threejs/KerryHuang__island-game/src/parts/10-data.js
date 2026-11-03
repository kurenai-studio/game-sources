// ================= DATA：城市、島、議題牽連、時段（虛構）；議題本身在 data/issues.json =================
const DATA = {
  city: { name: '今日', en: 'Today', subtitle: '群島', subtitleEn: 'Isles' },
  islands: [
    { id: 'traffic', no: '01', name: '交通', en: 'Transit', q: 0, r: 0, ground: 'stripe', tree: 'round', band: '#db6a41',
      summary: '大眾運輸、道路安全與通勤，每天出門都會碰到。', summaryEn: 'Transit, road safety and the daily commute.' },
    { id: 'care', no: '02', name: '托育', en: 'Childcare', q: 1, r: 0, ground: 'speckle', tree: 'cherry', band: '#f2b5c6',
      summary: '托嬰、幼兒園與育兒補助，關於怎麼把孩子帶大。', summaryEn: 'Daycare, preschool and support for young families.' },
    { id: 'edu', no: '03', name: '教育', en: 'Education', q: -1, r: 0, ground: 'brick', tree: 'cone', band: '#6f7fb5',
      summary: '校園、課程與升學，從國小到高中。', summaryEn: 'Schools, curriculum and the road to graduation.' },
    { id: 'elder', no: '04', name: '長照', en: 'Elder care', q: 0, r: 1, ground: 'speckle', tree: 'willow', band: '#58a6a6',
      summary: '長照服務、高齡生活與家庭照顧者。', summaryEn: 'Long-term care, ageing and family caregivers.' },
    { id: 'sport', no: '05', name: '運動', en: 'Sports', q: -1, r: 1, ground: 'stripe', tree: 'cone', band: '#fcea8b',
      summary: '運動場館、賽事與全民運動。', summaryEn: 'Venues, events and everyday exercise.' },
    { id: 'green', no: '06', name: '綠地', en: 'Parks', q: 1, r: -1, ground: 'speckle', tree: 'fruit', band: '#9cc27a',
      summary: '公園、行道樹與城市怎麼面對高溫和暴雨。', summaryEn: 'Parks, street trees and a city facing heat and storms.' },
    { id: 'culture', no: '07', name: '文化', en: 'Culture', q: 2, r: -1, ground: 'brick', tree: 'cherry', band: '#db6a41',
      summary: '圖書館、藝文活動與老建築。', summaryEn: 'Libraries, the arts and old buildings.' },
    { id: 'youth', no: '08', name: '青年', en: 'Youth', q: 0, r: -1, ground: 'stripe', tree: 'palm', band: '#f2b5c6',
      summary: '工作、薪水與租屋，年輕人怎麼在城市站穩。', summaryEn: 'Jobs, pay and rent for young people.' },
    { id: 'digital', no: '09', name: '數位', en: 'Digital', q: 1, r: 1, ground: 'brick', tree: 'cone', band: '#58a6a6',
      summary: '數位服務、資安與 AI 進入日常。', summaryEn: 'Digital services, security and AI in daily life.' },
    { id: 'safety', no: '10', name: '安全', en: 'Safety', q: 2, r: 0, ground: 'speckle', tree: 'round', band: '#6f7fb5',
      summary: '防災、治安與詐騙。', summaryEn: 'Disaster readiness, crime and scams.' },
    { id: 'eco', no: '11', name: '環保', en: 'Environment', q: -2, r: 1, ground: 'stripe', tree: 'fruit', band: '#71806a',
      summary: '垃圾、回收、空氣與能源。', summaryEn: 'Waste, recycling, air and energy.' },
    { id: 'tour', no: '12', name: '觀光', en: 'Tourism', q: -1, r: 2, ground: 'brick', tree: 'palm', band: '#fcea8b',
      summary: '觀光、夜市與來訪的旅客。', summaryEn: 'Tourism, night markets and visitors.' },
  ],
  // 議題牽連：evidence = official 直接牽動（實線）/ thematic 間接相關（虛線）/ pending 有人提出（點線）
  flows: [
    { id: 'f1', from: 'edu', to: 'culture', cargo: 'book', role: 'student', evidence: 'official', label: '圖書館與課後學習', en: 'Libraries and after-school learning', count: 8 },
    { id: 'f2', from: 'eco', to: 'edu', cargo: 'meal', role: 'farmer', evidence: 'official', label: '食農與校園午餐', en: 'Food education and school lunch', count: 6 },
    { id: 'f3', from: 'green', to: 'eco', cargo: 'sapling', role: 'worker', evidence: 'thematic', label: '綠地與減碳', en: 'Green space and carbon cuts', count: 6 },
    { id: 'f4', from: 'elder', to: 'traffic', cargo: 'medkit', role: 'elder', evidence: 'official', label: '高齡者怎麼出門', en: 'Getting around in old age', count: 7 },
    { id: 'f5', from: 'care', to: 'elder', cargo: 'meal', role: 'parent', evidence: 'thematic', label: '上有老下有小', en: 'Caring for kids and parents at once', count: 6 },
    { id: 'f6', from: 'digital', to: 'elder', cargo: 'laptop', role: 'researcher', evidence: 'pending', label: '長輩的數位落差', en: 'The digital gap for elders', count: 5 },
    { id: 'f7', from: 'youth', to: 'tour', cargo: 'ticket', role: 'tourist', evidence: 'thematic', label: '觀光業的青年工作', en: 'Young workers in tourism', count: 8 },
    { id: 'f8', from: 'traffic', to: 'sport', cargo: 'ball', role: 'commuter', evidence: 'official', label: '去球場的路', en: 'Getting to the courts', count: 6 },
    { id: 'f9', from: 'safety', to: 'youth', cargo: 'letter', role: 'civil', evidence: 'pending', label: '詐騙盯上年輕人', en: 'Scams targeting the young', count: 5 },
  ],
  // 一天時段：start 為分鐘；lit 是該時段亮起的模型種類
  dayCycle: [
    { start: 0, name: '深夜', en: 'Late night', lit: ['hall', 'clock'] },
    { start: 360, name: '清晨', en: 'Dawn', lit: ['court', 'clinic', 'farm', 'house'] },
    { start: 450, name: '上學通勤', en: 'Morning rush', lit: ['busstop', 'bikes', 'classroom'] },
    { start: 720, name: '午餐', en: 'Lunch', lit: ['booth', 'farm', 'coin'] },
    { start: 960, name: '放學', en: 'After school', lit: ['classroom', 'book', 'court'] },
    { start: 1065, name: '黃昏', en: 'Dusk', lit: ['busstop', 'river', 'bikes'] },
    { start: 1140, name: '晚上', en: 'Evening', lit: ['stage', 'book', 'globe'] },
  ],
};

// 每座島的議題依熱度排，同熱度新的在前；排第一的佔主位
const sortIssues = (list) => [...list].sort((a, b) => b.heat - a.heat || b.updated.localeCompare(a.updated));
DATA.islands.forEach((d) => { d.items = sortIssues(ISSUES[d.id] || []); });
