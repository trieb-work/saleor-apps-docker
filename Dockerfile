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
# Add standalone output to next.config.js more reliably
RUN cd apps/${APP_PATH} && \
    echo "Original next.config.js:" && \
    cat next.config.js && \
    if grep -q "import .* from" next.config.js; then \
        # ES Module case
        if grep -q "return {" next.config.js; then \
            # Function returning config case (like cms-v2)
            sed -i '/return {/a\    output: "standalone",' next.config.js; \
        elif grep -q "export default" next.config.js; then \
            # Direct export case
            sed -i 's/export default {/export default { output: "standalone",/' next.config.js; \
        else \
            # Complex case, add at the end
            echo "const originalConfig = nextConfig;" >> next.config.js && \
            echo "export default { ...originalConfig, output: 'standalone' };" >> next.config.js; \
        fi \
    else \
        # CommonJS case
        if grep -q "module.exports = nextConfig" next.config.js; then \
            # Simple export case
            sed -i 's/const nextConfig = {/const nextConfig = { output: "standalone",/' next.config.js; \
        elif grep -q "return {" next.config.js; then \
            # Function case
            sed -i '/return {/a\    output: "standalone",' next.config.js; \
        elif grep -q "module.exports = {" next.config.js; then \
            # Direct object export
            sed -i 's/module.exports = {/module.exports = { output: "standalone",/' next.config.js; \
        else \
            # Fallback: try to add it before the last export
            sed -i '$ i const originalConfig = module.exports;' next.config.js && \
            sed -i '$ i module.exports = { ...originalConfig, output: "standalone" };' next.config.js; \
        fi \
    fi && \
    echo "Modified next.config.js:" && \
    cat next.config.js

# Set environment variables. Mostly dummy that get replaced on runtime
ENV NEXT_TELEMETRY_DISABLED=1
ENV SECRET_KEY="dummy_secret_key_for_build_time_only"
ENV APL="file"
ENV NODE_ENV="production"

RUN cd apps/${APP_PATH} && pnpm build 

# Production image, copy all the files and run next
FROM default AS runner
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

WORKDIR /app/apps/${APP_PATH}

CMD ["node", "server.js"]
