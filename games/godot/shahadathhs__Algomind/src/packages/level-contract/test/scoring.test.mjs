// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import { DEFAULT_POINTS_RULES, scoreResult } from "../dist/index.js";
import { loadFixtures } from "./helpers.mjs";

const fixtures = loadFixtures("scoring");

test("the scoring fixtures exist and describe themselves", () => {
  assert.ok(fixtures.length >= 8);
  for (const { name, data } of fixtures) {
    assert.equal(typeof data.description, "string", `${name} needs a description`);
  }
});

for (const { name, data } of fixtures) {
  test(`scoring fixture: ${name}`, () => {
    assert.deepEqual(scoreResult(data.rules, data.input), data.expected);
  });
}

test("the default rules are version 1 and match the fixtures' rules", () => {
  assert.equal(DEFAULT_POINTS_RULES.version, 1);
  for (const { data } of fixtures) assert.deepEqual(data.rules, DEFAULT_POINTS_RULES);
});

test("a better result never scores less", () => {
  const input = { difficulty: /** @type {"easy"} */ ("easy"), par: { commands: 5, steps: 8 } };
  let previous = Infinity;
  for (let slots = 5; slots <= 14; slots += 1) {
    for (const steps of [8, 20]) {
      const { points } = scoreResult(DEFAULT_POINTS_RULES, { ...input, slots, steps });
      if (steps === 8) {
        assert.ok(points <= previous, `slots ${slots}`);
        previous = points;
      }
    }
  }
});
