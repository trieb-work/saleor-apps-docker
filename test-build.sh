#!/bin/bash

# echo "🧹 Cleaning up previous test..."
# rm -rf saleor-apps

# echo "📦 Cloning Saleor Apps repository..."
# git clone https://github.com/saleor/apps.git saleor-apps

# Build a test app (e.g., avatax)
APP_NAME="app-avatax"
APP_PATH="avatax"
echo "📝 Getting version for $APP_NAME..."
APP_VERSION=$(git ls-remote --tags https://github.com/saleor/apps | grep $APP_NAME | grep -v '\^' | cut -d '/' -f 3 | sort -V | tail -n 1 | cut -d '@' -f 2)

# checking out the last release in the saleor-apps repo (tag name is e.g., app-avatax@1.12.3)
echo "📝 Checking out $APP_VERSION for $APP_NAME..."
cd saleor-apps
git checkout $APP_NAME@$APP_VERSION
cd ..

echo "🏗️  Building Docker image..."
# Build the Docker image
DOCKER_BUILDKIT=1 docker buildx build \
    --platform linux/amd64 \
    --progress=plain \
    --build-arg APP_NAME=${APP_NAME} \
    --build-arg APP_PATH=${APP_PATH} \
    -t ghcr.io/trieb-work/${APP_NAME}:${APP_VERSION} \
    -f Dockerfile \
    ./saleor-apps
