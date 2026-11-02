LOVE ?= love
APP_NAME := divadelni-utopie
GAME_TITLE := Divadelni utopie
BUILD_DIR := build
WEB_DIR := ew
LOVE_FILE := $(BUILD_DIR)/$(APP_NAME).love
LOVEJS ?= npx love.js
LOVEJS_MEMORY ?= 67108864
LOVEJS_FLAGS ?= -c -m $(LOVEJS_MEMORY)

.PHONY: run love web clean check

run:
	$(LOVE) .

love:
	mkdir -p $(BUILD_DIR)
	rm -f $(LOVE_FILE)
	zip -9 -r $(LOVE_FILE) . \
		-x "*.git*" \
		-x "$(BUILD_DIR)/*" \
		-x "dist/*" \
		-x "ew/*" \
		-x "web/*" \
		-x ".agents/*" \
		-x ".codex" \
		-x ".codex/*" \
		-x "backend/*"

web: love
	$(LOVEJS) $(LOVEJS_FLAGS) -t "$(GAME_TITLE)" $(LOVE_FILE) $(WEB_DIR)
	cp datasets/base/images/mimi.png $(WEB_DIR)/favicon.ico
	cp web/score-bridge.js $(WEB_DIR)/score-bridge.js
	perl -0pi -e 's#<script type="text/javascript" src="game.js"></script>#<script type="text/javascript" src="score-bridge.js"></script>\n    <script type="text/javascript" src="game.js"></script>#' $(WEB_DIR)/index.html
	perl -0pi -e 's#Love[(]Module[)];#Love(Module); if (window.DivadelniScoreBridge) window.DivadelniScoreBridge.start(Module);#' $(WEB_DIR)/index.html
	perl -0pi -e 's#Module\["FS_unlink"\]=FS[.]unlink;#Module["FS_unlink"]=FS.unlink;Module["FS_readFile"]=FS.readFile;Module["FS_writeFile"]=FS.writeFile;Module["FS_analyzePath"]=FS.analyzePath;Module["FS_syncfs"]=FS.syncfs;#' $(WEB_DIR)/love.js

clean:
	rm -rf $(BUILD_DIR) $(WEB_DIR)

check:
	find . -name '*.lua' ! -path './.git/*' ! -path './build/*' -print | sort | while read -r file; do \
		luac -p "$$file"; \
	done
	lua scripts/check_data.lua
	for file in tests/*_spec.lua; do \
		lua "$$file"; \
	done
	if command -v php >/dev/null 2>&1; then \
		find backend -name '*.php' -print | sort | while read -r file; do \
			php -l "$$file" >/dev/null; \
		done; \
	fi
