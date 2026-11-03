export const DEBUG = import.meta.env.DEV;

let debugDiv: HTMLElement;

if (DEBUG) {
	debugDiv = document.body.appendChild(document.createElement("div"));
	debugDiv.classList.add("debug");
	const style = document.body.appendChild(document.createElement("style"));
	style.innerText = /*css*/`
		.debug {
			grid-area: unset;
			padding: 4px 0;
			max-width: 640px;
			color: yellow;
			font-family: monospace;
			display: flex;
			column-rule: 1px solid yellow;
			gap: 16px;
			row-gap: 4px;
			flex-wrap: wrap;
		}
	`;
}

const watches: Record<string, any> = {}

export function debugWatch(key: string, value: any) {
	if (DEBUG) {
		if (typeof value === "number") {
			watches[key] = value.toFixed(2);
		} else {
			watches[key] = value;
		}
		debugDiv.innerHTML = Object.entries(watches).map(([k, v]) => /*html*/`<span>${k}: ${v}</span>`).join("");
	}
}
