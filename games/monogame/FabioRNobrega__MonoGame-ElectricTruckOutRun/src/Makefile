SHELL := /bin/sh

SOLUTION := ElectricTruckOutRun.sln
PROJECT := src/ElectricTruckOutRun.Game/ElectricTruckOutRun.Game.csproj
COMPOSE := docker compose
LOCAL_UID := $(shell id -u)
LOCAL_GID := $(shell id -g)
COMPOSE_ENV := LOCAL_UID=$(LOCAL_UID) LOCAL_GID=$(LOCAL_GID)
RUN := $(COMPOSE_ENV) $(COMPOSE) run --rm --build dev
RUN_PORTS := $(COMPOSE_ENV) $(COMPOSE) run --rm --build --service-ports dev

.DEFAULT_GOAL := help

.PHONY: help docker-game-build docker-run docker-publish-game docker-publish-game-linux \
	docker-publish-game-windows docker-publish-game-macos docker-publish-game-macos-arm64 \
	docker-publish-game-macos-x64 docker-test docker-clean docker-shell docker-restore \
	docker-watch docker-format docker-format-check docker-build

help:
	@echo "MonoGame Docker development commands:"
	@echo "  make docker-game-build           Build the game"
	@echo "  make docker-run                  Run through noVNC on http://localhost:6080"
	@echo "  make docker-watch                Restart the game when source files change"
	@echo "  make docker-restore              Restore NuGet packages and local tools"
	@echo "  make docker-test                 Run the Core xUnit test project"
	@echo "  make docker-format               Format C# source"
	@echo "  make docker-format-check         Verify C# formatting"
	@echo "  make docker-publish-game         Publish Linux, Windows, and both macOS builds"
	@echo "  make docker-publish-game-linux   Publish linux-x64"
	@echo "  make docker-publish-game-windows Publish win-x64"
	@echo "  make docker-publish-game-macos   Publish osx-arm64 and osx-x64"
	@echo "  make docker-shell                Open a development shell"
	@echo "  make docker-clean                Remove build and publish output"

docker-build:
	$(COMPOSE_ENV) $(COMPOSE) build

docker-restore:
	$(RUN) sh -lc "dotnet tool restore --tool-manifest .config/dotnet-tools.json && dotnet restore $(SOLUTION)"

docker-game-build:
	$(RUN) dotnet build $(SOLUTION) --configuration Debug

docker-run:
	$(RUN_PORTS) ./scripts/run-game.sh

docker-watch:
	$(RUN_PORTS) ./scripts/run-game.sh dotnet watch --project $(PROJECT) run

docker-test:
	$(RUN) dotnet test $(SOLUTION) --configuration Debug

docker-format:
	$(RUN) dotnet format $(SOLUTION)

docker-format-check:
	$(RUN) dotnet format $(SOLUTION) --verify-no-changes

docker-publish-game: docker-publish-game-linux docker-publish-game-windows docker-publish-game-macos

docker-publish-game-linux:
	$(RUN) dotnet publish $(PROJECT) --configuration Release --runtime linux-x64 --self-contained true --output artifacts/publish/linux-x64

docker-publish-game-windows:
	$(RUN) dotnet publish $(PROJECT) --configuration Release --runtime win-x64 --self-contained true --output artifacts/publish/win-x64

docker-publish-game-macos: docker-publish-game-macos-arm64 docker-publish-game-macos-x64

docker-publish-game-macos-arm64:
	$(RUN) dotnet publish $(PROJECT) --configuration Release --runtime osx-arm64 --self-contained true --output artifacts/publish/osx-arm64

docker-publish-game-macos-x64:
	$(RUN) dotnet publish $(PROJECT) --configuration Release --runtime osx-x64 --self-contained true --output artifacts/publish/osx-x64

docker-shell:
	$(RUN) bash

docker-clean:
	$(RUN) dotnet clean $(SOLUTION)
	$(RUN) sh -lc "if [ -d artifacts ]; then find artifacts -mindepth 1 -delete; fi"
