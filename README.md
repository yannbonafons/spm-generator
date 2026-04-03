# CreatePackages

Script to scaffold Swift Package Manager (SPM) library packages for iOS development.

## Requirements

- Xcode 26+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Swift 6.2+

## Setup

```bash
cp .env.example .env
# Edit .env and fill in your values
```

## Usage

```bash
./create-spm.sh MyPackage                       # local package, no SwiftLint, no git
./create-spm.sh -s MyPackage                    # with SwiftLint SPM plugin
./create-spm.sh -g MyPackage                    # with git init + GitHub prompt
./create-spm.sh -s -g MyPackage                 # with SwiftLint + git
./create-spm.sh -o /path/to/dir -s -g MyPackage # custom output dir + all options
```

| Flag | Description |
|------|-------------|
| `-o dir` | Output directory (overrides `PACKAGES_DIR` from `.env`) |
| `-s` | Add SwiftLint via SPM build tool plugin |
| `-g` | Initialize git repository and prompt to create GitHub remote |

## License

MIT — see [LICENSE](LICENSE).

## What gets generated

```
MyPackage/
├── Package.swift              # Swift 6.2, iOS 17+, strict concurrency
├── .swiftlint.yml             # copied from project root (-s only)
├── README.md
├── CLAUDE.md
├── Sources/MyPackage/
├── Tests/MyPackageTests/
└── Example/
    └── MyPackageApp/
        ├── Sources/MyPackageApp.swift
        ├── project.yml
        └── MyPackageApp.xcodeproj
```
