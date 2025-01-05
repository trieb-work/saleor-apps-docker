FROM node:22-alpine AS base
RUN apk add --no-cache libc6-compat git

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable pnpm

WORKDIR /app

# Clone the specific version of the app
ARG APP_NAME
ARG APP_VERSION

RUN git clone https://github.com/saleor/apps.git . && \
    git checkout ${APP_NAME}@${APP_VERSION}

# Install dependencies
RUN pnpm install --filter=${APP_NAME}

# Set environment variables
ENV NEXT_TELEMETRY_DISABLED=1
ENV SECRET_KEY="dummy_secret_key_for_build_time_only"
ENV NODE_ENV="production"

# Get the app path (remove 'app-' prefix)
ARG APP_PATH
RUN cd apps/${APP_PATH} && \
    echo "{ \"output\": \"standalone\" }" > next.config.temp.json && \
    jq -s '.[0] * .[1]' next.config.js next.config.temp.json > next.config.new.js && \
    mv next.config.new.js next.config.js && \
    pnpm build

# Production image, copy all the files and run next
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV="production"

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

ARG APP_PATH
COPY --from=base /app/apps/${APP_PATH}/.next/standalone ./
COPY --from=base /app/apps/${APP_PATH}/.next/static ./.next/static
COPY --from=base /app/apps/${APP_PATH}/package.json ./package.json

USER nextjs

ENV PORT="3000"
EXPOSE 3000

CMD ["node", "server.js"]
