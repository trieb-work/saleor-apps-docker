FROM node:22-alpine AS default

FROM default AS base
RUN apk add --no-cache libc6-compat git jq

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable pnpm

WORKDIR /app

COPY . .

ARG APP_NAME

RUN pnpm install

ARG APP_PATH
# Add standalone output to next.config.js
RUN cd apps/${APP_PATH} && \
    echo "Original next.config.js:" && \
    cat next.config.js && \
    if grep -q "const nextConfig = {" next.config.js; then \
        # Simple object case (most apps)
        sed -i 's/const nextConfig = {/const nextConfig = { output: "standalone",/' next.config.js; \
    elif grep -q "return {" next.config.js; then \
        # Function case (cms-v2)
        sed -i '/return {/a\    output: "standalone",' next.config.js; \
    fi && \
    echo "Modified next.config.js:" && \
    cat next.config.js

# Set environment variables. Mostly dummy that get replaced on runtime
ENV NEXT_TELEMETRY_DISABLED=1
ENV SECRET_KEY="dummy_secret_key_for_build_time_only"
ENV APL="file"
ENV NODE_ENV="production"
ENV AWS_ACCESS_KEY_ID="dummy"
ENV AWS_REGION="dummy"
ENV AWS_SECRET_ACCESS_KEY="dummy"
ENV DYNAMODB_LOGS_TABLE_NAME="dummy"

RUN cd apps/${APP_PATH} && pnpm build 

# Production image, copy all the files and run next
FROM default AS runner
WORKDIR /app

ENV NODE_ENV="production"

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

ARG APP_PATH
COPY --from=base /app/apps/${APP_PATH}/.next/standalone ./
COPY --from=base /app/apps/${APP_PATH}/.next/static ./apps/${APP_PATH}/.next/static

USER nextjs

ENV PORT="8000"
EXPOSE 8000

WORKDIR /app/apps/${APP_PATH}
CMD ["node", "server.js"]
