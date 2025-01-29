#!/bin/bash

# Test script to verify next.config.js modifications for all apps
# This script will clone the repo and test our next.config.js modifications without building

# Clean up
rm -rf saleor-apps
echo "🧹 Cleaning up previous test..."

# Clone repo
echo "📦 Cloning Saleor Apps repository..."
git clone https://github.com/trieb-work/saleor-appss.git saleor-apps
cd saleor-apps

# Apps to test
apps=(
    "avatax"
    "cms-v2"
    "search"
    "klaviyo"
    "products-feed"
    "smtp"
)

modify_next_config() {
    local file=$1
    local temp_file="${file}.tmp"
    
    # Add output: "standalone" to the config object
    if grep -q "const nextConfig = {" "$file"; then
        # Simple object case
        sed 's/const nextConfig = {/const nextConfig = { output: "standalone",/' "$file" > "$temp_file"
    elif grep -q "return {" "$file"; then
        # Function returning object case
        sed '/return {/a\    output: "standalone",' "$file" > "$temp_file"
    elif grep -q "const nextConfig = " "$file"; then
        # Variable assignment case
        sed '/const nextConfig = /a\nextConfig.output = "standalone";' "$file" > "$temp_file"
    else
        echo "❌ Could not find a suitable place to add output: standalone"
        return 1
    fi
    
    mv "$temp_file" "$file"
    return 0
}

for app in "${apps[@]}"; do
    echo ""
    echo "Testing app: $app"
    echo "===================="
    
    if [ ! -f "apps/$app/next.config.js" ]; then
        echo "❌ next.config.js not found for $app"
        continue
    fi

    echo "Original next.config.js:"
    echo "--------------------"
    cat "apps/$app/next.config.js"
    echo ""
    
    # Create a backup
    cp "apps/$app/next.config.js" "apps/$app/next.config.js.bak"
    
    # Test modification
    if modify_next_config "apps/$app/next.config.js"; then
        echo "✅ Successfully modified next.config.js"
    else
        echo "❌ Failed to modify next.config.js"
    fi
    
    echo ""
    echo "Modified next.config.js:"
    echo "--------------------"
    cat "apps/$app/next.config.js"
    echo ""
    
    # Verify the file is still valid JavaScript
    if node -c "apps/$app/next.config.js" 2>/dev/null; then
        echo "✅ Syntax check passed"
    else
        echo "❌ Syntax check failed"
    fi
    
    # Restore backup
    mv "apps/$app/next.config.js.bak" "apps/$app/next.config.js"
done

cd ..
rm -rf saleor-apps
