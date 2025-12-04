<#
setup-mailtrap-env.ps1

Script para configurar facilmente as credenciais do Mailtrap como variáveis de ambiente.

Uso:
  .\setup-mailtrap-env.ps1

O script vai pedir suas credenciais do Mailtrap (aquelas que você copia do dashboard).
#>

Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Configurador de Credenciais Mailtrap   " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Verificar se está rodando como admin (opcional, mas recomendado)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  Aviso: Execute como Administrador para que setx funcione permanentemente." -ForegroundColor Yellow
    Write-Host "   Ou apenas configure para a sessão atual." -ForegroundColor Yellow
    Write-Host ""
}

# Solicitar credenciais
Write-Host "📋 Obtenha seus valores em: https://mailtrap.io/inboxes" -ForegroundColor Cyan
Write-Host "   Integrations → Java → copie os valores abaixo" -ForegroundColor Cyan
Write-Host ""

$username = Read-Host "🔐 SPRING_MAIL_USERNAME (ex: 6795143f3f342e)"
$password = Read-Host "🔐 SPRING_MAIL_PASSWORD (ex: 89d06af0f46e59)"

if (-not $username -or -not $password) {
    Write-Host "❌ Username e password são obrigatórios!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Configurando variáveis de ambiente..." -ForegroundColor Yellow

# Tentar setx (permanente, requer admin)
if ($isAdmin) {
    try {
        [Environment]::SetEnvironmentVariable("SPRING_MAIL_HOST", "sandbox.smtp.mailtrap.io", "User")
        [Environment]::SetEnvironmentVariable("SPRING_MAIL_PORT", "2525", "User")
        [Environment]::SetEnvironmentVariable("SPRING_MAIL_USERNAME", $username, "User")
        [Environment]::SetEnvironmentVariable("SPRING_MAIL_PASSWORD", $password, "User")
        [Environment]::SetEnvironmentVariable("SPRING_MAIL_FROM", "sender@example.com", "User")
        Write-Host "✅ Variáveis configuradas permanentemente!" -ForegroundColor Green
        Write-Host "   (⚠️  Feche e reabra o PowerShell para que façam efeito)" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ Erro ao configurar: $_" -ForegroundColor Red
    }
} else {
    # Apenas para sessão atual
    $env:SPRING_MAIL_HOST = "sandbox.smtp.mailtrap.io"
    $env:SPRING_MAIL_PORT = "2525"
    $env:SPRING_MAIL_USERNAME = $username
    $env:SPRING_MAIL_PASSWORD = $password
    $env:SPRING_MAIL_FROM = "sender@example.com"
    Write-Host "✅ Variáveis configuradas para esta sessão!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Verificando..." -ForegroundColor Cyan
Get-ChildItem Env: | Where-Object { $_.Name -like "SPRING_*" } | Format-Table Name, Value

Write-Host ""
Write-Host "Pronto para rodar o demo:" -ForegroundColor Green
Write-Host "  .\run_demo.ps1 -Port 9090 -StartApp" -ForegroundColor Cyan
Write-Host ""
