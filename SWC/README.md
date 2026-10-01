# Semantic Windows Compiler (SWC) 2.3.2

This directory contains the compact self-hosted SWC compiler and its Semantic source.

## Contents

- `swc.exe` — compact self-hosted Windows compiler, approximately 3 MB
- `src/swc-selfhost-windows.se` — complete self-host Semantic source
- `swc.smod` — Semantic module manifest for the self-host source
- `matrix-delta/` — integrated Semantic matrix units used by the current build

## Usage

```powershell
.\swc.exe version
.\swc.exe compile .\swc.smod -o .\swc-next.exe --embed-all
```

The 113 MB matrix-full wrapper is intentionally not included. This package contains
the compact self-host executable only.

## Self-host proof

The supplied self-host executable was generated from the accompanying Semantic
source and supports the current SWC compile/SMOD/embed-all path. Keep the existing
compiler until a newly generated candidate has passed the self-host validation.
