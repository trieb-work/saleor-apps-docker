# Install dependencies only when needed
FROM node:22-alpine AS base
RUN apk add --no-cache libc6-compat git

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable pnpm

WORKDIR /app

COPY . .

ARG APP_NAME

RUN pnpm install --filter=${APP_NAME}

ARG APP_PATH
# Add standalone output to next.config.js
RUN sed -i 's/const nextConfig = {/const nextConfig = { output: "standalone",/' apps/${APP_PATH}/next.config.js

# Set environment variables
ENV NEXT_TELEMETRY_DISABLED=1
ENV SECRET_KEY="dummy_secret_key_for_build_time_only"
ENV NODE_ENV="production"

RUN cd apps/${APP_PATH} && pnpm build 


# Production image, copy all the files and run next
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV="production"

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

ARG APP_PATH
COPY --from=base /app/apps/${APP_PATH}/.next/standalone ./
COPY --from=base /app/apps/${APP_PATH}/.next/static ./.next/static

USER nextjs

ENV PORT="8000"
EXPOSE 8000

CMD ["node", "server.js"]
