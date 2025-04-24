#!/bin/bash
# Usage: ./patch-next-config.sh path/to/next.config.js|ts
set -e
file="$1"
if [[ ! -f "$file" ]]; then
  echo "❌ File not found: $file"
  exit 1
fi
temp_file="${file}.tmp"

# Check for the cms app's specific pattern (function returning object)
if grep -q "const nextConfig = (): NextConfig =>" "$file"; then
  # Special case for cms app with function returning object
  sed 's/return {/return { output: "standalone",/' "$file" > "$temp_file"
elif grep -q "const nextConfig:[^=]* *= *{" "$file"; then
  # TypeScript object with type annotation
  sed 's/\(const nextConfig:[^=]* *= *{\)/\1 output: "standalone",/' "$file" > "$temp_file"
elif grep -q "const nextConfig *= *{" "$file"; then
  # Simple object case JS/TS
  sed 's/const nextConfig *= *{/const nextConfig = { output: "standalone",/' "$file" > "$temp_file"
elif grep -q "return {" "$file"; then
  # Generic function returning object case
  sed 's/return {/return { output: "standalone",/' "$file" > "$temp_file"
elif grep -q "const nextConfig = " "$file"; then
  # Variable assignment case
  sed '/const nextConfig = /a\nextConfig.output = "standalone";' "$file" > "$temp_file"
else
  echo "❌ Could not find a suitable place to add output: standalone in $file"
  exit 1
fi
mv "$temp_file" "$file"