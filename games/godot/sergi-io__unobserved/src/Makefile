SHELL := /bin/sh

GODOT ?= ../../Godot.app/Contents/MacOS/Godot
PROJECT_DIR := $(CURDIR)
NETWORK_PORT ?= 2456

.PHONY: typecheck test-network

typecheck:
	"$(GODOT)" --headless --log-file /private/tmp/unobserved-godot-typecheck.log --path "$(PROJECT_DIR)" --script res://scripts/typecheck.gd

test-network:
	@command -v "$(GODOT)" >/dev/null 2>&1 || { echo "Godot executable not found: $(GODOT)" >&2; exit 127; }; \
	server_pid=; \
	client_1_pid=; \
	client_2_pid=; \
	cleanup() { \
		status=$$?; \
		trap - INT TERM EXIT; \
		for pid in $$client_2_pid $$client_1_pid $$server_pid; do \
			if [ -n "$$pid" ] && kill -0 "$$pid" 2>/dev/null; then \
				kill "$$pid" 2>/dev/null || true; \
			fi; \
		done; \
		wait 2>/dev/null || true; \
		exit $$status; \
	}; \
	trap cleanup INT TERM EXIT; \
	"$(GODOT)" --headless --log-file /private/tmp/unobserved-network-server.log --path "$(PROJECT_DIR)" -- --server --port $(NETWORK_PORT) --max-players 100 & \
	server_pid=$$!; \
	sleep 2; \
	"$(GODOT)" --path "$(PROJECT_DIR)" -- --join 127.0.0.1 --port $(NETWORK_PORT) --name Player1 & \
	client_1_pid=$$!; \
	"$(GODOT)" --path "$(PROJECT_DIR)" -- --join 127.0.0.1 --port $(NETWORK_PORT) --name Player2 & \
	client_2_pid=$$!; \
	wait
