#!/bin/sh

# Test build script for Saleor Apps Docker images
# 
# This script can be used to test building Docker images for Saleor Apps
# It supports building a specific app or all apps
#
# Usage:
#   ./test-build.sh [app_name]
#
# Examples:
#   ./test-build.sh                # Build all apps
#   ./test-build.sh app-avatax     # Build only app-avatax
#
# Supported apps:
#   - app-avatax
#   - cms
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
    
    # Get releases from GitHub API using a more robust approach
    local temp_file=$(mktemp)
    curl -s "https://api.github.com/repos/trieb-work/saleor-apps/releases" | grep -A 1 "tag_name" | grep -E "$app_name|saleor-app-$app_name" > "$temp_file"
    
    # Extract the latest release tag
    local release=$(grep -o '"tag_name": "[^"]*"' "$temp_file" | grep -o '"[^"]*"$' | tr -d '"' | sort -V | tail -n 1)
    rm "$temp_file"
    
    if [ -z "$release" ]; then
        echo "❌ No matching version found for $app_name"
        return 1
    fi
    
    # Extract app name and version from release tag (exactly as in GitHub workflow)
    local release_app_name=$(echo $release | cut -d'@' -f1)
    local version=$(echo $release | cut -d'@' -f2)
    
    # Get the app path (without saleor-app- or app- prefix if present)
    local release_app_path=$release_app_name
    if echo "$release_app_name" | grep -q "^saleor-app-"; then
        release_app_path=${release_app_name#saleor-app-}
    elif echo "$release_app_name" | grep -q "^app-"; then
        release_app_path=${release_app_name#app-}
    fi
    
    echo "📝 Found version $version (tag: $release)"
    echo "📝 Checking out $release..."
    cd saleor-apps
    git checkout $release
    cd ..
    
    echo "🏗️  Building Docker image for $app_name..."
    cp patch-next-config.sh saleor-apps/

    docker build \
        --build-arg APP_NAME=${app_name} \
        --build-arg APP_PATH=${app_path} \
        -t ghcr.io/trieb-work/saleor-apps/${app_name}:${version} \
        --progress=plain \
        -f Dockerfile \
        ./saleor-apps
}

# Test all apps
apps=(
    "app-avatax:avatax"
    "cms:cms"
    "search:search"
    "klaviyo:klaviyo"
    "products-feed:products-feed"
    "smtp:smtp"
    "segment:segment"
    "payment-stripe:stripe"
)

# Check if an app was specified
if [ $# -eq 1 ]; then
    app_name=""
    app_path=""
    
    # Find the specified app in the apps array
    for app in "${apps[@]}"; do
        IFS=':' read -r name path <<< "$app"
        if [ "$name" == "$1" ] || [ "$path" == "$1" ]; then
            app_name=$name
            app_path=$path
            break
        fi
    done
    
    if [ -z "$app_name" ]; then
        echo "❌ App not found: $1"
        exit 1
    fi
    
    echo "Building specific app: $app_name"
    build_app "$app_name" "$app_path"
else
    # Build all apps
    for app in "${apps[@]}"; do
        IFS=':' read -r name path <<< "$app"
        echo "Testing $name ($path)..."
        build_app "$name" "$path"
    done
fi
