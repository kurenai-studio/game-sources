if(!THREE) throw new Error('three.js unavailable');
(function(){
"use strict";
const MODERN=!!THREE.SRGBColorSpace;      // r152+ colour management and physical lights

