#!/bin/bash

# Build script for WebAssembly version

echo "Building Space Shooter for WebAssembly..."

# Set environment for WASM
export GOOS=js
export GOARCH=wasm

# Build the game
go build -o web/game.wasm cmd/game/main.go

# Copy wasm_exec.js from Go installation
cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" web/

echo "Build complete!"
echo "Files generated in web/ directory:"
echo "  - game.wasm"
echo "  - wasm_exec.js"
echo "  - index.html"
echo ""
echo "To run locally:"
echo "  cd web && python3 -m http.server 8080"
echo "  Then open: http://localhost:8080"
