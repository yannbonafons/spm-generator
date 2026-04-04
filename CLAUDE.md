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
  LICENSE.template                         # MIT license (used with -l)
.env                                       # Local config (git-ignored) — define GITHUB_USERNAME here
.env.example                               # Template to copy for new users
.swiftlint.yml                             # SwiftLint config, copied into packages generated with -s
```

Packages are generated in a separate directory defined by `PACKAGES_DIR` in `.env` (default: script directory).

## Usage

```bash
./create-spm.sh MyPackage                          # local package, no SwiftLint, no git
./create-spm.sh -s MyPackage                       # with SwiftLint SPM plugin
./create-spm.sh -g MyPackage                       # with git init + GitHub prompt
./create-spm.sh -l MyPackage                       # with MIT LICENSE file
./create-spm.sh -s -g -l MyPackage                 # with SwiftLint + git + license
./create-spm.sh -o /path/to/dir -s -g -l MyPackage # custom output dir + all options
```

| Flag | Description |
|------|-------------|
| `-o dir` | Output directory (overrides `PACKAGES_DIR` from `.env`) |
| `-s` | Add SwiftLint via SPM build tool plugin + copy `.swiftlint.yml` + run `swift package resolve` |
| `-g` | Initialize git repository and prompt to create GitHub remote |
| `-l` | Add MIT LICENSE file + license mention in README |

## What the script does (step by step)

1. Resolves output directory: `-o` flag → `PACKAGES_DIR` in `.env` → script directory
2. Runs `swift package init --type library`
3. Fixes folder structure (`Sources/<Name>/`, `Tests/<Name>Tests/`)
4. Generates `Package.swift` from template (with or without SwiftLint depending on `-s`)
5. **`-s` only** — Copies `.swiftlint.yml` from project root into the generated package
6. Generates `README.md` from template
7. **`-l` only** — Generates `LICENSE` (MIT) from template + appends license section to `README.md`
8. Generates `CLAUDE.md` from template
9. Creates Example app (`<Name>App`) with `project.yml` for XcodeGen
10. Runs `xcodegen generate`
11. **`-s` only** — Runs `swift package resolve` to pre-fetch SwiftLint into cache
12. **`-g` only** — `git init` + first commit, then prompts to create GitHub repo

## Configuration

Variables loaded from a `.env` file at the project root (ignored by git).

```
# .env
GITHUB_USERNAME=your_github_username
PACKAGES_DIR=/absolute/or/relative/path/to/packages  # optional
```

Copy `.env.example` → `.env` and fill in the values. `GITHUB_USERNAME` is required. `PACKAGES_DIR` is optional — if omitted, packages are generated in the script's directory.

## Template variable substitution

Templates use `$VAR` syntax, substituted at generation time via `envsubst`.

| Variable            | Value                                        |
|---------------------|----------------------------------------------|
| `$PACKAGE_NAME`     | Name passed to the script                    |
| `$APP_NAME`         | `${PACKAGE_NAME}App`                         |
| `$GITHUB_USERNAME`  | Loaded from `.env`                           |

## Rules for working on this project

- Only modify `create-spm.sh` and files in `templates/`
- Do **not** modify anything inside the generated package folders
- Keep templates generic — no package-specific logic
- Test by running the script and inspecting the generated output

## Tech stack of generated packages

- Swift 6.2 (`swift-tools-version: 6.2`)
- iOS 17+ minimum deployment
- Strict concurrency: `MainActor` default isolation, `ApproachableConcurrency` enabled
- SwiftLint via SPM build tool plugin (`SwiftLintBuildToolPlugin`) — optional, with `-s`
- Swift Testing (not XCTest)
- XcodeGen for the Example app (`project.yml`)
