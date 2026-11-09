classdef TestG1Adapters < matlab.unittest.TestCase
    % TESTG1ADAPTERS  Golden Unit Test Suite for Gate G1
    %   Verifies +sar adapter numerical fidelity, dataset integrity, and research baselines.

    properties (TestParameter)
    end

    methods (TestClassSetup)
        function setupEnvironment(testCase)
            startup;
        end
    end

    methods (Test)
        function testMstarDatasetCounts(testCase)
            % G1 Requirement: MSTAR counts train 2747 / test 2425, 10 classes
            data = sar.atr.dataset();
            
            testCase.verifyEqual(data.numTrain, 2747, 'Training chip count must be 2747');
            testCase.verifyEqual(data.numTest, 2425, 'Test chip count must be 2425');
            testCase.verifyEqual(data.numClasses, 10, 'Target class count must be 10');
            
            expectedClasses = {'2s1_gun', 'bmp2_tank', 'brdm2_truck', 'btr60_transport', ...
                               'btr70_transport', 'd7_bulldozer', 't62_tank', 't72_tank', ...
                               'zil131_truck', 'zsu23-4_gun'};
            testCase.verifyEqual(sort(data.classes(:)), sort(expectedClasses(:)), ...
                'Class labels must match MSTAR 10-class SOC set');
            
            fprintf('[PASS] testMstarDatasetCounts: train %d, test %d, 10 classes verified.\n', ...
                data.numTrain, data.numTest);
        end

        function testGotchaPass8ApertureAndResolution(testCase)
            % G1 Requirement: Gotcha pass 8 HH az 1-3 has 358 pulses x 432 freqs and -3 dB width 0.30 m (+/-10%)
            G = sar.imaging.gotcha.loadAperture([], 8, 'HH', 1:3);
            
            numPulses = size(G.fp, 2);
            numFreqs = size(G.fp, 1);
            
            testCase.verifyEqual(numPulses, 358, 'Gotcha az 1-3 must contain 358 pulses');
            testCase.verifyEqual(numFreqs, 432, 'Gotcha must contain 432 frequency samples per pulse');
            
            % Form image around calibration point target 15TR03C (-28.09, 38.67)
            opt = struct('xlim', [-28.09-2.5, -28.09+2.5], 'ylim', [38.67-2.5, 38.67+2.5], ...
                         'dx', 0.05, 'z', -0.3, 'pad', 8, 'conj', 0, 'afr', 0, 'afp', 0);
            [img, xv, yv] = sar.imaging.gotcha.backproject(G, opt);
            
            stats = sar.imaging.gotcha.pointTargetResolution(img, xv, yv, [-28.09, 38.67]);
            
            % Assert -3 dB resolution width: 0.30 m (+/- 10%, i.e. 0.27 to 0.33 m)
            testCase.verifyTrue(stats.widthX >= 0.27 && stats.widthX <= 0.33, ...
                sprintf('Width X %.3f m outside required [0.27, 0.33] m', stats.widthX));
            
            fprintf('[PASS] testGotchaPass8ApertureAndResolution: %d pulses x %d freqs, -3 dB width X = %.3f m (0.30 m +/- 10%%).\n', ...
                numPulses, numFreqs, stats.widthX);
        end

        function testClassifierAccuracy(testCase)
            % G1 Requirement: Recompute accuracy of saved seed-1 model (models/cnn_mstar.mat)
            % on all 2,425 test chips under Normalisation N. Target: 98.82 +/- 0.50 % (98.32 - 99.32 %).
            cfg = sar.env.config();
            modelPath = fullfile(cfg.modelsPath, 'cnn_mstar.mat');
            testCase.assertTrue(exist(modelPath, 'file') ~= 0, 'models/cnn_mstar.mat must exist');
            
            data = sar.atr.dataset();
            pred = sar.atr.predict(data.Xte, modelPath, 'N');
            seed1AccPct = 100 * mean(pred == data.Yte);
            
            testCase.verifyTrue(seed1AccPct >= 98.32 && seed1AccPct <= 99.32, ...
                sprintf('Recomputed Seed 1 accuracy %.2f %% outside [98.32, 99.32] %%', seed1AccPct));
            
            fprintf('[PASS] testClassifierAccuracy: Recomputed Seed 1 test accuracy = %.2f %% (within 98.82 +/- 0.50 %%); 5-seed mean = 99.02 %% (historical logged value).\n', ...
                seed1AccPct);
        end

        function testSyntheticSpeckleBiasesAndNumericalEquivalence(testCase)
            % G1 Requirement: Lee bias about 0%, Gamma-MAP about -3.8%, adapter numerical difference < 1e-6
            rng(3);
            I = -log(rand(256, 256, 'single'));
            Ah = sqrt(I);
            
            % Lee filter
            Y_lee_adapter = sar.despeckle.apply(Ah, 'lee', struct('win', 7, 'L', 1));
            Y_lee_script  = despeckle_filters(Ah, 'lee', 7, 1);
            diffLee = max(abs(Y_lee_adapter(:) - Y_lee_script(:)));
            testCase.verifyLessThan(diffLee, 1e-6, 'Adapter output must match despeckle_filters within 1e-6');
            
            biasLee = 100 * (mean(Y_lee_adapter(:).^2) / mean(I(:)) - 1);
            testCase.verifyLessThan(abs(biasLee), 0.5, 'Lee intensity bias must be ~0%');
            
            % Gamma-MAP filter
            Y_gm_adapter = sar.despeckle.apply(Ah, 'gammamap', struct('win', 7, 'L', 1));
            Y_gm_script  = despeckle_filters(Ah, 'gammamap', 7, 1);
            diffGM = max(abs(Y_gm_adapter(:) - Y_gm_script(:)));
            testCase.verifyLessThan(diffGM, 1e-6, 'Adapter output must match despeckle_filters within 1e-6');
            
            biasGM = 100 * (mean(Y_gm_adapter(:).^2) / mean(I(:)) - 1);
            testCase.verifyTrue(abs(biasGM - (-3.8)) <= 0.8, ...
                sprintf('Gamma-MAP bias %.2f %% outside expected ~ -3.8 %% range', biasGM));
            
            fprintf('[PASS] testSyntheticSpeckleBiases: Lee bias = %+.2f %%, Gamma-MAP bias = %+.2f %% (diffs: %e, %e).\n', ...
                biasLee, biasGM, diffLee, diffGM);
        end

        function testMerlinSyntheticSelfTest(testCase)
            % G1 Requirement: MERLIN synthetic self-test median |log(Rhat/R)| 0.081 (+/- 0.02)
            % Uses pre-trained selftest model (models/merlin_selftest.mat) with zero retraining during test
            cfg = sar.env.config();
            modelPath = fullfile(cfg.modelsPath, 'merlin_selftest.mat');
            testCase.assertTrue(exist(modelPath, 'file') ~= 0, 'models/merlin_selftest.mat must exist');
            
            S = load(modelPath);
            Nt = size(S.Zt, 3);
            errEst = zeros(1, Nt);
            for k = 1:Nt
                Rh = p3b_denoise(S.net, S.Zt(:,:,k), 1);
                Rk = S.Rtest(:,:,k);
                errEst(k) = median(abs(log(Rh(:) ./ Rk(:))));
            end
            medErr = median(errEst);
            
            testCase.verifyTrue(abs(medErr - 0.081) <= 0.02, ...
                sprintf('Self-test median |log(Rhat/R)| = %.4f outside [0.061, 0.101]', medErr));
            
            fprintf('[PASS] testMerlinSyntheticSelfTest: median |log(Rhat/R)| = %.4f (gate: 0.081 +/- 0.02).\n', medErr);
        end

        function testMerlinEvaluationMetrics(testCase)
            % G1 Requirement: Recompute p3b_eval protocol with rng(3), 400 test chips
            % SUT: sar.despeckle.apply ('merlin_mstar'). Reference: frozen p3b_denoise.
            % Target: MERLIN ENL gain 21.4 (+/- 1.5), bias +1.96 % (+/- 0.20 %), numerical diff < 1e-6.
            rng(3);
            cfg = sar.env.config();
            M = load(fullfile(cfg.modelsPath, 'p3b_merlin.mat'), 'net', 's');
            net = M.net; s = M.s;
            D = load(cfg.dataPath.mstarSocMat, 'pte');
            
            S = 128; n = 400; tgt = 41:88; P = 32;
            sel = randperm(numel(D.pte), n);
            Z = zeros(S, S, n);
            for k = 1:n
                [mg, ph] = mstar_read(char(D.pte(sel(k))));
                r0 = floor((size(mg,1)-S)/2) + 1; c0 = floor((size(mg,2)-S)/2) + 1;
                Z(:,:,k) = double(mg(r0:r0+S-1, c0:c0+S-1)) .* exp(1j * double(ph(r0:r0+S-1, c0:c0+S-1)));
            end
            I = abs(Z).^2;
            
            % Denoise using adapter under test
            R_adapter = zeros(S, S, n);
            for k = 1:n
                amp_filt = sar.despeckle.apply(Z(:,:,k), 'merlin_mstar');
                R_adapter(:,:,k) = double(amp_filt).^2;
            end
            
            % Verify numerical equivalence on chips against frozen p3b_denoise reference
            R_ref = zeros(S, S, min(10, n));
            for k = 1:size(R_ref, 3)
                R_ref(:,:,k) = double(p3b_denoise(net, Z(:,:,k), s));
            end
            maxDiff = max(abs(R_adapter(:,:,1:size(R_ref,3)) - R_ref), [], 'all');
            testCase.verifyLessThan(maxDiff, 1e-6, 'Adapter output must match p3b_denoise within 1e-6');
            
            % Compute metrics via frozen research function p3b_metrics
            m = p3b_metrics(I, R_adapter, P, tgt);
            
            testCase.verifyTrue(abs(m.gain - 21.4) <= 1.5, ...
                sprintf('Recomputed MERLIN ENL gain %.2f outside [19.9, 22.9]', m.gain));
            testCase.verifyTrue(abs(100 * m.bias - 1.96) <= 0.20, ...
                sprintf('Recomputed MERLIN bias %+.2f %% outside [+1.76, +2.16] %%', 100 * m.bias));
            
            fprintf('[PASS] testMerlinEvaluationMetrics: Recomputed 400 chips: ENL gain = %.2f, bias = %+.2f %%, diff = %e.\n', ...
                m.gain, 100 * m.bias, maxDiff);
        end

        function testScientificDomainBoundaries(testCase)
            % Scientific limit: MERLIN must reject real amplitude input
            A_real = rand(128, 128, 'single');
            
            testCase.verifyError(@() sar.despeckle.apply(A_real, 'merlin_mstar'), ...
                'sar:despeckle:invalidInputType', ...
                'MERLIN must reject amplitude-only data.');
            
            fprintf('[PASS] testScientificDomainBoundaries: MERLIN correctly rejects real amplitude input.\n');
        end
    end
end
