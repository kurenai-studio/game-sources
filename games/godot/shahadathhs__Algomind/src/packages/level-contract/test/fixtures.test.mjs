// @ts-check
import assert from "node:assert/strict";
import { test } from "node:test";
import {
  explainResult,
  patrolCell,
  simulate,
  simulateAll,
  solve,
  validateAuthoringLevel,
  validateLevel,
  validateProgram,
} from "../dist/index.js";
import { loadFixtures } from "./helpers.mjs";

/** @param {{ path: string, code: string }[]} issues */
const normalize = (issues) => issues.map((i) => `${i.path}|${i.code}`).sort();

const validFixtures = loadFixtures("levels/valid");
const invalidFixtures = loadFixtures("levels/invalid");
const runFixtures = loadFixtures("runs");
const solverFixtures = loadFixtures("solver");
const boardFixtures = loadFixtures("boards");
const patrolFixtures = loadFixtures("patrols");

test("the fixture suite is large enough and self-describing", () => {
  assert.ok(validFixtures.length >= 5);
  assert.ok(invalidFixtures.length >= 10);
  assert.ok(runFixtures.length >= 12);
  assert.ok(solverFixtures.length >= 8);
  for (const { name, data } of [
    ...validFixtures,
    ...invalidFixtures,
    ...runFixtures,
    ...solverFixtures,
    ...boardFixtures,
    ...patrolFixtures,
  ]) {
    assert.equal(typeof data.description, "string", `${name} needs a description`);
    assert.ok(data.description.length > 0, `${name} needs a description`);
  }
});

for (const { name, data } of validFixtures) {
  test(`valid level fixture: ${name}`, () => {
    assert.ok(data.mode === "public" || data.mode === "authoring");
    const result =
      data.mode === "authoring" ? validateAuthoringLevel(data.level) : validateLevel(data.level);
    assert.deepEqual(result.issues, []);
    assert.equal(result.ok, true);
  });
}

for (const { name, data } of invalidFixtures) {
  test(`invalid level fixture: ${name}`, () => {
    assert.ok(data.mode === "public" || data.mode === "authoring");
    assert.ok(data.expectedIssues.length > 0);
    const result =
      data.mode === "authoring" ? validateAuthoringLevel(data.level) : validateLevel(data.level);
    assert.equal(result.ok, false);
    assert.deepEqual(normalize(result.issues), normalize(data.expectedIssues));
    for (const issue of result.issues) {
      assert.equal(typeof issue.message, "string");
      assert.ok(issue.message.length > 0);
    }
  });
}

for (const { name, data } of runFixtures) {
  test(`run fixture: ${name}`, () => {
    assert.deepEqual(validateLevel(data.level).issues, []);
    assert.deepEqual(
      normalize(validateProgram(data.level, data.program).issues),
      normalize(data.programIssues),
    );
    const result = simulate(data.level, data.program);
    assert.deepEqual(result, data.expected);
    assert.equal(result.steps, result.trace.length);
    assert.equal(typeof explainResult(result), "string");
  });
}

for (const { name, data } of boardFixtures) {
  test(`boards fixture: ${name}`, () => {
    assert.deepEqual(validateLevel(data.level).issues, []);
    assert.deepEqual(
      normalize(validateProgram(data.level, data.program).issues),
      normalize(data.programIssues),
    );
    const result = simulateAll(data.level, data.program);
    const summary = {
      status: result.status,
      firstFailure: result.firstFailure,
      steps: result.steps,
      results: result.results.map((r) => ({
        status: r.status,
        reason: r.reason,
        steps: r.steps,
        finalState: r.finalState,
        blockedCell: r.blockedCell,
      })),
    };
    assert.deepEqual(summary, data.expected);
  });
}

for (const { name, data } of solverFixtures) {
  test(`solver fixture: ${name}`, () => {
    assert.deepEqual(validateLevel(data.level).issues, []);
    assert.deepEqual(solve(data.level), data.expected);
  });
}

for (const { name, data } of patrolFixtures) {
  test(`patrol fixture: ${name}`, () => {
    const cells = [];
    for (let step = 0; step < data.cells.length; step += 1) {
      cells.push(patrolCell(data.patrol, step));
    }
    assert.deepEqual(cells, data.cells);
  });
}
