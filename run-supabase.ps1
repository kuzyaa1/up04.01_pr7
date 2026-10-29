$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    flutter run -d chrome --web-port=5555 --dart-define-from-file=config/supabase.public.json
} finally {
    Pop-Location
}
