// Shell fur: de vorm wordt in laagjes langs de normaal herhaald, en elk laagje laat alleen
// de haren door die zo lang zijn. Gebruikt voor de vacht van de honden en het vilt van de bal.
import * as THREE from 'three';

const HASH = `float furHash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float furRuis(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
  return mix(mix(furHash(i), furHash(i + vec2(1, 0)), f.x), mix(furHash(i + vec2(0, 1)), furHash(i + vec2(1, 1)), f.x), f.y); }`;

// maat: [omtrek, lengte] van de vorm in meters, zodat de haardichtheid overal gelijk is.
// wortel: hoe donker de vacht bij de huid is (schaduw tussen de haren).
export function furMesh(geometry, { kleur, glans = 0x000000, lengte, cel, lagen, maat, map = null, ruw = 0.55, hang = 0.3, wortel = 0.3 }) {
  const basis = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ color: kleur, map, roughness: 0.9 }));
  basis.material.color.multiplyScalar(wortel + 0.15); // de huid onder de vacht ligt in de schaduw
  basis.castShadow = true;

  const mat = new THREE.MeshPhysicalMaterial({
    color: kleur, map, roughness: ruw,
    sheen: glans ? 0.3 : 0, sheenColor: glans, sheenRoughness: 0.5, envMapIntensity: 0.45,
    anisotropy: glans ? 0.6 : 0, anisotropyRotation: Math.PI / 2, // glans langgerekt dwars op de haarrichting
  });
  mat.defines.USE_UV = '';
  mat.onBeforeCompile = (sh) => {
    sh.uniforms.furLen = { value: lengte };
    sh.uniforms.furLagen = { value: lagen };
    sh.uniforms.furHang = { value: hang };
    sh.uniforms.furWortel = { value: wortel };
    sh.uniforms.furCel = { value: new THREE.Vector2(maat[0] / cel, maat[1] / cel) };
    sh.vertexShader = sh.vertexShader
      .replace('#include <common>', '#include <common>\nuniform float furLen, furLagen, furHang;\nvarying float vLaag;')
      .replace('#include <begin_vertex>', `#include <begin_vertex>
        vLaag = (float(gl_InstanceID) + 1.0) / furLagen;
        transformed += normalize(objectNormal) * furLen * vLaag;
        transformed.y -= furLen * furHang * vLaag * vLaag;`);
    sh.fragmentShader = sh.fragmentShader
      .replace('#include <common>', `#include <common>\nuniform vec2 furCel;\nuniform float furWortel;\nvarying float vLaag;\n${HASH}`)
      .replace('#include <map_fragment>', `#include <map_fragment>
        vec2 fuv = vUv * furCel;
        vec2 cel = floor(fuv);
        float lang = 0.45 + 0.55 * furHash(cel); // elke cel heeft een haar, de lengte wisselt
        vec2 mid = 0.5 + 0.3 * (vec2(furHash(cel + 7.3), furHash(cel + 3.1)) - 0.5);
        float haar = step(vLaag, lang) * step(length(fract(fuv) - mid), 0.75 * (1.0 - 0.8 * vLaag / lang)); // taps
        // Ver weg zijn haren kleiner dan een pixel: dan een dichte laag, anders gaat het flikkeren.
        float ver = smoothstep(0.6, 1.4, max(fwidth(fuv.x), fwidth(fuv.y)));
        if (mix(haar, step(vLaag, 0.45), ver) < 0.5) discard;
        // Plukken en strepen in de haarrichting, zodat de vacht ook van een afstand geen glad plastic is.
        float pluk = 0.72 + 0.4 * furRuis(fuv * vec2(0.5, 0.04)) + 0.2 * furRuis(fuv * 0.1);
        diffuseColor.rgb *= mix(furWortel, 1.0, vLaag) * pluk;`);
  };
  const vacht = new THREE.InstancedMesh(geometry, mat, lagen);
  vacht.receiveShadow = true;

  const g = new THREE.Group();
  g.add(basis, vacht);
  return g;
}
