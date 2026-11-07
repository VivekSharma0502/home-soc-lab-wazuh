# Incident Report 02 — SMB Password Brute Force

| Field | Value |
|---|---|
| **MITRE ATT&CK** | T1110 — Brute Force |
| **Attacker** | Kali Linux `192.168.50.7` |
| **Target** | `labuser` on WIN11-VICTIM (SMB / 445) |
| **Tool** | `nxc smb 192.168.50.6 -u labuser -p pw.txt --smb-timeout 10` (NetExec) |
| **Default detection** | ✅ Failed attempts / ❌ Successful compromise |
| **After engineering** | ✅ Rule 100110, level 12 |

## 1. Setup (deliberately weak, lab only)
Local user `labuser` with password `Summer2026!`, SMB allowed from `192.168.50.0/24` only.

## 2. Round 1 — Windows defended itself
| Defense observed | Effect |
|---|---|
| **SMB authentication rate limiter** (Windows 11 24H2) | 2 s delay after each failed login → NetExec's default 2 s timeout made every attempt time out |
| **Account lockout policy** | `labuser` locked (`STATUS_ACCOUNT_LOCKED_OUT`) — even the correct password was rejected |

Wazuh detected this **out of the box**:
- Rule 60122 — Logon Failure (Event 4625), one per guess
- *Multiple Windows Logon Failures* — built-in correlation alert (level 10)
- Event 4740 — *User account locked out*

## 3. Round 2 — simulating a weak corporate policy
`net accounts /lockoutthreshold:50` and SMB auth delay set to 0 → the brute force **succeeded**
(`[+] labuser:Summer2026!`).

## 4. Detection gap
Wazuh raised alerts for the failures, but nothing marked the **successful login that followed** —
the moment the account was actually compromised.

## 5. Fix — Rule 100110 (level 12)
Fires on an `authentication_success` event when an `authentication_failures` alert came from the
**same source IP within 5 minutes**.

## 6. False positive found & fixed
First version also fired for **`ANONYMOUS LOGON`** — NetExec opens an anonymous null session to
fingerprint the host. Added `targetUserName negate ^ANONYMOUS LOGON$`.

## 7. Result
`Brute force SUCCEEDED: labuser logged in from 192.168.50.7 after multiple failures` — level 12.

## 8. Lesson
Detecting attempts is not enough; correlate failure → success to catch the compromise itself.
Modern Windows defaults (rate limiting + lockout) are effective — weakening them is a real-world risk.
