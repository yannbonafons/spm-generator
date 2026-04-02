# SPM Package Generator

Script project to scaffold Swift Package Manager (SPM) library packages for iOS development.

## Project structure

```
create-spm.sh                              # Main generator script — only file to modify
templates/                                 # Template files used by the script
  Package.swift.template                   # Package manifest without SwiftLint
  Package.swift.swiftlint.template         # Package manifest with SwiftLint SPM plugin
  README.md.template                       # Package README
  CLAUDE.md.template                       # Context file for Claude in generated packages
  project.yml.template                     # XcodeGen config for the Example app
.env                                       # Local config (git-ignored) — define GITHUB_USERNAME here
.env.example                               # Template to copy for new users
.swiftlint.yml                             # SwiftLint config, copied into packages generated with -s
DateFormatter/                             # ⚠️ Generated packages — DO NOT modify
Netcall/                                   # ⚠️ Generated packages — DO NOT modify
PrintUI/                                   # ⚠️ Generated packages — DO NOT modify
UserDefaultsStorage/                       # ⚠️ Generated packages — DO NOT modify
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
| `-o dir` | Output directory (default: current directory) |
| `-s` | Add SwiftLint via SPM build tool plugin + copy `.swiftlint.yml` + run `swift package resolve` |
| `-g` | Initialize git repository and prompt to create GitHub remote |

## What the script does (step by step)

1. Resolves output directory (current dir or `-o` option)
2. Runs `swift package init --type library`
3. Fixes folder structure (`Sources/<Name>/`, `Tests/<Name>Tests/`)
4. Generates `Package.swift` from template (with or without SwiftLint depending on `-s`)
5. **`-s` only** — Copies `.swiftlint.yml` from project root into the generated package
6. Generates `README.md` from template
7. Generates `CLAUDE.md` from template
8. Creates Example app (`<Name>App`) with `project.yml` for XcodeGen
9. Runs `xcodegen generate` if available
10. **`-s` only** — Runs `swift package resolve` to pre-fetch SwiftLint into cache
11. **`-g` only** — `git init` + first commit, then prompts to create GitHub repo

## Configuration

`GITHUB_USERNAME` is loaded from a `.env` file at the project root (ignored by git).

```
# .env
GITHUB_USERNAME=your_github_username
```

Copy `.env.example` → `.env` and fill in the value. The script errors out if the variable is not set.

## Template variable substitution

Templates use `$VAR` syntax, substituted at generation time via `envsubst`.

| Variable           | Value                              |
|--------------------|------------------------------------|
| `$PACKAGE_NAME`    | Name passed to the script          |
| `$APP_NAME`        | `${PACKAGE_NAME}App`               |
| `$GITHUB_USERNAME` | Loaded from `.env`                 |

## Rules for working on this project

- Only modify `create-spm.sh` and files in `templates/`
- Do **not** modify anything inside the generated package folders
- Keep templates generic — no package-specific logic
- Test by running the script and inspecting the generated output

## Tech stack of generated packages

- Swift 6.2 (`swift-tools-version: 6.2`)
- iOS 17+ minimum deployment
- Strict concurrency: `MainActor` default isolation, `ApproachableConcurrency` enabled
- SwiftLint via SPM build tool plugin (`SwiftLintBuildToolPlugin`)
- Swift Testing (not XCTest)
- XcodeGen for the Example app (`project.yml`)
