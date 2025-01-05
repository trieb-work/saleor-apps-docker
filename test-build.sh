#!/bin/bash

# Function to build an app
build_app() {
    local app_name=$1
    local app_path=$2
    
    echo "🧹 Cleaning up previous test..."
    rm -rf saleor-apps
    
    echo "📦 Cloning Saleor Apps repository..."
    git clone https://github.com/saleor/apps.git saleor-apps
    
    echo "📝 Getting version for $app_name..."
    # Use exact tag matching with ^ and $ to avoid partial matches
    local app_version=$(git ls-remote --tags https://github.com/saleor/apps | \
        grep -E "refs/tags/${app_name}@[0-9]+\.[0-9]+\.[0-9]+$" | \
        grep -v '\^' | \
        cut -d '/' -f 3 | \
        sort -V | \
        tail -n 1 | \
        cut -d '@' -f 2)
    
    if [ -z "$app_version" ]; then
        echo "❌ No matching version found for $app_name"
        return 1
    fi
    
    echo "📝 Checking out $app_version for $app_name..."
    cd saleor-apps
    git checkout $app_name@$app_version
    cd ..
    
    echo "🏗️  Building Docker image for $app_name..."
    DOCKER_BUILDKIT=1 docker buildx build \
        --platform linux/amd64 \
        --progress=plain \
        --build-arg APP_NAME=${app_name} \
        --build-arg APP_PATH=${app_path} \
        -t ghcr.io/trieb-work/saleor-apps/${app_name}:${app_version} \
        -f Dockerfile \
        ./saleor-apps
}

# Test all apps
apps=(
    "app-avatax:avatax"
    "cms-v2:cms-v2"
    "search:search"
    "klaviyo:klaviyo"
    "products-feed:products-feed"
    "smtp:smtp"
)

for app in "${apps[@]}"; do
    IFS=':' read -r app_name app_path <<< "$app"
    echo "Testing $app_name ($app_path)..."
    build_app "$app_name" "$app_path"
done
