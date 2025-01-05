#!/bin/bash

echo "🧹 Cleaning up previous test..."
rm -rf saleor-apps

echo "📦 Cloning Saleor Apps repository..."
git clone https://github.com/saleor/apps.git saleor-apps

# Build a test app (e.g., avatax)
APP_NAME="app-avatax"  # This should match the name in package.json
APP_PATH="avatax"      # This is the directory name in apps/
echo "📝 Getting version for $APP_NAME..."
APP_VERSION=$(git ls-remote --tags https://github.com/saleor/apps | grep "$APP_NAME@" | grep -v '\^' | cut -d '/' -f 3 | sort -V | tail -n 1 | cut -d '@' -f 2)

# checking out the last release in the saleor-apps repo (tag name matches package.json name)
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
    -t ghcr.io/trieb-work/saleor-apps/${APP_NAME}:${APP_VERSION} \
    -f Dockerfile \
    ./saleor-apps
