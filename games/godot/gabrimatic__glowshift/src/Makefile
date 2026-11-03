GODOT ?= godot
VERSION := $(shell sed -n 's/^config\/version="\(.*\)"/\1/p' project.godot)

.PHONY: run editor import test export macos windows linux web serve clean

run: ## Play from source
	$(GODOT) --path .

editor: ## Open the project in the Godot editor
	$(GODOT) --editor --path .

import:
	$(GODOT) --headless --path . --import

test: import ## Run the headless smoke test
	$(GODOT) --headless --fixed-fps 60 --path . -s res://tests/smoke_test.gd

export: macos windows linux web ## Build every platform into build/

macos: import
	mkdir -p build/macos
	$(GODOT) --headless --path . --export-release macOS build/macos/Glowshift.zip

windows: import
	mkdir -p build/windows
	$(GODOT) --headless --path . --export-release Windows build/windows/Glowshift.exe

linux: import
	mkdir -p build/linux
	$(GODOT) --headless --path . --export-release Linux build/linux/Glowshift.x86_64

web: import
	mkdir -p build/web
	$(GODOT) --headless --path . --export-release Web build/web/index.html

serve: web ## Play the web build at http://127.0.0.1:8060
	python3 -m http.server 8060 --bind 127.0.0.1 --directory build/web

clean:
	rm -rf build .godot
