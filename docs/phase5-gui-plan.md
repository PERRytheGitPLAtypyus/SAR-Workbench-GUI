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
   - `sar.registry.despeckle`: Declares despeckle algorithms, parameter metadata, input domain requirements (`complex` vs `amplitude`), and scientific constraints.
   - `sar.registry.classifiers`: Declares ATR model architectures, supported classes, normalization methods, and domain notes.
4. **Configuration**: Configurable data and model paths managed via `sarconfig.json` (with `sarconfig.example.json` tracked in git).
5. **Scientific Integrity**: Strict adherence to physical and empirical limits. Warnings are displayed when pre-conditions (e.g. complex single-look data for MERLIN, normalization consistency for CNNs) are violated.

---

## 2. Directory Structure
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
│   ├── p3b_merlin_gotcha.mat   # Frozen MERLIN network (Gotcha-trained)
│   └── cnn_mstar.mat           # Final trained MSTAR 4-block CNN (trained in G2b)
├── tests/
│   ├── TestG1Adapters.m        # MATLAB Unit Test suite for Gate G1 golden tests
│   └── TestG3UI.m              # Scripted UI execution test suite for Gate G3
├── research/                   # Frozen research scripts (strictly read-only)
├── research_new/               # New utility/training scripts (e.g. train_final_mstar.m)
├── docs/
│   ├── phase5-gui-plan.md      # This document
│   ├── gate_log.md             # Execution log of all gates with raw command outputs
│   ├── DATA.md                 # Data download and setup guide
│   ├── CITATIONS.md            # Academic citations and data credits
│   └── LIMITATIONS.md          # Known scientific and algorithmic boundaries
├── sarconfig.json              # Local configuration file (data and model paths)
├── sarconfig.example.json      # Template configuration file
├── startup.m                   # Project path setup script
└── README.md                   # Project overview and quickstart guide
```

---

## 3. Gates and Verification Milestones

### Gate G0: Repository Skeleton & Environment Baseline
- Create folder structure: `app/`, `+sar/`, `models/`, `tests/`, `research/`, `docs/`, `research_new/`.
- Provide `sarconfig.json` and `sarconfig.example.json`.
- Implement `sar.env.check` verifying MATLAB version, required toolboxes, GPU availability, data directories, and model files.
- Build initial tabbed `app/SARWorkbench.m` with Home tab showing real-time environment status.
- **PASS Criteria**: App opens without error; Home status indicators accurately reflect environment and hardware.

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

## 4. Scientific Limits & Domain Constraints
The UI explicitly embeds and enforces the following physical and empirical truths:
1. **MERLIN Single-Look Complex Requirement**: MERLIN was trained on complex single-look SAR data. It cannot operate on amplitude-only (detected) imagery such as Sentinel-1 GRD.
2. **Point Target Degradation in MERLIN**: MERLIN does not preserve isolated point scattering on Gotcha data (peak ratio ~1.54 with MSTAR net, ~0.39 with Gotcha net). Gotcha imaging surfaces a prominent advisory banner when MERLIN is selected.
3. **Classical Filter Characteristics**: Classical filters (Lee, Frost, Gamma-MAP) do not improve downstream classifier accuracy beyond standard data augmentation, and Gamma-MAP introduces an inherent -3.8% intensity bias.
4. **Gotcha Autofocus Offsets**: AFRL Gotcha data exhibits 0.15-0.75 m look-dependent azimuth offsets. Phase Gradient Autofocus (PGA) is not implemented in this baseline.
5. **Preprocessing Distribution Shift**: MSTAR classifiers trained under Normalisation N suffer catastrophic degradation (15-50% accuracy) if evaluated on mismatched preprocessing or raw unnormalized amplitudes.
