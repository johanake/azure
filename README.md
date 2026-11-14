# Azure reference architectures

Reference architectures from my blog, written in Bicep. Each folder under
`reference-architectures/` stands alone, with its own README, modules and
deployment steps.

| Architecture | What it covers |
|---|---|
| [landing-zone-governance](reference-architectures/landing-zone-governance/) | Management group hierarchy, subscription placement and vending, and a central Log Analytics workspace, modelled on the Cloud Adoption Framework. Policy assignments go here too. |

## Secret scanning

A [gitleaks](https://github.com/gitleaks/gitleaks) pre-commit hook blocks
commits that contain secrets. `.gitleaks.toml` adds rules for Azure
subscription IDs and billing scopes. Those belong in each architecture's
gitignored `.env`. Set the hook up once after cloning:

```bash
pip install pre-commit      # or: brew install pre-commit
pre-commit install
```
