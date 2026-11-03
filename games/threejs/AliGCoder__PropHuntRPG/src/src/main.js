import { App } from './App.js';

const app = new App( {
	viewport: document.getElementById( 'viewport' ),
	ui: document.getElementById( 'ui' )
} );

app.start().catch( ( err ) => {

	console.error( err );
	document.getElementById( 'ui' ).innerHTML = `
		<div class="overlay"><div class="panel modal">
			<h2>Couldn't start the renderer</h2>
			<p class="muted">PropHunt RPG needs a browser with WebGPU or WebGL 2 (latest Chrome, Edge, Firefox or Safari).</p>
			<pre style="white-space:pre-wrap;font-size:12px;opacity:.7">${String( err?.message ?? err ).replace( /</g, '&lt;' )}</pre>
		</div></div>`;

} );
