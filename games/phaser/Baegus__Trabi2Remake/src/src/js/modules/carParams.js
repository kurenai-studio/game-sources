// Borland Turbo Pascal Real48 Decoder
export function readPascalReal48(bytes, offset) {
	let exponent = bytes[offset];
	if (exponent === 0) return 0.0;

	let sign = (bytes[offset + 5] & 0x80) ? -1 : 1;
	let mantissa = 1.0;
	let fraction = 0.5;

	for (let bit = 6; bit >= 0; bit--) {
		if ((bytes[offset + 5] >> bit) & 1) mantissa += fraction;
		fraction /= 2;
	}
	for (let i = 4; i >= 1; i--) {
		for (let bit = 7; bit >= 0; bit--) {
			if ((bytes[offset + i] >> bit) & 1) mantissa += fraction;
			fraction /= 2;
		}
	}
	let realExponent = exponent - 129;
	return sign * mantissa * Math.pow(2, realExponent);
}

/**
 * PAR file key for a given difficulty level.
 * The original game only uses PAR1 (Easy), PAR3 (Medium), PAR5 (Hard).
 * PAR2 and PAR4 exist on disk but are never loaded by the EXE.
 */
const DIFFICULTY_PAR_MAP = ["PAR1.PAR", "PAR3.PAR", "PAR5.PAR"];

export function getParKeyForDifficulty(diff) {
	return DIFFICULTY_PAR_MAP[diff] ?? DIFFICULTY_PAR_MAP[0];
}

/**
 * Per-car-type modifier values, hardcoded in the EXE at FUN_1000_13ce.
 * R1 adjusts speed factor, R2 adjusts accel factor, R3 adjusts a third parameter.
 * Type 4 (all zeros) is the player car — modifiers cancel out.
 */
export const CAR_TYPE_MODIFIERS = [
	{ r1: 0.4,  r2: -0.006, r3: -0.004 }, // type 0
	{ r1: 0.4,  r2: -0.006, r3:  0.002 }, // type 1
	{ r1: -0.2, r2:  0.003, r3: -0.002 }, // type 2
	{ r1: 0.8,  r2: -0.012, r3:  0.006 }, // type 3
	{ r1: 0.0,  r2:  0.0,   r3:  0.0   }, // type 4 (player)
	{ r1: -0.6, r2:  0.009, r3:  0.0   }, // type 5
];

/**
 * Computes car statistics based on PAR file data, difficulty, transmission and car type.
 *
 * The original game stores typed constants in the code segment near FUN_1000_15BB:
 *   5.0 (Single), 13.0 (Single), 0.6 (Extended), 1.9 (Extended)
 * The top speed uses integer arithmetic: base + trunc(slider × 13/5 + offset).
 * The 0-60 / 0-120 times use difficulty-specific step functions.
 * For non-player cars, values are scaled by the effective R1/R2 ratios.
 *
 * @param {Uint8Array} bytes  first 12+ bytes of the PAR file for the current difficulty
 * @param {number} diff       0=Easy, 1=Medium, 2=Hard
 * @param {number} trans      0-21
 * @param {number} [carType=4] 0-5, default 4 = player (no modifier)
 * @returns {object} Parsed stats
 */
export function getTransmissionStats(bytes, diff, trans, carType = 4) {
	if (!bytes || bytes.length < 12) return null;

	let parR1 = readPascalReal48(bytes, 0);
	let parR2 = readPascalReal48(bytes, 6);

	const mod = CAR_TYPE_MODIFIERS[carType] ?? CAR_TYPE_MODIFIERS[4];
	let r1 = parR1 + (trans - 10) * mod.r1;
	let r2 = parR2 + (10 - trans) * mod.r2;

	// --- Top speed (km/h) ---
	// Constants from the EXE: 13.0/5.0 = 2.6 km/h per slider step.
	// Offset 0.6 (Easy) or 0.4 (Medium/Hard) controls integer truncation rounding.
	// Trans 14 reuses trans 13's speed. Hard trans 16 has a +1 FP precision artifact.
	const SPEED_BASES = [94, 91, 78];
	const SPEED_OFFSETS = [0.6, 0.4, 0.4];
	let effectiveTrans = (trans === 14) ? 13 : trans;
	let par1Speed = SPEED_BASES[diff] + Math.trunc(effectiveTrans * 13 / 5 + SPEED_OFFSETS[diff]);
	if (diff === 2 && trans === 16) par1Speed += 1;
	let finalSpeed = par1Speed * (r1 / parR1);

	// --- 0-60 km/h time (seconds) ---
	let par1_60;
	if (diff === 0) {
		par1_60 = 3 + Math.ceil(trans / 15);
	} else if (diff === 1) {
		par1_60 = 4 + Number(trans >= 3) + Number(trans >= 11) + Number(trans >= 16) + Number(trans >= 20);
	} else {
		if (trans === 0) par1_60 = 5;
		else if (trans < 6) par1_60 = 6;
		else if (trans < 10) par1_60 = 7;
		else if (trans < 15) par1_60 = 8;
		else par1_60 = 8 + Math.floor(((trans - 14) * 2 + 1) / 3) + Number(trans === 16);
	}

	// --- 0-120 km/h time (seconds) ---
	let par1_120;
	if (diff === 0) {
		if (trans < 15) par1_120 = 14;
		else if (trans < 17) par1_120 = 15;
		else if (trans < 20) par1_120 = 16;
		else par1_120 = 17;
	} else if (diff === 1) {
		par1_120 = 18 + Number(trans >= 13) + Number(trans >= 15) + Number(trans >= 16)
			+ Number(trans >= 18) + Number(trans >= 19) + Number(trans >= 20) + Number(trans >= 21);
	} else {
		// Hard: uses EXE constants 1.9 (Extended Real) and 0.6 (Extended Real)
		par1_120 = Math.floor(trans * 1.9 + 0.6);
	}

	// Scale by PAR ratios (cancels to 1.0 for player car type 4)
	let finalAccelTime = r2 > 0.0001 ? par1_60 * (parR2 / r2) : 999.9;
	let final120Time = r2 > 0.0001 ? par1_120 * (parR2 / r2) : 999.9;

	if (Math.round(finalSpeed) < 120) {
		final120Time = 999.9;
	}

	let speedRounded = Math.round(finalSpeed);
	let accelRounded = finalAccelTime > 100 ? null : Math.round(finalAccelTime);
	let t120Rounded = final120Time > 100 ? null : Math.round(final120Time);

	return {
		r1, r2, parR1, parR2,
		finalSpeed,
		speedRounded,
		finalAccelTime,
		accelRounded,
		final120Time,
		t120Rounded,
		maxSpeed: speedRounded,
		zeroTo60: accelRounded !== null ? accelRounded + "s" : "---",
		zeroTo120: t120Rounded !== null ? t120Rounded + "s" : "---"
	};
}
