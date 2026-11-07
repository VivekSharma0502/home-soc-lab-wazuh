# Screenshots

| File | What it shows |
|---|---|
| `00-dashboard-overview.png` | Threat Hunting dashboard: alert totals and top MITRE ATT&CK techniques |
| `00b-agent-active.png` | WIN11-VICTIM agent connected and active |
| `01a-nmap-scan.png` | Kali nmap SYN scan (1000 filtered ports) |
| `01b-portscan-detected.png` | Custom rule 100100 catching blocked connections from Kali (192.168.50.7) |
| `02a-lockout.png` | NetExec brute force stopped by Windows account lockout |
| `02b-default-bruteforce-alerts.png` | Wazuh default alerts: logon failures, multiple failures, account locked out |
| `02c-bruteforce-succeeded.png` | Custom rule 100110: "Brute force SUCCEEDED" (level 12) |
| `03a-encoded-powershell.png` | Rule 92057: base64-encoded PowerShell |
| `03b-backdoor-admin.png` | Backdoor admin: user created + Administrators group changed |
| `03c-defender-block.png` | Microsoft Defender blocking schtasks persistence |
| `03d-defender-in-siem.png` | Defender detections visible in Wazuh after onboarding its log |
| `03e-defender-bypass.png` | Register-ScheduledTask bypassing Defender (task Ready) |
| `03f-event-4698.jpg` | Event 4698 exposing the hidden SYSTEM PowerShell task |
| `03g-persistence-detected.png` | Custom rule 100120: suspicious scheduled task (level 12) |
| `04a-noise-before.png` | Alert-noise baseline by rule |
| `04b-noise-root-causes.png` | Root cause of each noisy rule |
| `04c-tuning-validation.png` | Benign PSScriptPolicyTest silenced, malicious evil_payload.ps1 still alerts |
| `04d-noise-after.png` | Alerts per hour after tuning (~140 → 33) |
