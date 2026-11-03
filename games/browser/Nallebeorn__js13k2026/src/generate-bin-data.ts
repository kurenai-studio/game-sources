import { mkdir, readFile, writeFile } from "fs/promises";
import { serializeData, serializeObjects } from "./src/gamedata/binwriter.ts";
import { existsSync } from "fs";
import objectsData from "./src/gamedata/objects.ts";

const t0 = performance.now();

mkdir("public", { recursive: true });

const { objectNames, slotNames } = serializeObjects(objectsData);
await writeFileIfChanged("src/gamedata/objects.gen.ts", getNameConstants(objectNames, slotNames));

const levelData = (await import("./src/gamedata/level.ts")).default;
const { buffer, sections, dialogue } = serializeData(objectsData, levelData);

await Promise.all([
  writeFile("public/b", Buffer.from(buffer)),
  writeFileIfChanged("src/gamedata/sections.gen.ts", getSetionConstants(sections)),
  writeFileIfChanged("src/gamedata/dialogue.gen.ts", getDialogueConstants(dialogue)),
]);
const t1 = performance.now();
console.log(`[${getTimestamp()}] Regenerated binary data file: ${buffer.byteLength}B (${objectNames.length} objects)`);
console.log(`Time: ${(t1 - t0).toFixed(2)}ms`);

function getNameConstants(names: string[], slotNames: Record<string, Record<string, number>>) {
	const nameConstants = names
		.map((name, idx) => `export const obj_${name} = ${idx};`)
		.join("\n");
	const nameConstantsUnion = names.map(name => `typeof obj_${name}`).join(" | ");

	const slotNameConstants = Object.entries(slotNames)
		.flatMap(
			([object, slots]) => Object.entries(slots)
				.map(([slot, idx]) => `export const obj_${object}_${slot}Slot = ${idx};`),
	).join("\n");

	return `${nameConstants}\nexport type RenderObjectHandle = ${nameConstantsUnion};\n${slotNameConstants}`;
}

function getSetionConstants(sections: Map<string, number>) {
	return sections.entries().map(([section, offset]) =>
		`export const section_${section}End = ${offset};`
	).toArray().join("\n");
}

function getDialogueConstants(dialogue: string[]) {
	// return `export const dialogue = "${dialogue.join("|")}".split("|");`;
	return `export const dialogue = [${dialogue.map(d => `"${d}"`).join(", ")}];`;
}

function getTimestamp(): string {
	return new Date().toLocaleTimeString(
		[],
		{
			hour: "2-digit",
			minute: "2-digit",
			second: "2-digit",
			fractionalSecondDigits: 2,
		}
	);
}

async function writeFileIfChanged(file: string, contents: string) {
	if (!existsSync(file) || contents !== await readFile(file, "utf8")) {
		return writeFile(file, contents);
	}
}
