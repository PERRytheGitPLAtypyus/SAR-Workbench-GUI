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
