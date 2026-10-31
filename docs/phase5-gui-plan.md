# SAR Workbench - Phase 5 GUI & Release Plan

## 1. Overview and Architecture
SAR Workbench is a comprehensive MATLAB application and adapter suite providing an interactive GUI and programmatic API for synthetic aperture radar (SAR) workflows:
- SAR phase history simulation and point-target validation.
- Time-domain backprojection image formation (AFRL Gotcha volumetric SAR data).
- Classical (Lee, Frost, Gamma-MAP) and deep self-supervised (MERLIN) speckle filtering.
- Automatic Target Recognition (ATR) on MSTAR vehicle chips via deep CNNs.
- Interactive visualization of research trade-offs (data dose, filter comparisons, sample complexity curves).

### Core Architectural Rules
1. **Separation of Concerns**: The GUI (`app/SARWorkbench.m`) is strictly a presentation layer. It contains no algorithms. All operations invoke `+sar` package functions.
2. **Adapter Layer (`+sar`)**: Thin wrappers around validated frozen research functions (`bp_gotcha`, `despeckle_filters`, `p3b_denoise`, `mstar_read`, `p4b_predict`, etc.).
3. **Registry Pattern**:
   - `sar.registry.despeckle`: Declares despeckle algorithms, parameter metadata, input domain requirements (`complex` vs `amplitude`), and scientific constraints. Excludes failed methods (`status == 'FAILED_VALIDATION'`) from operational controls.
   - `sar.registry.classifiers`: Declares ATR model architectures, supported classes, normalization methods, and domain notes.
4. **Configuration**: Configurable data and model paths managed via `sarconfig.json` (untracked, local) and `sarconfig.example.json` (tracked in git).
5. **Scientific Integrity**: Strict adherence to physical and empirical limits. Warnings are displayed when pre-conditions (e.g. complex single-look data for MERLIN, normalization consistency for CNNs) are violated.

---

## 2. Deviations from the Brief
1. **Model Filenames**: The brief references `models/merlin.mat`, whereas the frozen Phase 3b trained networks are named `models/p3b_merlin.mat` (MSTAR-trained) and `models/p3b_merlin_gotcha.mat` (Gotcha-trained).
2. **Repository Location**: The brief mentions "Do not put the repo inside OneDrive", but the active workspace assigned by the environment was `C:\Users\sruja\OneDrive\Documents\SARorsmthn`. As confirmed by the user, the repository is maintained in this workspace with `.gitignore` strictly excluding datasets and `.mat` files, while `sarconfig.json` stores local paths and is not tracked in git (only `sarconfig.example.json` is committed).
3. **Dedicated ATR CNN Status Lamp**: To ensure that the Home status lamps match reality 1-to-1 with the environment report, the model status is separated into two lamps: `LampMerlin` (Green) and `LampCnn` (Amber until `models/cnn_mstar.mat` is trained).
4. **MERLIN Gotcha Validation Failure**: `models/p3b_merlin_gotcha.mat` failed the point-target preservation test (peak ratio 0.39, widths 1.39 and 1.45). It is explicitly registered with status `FAILED_VALIDATION` and excluded from normal operational despeckle options.

---

## 3. Directory Structure
```
SARorsmthn/
├── app/
│   └── SARWorkbench.m          # Main programmatic MATLAB UI figure classdef
├── +sar/
│   ├── +env/                   # Environment, toolbox, GPU, and path verification
│   │   ├── check.m
│   │   └── config.m
│   ├── +registry/              # Despeckle and classifier registry definitions
│   │   ├── despeckle.m
│   │   └── classifiers.m
│   ├── +despeckle/             # Adapters for classical & MERLIN filtering
│   │   ├── apply.m
│   │   └── metrics.m
│   ├── +imaging/               # Backprojection & simulation adapters
│   │   ├── backproject.m
│   │   ├── simulate.m
│   │   └── gotcha.m
│   ├── +atr/                   # Classification & MSTAR chip inspection adapters
│   │   ├── predict.m
│   │   ├── evaluate.m
│   │   └── mstar.m
│   └── +results/               # Results loader for stage 2m and dose curves
│       └── loadCurves.m
├── models/
│   ├── p3b_merlin.mat          # Frozen MERLIN network (MSTAR-trained)
│   ├── p3b_merlin_gotcha.mat   # Frozen MERLIN network (Gotcha-trained, failed validation)
│   └── cnn_mstar.mat           # Final trained MSTAR 4-block CNN (trained in G2b)
├── tests/
│   ├── test_g0_skeleton.m      # Automated verification test suite for Gate G0
│   ├── TestG1Adapters.m        # MATLAB Unit Test suite for Gate G1 golden tests
│   └── TestG3UI.m              # Scripted UI execution test suite for Gate G3
├── research/                   # Frozen research scripts (strictly read-only, byte-identical)
├── research_new/               # New utility/training scripts (e.g. train_final_mstar.m)
├── docs/
│   ├── phase5-gui-plan.md      # This document
│   ├── gate_log.md             # Execution log of all gates with raw command outputs
│   ├── home_tab.png            # Screenshot of the Home tab matching environment reality
│   ├── DATA.md                 # Data download and setup guide
│   ├── CITATIONS.md            # Academic citations and data credits
│   └── LIMITATIONS.md          # Known scientific and algorithmic boundaries
├── sarconfig.json              # Local configuration file (untracked in git)
├── sarconfig.example.json      # Template configuration file (tracked in git)
├── startup.m                   # Project path setup script
└── README.md                   # Project overview and quickstart guide
```

---

## 4. Gates and Verification Milestones

### Gate G0: Repository Skeleton & Environment Baseline
- Create folder structure: `app/`, `+sar/`, `models/`, `tests/`, `research/`, `docs/`, `research_new/`.
- Provide `sarconfig.json` (untracked) and `sarconfig.example.json` (tracked).
- Implement `sar.env.check` verifying MATLAB version, required toolboxes, GPU availability, data directories, and model files.
- Build initial tabbed `app/SARWorkbench.m` with Home tab showing real-time environment status.
- **PASS Criteria**: App opens without error; Home status indicators accurately reflect environment and hardware (including Amber lamp for ATR CNN before training).

### Gate G1: `+sar` Adapters & Golden Unit Tests
Golden verification tests running via `matlab.unittest`:
- **MSTAR Dataset Counts**: 2,747 train chips (17 deg), 2,425 test chips (15 deg), across 10 classes.
- **Gotcha Pass 8 Aperture**: Pulses = 358, Frequencies = 432, -3 dB impulse response resolution = 0.30 m (±10%).
- **ATR Accuracy Baseline**: Full-data CNN baseline under Normalisation N achieves 98.82% ± 0.5%.
- **Filter Biases**: Lee filter intensity bias ~ 0%, Gamma-MAP bias ~ -3.8% on synthetic Rayleigh/exponential speckle.
- **MERLIN Synthetic Self-Test**: Median $| \log(\hat{R}/R) | = 0.081 \pm 0.02$.
- **MERLIN Denoising Performance**: `p3b_eval` on test chips with `rng(3)` yields ENL gain 21.4 ± 1.5, bias +1.96%.
- **PASS Criteria**: 100% test pass in `TestG1Adapters.m`.

### Gate G2: Feature Tabs Verification
- **G2a: Despeckle Tab**:
  - Filtering an MSTAR chip matches script output (`despeckle_filters` / `p3b_denoise`) with max absolute difference $< 10^{-6}$.
  - Complex vs amplitude input enforcement: MERLIN disabled for amplitude-only data; scientific domain banner displayed.
- **G2b: MSTAR + ATR Tab**:
  - Train final 4-block CNN (`models/cnn_mstar.mat`) using `research_new/train_final_mstar.m` (seed 1).
  - Verify whole-test-set (2,425 chips) accuracy equals 98.82% ± 0.5%.
  - Display chip preview, class probabilities, and normalisation warnings.
- **G2c: Gotcha Imaging Tab**:
  - Backprojection image formation on pass 8 HH az 1-3.
  - Profile extraction confirms cross-range resolution of 0.30 m (-3 dB width).
- **G2d: Simulate Tab**:
  - 4 point-target spotlight simulation focusing to $(0,0)$ and off-center coordinates without artifacts.
- **G2e: Results Tab**:
  - Sample-complexity curves and summary table match `p4b_stage2m.mat` and `p4b_runs/`.

### Gate G3: Usability, Robustness & Resource Guards
- Asynchronous progress reporting with cancellation dialogs for long tasks.
- GPU VRAM guard checking available memory before triggering large batches or image formations.
- Tiling support (stride 64 on 128x128 blocks) for large Gotcha and Sentinel-1 images.
- Scripted click-through test exercising all tabs and controls with zero uncaught exceptions.

### Gate G4: Documentation & Release Packaging
- Documentation: `README.md`, `docs/DATA.md`, `docs/CITATIONS.md`, `docs/LIMITATIONS.md`.
- Required products dependency audit via `matlab.codetools.requiredFilesAndProducts`.
- Clean-clone validation.

---

## 5. Scientific Limits & Domain Constraints
The UI explicitly embeds and enforces the following physical and empirical truths:
1. **MERLIN Single-Look Complex Requirement**: MERLIN was trained on complex single-look SAR data. It cannot operate on amplitude-only (detected) imagery such as Sentinel-1 GRD.
2. **Point Target Distortion in MERLIN**: MERLIN distorts point targets (MSTAR net overshoots 1.54, Gotcha net undershoots 0.39). Gotcha net failed validation with peak ratio 0.39 and widths 1.39 and 1.45.
3. **Classical Filter Characteristics**: Classical filters (Lee, Frost, Gamma-MAP) do not improve downstream classifier accuracy beyond standard data augmentation, and Gamma-MAP introduces an inherent -3.8% intensity bias.
4. **Gotcha Autofocus Offsets**: AFRL Gotcha data exhibits 0.15-0.75 m look-dependent azimuth offsets. Phase Gradient Autofocus (PGA) is not implemented in this baseline.
5. **Preprocessing Distribution Shift**: MSTAR classifiers trained under Normalisation N suffer catastrophic degradation (15-50% accuracy) if evaluated on mismatched preprocessing or raw unnormalized amplitudes.
