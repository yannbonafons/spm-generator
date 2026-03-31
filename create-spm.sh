#!/bin/bash

set -e

PACKAGE_NAME=$1

if [ -z "$PACKAGE_NAME" ]; then
  echo "❌ Usage: ./create-spm.sh MyPackage"
  exit 1
fi

echo "🚀 Creating package: $PACKAGE_NAME"

mkdir -p "$PACKAGE_NAME"
cd "$PACKAGE_NAME"

# 1. Create SPM package
swift package init --type library --name "$PACKAGE_NAME"

# 2. Fix folder structure
mkdir -p Sources/"$PACKAGE_NAME"
mkdir -p Tests/"$PACKAGE_NAME"Tests

# Move default files
mv Sources/*.swift Sources/"$PACKAGE_NAME"/ 2>/dev/null || true
mv Tests/*.swift Tests/"$PACKAGE_NAME"Tests/ 2>/dev/null || true

# 3. Update Package.swift
cat > Package.swift <<EOF
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "$PACKAGE_NAME",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "$PACKAGE_NAME",
            targets: ["$PACKAGE_NAME"]
        ),
    ],
    targets: [
        .target(
            name: "$PACKAGE_NAME"
        ),
        .testTarget(
            name: "${PACKAGE_NAME}Tests",
            dependencies: ["$PACKAGE_NAME"]
        ),
    ]
)
EOF

echo "📦 Package.swift configured"

# 4. Create Example app
mkdir -p Example
cd Example

APP_NAME="${PACKAGE_NAME}App"

echo "📱 Creating example app: $APP_NAME"

#xcodebuild -create-xcodeproj "$APP_NAME" >/dev/null 2>&1 || true

mkdir -p "$APP_NAME"
cd "$APP_NAME"
mkdir -p Sources

# Create minimal SwiftUI app
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

# Create Xcode project (fallback via xcodegen if installed)
if command -v xcodegen &> /dev/null
then
cat > project.yml <<EOF
name: $APP_NAME

options:
  bundleIdPrefix: com.example

targets:
  $APP_NAME:
    type: application
    platform: iOS
    deploymentTarget: "17.0"

    settings:
      GENERATE_INFOPLIST_FILE: YES
      PRODUCT_BUNDLE_IDENTIFIER: com.Bonafons.$PACKAGE_NAME
      SWIFT_VERSION: "6.2"

    sources:
      - Sources

    dependencies:
      - package: $PACKAGE_NAME

packages:
  $PACKAGE_NAME:
    path: ../../
EOF

xcodegen generate
else
echo "⚠️ xcodegen not installed → create project manually in Xcode"
fi

cd ../..

# 5. Git init
git init
git add .
git commit -m "Initial commit: $PACKAGE_NAME"

echo "✅ Done!"
echo ""
echo "👉 Next steps:"
echo "1. Open Example/${APP_NAME}/${APP_NAME}.xcodeproj"
echo "2. Verify local package is linked"
echo "3. Start coding 🚀"