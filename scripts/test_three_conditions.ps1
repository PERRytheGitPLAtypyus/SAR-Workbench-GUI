# scripts/test_three_conditions.ps1
# Test SARWorkbench launch under 3 distinct starting conditions

$repoRoot = "C:\Users\sruja\OneDrive\Documents\SARorsmthn"
$appDir = "$repoRoot\app"
$testsDir = "$repoRoot\tests"
$userPathDir = "C:\Users\sruja\OneDrive\Documents\MATLAB"

Write-Host "=================== CONDITION (A): REPO ROOT ==================="
Set-Location $repoRoot
matlab -batch "addpath('$testsDir'); test_interactive_launch('A_RepoRoot');"

Write-Host "`n============== CONDITION (B): EXTERNAL DIR (TEMP) =============="
Set-Location $env:TEMP
matlab -batch "addpath('$appDir'); addpath('$testsDir'); test_interactive_launch('B_ExternalFolderOnlyApp');"

Write-Host "`n============== CONDITION (C): USERPATH (DEFAULT) ==============="
Set-Location $userPathDir
matlab -batch "addpath('$testsDir'); test_interactive_launch('C_UserPathDefault');"

Write-Host "`n================ ALL THREE CONDITIONS COMPLETE ================"
