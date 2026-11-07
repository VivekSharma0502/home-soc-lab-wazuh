# Home SOC Lab - Windows 11 victim setup
# Run in an ADMIN PowerShell inside the isolated victim VM only.
# WARNING: several steps deliberately weaken security. Never run on a real machine.

$WazuhManager = "192.168.50.10"

# --- 1. Sysmon with SwiftOnSecurity config --------------------------------
cd $env:TEMP
Invoke-WebRequest https://download.sysinternals.com/files/Sysmon.zip -OutFile Sysmon.zip
Expand-Archive Sysmon.zip -DestinationPath C:\Sysmon -Force
Invoke-WebRequest https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml -OutFile C:\Sysmon\sysmonconfig.xml
C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml

# --- 2. Wazuh agent ----------------------------------------------------------
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.9-1.msi -OutFile $env:TEMP\wazuh-agent.msi
msiexec.exe /i $env:TEMP\wazuh-agent.msi /q WAZUH_MANAGER=$WazuhManager WAZUH_AGENT_NAME='WIN11-VICTIM'
Start-Sleep 30
NET START WazuhSvc

# --- 3. Audit policy (telemetry needed by the custom rules) ------------------
# Attack 1: firewall packet drops -> Event 5152 / 5157
auditpol /set /subcategory:"Filtering Platform Packet Drop" /failure:enable
auditpol /set /subcategory:"Filtering Platform Connection" /failure:enable
# Attack 3: scheduled task creation -> Event 4698
auditpol /set /subcategory:"Other Object Access Events" /success:enable

# --- 4. Stop the agent from dropping Event 5152 ------------------------------
# The default agent config excludes 5152/5157 from the Security channel query.
$conf = "C:\Program Files (x86)\ossec-agent\ossec.conf"
Copy-Item $conf "$conf.bak"
(Get-Content $conf) `
  -replace '\s*and\s+EventID\s*!=\s*5157','' `
  -replace 'EventID != 5152\]', 'EventID != 5145]' | Set-Content $conf
net stop WazuhSvc; net start WazuhSvc

# --- 5. Lab-only weakening (so attacks can be simulated) ---------------------
# Stop Windows Update growing the VM disk
Stop-Service wuauserv -Force
Set-Service wuauserv -StartupType Disabled
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name NoAutoUpdate -Value 1 -Type DWord

# Weak account + SMB open to the lab subnet only (Attack 2)
net user labuser Summer2026! /add
New-NetFirewallRule -DisplayName "LAB - SMB from SOC-Net" -Direction Inbound -Protocol TCP -LocalPort 445 -RemoteAddress 192.168.50.0/24 -Action Allow
Set-SmbServerConfiguration -InvalidAuthenticationDelayTimeInMs 0 -Force
net accounts /lockoutthreshold:50
