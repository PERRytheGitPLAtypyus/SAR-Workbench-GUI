function arm = p4b_arms(key, sel)
% P4B_ARMS  The arms of Phase 4b (all at 10 % data). Names are used in the result file names and in p4b_stats.
%   key: 'A0' raw | 'A1' boxcar 7 | 'A2_w5' 'A2_w9' boxcar 5 / 9 | 'A3_lee' 'A3_frost' | 'B1' shift aug | 'B2' shift + speckle noise
%        'C1' random blur aug (train raw) | 'C3' mixed raw + boxcar 7 | 'B4' best augmentation + dropout/weight decay (needs sel)
%        'E1_lee' 'E1_box5': shift augmentation on Lee-7 / boxcar-5 filtered chips (does filtering add on top of augmentation? compare with B1)
%   tests{1} is the main test condition of the arm (also used for validation); the other test specs are free extra cells.
%   sel (for B4): sel.aug 'none'|'B1'|'B2', sel.drop, sel.wd   (chosen on validation by run_p4b_stage1b)
raw = struct('type', 'raw', 'win', 0); bx7 = struct('type', 'boxcar', 'win', 7);
K = 10;                                                    % offline augmentation copies
switch key
    case 'A0',      arm = p4b_arm('A0', 'raw');            arm.tests = {raw, bx7};
    case 'A1',      arm = p4b_arm('A1', 'boxcar', 7);      arm.tests = {bx7, raw};
    case 'A2_w5',   arm = p4b_arm('A2_w5', 'boxcar', 5);
    case 'A2_w9',   arm = p4b_arm('A2_w9', 'boxcar', 9);
    case 'A3_lee',  arm = p4b_arm('A3_lee', 'lee', 7);
    case 'A3_frost',arm = p4b_arm('A3_frost', 'frost', 7);
    case 'B1',      arm = p4b_arm('B1', 'raw'); arm.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', K); arm.tests = {raw};
    case 'B2',      arm = p4b_arm('B2', 'raw'); arm.aug = struct('shift', true, 'noiseL', [1 4], 'blurSet', [], 'K', K); arm.tests = {raw};
    case 'C1',      arm = p4b_arm('C1', 'raw'); arm.aug = struct('shift', false, 'noiseL', [], 'blurSet', [1 3 5 7 9], 'K', K); arm.tests = {raw, bx7};
    case 'C3',      arm = p4b_arm('C3', 'raw'); arm.mix = {raw, bx7}; arm.tests = {raw, bx7};
    case 'E1_lee',  arm = p4b_arm('E1_lee', 'lee', 7);     arm.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', K);
    case 'E1_box5', arm = p4b_arm('E1_box5', 'boxcar', 5); arm.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', K);
    case 'B4'
        arm = p4b_arm('B4', 'raw'); arm.tests = {raw};
        switch sel.aug
            case 'B1', arm.aug = struct('shift', true, 'noiseL', [], 'blurSet', [], 'K', K);
            case 'B2', arm.aug = struct('shift', true, 'noiseL', [1 4], 'blurSet', [], 'K', K);
        end
        arm.drop = sel.drop; arm.wd = sel.wd;
    otherwise, error('unknown arm %s', key);
end
end
