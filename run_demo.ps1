<#
run_demo.ps1

Script de demonstração para iniciar o microserviço (opcional) e enviar um PDF de teste.

Parâmetros:
 -PdfPath: caminho para o PDF a enviar. Se omitido, será criado um arquivo PDF simples em %TEMP%\sample.pdf
 -Port: porta onde o serviço está escutando (padrão 8081)
 -To: destinatário do e-mail (padrão recipient@example.com)
 -StartApp: switch; se presente, o script inicia o JAR em segundo plano antes de enviar

Exemplo:
 .\run_demo.ps1 -PdfPath 'C:\meu\arquivo.pdf' -Port 8081 -StartApp
#>

param(
    [string]$PdfPath = "",
    [int]$Port = 8081,
    [string]$To = 'recipient@example.com',
    [switch]$StartApp
)

function Write-Log { param($m) Write-Host "[run_demo] $m" }

$projectRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $projectRoot

if ($StartApp) {
    Write-Log "Iniciando a aplicação em segundo plano na porta $Port..."
    $argList = @('-jar', 'target\email-microservice-0.0.1-SNAPSHOT.jar', "--server.port=$Port")
    $outLog = ".\app-$Port.log"
    $errLog = ".\app-$Port.err.log"
    Start-Process -FilePath java -ArgumentList $argList -RedirectStandardOutput $outLog -RedirectStandardError $errLog -NoNewWindow
    Start-Sleep -Seconds 2
    Write-Log "Logs: app-$Port.log e app-$Port.err.log"
}

if (-not $PdfPath -or -not (Test-Path $PdfPath)) {
    $tmp = [IO.Path]::Combine($env:TEMP, "sample-demo.pdf")
    Write-Log "Nenhum PDF valido fornecido. Criando arquivo de demonstracao: $tmp"
    
    # Criar um PDF válido com magic bytes (%PDF)
    $pdfHeader = "%PDF-1.4`n"
    $pdfContent = "1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj 2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj 3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R>>endobj 4 0 obj<</Length 44>>stream BT /F1 12 Tf 100 750 Td (Teste de Anexo) Tj ET endstream endobj xref 0 5 0000000000 65535 f 0000000009 00000 n 0000000058 00000 n 0000000115 00000 n 0000000229 00000 n trailer<</Size 5/Root 1 0 R>> startxref 369 %%EOF"
    
    $pdfBytes = [System.Text.Encoding]::UTF8.GetBytes($pdfHeader + $pdfContent)
    [System.IO.File]::WriteAllBytes($tmp, $pdfBytes)
    $PdfPath = $tmp
}

Write-Log "Lendo PDF de: $PdfPath"
$bytes = [System.IO.File]::ReadAllBytes($PdfPath)
$base64 = [Convert]::ToBase64String($bytes)

$payload = @{ to=$To; subject='Teste demo'; body='Mensagem gerada pelo run_demo.ps1'; filename=[IO.Path]::GetFileName($PdfPath); pdfBase64=$base64 } | ConvertTo-Json

$uri = "http://localhost:$Port/api/email/send-pdf"
Write-Log "Enviando POST para $uri (to=$To, filename=$($PdfPath | Split-Path -Leaf))"
try {
    $resp = Invoke-RestMethod -Uri $uri -Method Post -Body $payload -ContentType 'application/json' -TimeoutSec 30
    Write-Log "Resposta: $resp"
} catch {
    Write-Log "Falha ao enviar: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        try {
            $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $content = $sr.ReadToEnd()
            Write-Log "Resposta do servidor: $content"
        } catch {}
    }
}

Write-Log "Pronto. Verifique o painel Mailtrap e os logs em app-$Port.log / app-$Port.err.log"
