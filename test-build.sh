#!/bin/bash

# Test build script for Saleor Apps Docker images
# 
# Usage:
#   Build all apps:
#     ./test-build.sh
#
#   Build specific app:
#     ./test-build.sh <app-name>
#     Example: ./test-build.sh cms-v2
#
# Available apps:
#   - app-avatax
#   - cms-v2
#   - search
#   - klaviyo
#   - products-feed
#   - smtp
#
# The script will:
# 1. Clone the Saleor Apps repository
# 2. Get the latest version for the app(s)
# 3. Build Docker image(s) with the correct naming convention
#
# Note: This is a test script. For production builds, use the GitHub Action workflow.

# Function to build an app
build_app() {
    local app_name=$1
    local app_path=$2
    
    echo "🧹 Cleaning up previous test..."
    rm -rf saleor-apps
    
    echo "📦 Cloning Saleor Apps repository..."
    git clone https://github.com/trieb-work/saleor-apps.git saleor-apps
    
    echo "📝 Getting version for $app_name..."
    # Use exact tag matching with ^ and $ to avoid partial matches
    local app_version=$(git ls-remote --tags https://github.com/trieb-work/saleor-appss | \
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
    docker build \
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
    "segment:segment"
)

# Check if an app was specified
if [ $# -eq 1 ]; then
    # Find the app in the array
    for app in "${apps[@]}"; do
        IFS=':' read -r app_name app_path <<< "$app"
        if [ "$app_name" = "$1" ]; then
            echo "Building specific app: $app_name"
            build_app "$app_name" "$app_path"
            exit 0
        fi
    done
    echo "❌ App $1 not found. Available apps:"
    for app in "${apps[@]}"; do
        IFS=':' read -r app_name _ <<< "$app"
        echo "  - $app_name"
    done
    exit 1
else
    # Build all apps
    for app in "${apps[@]}"; do
        IFS=':' read -r app_name app_path <<< "$app"
        echo "Testing $app_name ($app_path)..."
        build_app "$app_name" "$app_path"
    done
fi
