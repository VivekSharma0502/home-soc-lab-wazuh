# Report 04 — Alert Tuning (False-Positive Reduction)

## Method
1. **Measure** — count alerts per rule from an idle victim (`scripts/noise-analysis.sh`).
2. **Investigate** — for each noisy rule, find the exact process / file / registry key behind it.
3. **Suppress narrowly** — level-0 child rules matching only the verified benign pattern.
4. **Validate** — benign trigger must be silent **and** a malicious variant must still alert.
5. **Re-measure** — alerts per idle hour before vs after.

## Baseline (before tuning)
~730 alerts in one day from a single, mostly idle Windows VM. Top offenders:

| Rule | Count | Level | Root cause | Decision |
|---|---|---|---|---|
| 60104 audit failure | 347 | 5 | Non-TCP packet drops (broadcast, LLMNR `224.0.0.252`, `169.254.x`) — side effect of our own WFP auditing | Suppress (100200) |
| 92307 new service | 96 | 3 | Windows per-user services at logon (`WpnUserService_517c0`) | Suppress (100202) |
| 92205 / 92213 | 50 + 6 | 9 / **15** | `powershell.exe` creating `__PSScriptPolicyTest_*.ps1` — PowerShell's own policy check, partly triggered by the 32-bit Wazuh agent | Suppress (100201) |
| 100100 (ours!) | 56 | 3 | Outbound drops + late replies to ephemeral ports | Tighten rule + 100204 / 100205 |
| 92217 | 8 | 6 | Defender signature updates (`mpam-*.exe`), `SecurityHealthSetup.exe` | Suppress (100203) |
| 92058 AppCompat | 1 | 12 | `sdbinst.exe` | **Kept** — rare, and a known persistence technique (T1546.011) |

## Bug found during validation
The first version of rules 100201–100203 **never matched**. Windows eventchannel paths are stored
with escaped backslashes (`C:\\Windows\\...`), so a regex for a single `\` failed silently.
Fixed by using `\\\\` and re-tested. **Lesson: always validate suppressions against live events.**

## Validation
| Test | Input | Expected | Result |
|---|---|---|---|
| Benign | Open PowerShell → `__PSScriptPolicyTest_*.ps1` | Silent | ✅ No alert |
| Malicious | `Set-Content $env:TEMP\evil_payload.ps1` | Alert | ✅ Rule 92213, level 15 |

## Result
| Metric | Before | After |
|---|---|---|
| Alerts / idle hour (WIN11-VICTIM, measured) | ~140 (avg 08:00–10:00 UTC) | **33** (12:00 UTC) |
| Noise reduction (measured) | — | **~77%** |
| Baseline alerts / day | ~730 | — |
| Alerts with root cause fixed or suppressed | — | 563 (~77% of baseline) |
| Level-15 false positives | 6+ / day | **0** |
| Malicious variant still detected | — | ✅ (rule 92213, level 15) |

563 = 347 (60104) + 96 (92307) + 56 (92205 / 92213) + 56 (100100) + 8 (92217).
Both the per-rule estimate and the measured idle hour agree on **~77%**.
