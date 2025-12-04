<#
deploy-railway.ps1

Script automático para fazer deploy no Railway.
Requer: Git instalado e conta Railway.

Uso:
  .\deploy-railway.ps1 -GitHubRepo "seu-usuario/email-microservice"

#>

param(
    [string]$GitHubRepo = ""
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Deploy Automático para Railway      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar Git
Write-Host "📋 Verificando Git..." -ForegroundColor Yellow
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git não encontrado! Instale em: https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Git OK" -ForegroundColor Green

# Solicitar GitHub repo se não foi passado
if (-not $GitHubRepo) {
    Write-Host ""
    $GitHubRepo = Read-Host "🔗 GitHub Repository (formato: usuario/repositorio)"
}

if (-not $GitHubRepo -or $GitHubRepo -notmatch "^[\w-]+/[\w-]+$") {
    Write-Host "❌ Formato inválido! Use: usuario/repositorio" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📦 Repositório: $GitHubRepo" -ForegroundColor Cyan
Write-Host ""

# Verificar se é repositório Git
if (-not (Test-Path ".git")) {
    Write-Host "❌ Não é um repositório Git! Você está no diretório correto?" -ForegroundColor Red
    Write-Host "   Execute: git init" -ForegroundColor Yellow
    exit 1
}

# Verificar se há commits
$commitCount = (git rev-list --count HEAD 2>$null)
if ($commitCount -eq 0) {
    Write-Host "⚠️  Repositório vazio. Fazendo primeiro commit..." -ForegroundColor Yellow
    git add .
    git commit -m "Initial commit: Email microservice"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao fazer commit" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Repositório Git OK (commits: $commitCount)" -ForegroundColor Green
Write-Host ""

# Push para GitHub
Write-Host "📤 Fazendo push para GitHub..." -ForegroundColor Yellow
git push -u origin main 2>&1 | Select-Object -Last 5
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Nota: Se o push falhou, verifique seu remote:" -ForegroundColor Yellow
    git remote -v
    Write-Host ""
    Write-Host "Configure com: git remote set-url origin https://github.com/$GitHubRepo.git" -ForegroundColor Cyan
    exit 1
}
Write-Host "✅ Push OK" -ForegroundColor Green
Write-Host ""

# Instruções Railway
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║       Próximas Etapas (Manual)         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "1️⃣  Abra Railway:" -ForegroundColor Cyan
Write-Host "   https://railway.app" -ForegroundColor White
Write-Host ""

Write-Host "2️⃣  Clique em 'New Project' → 'Deploy from GitHub repo'" -ForegroundColor Cyan
Write-Host ""

Write-Host "3️⃣  Selecione seu repositório: $GitHubRepo" -ForegroundColor Cyan
Write-Host ""

Write-Host "4️⃣  Railway vai compilar automaticamente (~2-3 min)" -ForegroundColor Cyan
Write-Host ""

Write-Host "5️⃣  Configure variáveis em 'Variables':" -ForegroundColor Cyan
Write-Host "   SPRING_MAIL_HOST = sandbox.smtp.mailtrap.io" -ForegroundColor DarkCyan
Write-Host "   SPRING_MAIL_PORT = 2525" -ForegroundColor DarkCyan
Write-Host "   SPRING_MAIL_USERNAME = 6795143f3f342e" -ForegroundColor DarkCyan
Write-Host "   SPRING_MAIL_PASSWORD = 89d06af0f46e59" -ForegroundColor DarkCyan
Write-Host "   SPRING_MAIL_FROM = sender@example.com" -ForegroundColor DarkCyan
Write-Host ""

Write-Host "6️⃣  Clique 'Save' - Railway reinicia automaticamente" -ForegroundColor Cyan
Write-Host ""

Write-Host "7️⃣  Vá para 'Deployments' → copie a URL em 'Domains'" -ForegroundColor Cyan
Write-Host ""

Write-Host "8️⃣  Seu endpoint online estará em:" -ForegroundColor Cyan
Write-Host "   https://seu-app-xxx.railway.app/api/email/send-pdf" -ForegroundColor White
Write-Host ""

Write-Host "✅ Deploy iniciado! Acompanhe em: https://railway.app/dashboard" -ForegroundColor Green
Write-Host ""
