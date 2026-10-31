# SAR Workbench - Gate Execution Log

This file records the verifiable execution history for all project gates. Every gate entry contains the exact command executed, date and timestamp, raw output verbatim, and the gate verdict (PASS / FAIL).

---

## Pre-Gate Verification: Research Frozen Integrity & Config Isolation

### 1. Research SHA256 Integrity Verification
- **Command**:
```powershell
powershell -Command "$diffFound = $false; Get-ChildItem -Path research/*.m | ForEach-Object { $rf = $_.FullName; $of = Join-Path (Get-Location) $_.Name; if (Test-Path $of) { $h1 = (Get-FileHash $rf -Algorithm SHA256).Hash; $h2 = (Get-FileHash $of -Algorithm SHA256).Hash; if ($h1 -ne $h2) { Write-Host ('DIFF: ' + $_.Name); $diffFound = $true; } } else { Write-Host ('MISSING IN ROOT: ' + $_.Name); $diffFound = $true; } }; if (-not $diffFound) { Write-Host 'ALL 70 RESEARCH FILES ARE BYTE-IDENTICAL TO ROOT ORIGINALS (SHA256 VERIFIED).' }"
```
- **Date**: 2026-10-31 13:58:10
- **Raw Output**:
```
ALL 70 RESEARCH FILES ARE BYTE-IDENTICAL TO ROOT ORIGINALS (SHA256 VERIFIED).
```
- **Verdict**: PASS

### 2. Configuration Leak Check
- **Command**: `git ls-files sarconfig.json sarconfig.example.json`
- **Raw Output**:
```
sarconfig.example.json
```
- **Verdict**: PASS (`sarconfig.json` is untracked and excluded by `.gitignore`)

---

## Gate G0: Repository Skeleton, Registry Validation & Environment Baseline

- **Command**: `matlab -batch "addpath('tests'); test_g0_skeleton;"`
- **Date**: 2026-10-31 14:23:50
- **Verdict**: PASS

### Raw Command Output
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G0 VERIFICATION ====================
Date: 2026-10-31 14:23:50
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
[PASS] Skeleton directory exists: app
[PASS] Skeleton directory exists: +sar
[PASS] Skeleton directory exists: models
[PASS] Skeleton directory exists: tests
[PASS] Skeleton directory exists: research
[PASS] Skeleton directory exists: docs
[PASS] Skeleton directory exists: research_new
[PASS] Template configuration file exists: sarconfig.example.json
[PASS] Despeckle registry verified: MERLIN Gotcha marked FAILED_VALIDATION.
================ SAR Workbench Environment Check ================
Timestamp: 2026-10-31 14:23:50
Root Dir : C:\Users\sruja\OneDrive\Documents\SARorsmthn

[PASS] MATLAB Version: (R2026a) (26.1)

--- Toolboxes ---
[PASS] Deep Learning Toolbox               : Installed
[PASS] Image Processing Toolbox            : Installed
[PASS] Signal Processing Toolbox           : Installed
[PASS] Statistics and Machine Learning     : Installed
[PASS] Phased Array System Toolbox         : Installed
[PASS] Parallel Computing Toolbox          : Installed

--- GPU Acceleration ---
[PASS] GPU Detected: NVIDIA GeForce RTX 3050 Laptop GPU (4.00 GB total, 3.23 GB free, CC 8.6)

--- Data Paths ---
[PASS] MSTAR Data: found (13 raw folders, mstar_soc.mat=1)
[PASS] Gotcha Data: found (1440 .mat files in C:\Users\sruja\OneDrive\Documents\SARorsmthn\Gotcha-CP-Disc2)
[PASS] Sentinel-1 Data: found (2 SAFE dirs, 0 zip files)

--- Trained Models ---
[PASS] MERLIN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin.mat
[PASS] MERLIN (Gotcha): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin_gotcha.mat
[WARN] ATR CNN (MSTAR): Not trained yet (run research_new/train_final_mstar.m for G2b)

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] sar.env.check returned PASS
Launching programmatic UI figure: SARWorkbench...
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
================ SAR Workbench Environment Check ================
Timestamp: 2026-10-31 14:23:54
Root Dir : C:\Users\sruja\OneDrive\Documents\SARorsmthn

[PASS] MATLAB Version: (R2026a) (26.1)

--- Toolboxes ---
[PASS] Deep Learning Toolbox               : Installed
[PASS] Image Processing Toolbox            : Installed
[PASS] Signal Processing Toolbox           : Installed
[PASS] Statistics and Machine Learning     : Installed
[PASS] Phased Array System Toolbox         : Installed
[PASS] Parallel Computing Toolbox          : Installed

--- GPU Acceleration ---
[PASS] GPU Detected: NVIDIA GeForce RTX 3050 Laptop GPU (4.00 GB total, 3.23 GB free, CC 8.6)

--- Data Paths ---
[PASS] MSTAR Data: found (13 raw folders, mstar_soc.mat=1)
[PASS] Gotcha Data: found (1440 .mat files in C:\Users\sruja\OneDrive\Documents\SARorsmthn\Gotcha-CP-Disc2)
[PASS] Sentinel-1 Data: found (2 SAFE dirs, 0 zip files)

--- Trained Models ---
[PASS] MERLIN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin.mat
[PASS] MERLIN (Gotcha): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin_gotcha.mat
[WARN] ATR CNN (MSTAR): Not trained yet (run research_new/train_final_mstar.m for G2b)

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] ATR CNN lamp is AMBER (matches reality: model not trained yet).
[PASS] App opened and all Home status lights match reality.
Screenshot saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\home_tab.png
[PASS] Home tab screenshot exported: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\home_tab.png
[PASS] GUI safely closed.

>>> GATE G0 RESULT: PASS <<<
==============================================================
```
