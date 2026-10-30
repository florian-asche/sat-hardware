# Release process

## Versioning

Semantic Versioning. The single source of truth for the version is the **top entry of
`debian/changelog`** (`dpkg-parsechangelog -ldebian/changelog --show-field Version`); the Python
version is derived from it during the package build. Git tags are `v<version>`.

## Workflows (`.github/workflows/`)

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | PR, push to `main` | `ruff check`, `ruff format --check`, `mypy`, `pytest` (Python 3.11 and 3.13), changelog parse |
| `build.yml` | PR, push to `main`, tags `v*` | `.deb` per architecture (amd64, native arm64) -> image that installs the `.deb` -> multi-arch manifest in GHCR (not pushed for PRs); on tags also the GitHub release |
| `pr-labels.yaml` | PR | Sets the label from the ticked "Types of changes" checkbox |

## Cutting a release

1. Add an entry on top of `debian/changelog` (new version, distribution `trixie`) and move the
   `[Unreleased]` notes of `CHANGELOG.md` under the new version heading.
2. Merge that change to `main` via PR.
3. Tag and push: `git tag v<version> && git push origin v<version>`.
4. `build.yml` builds both packages and images, pushes `ghcr.io/<owner>/sat-hardware-agent:v<version>`
   and `:latest`, then creates the GitHub release with both `.deb` files attached and generated notes
   (categories from `.github/release.yml`, taken from the PR labels). The job fails if the tag does
   not match the `debian/changelog` version. Versions containing `-` or `~` are marked as pre-releases.

## Requirements

- Repository setting "Workflow permissions" must allow `packages: write` for GHCR pushes.
- The first GHCR image is private by default; set the package to public in the package settings if wanted.

## Not verified yet

The release job and GHCR push run for the first time with the first tag.
