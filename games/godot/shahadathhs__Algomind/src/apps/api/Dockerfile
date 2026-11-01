# syntax=docker/dockerfile:1
# Build from the repository root:  docker build -f apps/api/Dockerfile .
FROM node:22-alpine AS base
RUN corepack enable
WORKDIR /repo

# Resolve dependencies from the lockfile alone, so this layer is cached across source edits.
FROM base AS deps
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
RUN pnpm fetch

FROM deps AS build
COPY . .
RUN pnpm install --offline --frozen-lockfile --filter @algomind/api...
RUN pnpm --filter @algomind/api build
# A self-contained production copy: dist, prisma schema and migrations, production deps.
RUN pnpm --filter @algomind/api deploy --legacy --prod /out

FROM node:22-alpine AS run
# Prisma's migration engine needs OpenSSL.
RUN apk add --no-cache openssl
ENV NODE_ENV=production PORT=8000
WORKDIR /app
COPY --from=build /out .
EXPOSE 8000
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/v1/health" >/dev/null || exit 1
# Apply pending migrations, then start. Safe with one instance (a no-op when up to date).
CMD ["sh", "-c", "node_modules/.bin/prisma migrate deploy && node dist/main.js"]
