import { expect, suite, test } from "vitest";
import { quantizePosition, quantizeNormal, quantizeAngle, quantizeSize, dequantizePosition, dequantizeAngle } from "./binformatHelpers.ts";

suite("binformat", () => {
	suite("quantizePosition", () => {
		const testCases: [number, number][] = [
			[0, 0],
			[-16, -127],
			[16, 127],
			[0.1, 1],
			[-0.1, -1],
			[17, 127],
			[-17, -127],
			[100, 127],
			[-100, -127]
		]

		testCases.forEach(([input, expected]) => {
			test(`quantizePosition(${input}) = ${expected}`, () => {
				expect(quantizePosition(input)).toBe(expected);
			});
		});

		suite("roundtrip", () => {
			const testCases: number[] = [
				0,
				-16,
				16,
				8,
				1,
			];

			testCases.forEach((input) => {
				test(`roundtrip position (${input})`, () => {
					const result = dequantizePosition(quantizePosition(input));
					const MAX_ERROR = (16 / 127) / 2;
					expect(result - input, `${result}`).toBeLessThan(MAX_ERROR);
				});
			});
		});
	});

	suite("quantizeSize", () => {
		const testCases: [number, number][] = [
			[0, 0],
			[-16, 0],
			[16, 255],
			[0.05, 1],
			[-0.1, 0],
			[17, 255],
			[100, 255],
		]

		testCases.forEach(([input, expected]) => {
			test(`quantizeSize(${input}) = ${expected}`, () => {
				expect(quantizeSize(input)).toBe(expected);
			});
		});
	});

	suite("quantizeNormal", () => {
		const testCases: [number, number][] = [
			[0, 0],
			[-1, -127],
			[1, 127],
			[1.5, 127],
			[-1.5, -127],
			[0.25, 32],
			[-0.25, -32]
		]

		testCases.forEach(([input, expected]) => {
			test(`quantizeNormal(${input}) = ${expected}`, () => {
				expect(quantizeNormal(input)).toBe(expected);
			});
		});
	});

	suite("quantizeAngle", () => {
		const testCases: [number, number][] = [
			[0, 0],
			[180, 128],
			[-180, 128],
			[90, 64],
			[-90, 192],
			[360, 0],
			[359, 255]
		]

		testCases.forEach(([input, expected]) => {
			test(`quantizeAngle(${input}) = ${expected}`, () => {
				expect(quantizeAngle(input)).toBe(expected);
			});
		});

		suite("roundtrip", () => {
			const testCases: number[] = [
				0,
				90,
				2,
				45,
				350,
				1,
			];

			testCases.forEach((input) => {
				test(`roundtrip angle (${input})`, () => {
					const result = dequantizeAngle(quantizeAngle(input));
					const MAX_ERROR = (360 / 256) / 2;
					expect(result - input, `${result}`).toBeLessThan(MAX_ERROR);
				});
			});
		});
	});
});
