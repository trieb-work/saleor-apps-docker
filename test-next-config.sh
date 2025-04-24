#!/bin/bash

# Test script to verify next.config.js/.ts modifications for all apps
# This script will clone the repo and test our next.config.js/.ts modifications without building

# Clean up
rm -rf saleor-apps
echo "🧹 Cleaning up previous test..."

# Clone repo
echo "📦 Cloning Saleor Apps repository..."
git clone https://github.com/trieb-work/saleor-apps.git saleor-apps
cd saleor-apps

# Apps to test
apps=(
    "avatax"
    "cms"
    "search"
    "klaviyo"
    "products-feed"
    "smtp",
    "segment"
)

for app in "${apps[@]}"; do
    echo ""
    echo "Testing app: $app"
    echo "===================="
    
    config_file_js="apps/$app/next.config.js"
    config_file_ts="apps/$app/next.config.ts"
    
    if [ -f "$config_file_js" ]; then
        config_file="$config_file_js"
    elif [ -f "$config_file_ts" ]; then
        config_file="$config_file_ts"
    else
        echo "❌ next.config.js/.ts not found for $app"
        continue
    fi

    echo "Original $config_file:"
    echo "--------------------"
    cat "$config_file"
    echo ""
    
    # Create a backup
    cp "$config_file" "$config_file.bak"
    
    # Patch using the new utility script
    if ../patch-next-config.sh "$config_file"; then
        echo "✅ Successfully modified $config_file"
    else
        echo "❌ Failed to modify $config_file"
    fi
    
    echo ""
    echo "Modified $config_file:"
    echo "--------------------"
    cat "$config_file"
    echo ""
    
    # Verify the file is still valid JavaScript/TypeScript (basic check)
    if [[ "$config_file" == *.js ]]; then
        if node -c "$config_file" 2>/dev/null; then
            echo "✅ Syntax check passed"
        else
            echo "❌ Syntax check failed"
        fi
    elif [[ "$config_file" == *.ts ]]; then
        if command -v tsc >/dev/null 2>&1; then
            if tsc --noEmit "$config_file" 2>/dev/null; then
                echo "✅ TypeScript type check passed"
            else
                echo "❌ TypeScript type check failed"
            fi
        else
            echo "⚠️  tsc not found, skipping TypeScript check"
        fi
    fi
    
    # Restore backup
    mv "$config_file.bak" "$config_file"
done

cd ..
