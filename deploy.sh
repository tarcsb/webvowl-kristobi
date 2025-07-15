#!/bin/bash

# === USER CONFIGURATION ===
GITHUB_USERNAME="tarcsb"
REPO_NAME="webvowl-kristobi"
BRANCH="refactor/vite"
FORK_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

echo ""
echo "🧠 Kristobi Setup Script Starting..."
echo "-------------------------------------"

# === Safety Check: Must be in a .git repo ===
if [ ! -d .git ]; then
  echo "❌ This directory is not a Git repository. Run this inside your cloned repo."
  exit 1
fi

# === Check correct repo ===
REMOTE=$(git remote get-url origin)
if [[ "$REMOTE" != *"$REPO_NAME.git" ]]; then
  echo "❌ This does not appear to be the correct Kristobi fork: $REMOTE"
  exit 1
fi

# === Checkout or Create Target Branch ===
echo "🔀 Checking out branch '$BRANCH'..."
git fetch origin
if git rev-parse --verify origin/$BRANCH >/dev/null 2>&1; then
  git checkout -B $BRANCH origin/$BRANCH
else
  echo "⚠️ Branch '$BRANCH' not found. Using existing local branch instead."
  BRANCH=$(git branch --show-current)
fi

# === Install Dependencies ===
echo "📦 Installing npm dependencies..."
npm install || { echo "❌ npm install failed."; exit 1; }

# === Inject Missing Build Scripts ===
echo "🧪 Checking package.json for Vite build script..."
if ! grep -q '"build":' package.json; then
  echo "⚙️ Injecting Vite-compatible scripts..."
  npx json -I -f package.json -e 'this.scripts.build="vite build"'
  npx json -I -f package.json -e 'this.scripts.dev="vite"'
  npx json -I -f package.json -e 'this.scripts.preview="vite preview"'
else
  echo "✅ Build script already exists."
fi

# === Run audit fix safely ===
echo "🛡️ Running npm audit fix..."
npm audit fix || echo "⚠️ Some vulnerabilities may remain."

# === Create netlify.toml ===
echo "📝 Creating netlify.toml..."
cat > netlify.toml <<EOL
[build]
  command = "npm run build"
  publish = "dist"
EOL

# === Create index.html if missing ===
if [ ! -f "index.html" ]; then
  echo "🛠️ Creating Vite entry file: index.html..."
  cat > index.html <<EOL
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Kristobi Provenance Viewer</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      body {
        font-family: 'Inter', sans-serif;
        background: #fafafa;
        margin: 0;
        padding: 2rem;
        text-align: center;
      }
      h1 {
        color: #006060;
      }
    </style>
  </head>
  <body>
    <h1>Kristobi Provenance Graph Viewer</h1>
    <div id="app"></div>
    <script type="module" src="/src/index.js"></script>
  </body>
</html>
EOL
else
  echo "✅ index.html already exists."
fi

# === Run Build ===
echo "🏗️ Running Vite production build..."
npm run build || { echo "❌ Build failed. Check index.html or entry path."; exit 1; }

# === Commit and Push ===
echo "📤 Committing and pushing changes..."
git add package.json netlify.toml index.html
git commit -m "Automated setup: add build scripts, index.html, netlify.toml" || echo "ℹ️ Nothing to commit."
git push origin $BRANCH

# === Final Output ===
echo ""
echo "✅ All done! Your project is Netlify-ready and Squarespace-embeddable."
echo "---------------------------------------------------------------"
echo "👉 NEXT STEPS:"
echo "1. Go to https://app.netlify.com"
echo "2. Click 'Add new site' → 'Import from GitHub'"
echo "3. Select your repo: $REPO_NAME"
echo "4. Netlify will auto-detect netlify.toml and deploy"
echo ""
echo "✅ Once deployed, embed it into Squarespace using:"
echo ""
echo "<iframe src=\"https://YOUR-NETLIFY-SITE.netlify.app\" width=\"100%\" height=\"600\" style=\"border:none;\"></iframe>"