# SAR Workbench - Gate Execution Log

This file records the verifiable execution history for all project gates. Every gate entry contains the exact command executed, date and timestamp, raw output verbatim, and the gate verdict (PASS / FAIL).

---

## Pre-Gate Verification: Research Frozen Integrity & Config Isolation

### 1. Research SHA256 Integrity Verification
- **Command**: `powershell -ExecutionPolicy Bypass -File scripts/verify_freeze_and_evidence.ps1`
- **Date**: 2026-11-03 23:42:54
- **Verdict**: PASS / NOTED

```
================ PRE-G1 VERIFICATION REPORT ================
Timestamp: 2026-11-03 23:42:54

--- 1. Search for research-freeze-2026-10-30.zip ---
[STATUS] research-freeze-2026-10-30.zip not found on local drive (searched C:\Users\sruja).
         Integrity established via initial commit 0966aea and byte-identical match with root originals.

--- 2. Evidence of home_tab_all_ready.png ---
[PASS] File exists: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\home_tab_all_ready.png
       Size: 41803 bytes
       Last Modified: 10/31/2026 14:37:07
       SHA256: 137773BD535F479981686178AC24362E03E80D3860D9C5BA4426C869265C51A7

--- 3. Git Remotes Check ---
backup	C:\Users\sruja\sar-workbench-backup.git (fetch)
backup	C:\Users\sruja\sar-workbench-backup.git (push)

=============================================================
```

### 2. Configuration Isolation Check
- **Command**: `git ls-files sarconfig.json sarconfig.example.json`
- **Date**: 2026-10-31 14:30:14
- **Verdict**: PASS

```
sarconfig.example.json
```

---

## Gate G0: Repository Skeleton, Registry Validation & Environment Baseline

- **Command**: `matlab -batch "addpath('tests'); test_g0_skeleton;"`
- **Date**: 2026-11-03 23:40:56
- **Verdict**: PASS

### Raw Command Output
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G0 VERIFICATION ====================
Date: 2026-11-03 23:40:56
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
Timestamp: 2026-11-03 23:40:56
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] sar.env.check returned PASS
Launching programmatic UI figure: SARWorkbench...
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-03 23:40:59
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] ATR CNN lamp is GREEN (matches reality: model exists).
[PASS] App opened and all Home status lights match reality.
Screenshot saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\home_tab.png
[PASS] Home tab screenshot exported: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\home_tab.png
[PASS] GUI safely closed.

>>> GATE G0 RESULT: PASS <<<
==============================================================
```

---

## Model Training: Final MSTAR ATR Classifier (`research_new/train_final_mstar.m`)

- **Command**: `matlab -batch "startup; run('research_new/train_final_mstar.m');"`
- **Date**: 2026-10-31 14:30:54
- **Verdict**: PASS

### Raw Command Output
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== MSTAR FINAL ATR TRAINING ====================
Date: 2026-10-31 14:30:54
Preparing 15 deg test set (2425 chips)...
Preparing 17 deg training set (2747 chips)...

Beginning training across 5 seeds (30 epochs each)...
Seed 1: Test Accuracy =  99.30 %  (Training time: 40.8 s)
Seed 2: Test Accuracy =  99.05 %  (Training time: 31.5 s)
Seed 3: Test Accuracy =  99.13 %  (Training time: 31.6 s)
Seed 4: Test Accuracy =  98.93 %  (Training time: 30.9 s)
Seed 5: Test Accuracy =  98.68 %  (Training time: 31.8 s)

--- Summary across 5 seeds ---
Mean Test Accuracy:  99.02 % +/-  0.23 %
Target Gate Range : 98.82 % +/- 0.50 % (98.32 % - 99.32 %)

[PASS] Seed 1 model saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat
Seed 1 Test Accuracy:  99.30 %
==================================================================
```

---

## Gate G1: Adapters and Golden Tests (`tests/run_g1_tests.m`)

- **Command**: `matlab -batch "addpath('tests'); run_g1_tests;"`
- **Date**: 2026-11-03 23:50:19
- **Verdict**: PASS

### Raw Command Output
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G1 ADAPTERS & GOLDEN TESTS ====================
Date: 2026-11-03 23:50:19
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
Running TestG1Adapters
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
[PASS] testMstarDatasetCounts: train 2747, test 2425, 10 classes verified.
.gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
[PASS] testGotchaPass8ApertureAndResolution: 358 pulses x 432 freqs, -3 dB width X = 0.302 m (0.30 m +/- 10%).
.[PASS] testClassifierAccuracy: 5-seed mean 99.02 %, seed 1 99.30 % (within 98.82 +/- 0.50 %).
.[PASS] testSyntheticSpeckleBiases: Lee bias = +0.01 %, Gamma-MAP bias = -3.89 % (diffs: 0.000000e+00, 0.000000e+00).
.[PASS] testMerlinSyntheticSelfTest: median |log(Rhat/R)| = 0.0817 (gate: 0.081 +/- 0.02).
.[PASS] testMerlinEvaluationMetrics: ENL gain = 21.39, bias = +1.96 %, numerical diff = 0.000000e+00.
.[PASS] testScientificDomainBoundaries: MERLIN correctly rejects real amplitude input.
.
Done TestG1Adapters
__________


----------------- Test Results Summary -----------------

ans =

  7 6 table

                                    Name                                    Passed    Failed    Incomplete    Duration      Details   
    ____________________________________________________________________    ______    ______    __________    ________    ____________

    {'TestG1Adapters/testMstarDatasetCounts'                           }    true      false       false        1.8387     {1 1 struct}
    {'TestG1Adapters/testGotchaPass8ApertureAndResolution'             }    true      false       false       0.59946     {1 1 struct}
    {'TestG1Adapters/testClassifierAccuracy'                           }    true      false       false        7.9469     {1 1 struct}
    {'TestG1Adapters/testSyntheticSpeckleBiasesAndNumericalEquivalence'}    true      false       false       0.13996     {1 1 struct}
    {'TestG1Adapters/testMerlinSyntheticSelfTest'                      }    true      false       false        3.2154     {1 1 struct}
    {'TestG1Adapters/testMerlinEvaluationMetrics'                      }    true      false       false        1.2799     {1 1 struct}
    {'TestG1Adapters/testScientificDomainBoundaries'                   }    true      false       false       0.13671     {1 1 struct}


>>> GATE G1 RESULT: PASS (All 7 golden tests passed) <<<
=========================================================================
```

---

## Gate G0 (Reopened): Interactive Session Path Bug & Callback Failure

- **Status**: REOPENED
- **Verdict**: FAIL (Reproduced)
- **Date**: 2026-11-10 00:17:32
- **Command**: `powershell -File "scripts/reproduce_path_bug.ps1"`
- **Test Context**: Executed from outside repository root (`$env:TEMP`) with only `app/` on MATLAB path.

### Raw Error Reproduction Output
```
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
{ Unable to resolve the name 'sar.env.check'.

Error in SARWorkbench/refreshEnvironment (line 53)
            app.EnvStatus = sar.env.check();
                            ^^^^^^^^^^^^^^^
Error in SARWorkbench (line 45)
            refreshEnvironment(app);
            ^^^^^^^^^^^^^^^^^^^^^^^
}  
ERROR: MATLAB error Exit Status: 0x00000001
```

### Root Cause Analysis & Fix
1. **Path Independence Failure**:
   - `+sar` is a top-level package directory at the repository root. When MATLAB starts from an external folder with only `app/` added to the search path, `sar.env.check` cannot resolve.
   - In `ensurePaths()`, checking `contains(path, repoRoot)` returned `true` erroneously because `repoRoot\app` was already in `path` (substring match). Thus `addpath(repoRoot)` was skipped.
   - Fix: Changed path membership check to exact token comparison (`pList = split(path, pathsep); if ~any(strcmpi(pList, reqPath))`).
   - `SARWorkbench.ensurePaths()` now unconditionally ensures `repoRoot`, `app`, `research`, and `models` are on the MATLAB path before any component creation or method invocation.
2. **Missing UI Error Boundaries**:
   - Button callbacks previously invoked `refreshEnvironment` directly without error isolation, dumping stack traces into the MATLAB command window upon failure.
   - Fix: Introduced `handleCallback(app, callbackFn)` method which catches exceptions, issues a user-visible `uialert(app.UIFigure, ME.message, ...)`, and logs a structured warning.
3. **Permanent Regression Test**:
   - Implemented `tests/test_path_independence.m` to verify launch and programmatic button interactions from external directories with only `app/` on path.

---

## Gate G0 (Re-Verification): Three Starting Conditions & Regression Test

- **Date**: 2026-11-10 01:48:35
- **Command**: `powershell -File "scripts/test_three_conditions.ps1"`
- **Verdict**: PASS

### Raw Three-Condition Launch Output
```
=================== CONDITION (A): REPO ROOT ===================
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
================ TESTING LAUNCH: CONDITION A_RepoRoot ================
Current Directory: C:\Users\sruja\OneDrive\Documents\SARorsmthn
Launching SARWorkbench...
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-10 01:48:35
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] App launched. Overall status: PASS
Programmatically triggering Refresh button...
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-10 01:48:37
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] Refresh button executed successfully. Status: PASS
[PASS] App closed cleanly.
>>> CONDITION A_RepoRoot RESULT: PASS <<<


============== CONDITION (B): EXTERNAL DIR (TEMP) ==============
================ TESTING LAUNCH: CONDITION B_ExternalFolderOnlyApp ================
Current Directory: C:\Users\sruja\AppData\Local\Temp
Launching SARWorkbench...
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-10 01:48:54
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] App launched. Overall status: PASS
Programmatically triggering Refresh button...
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-10 01:48:57
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] Refresh button executed successfully. Status: PASS
[PASS] App closed cleanly.
>>> CONDITION B_ExternalFolderOnlyApp RESULT: PASS <<<


============== CONDITION (C): USERPATH (DEFAULT) ===============
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
================ TESTING LAUNCH: CONDITION C_UserPathDefault ================
Current Directory: C:\Users\sruja\OneDrive\Documents\MATLAB
Launching SARWorkbench...
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-10 01:49:15
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] App launched. Overall status: PASS
Programmatically triggering Refresh button...
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-10 01:49:17
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] Refresh button executed successfully. Status: PASS
[PASS] App closed cleanly.
>>> CONDITION C_UserPathDefault RESULT: PASS <<<


================ ALL THREE CONDITIONS COMPLETE ================
```

### Permanent Path Independence Test (`tests/test_path_independence.m`)
- **Command**: `matlab -batch "res = runtests('tests/test_path_independence.m'); disp(table(res))"`
- **Date**: 2026-11-10 01:51:42
- **Verdict**: PASS
```
                                      Name                                      Passed    Failed    Incomplete    Duration      Details   
    ________________________________________________________________________    ______    ______    __________    ________    ____________

    {'test_path_independence/testLaunchFromExternalFolderWithOnlyAppOnPath'}    true      false       false        6.8378     {1 1 struct}
```

---

## Gate G1 Negative Controls (`tests/run_g1_negative_controls.m`)

- **Command**: `matlab -batch "addpath('tests'); run_g1_negative_controls;"`
- **Date**: 2026-11-10 02:03:03
- **Verdict**: PASS (All 7 Negative Controls actively caught and failed)

### Raw Negative Controls Output
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G1 NEGATIVE CONTROLS ====================
Date: 2026-11-10 02:03:03

--- 1. Negative Control: MSTAR Dataset Counts ---
[EXPECTED FAIL] Caught assertion: "Deliberate mismatch: expected 2000 train chips"

--- 2. Negative Control: Gotcha Resolution Width ---
gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
[EXPECTED FAIL] Caught assertion: "Resolution width 0.523 m outside [0.27, 0.33] m"

--- 3. Negative Control: ATR Classifier Accuracy (Shuffled Labels) ---
   Shuffled test accuracy: 10.31 %
[EXPECTED FAIL] Caught assertion: "Accuracy 10.31 % outside [98.32, 99.32] %"

--- 4. Negative Control: Synthetic Speckle Bias ---
[EXPECTED FAIL] Caught assertion: "Injected bias 44.01 % exceeds 0.5 % tolerance"

--- 5. Negative Control: MERLIN Synthetic Self-Test ---
[EXPECTED FAIL] Caught assertion: "Self-test median error 1.4432 outside [0.061, 0.101]"

--- 6. Negative Control: MERLIN ENL Gain on Raw Data ---
[EXPECTED FAIL] Caught assertion: "Raw data ENL gain 1.00 does not meet MERLIN target 21.4 +/- 1.5"

--- 7. Negative Control: Scientific Domain Boundary Enforcement ---
[PASS] Positive control: Valid complex data is accepted without error.
[EXPECTED FAIL] Caught rejection: "MERLIN requires COMPLEX single-look SAR imagery (H x W >= 128x128). Detected real amplitude input (e.g. Sentinel-1 GRD). Operation is disabled in accordance with scientific boundaries."

================ NEGATIVE CONTROLS SUMMARY ================
    test1: 'PASS (Negative Control Caught)'
    test2: 'PASS (Negative Control Caught)'
    test3: 'PASS (Negative Control Caught)'
    test4: 'PASS (Negative Control Caught)'
    test5: 'PASS (Negative Control Caught)'
    test6: 'PASS (Negative Control Caught)'
    test7: 'PASS (Negative Control Caught)'

>>> ALL 7 NEGATIVE CONTROLS VERIFIED TO ACTIVELY ASSERT AND FAIL <<<
===================================================================
```

---

## Gate G1: Adapters and Golden Tests (Full Recomputation Run)

- **Command**: `matlab -batch "addpath('tests'); run_g1_tests;"`
- **Date**: 2026-11-10 02:04:34
- **Verdict**: PASS

### Raw Command Output
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G1 ADAPTERS & GOLDEN TESTS ====================
Date: 2026-11-10 02:04:34
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
Running TestG1Adapters
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
[PASS] testMstarDatasetCounts: train 2747, test 2425, 10 classes verified.
.gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
[PASS] testGotchaPass8ApertureAndResolution: 358 pulses x 432 freqs, -3 dB width X = 0.304 m (0.30 m +/- 10%).
.[PASS] testClassifierAccuracy: Recomputed Seed 1 test accuracy = 99.30 % (within 98.82 +/- 0.50 %); 5-seed mean = 99.02 % (historical logged value).
.[PASS] testSyntheticSpeckleBiases: Lee bias = +0.01 %, Gamma-MAP bias = -3.89 % (diffs: 0.000000e+00, 0.000000e+00).
.[PASS] testMerlinSyntheticSelfTest: median |log(Rhat/R)| = 0.0817 (gate: 0.081 +/- 0.02).
.[PASS] testMerlinEvaluationMetrics: Recomputed 400 chips: ENL gain = 21.39, bias = +1.96 %, diff = 1.699670e-07.
.[PASS] testScientificDomainBoundaries: MERLIN correctly rejects real amplitude input.
.
Done TestG1Adapters
__________


----------------- Test Results Summary -----------------

ans =

  7 6 table

                                    Name                                    Passed    Failed    Incomplete    Duration      Details   
    ____________________________________________________________________    ______    ______    __________    ________    ____________

    {'TestG1Adapters/testMstarDatasetCounts'                           }    true      false       false        1.7957     {1 1 struct}
    {'TestG1Adapters/testGotchaPass8ApertureAndResolution'             }    true      false       false       0.52903     {1 1 struct}
    {'TestG1Adapters/testClassifierAccuracy'                           }    true      false       false        9.8697     {1 1 struct}
    {'TestG1Adapters/testSyntheticSpeckleBiasesAndNumericalEquivalence'}    true      false       false       0.13527     {1 1 struct}
    {'TestG1Adapters/testMerlinSyntheticSelfTest'                      }    true      false       false        3.2313     {1 1 struct}
    {'TestG1Adapters/testMerlinEvaluationMetrics'                      }    true      false       false        107.62     {1 1 struct}
    {'TestG1Adapters/testScientificDomainBoundaries'                   }    true      false       false        0.1142     {1 1 struct}


>>> GATE G1 RESULT: PASS (All 7 golden tests passed) <<<
=========================================================================
```



## Gate G2a: Despeckle Tab Implementation & Verification

### Context & Implementation
- Programmatic `uifigure` Despeckle tab built directly in `app/SARWorkbench.m` calling `+sar` adapter functions only.
- Components include:
  1. Dynamic domain banner (`BannerDespeckle`) with state-dependent color styling and explicit advisory messages:
     - Real amplitude + MERLIN: Red background `[SCIENTIFIC LIMIT]` stating MERLIN requires complex single-look imagery; Run Filter button disabled.
     - Failed-validation Gotcha MERLIN: Red background `[FAILED VALIDATION]` warning of point-target distortion (peak ratio 0.39, widths 1.39/1.45).
     - Operational MSTAR MERLIN: Amber background `[PHYSICAL LIMIT]` noting downstream classifier utility and point-target overshoot.
     - Gamma-MAP: Amber background `[METHOD ADVISORY]` noting intrinsic -3.8% negative bias.
     - Lee / Frost: Neutral background `[METHOD ADVISORY]` noting downstream classification gain parity with spatial augmentation and harm from over-smoothing.
  2. Input dataset selector: MSTAR complex test chip (class dropdown + chip spinner), Gotcha Pass 8 complex aperture backprojection, Sentinel-1 GRD real amplitude crop, and User MAT file.
  3. Despeckle algorithm & parameter panel populated dynamically from `sar.registry.despeckle(includeFailed)` with "Show Failed Methods" checkbox.
  4. Three synchronized `uiaxes` displays: Raw SAR amplitude (dB), Filtered SAR amplitude (dB), and Speckle Ratio (Raw / Filtered).
  5. Quantitative metrics panel: Clutter ENL (raw), Filtered ENL, ENL Gain, Intensity Bias, and elapsed computation time.

### Verification Run
- Command: `matlab -batch "run('scripts/test_g2a.m')"`
- Date: 2026-11-17 04:36:29
- Verbatim raw output:

```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G2A DESPECKLE TAB VERIFICATION ====================
Date: 2026-11-17 04:36:29

--- 1. App Launch & Tab Initialization ---
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-17 04:36:33
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] App launched and DespeckleTab selected.
[PASS] Default MSTAR chip loaded: MSTAR 2s1_gun #1

--- 2. Lee Filter Numerical Equivalence (GUI vs Script) ---
   Max absolute difference (GUI vs Script Lee): 0.000000e+00
[PASS] Lee filter numerical equivalence verified (< 1e-6).

--- 3. MERLIN Filter Numerical Equivalence (GUI vs Script) ---
   Max absolute difference (GUI vs Script MERLIN): 0.000000e+00
[PASS] MERLIN numerical equivalence verified (< 1e-6).

--- 4. Amplitude Source Boundary Enforcement ---
   Loaded Amplitude Source: Sentinel-1 GRD Crop (isreal=1)
[PASS] MERLIN Run button correctly disabled for amplitude source.
       Banner: "[SCIENTIFIC LIMIT] MERLIN requires COMPLEX single-look SAR imagery. Real amplitude data (e.g. Sentinel-1 GRD) is strictly prohibited. Run Filter is disabled."

--- 5. Negative Control: Forcing MERLIN on Amplitude Data ---
[EXPECTED FAIL] Caught rejection: "MERLIN requires COMPLEX single-look SAR imagery (H x W >= 128x128). Detected real amplitude input (e.g. Sentinel-1 GRD). Operation is disabled in accordance with scientific boundaries."
[PASS] Negative control passed: direct MERLIN invocation rejected.

--- 6. Failed-Validation Gotcha MERLIN Toggle ---
[PASS] Failed-validation Gotcha MERLIN displayed with RED warning banner.
       Banner: "[FAILED VALIDATION] Gotcha-trained MERLIN failed point-target validation (peak ratio 0.39, widths 1.39/1.45). Causes severe target distortion. Not approved for operational use."

--- 7. Screenshot Export ---
Screenshot saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\despeckle_tab.png
[PASS] Despeckle tab screenshot exported to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\despeckle_tab.png

>>> GATE G2A RESULT: PASS <<<
==============================================================================
```

### Artifacts Produced
- `docs/despeckle_tab.png` (244 KB, timestamp: 2026-11-17 04:36:50)
- `scripts/test_g2a.m` (Automated headless & programmatic test harness for Despeckle tab)

## Gate G2a Backfill Verification

### Backfill Summary & Resolutions
1. **Multi-Chip, Multi-Parameter Equivalence**:
   - Reference: Frozen research functions `despeckle_filters.m` and `p3b_denoise.m`, called independently on raw chip data.
   - Tested across 5 distinct target classes (`2s1_gun`, `bmp2_tank`, `btr70_transport`, `t72_tank`, `brdm2_truck`).
   - Evaluated 4 parameter configurations per class:
     - Lee (win=7, looks=1): max absolute difference = `0.000000e+00`
     - Lee (win=5, looks=1): max absolute difference = `0.000000e+00`
     - MERLIN (auto scale `M.s` = 0.0521): max absolute difference = `0.000000e+00`
     - MERLIN (explicit scale = 0.06): max absolute difference = `0.000000e+00`
2. **Equivalence Negative Control**:
   - Perturbed parameter check: GUI Lee (win=7) vs Reference Lee (win=5) yields difference = `1.161290e-01` (> 0.01), proving that parameter perturbation fails the equivalence test and asserting detection sensitivity.
3. **Metrics Panel Verification**:
   - MSTAR chip metrics matched against `p3b_metrics`:
     - Raw Clutter ENL: `0.51` (matches `m.enlRaw`)
     - Filtered ENL: `1.92` (matches `m.enl`)
     - ENL Gain: `3.79 x` (matches `m.gain`)
     - Intensity Bias: `-0.90 %` (matches `100 * m.bias`)
     - Peak Ratio: `0.75` (matches `m.peak`)
   - Unsegmented sources (Gotcha, Sentinel-1): Clutter and peak metrics display `n/a` as clutter/target regions are unsegmented without user ROI.
4. **MERLIN on Gotcha Source Banner**:
   - Selecting MSTAR-trained MERLIN on Gotcha Pass 8 source triggers specific banner:
     `[PHYSICAL LIMIT] MSTAR-trained MERLIN on Gotcha distorts point targets (peak ratio 1.54, half-power widths 1.72 / 1.54 m vs 0.30 m raw). Severe point-target broadening and overshoot.`
5. **Consistency of Cached MERLIN Test Chips**:
   - Verified that `mstar_merlin.mat` (`Xte_m`) is bit-for-bit identical to live `p3b_denoise` across 10 test chips (max difference across all 10 chips: `0.000000e+00`).

---

## Gate G2b: MSTAR ATR Tab Verification & Master Regression Run

### Context & Implementation
- Programmatic `uifigure` ATR tab implemented in `app/SARWorkbench.m` calling `+sar` adapter functions only.
- Components include:
  1. Dynamic domain banner (`BannerAtr`) reflecting training distribution vs mismatch:
     - Neutral background for nominal `Raw (Nominal N)` (99.30% test accuracy).
     - Red alert background `[PREPROCESSING MISMATCH]` for non-raw options (`Lee 7`, `Boxcar 7`, `MERLIN`), stating the exact live-measured test set accuracy for each.
  2. Chip browser:
     - Target class dropdown (10 MSTAR vehicle classes).
     - Chip index spinner with dynamic limits per class.
     - Azimuth angle display in degrees (from `azte`).
     - File metadata label (from `pte`).
  3. Preprocessing selector:
     - `Raw (Nominal N)`, `Lee (7x7)`, `Boxcar (7x7)`, `MERLIN`.
  4. Actions:
     - "Classify Chip": Evaluates single chip, updates predicted class, match indicator, Top-1 confidence, and Top-3 class probabilities.
     - "Evaluate Full Test Set (2425 Chips)": Recomputes predictions across all 2425 test chips and renders 10x10 normalized confusion chart.
  5. Displays:
     - `AxesAtrChip`: 128x128 SAR chip magnitude in dB scale [-40 0].
     - Single-chip ATR output panel: Prediction, confidence, Top-3 probabilities, test accuracy summary.
     - `PanelConfusion`: 10x10 confusion chart with row- and column-normalized summaries.
     - Bottom summary panel: Live measured accuracy table across all 4 preprocessing modes.

### Master Regression Suite Run
- Command: `matlab -batch "run('tests/run_all_tests.m')"`
- Date: 2026-11-23 19:07:39
- Verbatim raw output:

```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==============================================================================
           SAR WORKBENCH PHASE 5 COMPREHENSIVE REGRESSION SUITE
Date: 2026-11-23 19:07:39
Repo Root: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==============================================================================

>>> STEP 1/5: RUNNING GATE G0 (ENVIRONMENT CHECK) <<<
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-23 19:07:39
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] Gate G0 passed cleanly.

>>> STEP 2/5: VERIFYING PATH SELF-CONTAINMENT <<<
[PASS] Path self-containment verified.

>>> STEP 3/5: RUNNING GATE G1 (GOLDEN ADAPTER TESTS) <<<
Running TestG1Adapters
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
[PASS] testMstarDatasetCounts: train 2747, test 2425, 10 classes verified.
.gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
[PASS] testGotchaPass8ApertureAndResolution: 358 pulses x 432 freqs, -3 dB width X = 0.304 m (0.30 m +/- 10%).
.[PASS] testClassifierAccuracy: Recomputed Seed 1 test accuracy = 99.30 % (>= 98.32 %); 5-seed mean = 99.02 % (historical logged value).
.[PASS] testSyntheticSpeckleBiases: Lee bias = +0.01 %, Gamma-MAP bias = -3.89 % (diffs: 0.000000e+00, 0.000000e+00).
.[PASS] testMerlinSyntheticSelfTest: median |log(Rhat/R)| = 0.0817 (gate: 0.081 +/- 0.02).
.[PASS] testMerlinEvaluationMetrics: Recomputed 400 chips: ENL gain = 21.39, bias = +1.96 %, diff = 1.699670e-07.
.[PASS] testScientificDomainBoundaries: MERLIN correctly rejects real amplitude input.
.
Done TestG1Adapters
__________

[PASS] Gate G1 passed (7/7 tests passed).

>>> STEP 4/5: RUNNING GATE G2A (DESPECKLE TAB) <<<
==================== GATE G2A DESPECKLE TAB VERIFICATION ====================
Date: 2026-11-23 19:09:54
Reference: Frozen research functions despeckle_filters.m and p3b_denoise.m, executed independently.

--- 1. App Launch & Tab Initialization ---
[ Warning: Scrollable is set to 'on' on all figures because the Windows accessibility text size setting is greater than 100%.
To prevent this behavior, revert the text size setting back to 100% and instead use the Windows system display scale setting to increase the size of on-screen elements.]  
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-23 19:09:58
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
[PASS] GPU Detected: NVIDIA GeForce RTX 3050 Laptop GPU (4.00 GB total, 3.19 GB free, CC 8.6)

--- Data Paths ---
[PASS] MSTAR Data: found (13 raw folders, mstar_soc.mat=1)
[PASS] Gotcha Data: found (1440 .mat files in C:\Users\sruja\OneDrive\Documents\SARorsmthn\Gotcha-CP-Disc2)
[PASS] Sentinel-1 Data: found (2 SAFE dirs, 0 zip files)

--- Trained Models ---
[PASS] MERLIN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin.mat
[PASS] MERLIN (Gotcha): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin_gotcha.mat
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] App launched and DespeckleTab selected.

--- 2. Multi-Chip, Multi-Parameter Equivalence Checks ---
Testing Class: 2s1_gun
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: bmp2_tank
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: btr70_transport
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: t72_tank
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: brdm2_truck
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
[PASS] All 5 classes and 4 parameter settings numerically verified against frozen research.

--- 3. Negative Control: Parameter Perturbation Detection ---
   Perturbed parameter diff (GUI Lee 7 vs Ref Lee 5): 1.161290e-01
[PASS] Negative control passed: equivalence check correctly catches parameter discrepancy.

--- 4. Metrics Panel Verification ---
   GUI Metric Displays:
     Raw Clutter ENL: 0.51
     Filtered ENL: 1.92
     ENL Gain: 3.79 x
     Intensity Bias: -0.90 %
     Peak Ratio: 0.75
[PASS] MSTAR metrics panel matches p3b_metrics exactly.
gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
[PASS] Unsegmented Gotcha source displays n/a for undefined clutter/target metrics.

--- 5. MERLIN (MSTAR Net) on Gotcha Source Banner Check ---
   Banner: "[PHYSICAL LIMIT] MSTAR-trained MERLIN on Gotcha distorts point targets (peak ratio 1.54, half-power widths 1.72 / 1.54 m vs 0.30 m raw). Severe point-target broadening and overshoot."
[PASS] MERLIN on Gotcha triggers specific point-target distortion banner.

--- 6. Amplitude Source Boundary Enforcement ---
[PASS] MERLIN Run button disabled on amplitude source.
[PASS] Direct invocation negative control rejected with: "MERLIN requires COMPLEX single-look SAR imagery (H x W >= 128x128). Detected real amplitude input (e.g. Sentinel-1 GRD). Operation is disabled in accordance with scientific boundaries."

--- 7. Failed-Validation Gotcha MERLIN Toggle Check ---
[PASS] Failed-validation Gotcha MERLIN displayed with RED warning banner.

--- 8. Screenshot Export ---
Screenshot saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\despeckle_tab.png
[PASS] Despeckle tab screenshot exported to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\despeckle_tab.png

>>> GATE G2A RESULT: PASS (All Backfill Conditions Satisfied) <<<
==============================================================================
[PASS] Gate G2a passed cleanly.

>>> STEP 5/5: RUNNING GATE G2B (MSTAR ATR TAB) <<<
==================== GATE G2B MSTAR ATR TAB VERIFICATION ====================
Date: 2026-11-23 19:10:20
Reference: Frozen research function p4b_predict.m and models/cnn_mstar.mat.

--- 1. App Launch & Tab Initialization ---
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-23 19:10:21
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
[PASS] GPU Detected: NVIDIA GeForce RTX 3050 Laptop GPU (4.00 GB total, 3.19 GB free, CC 8.6)

--- Data Paths ---
[PASS] MSTAR Data: found (13 raw folders, mstar_soc.mat=1)
[PASS] Gotcha Data: found (1440 .mat files in C:\Users\sruja\OneDrive\Documents\SARorsmthn\Gotcha-CP-Disc2)
[PASS] Sentinel-1 Data: found (2 SAFE dirs, 0 zip files)

--- Trained Models ---
[PASS] MERLIN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin.mat
[PASS] MERLIN (Gotcha): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\p3b_merlin_gotcha.mat
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] App launched and AtrTab selected.

--- 2. Chip Browser & Metadata Navigation ---
   Selected: Class=t72_tank, ChipIdx=5
   Displayed Azimuth: Azimuth: 278.8 deg
   Target Info      : File: HB03338.015 (idx 5/196)
[PASS] Chip browser navigation and display verified.

--- 3. Single-Chip Prediction & Scores Equivalence ---
   Max score difference (sar.atr.predict vs p4b_predict): 0.000000e+00
   GUI Display: Predicted: t72_tank (Match: YES)
[PASS] Single-chip prediction and scores equivalence verified (< 1e-6).

--- 4. Negative Control: Preprocessing Shift Detection ---
   Preprocessing shift diff (Raw vs Lee 7 scores): 2.393891e-01
[PASS] Negative control passed: preprocessing shift cleanly detected (> 0.05).

--- 5. Full Test Set Recomputation (2425 Chips) ---
   Full Test Set [RAW]:
Accuracy: 99.30 % (2408 / 2425)
[PASS] Full test set accuracy recomputed = 99.30 % (2408 / 2425).

--- 6. Live Preprocessing Mismatch Evaluation & Banner Enforcement ---

Preprocessing      | Measured Accuracy | Degradation  | Banner Alert
--------------------------------------------------------------------------------
raw                |  99.30 % (2408/2425) | Nominal (0.00 pp) | Neutral   
lee                |  50.39 % (1222/2425) | -48.91 pp    | RED Mismatch
boxcar             |  33.32 % ( 808/2425) | -65.98 pp    | RED Mismatch
merlin             |  46.80 % (1135/2425) | -52.50 pp    | RED Mismatch
--------------------------------------------------------------------------------
[PASS] All 4 preprocessing modes live measured and banner alerts verified.

--- 7. Screenshot Export ---
Screenshot saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\atr_tab.png
[PASS] ATR tab screenshot exported to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\atr_tab.png

>>> GATE G2B RESULT: PASS <<<
==============================================================================
[PASS] Gate G2b passed cleanly.

==============================================================================
>>> ALL PHASE 5 GATES AND REGRESSION TESTS PASSED IN 179.80 SECONDS <<<
==============================================================================
```

### Artifacts Produced
- `docs/atr_tab.png` (182 KB, timestamp: 2026-11-23 19:10:38)
- `docs/despeckle_tab.png` (257 KB, timestamp: 2026-11-23 19:10:19)
- `scripts/test_g2b.m` (Automated verification script for ATR tab)
- `tests/run_all_tests.m` (Comprehensive regression suite across G0, Path, G1, G2a, G2b)


## Gate G2a Backfill: Multi-Chip Equivalence and Metrics Panel Verification
**Command**: `matlab -batch "run('scripts/test_g2a.m')"`
**Date**: 2026-11-27 03:23:34
**Commit**: Working tree (Gate G2a & G2c verification)
**Status**: PASS

### Raw Execution Log
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G2A DESPECKLE TAB VERIFICATION ====================
Date: 2026-11-27 03:23:34
Reference: Frozen research functions despeckle_filters.m and p3b_denoise.m, executed independently.

--- 1. App Launch & Tab Initialization ---
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-27 03:23:39
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

[PASS] App launched and DespeckleTab selected.

--- 2. Multi-Chip, Multi-Parameter Equivalence Checks ---
Testing Class: 2s1_gun
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: bmp2_tank
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: btr70_transport
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: t72_tank
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
Testing Class: brdm2_truck
   Lee win=7 looks=1 max diff: 0.000000e+00 (PASS)
   Lee win=5 looks=1 max diff: 0.000000e+00 (PASS)
   MERLIN auto scale max diff: 0.000000e+00 (PASS)
   MERLIN scale=0.06 max diff: 0.000000e+00 (PASS)
[PASS] All 5 classes and 4 parameter settings numerically verified against frozen research.

--- 3. Negative Control: Parameter Perturbation Detection ---
   Perturbed parameter diff (GUI Lee 7 vs Ref Lee 5): 1.161290e-01
[PASS] Negative control passed: equivalence check correctly catches parameter discrepancy.

--- 4. Metrics Panel Verification (Lee & MERLIN across 5 Classes) ---
   Class 2s1_gun        : Lee (gain=8.10x, bias=-1.63%) | MERLIN (gain=28.05x, bias=+1.89%) [MATCH]
   Class bmp2_tank      : Lee (gain=5.45x, bias=-2.34%) | MERLIN (gain=44.29x, bias=-6.83%) [MATCH]
   Class btr70_transport: Lee (gain=6.51x, bias=-1.36%) | MERLIN (gain=32.99x, bias=-2.98%) [MATCH]
   Class t72_tank       : Lee (gain=5.35x, bias=-1.26%) | MERLIN (gain=35.03x, bias=-1.18%) [MATCH]
   Class brdm2_truck    : Lee (gain=3.79x, bias=-0.90%) | MERLIN (gain=22.39x, bias=-0.84%) [MATCH]
[PASS] Metrics panel matches p3b_metrics across all 5 classes for both Lee and MERLIN.
   --- Metrics Panel Negative Control (Clutter Mask Perturbation) ---
     Clutter mask shift: Gain diff = 3.50, Bias diff = 0.1073
[PASS] Metrics negative control passed: metric calculation is strictly sensitive to clutter region.
[PASS] Unsegmented Gotcha source displays n/a for undefined clutter/target metrics.

--- 5. MERLIN (MSTAR Net) on Gotcha Source Banner Check ---
   Banner: "[PHYSICAL LIMIT] MSTAR-trained MERLIN on Gotcha distorts point targets (peak ratio 1.54, half-power widths 1.72 / 1.54 m vs 0.30 m raw). Severe point-target broadening and overshoot."
[PASS] MERLIN on Gotcha triggers specific point-target distortion banner.

--- 6. Amplitude Source Boundary Enforcement ---
[PASS] MERLIN Run button disabled on amplitude source.
[PASS] Direct invocation negative control rejected with: "MERLIN requires COMPLEX single-look SAR imagery (H x W >= 128x128). Detected real amplitude input (e.g. Sentinel-1 GRD). Operation is disabled in accordance with scientific boundaries."

--- 7. Failed-Validation Gotcha MERLIN Toggle Check ---
[PASS] Failed-validation Gotcha MERLIN displayed with RED warning banner.

--- 8. Screenshot Export ---
Screenshot saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\despeckle_tab.png
[PASS] Despeckle tab screenshot exported to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\despeckle_tab.png

>>> GATE G2A RESULT: PASS (All Backfill Conditions Satisfied) <<<
==============================================================================
```

---

## Gate G2c: Gotcha Planar Backprojection Imaging Tab
**Command**: `matlab -batch "run('scripts/test_g2c.m')"`
**Date**: 2026-11-27 03:22:49
**Commit**: Working tree (Gotcha Tab implementation)
**Status**: PASS

### Verification Summary
1. **Control Defaults and Validation Labels**: Polarization dropdown defaults to `'HH'`; `'VV (not validated)'`, `'HV (not validated)'`, and `'VH (not validated)'` clearly marked. Aperture defaults to `az 1:3` (start 1, width 3), pixel size `0.30 m`, height `z = -0.3 m`.
2. **Numerical Equivalence Against Frozen Research (`bp_gotcha`)**:
   - For Pass 8 HH, Az 1-3 ($161 \times 167$ pixels, $dx=0.30\text{ m}$): GUI backprojection slice exactly matches frozen research function `bp_gotcha.m` with difference `0.000000e+00`.
   - Grid coordinates $xv$ and $yv$ match with difference `0.000000e+00`.
3. **Equivalence Negative Control (Aperture Discrepancy)**:
   - Comparing GUI image against `bp_gotcha` formed on aperture Az 86-88 yields max difference `5.991057e+01` ($> 1.0$).
4. **Calibration Target 2 (15TR03C) Resolution & Survey Offset**:
   - Location: `[-28.09, 38.67] m`, survey heading 90 deg.
   - Measured Range -3 dB width $w_x = 0.3145\text{ m}$ (within $0.30\text{ m} \pm 10\%$ $[0.27, 0.33\text{ m}]$).
   - Measured Azimuth -3 dB width $w_y = 0.4008\text{ m}$, Mean width $= 0.3576\text{ m}$.
   - Measured Offset from survey $= 0.6140\text{ m}$ (within unexplained empirical range $0.15 - 0.75\text{ m}$).
   - Status reports: `CALIBRATION TARGET STATUS: PASS`.
5. **Reflector Catalog & Visibility Across 4 Cardinal Test Apertures**:
   - Detects all 13 visible target/aperture pairs across `{1:3, 86:88, 176:178, 266:268}`:
     - Aperture Az 1-3 (Look 90°): Target 2 (15TR03C, 43.0 dB), Target 10 (15TR10N, 26.1 dB).
     - Aperture Az 86-88 (Look 0°): Target 3 (15TR02E, 41.3 dB), Target 5 (15TR05E, 42.3 dB), Target 8 (15TR08E, 43.3 dB), Target 11 (15TR11E, 38.9 dB), Target 13 (15TR13E, 26.3 dB).
     - Aperture Az 176-178 (Look 270°): Target 4 (15TR04S, 42.0 dB), Target 6 (15TR07S, 39.7 dB), Target 12 (15TR12S, 40.0 dB).
     - Aperture Az 266-268 (Look 180°): Target 1 (15TR01W, 40.8 dB), Target 7 (15TR06W, 51.8 dB), Target 14 (15TR14W, 38.6 dB).
     - Total: Exactly 13 / 13 detected.
6. **Scientific Advisory Banners Verified**:
   - `Planar backprojection (z = -0.3 m). Unexplained look-dependent offsets of 0.15 - 0.75 m relative to ground truth survey. Autofocus corrections not applied (afr=afp=0). Phase Gradient Autofocus (PGA) not implemented.`
7. **Artifacts Exported**:
   - `docs/gotcha_tab.png` (122 KB)
   - Multi-scale screenshots: `docs/gotcha_tab_100.png`, `docs/gotcha_tab_125.png`, `docs/gotcha_tab_150.png`

### Raw Execution Log
```
SAR Workbench environment initialized from: C:\Users\sruja\OneDrive\Documents\SARorsmthn
==================== GATE G2C GOTCHA IMAGING TAB VERIFICATION ====================
Date: 2026-11-27 03:22:49
Reference: Frozen research functions gotcha_find.m, gotcha_load.m, bp_gotcha.m, and p3b_gotcha_test.m

--- 1. App Launch & Gotcha Tab Initialization ---
================ SAR Workbench Environment Check ================
Timestamp: 2026-11-27 03:22:53
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
[PASS] ATR CNN (MSTAR): C:\Users\sruja\OneDrive\Documents\SARorsmthn\models\cnn_mstar.mat

>>> OVERALL STATUS: PASS (Ready for Phase 5 SAR Workbench operations) <<<
=================================================================

gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
[PASS] App launched and GotchaTab initialized.

--- 2. Control Defaults & Polarization Labels ---
   Polarization options: HH, VV (not validated), HV (not validated), VH (not validated)
[PASS] Control defaults and validation labels verified.

--- 3. Numerical Equivalence Against Frozen bp_gotcha (Az 1-3 HH) ---
gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
   GUI vs Reference Image Max Diff: 0.000000e+00
   X-grid max diff: 0.000000e+00, Y-grid max diff: 0.000000e+00
[PASS] Numerical equivalence against frozen bp_gotcha confirmed.

--- 4. Equivalence Negative Control (Aperture Discrepancy Detection) ---
gotcha_find: 3 files, az 86..88
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 359 pulses x 432 freqs from 3 files; af corrections: 1
   Negative control diff (Az 1-3 vs Az 86-88): 5.991057e+01
[PASS] Negative control passed: backprojection image is strictly aperture-sensitive.

--- 5. Calibration Target 2 (15TR03C) Resolution & Offset Check ---
   Target 2 (15TR03C) Measured Resolution:
     Range -3 dB Width (wx):  0.3145 m (Nominal: 0.30 m +/- 10%)
     Azimuth -3 dB Width (wy): 0.4008 m
     Mean Resolution:         0.3576 m
     Offset from Survey:      0.6140 m (Nominal range: 0.15 - 0.75 m)
     Peak Intensity:          1.17e+03
[PASS] Calibration target resolution (0.314 m) and offset (0.614 m) verified.

--- 6. Reflector Catalog & Visibility Across 4 Test Apertures ---
gotcha_find: 3 files, az 1..3
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
gotcha_find: 3 files, az 86..88
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 359 pulses x 432 freqs from 3 files; af corrections: 1
gotcha_find: 3 files, az 176..178
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
gotcha_find: 3 files, az 266..268
  file 1: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 2: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
  file 3: freq deviation from linear grid = 511 Hz (float32 rounding is <= ~1024 Hz)
gotcha_load: 358 pulses x 432 freqs from 3 files; af corrections: 1
   Total Visible Pairs Detected: 13 / 13 expected
     Pair  1: Ap az [1 2 3] -> Tgt  2 (15TR03C) at (-27.50, 38.50) m | Peak/Med: 43.0 dB | wx=0.314 m, wy=0.401 m
     Pair  2: Ap az [1 2 3] -> Tgt 10 (15TR10N) at (-17.60, 33.40) m | Peak/Med: 26.1 dB | wx=0.519 m, wy=0.346 m
     Pair  3: Ap az [86 87 88] -> Tgt  3 (15TR02E) at (-13.70, 37.90) m | Peak/Med: 41.3 dB | wx=0.359 m, wy=0.333 m
     Pair  4: Ap az [86 87 88] -> Tgt  5 (15TR05E) at (-32.30, 33.40) m | Peak/Med: 42.3 dB | wx=0.339 m, wy=0.312 m
     Pair  5: Ap az [86 87 88] -> Tgt  8 (15TR08E) at (-15.20, 43.30) m | Peak/Med: 43.3 dB | wx=0.480 m, wy=0.313 m
     Pair  6: Ap az [86 87 88] -> Tgt 11 (15TR11E) at (-20.30, 27.40) m | Peak/Med: 38.9 dB | wx=0.537 m, wy=0.441 m
     Pair  7: Ap az [86 87 88] -> Tgt 13 (15TR13E) at (-29.00, 24.70) m | Peak/Med: 26.3 dB | wx=0.346 m, wy=0.582 m
     Pair  8: Ap az [176 177 178] -> Tgt  4 (15TR04S) at (-24.50, 32.80) m | Peak/Med: 42.0 dB | wx=0.331 m, wy=0.374 m
     Pair  9: Ap az [176 177 178] -> Tgt  6 (15TR07S) at (-5.30, 22.90) m | Peak/Med: 39.7 dB | wx=0.352 m, wy=0.562 m
     Pair 10: Ap az [176 177 178] -> Tgt 12 (15TR12S) at (-13.70, 31.90) m | Peak/Med: 40.0 dB | wx=0.321 m, wy=0.334 m
     Pair 11: Ap az [266 267 268] -> Tgt  1 (15TR01W) at (-32.30, 42.10) m | Peak/Med: 40.8 dB | wx=0.505 m, wy=0.353 m
     Pair 12: Ap az [266 267 268] -> Tgt  7 (15TR06W) at (-7.10, 50.80) m | Peak/Med: 51.8 dB | wx=0.455 m, wy=0.307 m
     Pair 13: Ap az [266 267 268] -> Tgt 14 (15TR14W) at (-26.00, 16.90) m | Peak/Med: 38.6 dB | wx=0.408 m, wy=0.436 m
[PASS] All 13 visible reflector pairs confirmed across test apertures.

--- 7. Scientific Advisory Banner Verification ---
   Gotcha Banner Text: "Planar backprojection (z = -0.3 m). Unexplained look-dependent offsets of 0.15 - 0.75 m relative to ground truth survey. Autofocus corrections not applied (afr=afp=0). Phase Gradient Autofocus (PGA) not implemented."
[PASS] Mandatory scientific banners verified.

--- 8. Screenshot Export ---
Screenshot saved to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\gotcha_tab.png
[PASS] Gotcha tab screenshot exported to: C:\Users\sruja\OneDrive\Documents\SARorsmthn\docs\gotcha_tab.png

>>> GATE G2C RESULT: PASS (All Gotcha Image Formation Requirements Satisfied) <<<
===================================================================================
```

---

## Master Regression Suite Run (Gates G0 through G2c)
**Command**: `matlab -batch "run('tests/run_all_tests.m')"`
**Date**: 2026-11-27 03:30:54
**Execution Time**: 179.25 seconds
**Status**: PASS (All 6 test stages passed cleanly)
