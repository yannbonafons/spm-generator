#!/bin/bash
set -e

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
SWIFTLINT_YML="$SCRIPT_DIR/.swiftlint.yml"
ENV_FILE="$SCRIPT_DIR/.env"

# Load .env if present
if [ -f "$ENV_FILE" ]; then
  # shellcheck source=.env
  source "$ENV_FILE"
fi

# Validate required config
if [ -z "$GITHUB_USERNAME" ]; then
  echo "❌ GITHUB_USERNAME is not set."
  echo "   → Copy .env.example to .env and fill in your GitHub username."
  exit 1
fi

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  echo "Usage: ./create-spm.sh [-o output_dir] [-s] [-g] [-l] PackageName"
  echo ""
  echo "  PackageName   Name of the SPM library to create"
  echo "  -o dir        Output directory (default: current directory)"
  echo "  -s            Add SwiftLint via SPM build tool plugin"
  echo "  -g            Initialize git repository and prompt for GitHub remote"
  echo "  -l            Add MIT LICENSE file and license mention in README"
  exit 1
}

# ── Arguments ─────────────────────────────────────────────────────────────────
OUTPUT_DIR_OVERRIDE=""
USE_SWIFTLINT=false
USE_GIT=false
USE_LICENSE=false

while getopts ":o:sgl" opt; do
  case $opt in
    o) OUTPUT_DIR_OVERRIDE="$OPTARG" ;;
    s) USE_SWIFTLINT=true ;;
    g) USE_GIT=true ;;
    l) USE_LICENSE=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

# Resolve output directory:
# 1. -o flag (explicit override)
# 2. PACKAGES_DIR from .env
# 3. hardcoded default: ./Packages (relative to script location)
if [ -n "$OUTPUT_DIR_OVERRIDE" ]; then
  OUTPUT_DIR="$OUTPUT_DIR_OVERRIDE"
elif [ -n "$PACKAGES_DIR" ]; then
  OUTPUT_DIR="$PACKAGES_DIR"
else
  OUTPUT_DIR="$SCRIPT_DIR"
fi

PACKAGE_NAME=$1
if [ -z "$PACKAGE_NAME" ]; then
  echo "❌ Package name is required."
  usage
fi

export PACKAGE_NAME
export GITHUB_USERNAME
export APP_NAME="${PACKAGE_NAME}App"

# ── Helpers ───────────────────────────────────────────────────────────────────
render_template() {
  local template="$1"
  local destination="$2"
  envsubst '$PACKAGE_NAME $APP_NAME $GITHUB_USERNAME' < "$template" > "$destination"
}

# ── Start ─────────────────────────────────────────────────────────────────────
echo "🚀 Creating package: $PACKAGE_NAME"
echo "   → Output:    $OUTPUT_DIR/$PACKAGE_NAME"
echo "   → SwiftLint: $USE_SWIFTLINT"
echo "   → Git:       $USE_GIT"
echo "   → License:   $USE_LICENSE"
echo ""

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

mkdir -p "$PACKAGE_NAME"
cd "$PACKAGE_NAME"

# 1. Create SPM package
swift package init --type library --name "$PACKAGE_NAME"

# 2. Fix folder structure
mkdir -p Sources/"$PACKAGE_NAME"
mkdir -p Tests/"${PACKAGE_NAME}Tests"
mv Sources/*.swift Sources/"$PACKAGE_NAME"/ 2>/dev/null || true
mv Tests/*.swift Tests/"${PACKAGE_NAME}Tests"/ 2>/dev/null || true

# 3. Package.swift from template
if [ "$USE_SWIFTLINT" = true ]; then
  render_template "$TEMPLATES_DIR/Package.swift.swiftlint.template" Package.swift
  echo "📦 Package.swift configured (with SwiftLint SPM plugin)"
else
  render_template "$TEMPLATES_DIR/Package.swift.template" Package.swift
  echo "📦 Package.swift configured"
fi

# 4. Copy .swiftlint.yml
if [ "$USE_SWIFTLINT" = true ]; then
  if [ -f "$SWIFTLINT_YML" ]; then
    cp "$SWIFTLINT_YML" .swiftlint.yml
    echo "🔍 .swiftlint.yml copied"
  else
    echo "⚠️  .swiftlint.yml not found at $SWIFTLINT_YML — skipping"
  fi
fi

# 5. README.md from template
render_template "$TEMPLATES_DIR/README.md.template" README.md
echo "📄 README.md created"

# 5b. LICENSE + README mention (-l only)
if [ "$USE_LICENSE" = true ]; then
  render_template "$TEMPLATES_DIR/LICENSE.template" LICENSE
  echo "" >> README.md
  echo "## License" >> README.md
  echo "" >> README.md
  echo "MIT — see [LICENSE](LICENSE)." >> README.md
  echo "⚖️  LICENSE (MIT) created"
fi

# 6. CLAUDE.md from template
render_template "$TEMPLATES_DIR/CLAUDE.md.template" CLAUDE.md
echo "🤖 CLAUDE.md created"

# 7. Example app
APP_NAME="${PACKAGE_NAME}App"
mkdir -p Example
cd Example

mkdir -p "$APP_NAME"
cd "$APP_NAME"
mkdir -p Sources

cat > Sources/${APP_NAME}.swift <<EOF
import SwiftUI
import $PACKAGE_NAME

@main
struct ${APP_NAME}: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello from $PACKAGE_NAME 🎉")
        }
    }
}
EOF

render_template "$TEMPLATES_DIR/project.yml.template" project.yml

if command -v xcodegen &> /dev/null; then
  xcodegen generate
  echo "📱 Example app created: $APP_NAME"
else
  echo "⚠️  xcodegen not installed → project.yml created, run 'xcodegen generate' manually"
fi

cd ../..

# 8. Resolve packages (only needed when SwiftLint is added, to pre-fetch it)
if [ "$USE_SWIFTLINT" = true ]; then
  echo ""
  echo "📡 Resolving Swift packages (fetching SwiftLint, this may take a moment)..."
  swift package resolve
  echo "✅ Packages resolved"
fi

# 9. Git init + remote
if [ "$USE_GIT" = true ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────────────────────┐"
  echo "│  Please create the following repository on GitHub:              │"
  echo "│                                                                  │"
  echo "│  https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME"
  echo "│                                                                  │"
  echo "│  Then press any key to continue...                              │"
  echo "└─────────────────────────────────────────────────────────────────┘"
  read -n 1 -s

  git init
  git add .
  git commit -m "Initial commit: $PACKAGE_NAME"
  git branch -M main
  #git remote add origin git@github.com:$GITHUB_USERNAME/$PACKAGE_NAME
  #git push -u origin main
fi

echo ""
echo "✅ Done!"
echo ""
echo "👉 Next steps:"
echo "1. Open Example/${APP_NAME}/${APP_NAME}.xcodeproj"
echo "2. Verify local package is linked"
echo "3. Start coding 🚀"
