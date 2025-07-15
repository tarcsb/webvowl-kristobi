#!/bin/bash

echo "🧠 Vite + Kristobi Fix Script (macOS-compatible)"

# 1. Detect missing file
if [ ! -f "index.html" ]; then
  echo "❌ Missing index.html in project root."
  exit 1
fi

# 2. Look for real JS entry file
echo "🔍 Searching for entry file candidates in /src..."
ENTRY_FILE=$(find src -type f \( -name '*.js' -o -name '*.ts' \) | grep -Ei '(app|main|index)' | head -n1)

if [ -z "$ENTRY_FILE" ]; then
  echo "⚠️ No entry file found in /src. Creating fallback entry file..."
  mkdir -p src
  ENTRY_FILE="src/main.js"
  echo 'console.log("Kristobi demo graph initialized.")' > "$ENTRY_FILE"
fi

echo "✅ Using entry file: $ENTRY_FILE"

# 3. Fix index.html with macOS-safe sed
ENTRY_BASENAME=$(basename "$ENTRY_FILE")
sed -i '' "s|src=\"/src/.*.js\"|src=\"/$ENTRY_FILE\"|" index.html

# 4. Create netlify.toml if not present
if [ ! -f netlify.toml ]; then
  echo "📝 Writing netlify.toml..."
  cat > netlify.toml <<EOL
[build]
  command = "npm run build"
  publish = "dist"
EOL
fi

# 5. Check/patch package.json build scripts
echo "🧪 Ensuring correct scripts in package.json..."
if ! grep -q '"build":' package.json; then
  npx json -I -f package.json -e 'this.scripts.build="vite build"'
  npx json -I -f package.json -e 'this.scripts.dev="vite"'
  npx json -I -f package.json -e 'this.scripts.preview="vite preview"'
fi

# 6. Build the project
echo "🏗️ Running Vite production build..."
npm install
npm run build || {
  echo "❌ Build failed. Check entry path or Vite config."
  exit 1
}

echo "✅ Build complete. Output is in /dist"

# 7. Git commit + push (optional)
git add .
git commit -m "Fix Vite build path and add entry JS file" || echo "ℹ️ No new changes."
git push origin $(git branch --show-current)

# 8. Embed snippet for Squarespace
echo ""
echo "🧩 Embed this iframe in Squarespace:"
echo ""
echo "<iframe src=\"https://YOUR-NETLIFY-SITE.netlify.app\" width=\"100%\" height=\"600\" style=\"border:none;\"></iframe>"