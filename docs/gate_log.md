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

