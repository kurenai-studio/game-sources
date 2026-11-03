import { defineConfig } from "vite";
import glsl from "vite-plugin-glsl";
import { zipDist } from "./dist.ts";
import { resolve } from "path";
import { viteSingleFile } from "vite-plugin-singlefile";

export default defineConfig({
	base: "",
	server: {
    host: true,
		allowedHosts: ["nalle.local"]
	},
	build: {
		modulePreload: {
			polyfill: false,
		},
		assetsDir: ".",
		minify: "terser",
		terserOptions: {
			ecma: 2020,
			mangle: {
				properties: {
					reserved: [
						"Space",
						"KeyW",
						"KeyA",
						"KeyS",
						"KeyD",
						"success", // Wavedash (leaderboard response)
						"data", // Wavedash (leaderboard response)
					],
				},
				module: true,
				toplevel: true,
			},
			module: true,
			toplevel: true,
			compress: {
				pure_funcs: ["performance.now"],
				passes: 3,
				unsafe: true,
				unsafe_math: true,
				unsafe_arrows: true,
				unsafe_methods: true,
				toplevel: true,
			},
		},
	},
	plugins: [
		glsl({minify: true}),
		viteSingleFile(),
		zipDist(),
		{
			name: "strip-html",

			transformIndexHtml(html) {
				return html
					.replaceAll(" crossorigin", "")
					.replaceAll(/^\s*/gm, "")
					.replaceAll("\n", "")
					;
			}
		},
		{
			name: "generate-binary",

			buildStart() {
				this.addWatchFile(resolve("public/b"));
			},

			handleHotUpdate({ file, server }) {
				if (file === resolve("public/b")) {
					server.ws.send({type: "full-reload"})
				}
			}
		},
	],
});
