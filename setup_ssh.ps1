# MOPUS Test Setup — Run as Administrator in PowerShell
# Installs SSH, configures user, opens firewall, prints IP.

$ErrorActionPreference = "Stop"
Write-Host "`n  [+] MOPUS SSH Setup" -ForegroundColor Red
Write-Host ""

# 1. Install OpenSSH Server
Write-Host "[1/5] Installing OpenSSH Server..." -ForegroundColor Yellow
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Write-Host "  [✓] Installed" -ForegroundColor Green

# 2. Start service, set to auto
Write-Host "[2/5] Starting sshd..." -ForegroundColor Yellow
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
Write-Host "  [✓] sshd running" -ForegroundColor Green

# 3. Firewall rule
Write-Host "[3/5] Opening firewall..." -ForegroundColor Yellow
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}
Write-Host "  [✓] Port 22 open" -ForegroundColor Green

# 4. Create test user
Write-Host "[4/5] Creating test user..." -ForegroundColor Yellow
$user = "tester"
$pass = "P@ssw0rd123"
try {
    net user $user $pass /add *>$null
    net localgroup Administrators $user /add *>$null
    Write-Host "  [✓] User '$user' created + admin" -ForegroundColor Green
} catch {
    Write-Host "  [!] User may already exist" -ForegroundColor DarkGray
}

# 5. Set PowerShell as default shell
Write-Host "[5/5] Setting default shell..." -ForegroundColor Yellow
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null
Restart-Service sshd
Write-Host "  [✓] Shell set to PowerShell" -ForegroundColor Green

# Done — print IP
Write-Host ""
Write-Host "  [✓] SETUP COMPLETE" -ForegroundColor Red
Write-Host ""
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object InterfaceAlias -notmatch "Loopback").IPAddress
Write-Host "  SSH:  ssh tester@$ip" -ForegroundColor Cyan
Write-Host "  Pass: P@ssw0rd123" -ForegroundColor Cyan
Write-Host ""
