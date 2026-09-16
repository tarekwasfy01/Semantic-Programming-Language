# Semantic Website

Static, privacy-conscious GitHub Pages website for the Semantic Programming Language and Module Registry.

## Before publishing

1. Edit `assets/js/config.js` and set `registryRepo` to the repository that contains this site, `modules.json`, the issue template, and the registration workflow.
2. Add a real contact email address to `legal.html` and `privacy.html`.
3. In the repository settings, enable GitHub Issues and GitHub Actions with permission to read/write repository contents and issues.
4. Create the label `module-submission` (optional but recommended).
5. Publish the site using GitHub Pages.

## Module publishing flow

The website collects the module name and direct ZIP URL, then opens a pre-filled GitHub issue. The publisher signs into GitHub and submits it. `.github/workflows/register-module.yml` validates the ZIP and `.smod` manifest, then updates `modules.json` with only `name` and `url`.

The registry workflow never executes files from submitted archives and does not extract them to the repository.

## Release buttons

The site resolves GitHub's latest release API at runtime. Code Transpiler currently prefers `codetranspiler-gui.exe` when that asset is present. The Semantic button automatically starts working once a GitHub Release is published for `SemanticProgrammingLanguage/Semantic-Programming-Language`.
