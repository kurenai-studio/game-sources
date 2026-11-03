import { expect, suite, test } from "vitest";
import { average, ringPush } from "./util.ts";

suite("util", () => {
	suite("average", () => {
		const testCases: [number[], number][] = [
			[[1, 1, 1], 1],
			[[-1, 1], 0],
			[[0, 50], 25],
			[[0.1, 0.1, 0.09, 0.11], 0.1]
		];

		testCases.forEach(([input, expected]) => {
			test(`average(${input}) = ${expected}`, () => {
				expect(average(input)).toBe(expected);
			});
		});
	});

	suite("ringPush", () => {
		const testCases: [string[], string, number, string[]][] = [
			[[], "a", 1, ["a"]],
			[["a", "b", "c"], "d", 3, ["b", "c", "d"]],
		]

		testCases.forEach(([array, value, size, expected]) => {
			test(`ringPush([${array}], ${value}, ${size}) => [${expected}]`, () => {
				ringPush(array, value, size)
				expect(array).toEqual(expected);
			})
		});
	});
});
