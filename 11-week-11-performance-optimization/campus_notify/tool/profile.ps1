param(
    [ValidateSet('before', 'after')]
    [string]$Stage = 'after'
)

$ErrorActionPreference = 'Stop'
$week = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
$runner = Join-Path $week '.profile_runner'
$app = Join-Path $week 'campus_notify'

if (-not (Test-Path -LiteralPath (Join-Path $runner 'pubspec.yaml'))) {
    Push-Location $week
    try {
        flutter create --platforms=windows --project-name=profile_runner --no-pub .profile_runner
    } finally { Pop-Location }
}

$pubspec = @'
name: profile_runner
publish_to: none
environment:
  sdk: ^3.13.1
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
  vm_service: ^15.3.0
flutter:
  uses-material-design: true
'@
Set-Content -LiteralPath (Join-Path $runner 'pubspec.yaml') -Value $pubspec
New-Item -ItemType Directory -Force -Path (Join-Path $runner 'integration_test'), (Join-Path $runner 'test_driver') | Out-Null

$source = Join-Path $app 'lib\features\announcements\presentation\pages\announcement_list_page.dart'
if ($Stage -eq 'before') {
    $source = Join-Path $week 'docs\baseline\announcement_list_page.dart.txt'
}
Copy-Item -LiteralPath $source -Destination (Join-Path $runner 'lib\announcement_list_page.dart')
$test = Get-Content -LiteralPath (Join-Path $app 'integration_test\performance_test.dart') -Raw
$test = $test.Replace('package:campus_notify/features/announcements/presentation/pages/announcement_list_page.dart', '../lib/announcement_list_page.dart')
Set-Content -LiteralPath (Join-Path $runner 'integration_test\performance_test.dart') -Value $test
Copy-Item -LiteralPath (Join-Path $app 'test_driver\performance_driver.dart') -Destination (Join-Path $runner 'test_driver\performance_driver.dart')

Push-Location $runner
try {
    flutter drive --driver=test_driver/performance_driver.dart --target=integration_test/performance_test.dart -d windows --profile "--dart-define=PROFILE_STAGE=$Stage"
} finally { Pop-Location }
