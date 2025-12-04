<#
test-local.ps1

Script simples para testar o microserviço completamente local.
Não requer GitHub ou Railway.

Uso:
  .\test-local.ps1 -Port 8080
  .\test-local.ps1 -Port 9090 -BuildFirst
  .\test-local.ps1 -Port 8080 -Email seu@email.com
#>

param(
    [int]$Port = 8080,
    [string]$Email = "teste@example.com",
    [switch]$BuildFirst,
    [switch]$StopBefore
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Teste Local do Microserviço de Email  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. Parar processo anterior se solicitado
if ($StopBefore) {
    Write-Host "🛑 Parando processos Java anteriores..." -ForegroundColor Yellow
    Get-Process -Name java -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "✅ Pronto" -ForegroundColor Green
    Write-Host ""
}

# 2. Build (opcional)
if ($BuildFirst) {
    Write-Host "🔨 Compilando aplicação..." -ForegroundColor Yellow
    Write-Host "   (Primeira vez pode demorar ~30 segundos)" -ForegroundColor DarkGray
    mvn clean package -DskipTests -q
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao compilar!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Compilação OK" -ForegroundColor Green
    Write-Host ""
}

# 3. Verificar JAR
Write-Host "📦 Verificando JAR..." -ForegroundColor Yellow
if (-not (Test-Path "target/email-microservice-0.0.1-SNAPSHOT.jar")) {
    Write-Host "❌ JAR não encontrado! Execute com -BuildFirst" -ForegroundColor Red
    Write-Host "   Uso: .\test-local.ps1 -BuildFirst" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ JAR existe" -ForegroundColor Green
Write-Host ""

# 4. Configurar credenciais
Write-Host "🔑 Configurando credenciais Mailtrap..." -ForegroundColor Yellow
$env:SPRING_MAIL_HOST = "sandbox.smtp.mailtrap.io"
$env:SPRING_MAIL_PORT = "2525"
$env:SPRING_MAIL_USERNAME = "6795143f3f342e"
$env:SPRING_MAIL_PASSWORD = "89d06af0f46e59"
$env:SPRING_MAIL_FROM = "sender@example.com"
Write-Host "✅ Credenciais configuradas" -ForegroundColor Green
Write-Host ""

# 5. Iniciar aplicação
Write-Host "🚀 Iniciando aplicação na porta $Port..." -ForegroundColor Yellow
Write-Host "   (Aguarde 2-3 segundos para inicializar)" -ForegroundColor DarkGray
Write-Host ""

$appProcess = Start-Process -FilePath java -ArgumentList @(
    "-jar"
    "target/email-microservice-0.0.1-SNAPSHOT.jar"
    "--server.port=$Port"
) -PassThru -NoNewWindow

Start-Sleep -Seconds 3

# 6. Verificar se app está rodando
$appRunning = (Get-Process -Id $appProcess.Id -ErrorAction SilentlyContinue)
if (-not $appRunning) {
    Write-Host "❌ Aplicação falhou ao iniciar" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Aplicação rodando (PID: $($appProcess.Id))" -ForegroundColor Green
Write-Host "   URL: http://localhost:$Port/api/email/send-pdf" -ForegroundColor Cyan
Write-Host ""

# 7. Preparar payload
Write-Host "📝 Preparando requisição de teste..." -ForegroundColor Yellow

# PDF base64 de exemplo (válido)
$pdfBase64 = "JVBERi0xLjQKCjEgMCBvYmo8PC9UeXBlL0NhdGFsb2cvUGFnZXMgMiAwIFI+PmVuZG9iaiAyIDAgb2JqPDwvVHlwZS9QYWdlcy9LaWRzWzMgMCBSXS9Db3VudCAxPj5lbmRvYmogMyAwIG9iajw8L1R5cGUvUGFnZS9QYXJlbnQgMiAwIFIvTWVkaWFCb3hbMCAwIDYxMiA3OTJdL0NvbnRlbnRzIDQgMCBSPj5lbmRvYmogNCAwIG9iajw8L0xlbmd0aCA0ND4+c3RyZWFtIEJUIC9GMSA="

$payload = @{
    to = $Email
    subject = "Teste Local - $(Get-Date -Format 'HH:mm:ss')"
    body = "E-mail de teste local gerado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
    filename = "teste.pdf"
    pdfBase64 = $pdfBase64
} | ConvertTo-Json -Compress

Write-Host "✅ Payload pronto" -ForegroundColor Green
Write-Host "   To: $Email" -ForegroundColor DarkGray
Write-Host ""

# 8. Enviar requisição
Write-Host "📤 Enviando POST para http://localhost:$Port/api/email/send-pdf" -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod `
        -Uri "http://localhost:$Port/api/email/send-pdf" `
        -Method Post `
        -Body $payload `
        -ContentType "application/json" `
        -TimeoutSec 10 `
        -ErrorAction Stop

    Write-Host "✅ Resposta recebida:" -ForegroundColor Green
    Write-Host "   $response" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "🎉 SUCESSO!" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ Verifique o e-mail em: https://mailtrap.io/inboxes" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Erro ao enviar requisição:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor DarkRed
    Write-Host ""
    
    # Tentar ler resposta do servidor
    if ($_.Exception.Response) {
        try {
            $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorContent = $sr.ReadToEnd()
            Write-Host "📋 Resposta do servidor:" -ForegroundColor Yellow
            Write-Host "   $errorContent" -ForegroundColor DarkYellow
        } catch {}
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Aplicação continua rodando (PID: $($appProcess.Id))" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para parar: Get-Process -Id $($appProcess.Id) | Stop-Process -Force" -ForegroundColor DarkGray
Write-Host "Ou simplesmente feche o terminal ou pressione Ctrl+C" -ForegroundColor DarkGray
Write-Host ""
