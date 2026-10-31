# SAR Workbench - Gate Execution Log

This file records the verifiable execution history for all project gates. Every gate entry contains the exact command executed, date and timestamp, raw output verbatim, and the gate verdict (PASS / FAIL).

---

## Gate G0: Repository Skeleton & Environment Baseline

- **Command**: `matlab -batch "addpath('tests'); test_g0_skeleton;"`
- **Date**: 2026-10-31 13:29:15
- **Verdict**: PASS

### Raw Command Output
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G0 VERIFICATION ====================
Date: 2026-10-31 13:29:15
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
[PASS] Skeleton directory exists: app
[PASS] Skeleton directory exists: +sar
[PASS] Skeleton directory exists: models
[PASS] Skeleton directory exists: tests
[PASS] Skeleton directory exists: research
[PASS] Skeleton directory exists: docs
[PASS] Configuration files exist: sarconfig.json, sarconfig.example.json
================ SAR Workbench Environment Check ================
Timestamp: 2026-10-31 13:29:16
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
Timestamp: 2026-10-31 13:29:19
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

[PASS] App opened and Home status lights match reality.
[PASS] GUI safely closed.

>>> GATE G0 RESULT: PASS <<<
==============================================================
```
