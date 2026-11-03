// Copies Three.js next to index.html so the game works fully offline.
const fs = require('fs'), path = require('path');
try {
  fs.copyFileSync(path.join(__dirname, 'node_modules', 'three', 'build', 'three.min.js'), path.join(__dirname, 'three.min.js'));
  console.log('three.min.js copied');
} catch (e) { console.error('Could not copy three.min.js:', e.message); process.exit(1); }
