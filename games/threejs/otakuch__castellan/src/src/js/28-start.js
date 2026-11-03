/* ══════════════ 18 · start ══════════════ */
applyQuality(QUALITY.detected,true);
seedNoise(land.seed);
applySeason();
shapeTerrain();
scatter();
preset();
applyCam();
makeGhost();
setSeal();
sky(hour);
onQualityChanged(true);
requestAnimationFrame(frame);

})();
