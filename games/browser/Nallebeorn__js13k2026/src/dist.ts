import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { rm, stat } from "node:fs/promises";
import type { Plugin } from "vite";

const execFileAsync = promisify(execFile);

export function zipDist(): Plugin {
	return {
		name: "zip-dist",

		apply: "build",

		async writeBundle() {
			await rm("dist.zip", { force: true });

			await execFileAsync(
				"advzip",
				["-a", "-4", "dist.zip", "dist/b", "dist/index.html"],
			);

			const { size } = await stat("dist.zip");

			const sizeLimit = 13312;
			const sizeKb = Math.floor(size / 1024);
			const sideBytesRemainder = size % 1024;
			const sizeLimitKb = sizeLimit / 1024;
			console.log(`\nZIP size: ${size.toLocaleString()}/${sizeLimit.toLocaleString()} bytes (${sizeKb.toLocaleString()}KB ${sideBytesRemainder}B/${sizeLimitKb}KB)`);

			const percentageUsed = size / sizeLimit * 100;
			console.log(`Used: ${percentageUsed.toLocaleString()}%`);

			const remaining = sizeLimit - size;
			const remainingKb = Math.floor(Math.abs(remaining) / 1024);
			const remainingBytesRemainder = Math.abs(remaining) % 1024;
			console.log(`Remaining: ${remaining.toLocaleString()} bytes (${remainingKb.toLocaleString()}KB ${remainingBytesRemainder}B)`)

			if (size > sizeLimit) {
				console.error("Exceeding size limit!\n");
			} else {
				console.log("All good!\n");
			}
		},
	};
}
