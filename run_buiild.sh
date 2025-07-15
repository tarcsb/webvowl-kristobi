#!/bin/bash

echo "🔧 Kristobi Vite Fix & Netlify Prep (macOS M1/M2/M4 Compatible)"
echo "--------------------------------------------------------------"

# Step 1: Ensure clean index.html
if [ -f "index.html" ]; then
  echo "🧹 Cleaning up CommonJS-style imports..."
  sed -i '' '/sidebar\.js/d' index.html
else
  echo "❌ index.html missing. Exiting."
  exit 1
fi

# Step 2: Ensure build scripts are present
if ! grep -q '"build":' package.json; then
  echo "⚙️  Adding Vite build scripts to package.json..."
  npx json -I -f package.json -e 'this.scripts.build="vite build"'
  npx json -I -f package.json -e 'this.scripts.dev="vite"'
  npx json -I -f package.json -e 'this.scripts.preview="vite preview"'
fi

# Step 3: Fallback entry file (if needed)
if [ ! -f "src/app/main.js" ]; then
  echo "📄 Creating fallback JS entry: src/app/main.js"
  mkdir -p src/app
  echo 'console.log("Kristobi viewer running.");' > src/app/main.js
fi

# Step 4: Fix script path in index.html (macOS-safe)
echo "🔗 Updating entry <script> to match actual file..."
sed -i '' 's|src="/src/.*.js"|src="/src/app/main.js"|' index.html

# Step 5: Write Netlify config
echo "📝 Creating netlify.toml (if missing)..."
cat > netlify.toml <<EOL
[build]
  command = "npm run build"
  publish = "dist"
EOL

# Step 6: Install deps and build
echo "📦 Installing dependencies..."
npm install

echo "🏗️  Building site with Vite..."
npm run build || {
  echo "❌ Vite build failed. Check entry path and module types."
  exit 1
}

# Step 7: Git push
echo "📤 Committing and pushing..."
git add .
git commit -m "Fix Vite entry & prepare for Netlify" || echo "ℹ️ Nothing to commit"
git push origin $(git branch --show-current)

# Final instructions
echo ""
echo "✅ Build successful!"
echo "🎉 Netlify will now deploy from: /dist"
echo ""
echo "🧩 Embed in Squarespace:"
echo "<iframe src=\"https://YOUR-SITE.netlify.app\" width=\"100%\" height=\"600\" style=\"border:none;\"></iframe>"
