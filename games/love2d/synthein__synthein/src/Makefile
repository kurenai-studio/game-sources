synthein_version = devel
love_version = 11.4

env = SYNTHEIN_VERSION=$(synthein_version) LOVE_VERSION=$(love_version)

# Building commands
.PHONY: love
love: rust
	$(env) scripts/package-love.sh

.PHONY: run
run: rust
	love src --debug

.PHONY: appimage
appimage: love
	$(env) scripts/package-linux-appimage.sh

.PHONY: macos
macos: love
	$(env) scripts/package-macos.sh

.PHONY: windows
windows: love
	$(env) scripts/package-windows.sh

.PHONY: rust
rust:
	cargo build
	cp target/debug/libsyntheinrust.so src/syntheinrust.so

# Maintenance commands
.PHONY: check
check:
	find src -name '*.lua' -not -path 'src/vendor/*' | xargs wc -l | sort -rg
	find src -name '*.lua' -exec luac -p {} + && echo "No problems found"

.PHONY: clean
clean:
	rm -rf build/
	rm -f src/*.so

.PHONY: dep
dep:
	scripts/dependency-graph.lua --dot src/main.lua | dot -T png | display

.PHONY: data-tree
data-tree:
	dot -T png docs/data-tree.dot | display

.PHONY: task-map
task-map:
	dot -T png task-map.dot >task-map.png
	display task-map.png

.PHONY: analyze-draw-times
analyze-draw-times:
	love tools/analyze-draw-times

.PHONY: luacheck
luacheck:
	find src -name '*.lua' -not -path 'src/vendor/*' -exec luacheck --no-unused-args {} +

.PHONY: test
test:
	printf '\n' | love src --unit-tests
	test/init.sh
