// @ts-check
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";
import {
  COMMAND_NAMES,
  DIFFICULTIES,
  DIRECTIONS,
  ID_PATTERN,
  LIMITS,
  MECHANIC_PATTERN,
  SCHEMA_VERSION,
} from "../dist/index.js";
import { loadFixtures, packageRoot } from "./helpers.mjs";

/** @param {string} f */
const readSchema = (f) => JSON.parse(readFileSync(join(packageRoot, "schema", f), "utf8"));
const pub = readSchema("level.v1.schema.json");
const authoring = readSchema("level-authoring.v1.schema.json");
const body = pub.$defs.levelBody;
const props = body.properties;

test("the JSON Schema limits match the constants used by the validator", () => {
  assert.equal(props.schemaVersion.const, SCHEMA_VERSION);
  assert.deepEqual(
    [props.levelVersion.minimum, props.levelVersion.maximum],
    [LIMITS.levelVersion.min, LIMITS.levelVersion.max],
  );
  assert.deepEqual(
    [props.title.minLength, props.title.maxLength],
    [LIMITS.title.min, LIMITS.title.max],
  );
  assert.deepEqual(
    [props.description.minLength, props.description.maxLength],
    [LIMITS.description.min, LIMITS.description.max],
  );
  assert.deepEqual(props.difficulty.enum, DIFFICULTIES);
  assert.equal(props.requires.properties.mechanics.maxItems, LIMITS.mechanics.maxCount);
  assert.deepEqual(
    [
      props.requires.properties.mechanics.items.minLength,
      props.requires.properties.mechanics.items.maxLength,
    ],
    [LIMITS.mechanics.itemLength.min, LIMITS.mechanics.itemLength.max],
  );
  assert.equal(props.requires.properties.mechanics.items.pattern, MECHANIC_PATTERN);
  for (const side of ["width", "height"]) {
    assert.deepEqual(
      [props.board.properties[side].minimum, props.board.properties[side].maximum],
      [LIMITS.boardSide.min, LIMITS.boardSide.max],
    );
  }
  assert.equal(props.board.properties.walls.maxItems, LIMITS.maxWalls);
  assert.deepEqual(props.availableCommands.items, { $ref: "#/$defs/commandName" });
  assert.deepEqual(pub.$defs.commandName.enum, COMMAND_NAMES);
  assert.deepEqual(pub.$defs.direction.enum, DIRECTIONS);
  assert.equal(props.availableCommands.maxItems, COMMAND_NAMES.length);
  assert.deepEqual(
    [
      props.constraints.properties.maxCommands.minimum,
      props.constraints.properties.maxCommands.maximum,
    ],
    [LIMITS.maxCommands.min, LIMITS.maxCommands.max],
  );
  assert.deepEqual(
    [props.constraints.properties.maxSteps.minimum, props.constraints.properties.maxSteps.maximum],
    [LIMITS.maxSteps.min, LIMITS.maxSteps.max],
  );
  assert.equal(props.hints.maxItems, LIMITS.hints.maxCount);
  assert.deepEqual(
    [props.hints.items.minLength, props.hints.items.maxLength],
    [LIMITS.hints.itemLength.min, LIMITS.hints.itemLength.max],
  );
  assert.equal(pub.$defs.id.pattern, ID_PATTERN);
  assert.equal(pub.$defs.id.maxLength, LIMITS.levelId.max);
  assert.equal(LIMITS.levelId.max, LIMITS.slug.max);
});

test("the schema requires every field of the Level type, and the authoring schema adds only referenceSolution", () => {
  const first = loadFixtures("levels/valid").find((f) => f.name === "typical-first-steps");
  assert.deepEqual([...body.required].sort(), Object.keys(first?.data.level).sort());
  // belts, deliveries, extraBoards, ice, locks, patrols and startProgram are the optional properties: a level without test
  // boards, keys, patrols or a starting program leaves them out.
  assert.deepEqual(
    Object.keys(props).sort(),
    [
      ...body.required,
      "belts",
      "deliveries",
      "extraBoards",
      "ice",
      "locks",
      "patrols",
      "startProgram",
      "switches",
      "teleports",
    ].sort(),
  );
  assert.equal(pub.unevaluatedProperties, false);
  assert.equal(authoring.unevaluatedProperties, false);
  assert.deepEqual(authoring.required, ["referenceSolution"]);
  assert.deepEqual(Object.keys(authoring.properties), ["referenceSolution"]);
  assert.deepEqual(authoring.allOf, [{ $ref: "level.v1.schema.json#/$defs/levelBody" }]);
});

test("a public level has no sortOrder or referenceSolution property", () => {
  assert.equal("sortOrder" in props, false);
  assert.equal("referenceSolution" in props, false);
});
