// Fotomodus: het spel staat stil, de camera is vrij, met lenshoek, belichting en filters.
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

// Kleurmatrix (rij voor rij) en vignet per filter.
const FILTERS = {
  geen: [[1, 0, 0, 0, 1, 0, 0, 0, 1], 0],
  'zwart-wit': [[0.299, 0.587, 0.114, 0.299, 0.587, 0.114, 0.299, 0.587, 0.114], 0.25],
  sepia: [[0.393, 0.769, 0.189, 0.349, 0.686, 0.168, 0.272, 0.534, 0.131], 0.35],
  warm: [[1.12, 0, 0, 0, 1, 0, 0, 0, 0.84], 0.15],
  koel: [[0.88, 0, 0, 0, 1, 0, 0, 0, 1.16], 0.15],
  vintage: [[0.9, 0.15, 0.05, 0.1, 0.85, 0.05, 0.1, 0.2, 0.62], 0.7],
};

// Laatste pass van de composer: voorbeeld en opgeslagen foto zijn zo altijd gelijk.
export const filterShader = {
  uniforms: { tDiffuse: { value: null }, uM: { value: new THREE.Matrix3() }, uVignet: { value: 0 } },
  vertexShader: 'varying vec2 vUv; void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }',
  fragmentShader: `uniform sampler2D tDiffuse; uniform mat3 uM; uniform float uVignet; varying vec2 vUv;
    void main() { vec4 c = texture2D(tDiffuse, vUv);
      gl_FragColor = vec4(clamp(uM * c.rgb, 0.0, 1.0) * (1.0 - uVignet * smoothstep(0.35, 0.85, length(vUv - 0.5))), 1.0); }`,
};

// ui: de elementen van het fotopaneel. render() tekent één beeld, focus() geeft het punt om omheen te draaien,
// belichting() de basisbelichting van dit moment van de dag.
export function createPhoto({ renderer, camera, canvas, pass, ui, render, focus, belichting }) {
  const controls = new OrbitControls(camera, canvas);
  controls.enabled = false;
  controls.enableDamping = true;
  controls.maxPolarAngle = Math.PI / 2 - 0.03; // niet onder de grond
  controls.minDistance = 0.6;
  controls.maxDistance = 40;
  const foto = { aan: false, update: () => foto.aan && controls.update() };
  let terug = null;

  for (const naam in FILTERS) ui.filter.add(new Option(naam[0].toUpperCase() + naam.slice(1), naam));
  function pasToe() {
    const mm = +ui.lens.value;
    camera.fov = THREE.MathUtils.radToDeg(2 * Math.atan(12 / mm)); // kleinbeeld, 24 mm hoog
    camera.updateProjectionMatrix();
    ui.lensUit.textContent = `${mm} mm`;
    renderer.toneMappingExposure = belichting() * 2 ** +ui.belichting.value;
    ui.belichtingUit.textContent = `${+ui.belichting.value > 0 ? '+' : ''}${(+ui.belichting.value).toFixed(1)} EV`;
    const [m, vignet] = FILTERS[ui.filter.value];
    pass.uniforms.uM.value.set(...m);
    pass.uniforms.uVignet.value = vignet;
  }
  for (const el of [ui.lens, ui.belichting, ui.filter]) el.addEventListener('input', pasToe);

  foto.zet = (aan) => {
    foto.aan = controls.enabled = aan;
    document.body.classList.toggle('foto', aan);
    if (aan) {
      terug = { pos: camera.position.clone(), quat: camera.quaternion.clone(), fov: camera.fov };
      controls.target.copy(focus());
      pasToe();
    } else {
      camera.position.copy(terug.pos);
      camera.quaternion.copy(terug.quat);
      camera.fov = terug.fov;
      camera.updateProjectionMatrix();
      pass.uniforms.uM.value.identity();
      pass.uniforms.uVignet.value = 0;
    }
  };

  ui.sluiter.addEventListener('click', () => {
    render(); // toBlob moet in dezelfde beurt als het tekenen, anders is de buffer al leeg
    canvas.toBlob((blob) => {
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = `spot-${new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-')}.png`;
      a.click();
      setTimeout(() => URL.revokeObjectURL(a.href), 5000);
    }, 'image/png');
    ui.flits.classList.remove('aan');
    void ui.flits.offsetWidth; // herstart de animatie
    ui.flits.classList.add('aan');
  });
  return foto;
}
