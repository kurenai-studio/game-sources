.PHONY: help dev test e2e build docker-build docker-run run stop clean install

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

install: ## Install npm dependencies
	npm install

dev: ## Start Vite dev server
	npm run dev

test: ## Run unit tests
	npm run test

e2e: ## Run Playwright E2E tests
	npx playwright test

build: ## Production build
	npm run build

docker-build: ## Build Docker image
	docker build -t cannons .

run: build ## Build and preview locally
	npm run preview

docker-run: docker-build ## Build and run in Docker
	docker run -d --name cannons -p 8080:80 cannons

stop: ## Stop and remove Docker container
	docker stop cannons && docker rm cannons

clean: ## Remove build artifacts and dependencies
	docker rmi cannons 2>/dev/null || true
	rm -rf dist node_modules
