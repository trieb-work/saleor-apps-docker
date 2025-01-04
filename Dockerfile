FROM node:18-alpine AS deps

ARG PNPM_VERSION
RUN apk add --no-cache libc6-compat
RUN corepack enable
RUN corepack prepare pnpm@${PNPM_VERSION} --activate

WORKDIR /app

# Copy workspace configuration and root package files
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./

# Copy all package.json files from workspace packages
COPY apps/*/package.json ./apps/
COPY packages/*/package.json ./packages/
COPY templates/*/package.json ./templates/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM node:18-alpine AS builder

ARG PNPM_VERSION
RUN corepack enable
RUN corepack prepare pnpm@${PNPM_VERSION} --activate

WORKDIR /app

# Copy all files
COPY . .

# Copy installed dependencies
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/*/node_modules ./apps/*/node_modules
COPY --from=deps /app/packages/*/node_modules ./packages/*/node_modules

# Next.js collects completely anonymous telemetry data about general usage.
ENV NEXT_TELEMETRY_DISABLED 1

ARG APP_PATH
WORKDIR /app/${APP_PATH}

# Build the specific app
RUN pnpm build

# Production image, copy all the files and run next
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

ARG APP_PATH
COPY --from=builder /app/${APP_PATH}/public ./public
COPY --from=builder /app/${APP_PATH}/.next/standalone ./
COPY --from=builder /app/${APP_PATH}/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
