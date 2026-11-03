import { defineConfig } from 'vite';

// `BASE_PATH` is set by the GitHub Pages workflow so assets resolve under
// https://<user>.github.io/<repo>/ . Locally it defaults to '/'.
export default defineConfig( {
	base: process.env.BASE_PATH || '/',
	build: {
		target: 'es2022',
		chunkSizeWarningLimit: 2000
	},
	server: {
		host: true
	}
} );
