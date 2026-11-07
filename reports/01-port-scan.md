# Incident Report 01 — Network Port Scan

| Field | Value |
|---|---|
| **MITRE ATT&CK** | T1046 — Network Service Discovery |
| **Attacker** | Kali Linux `192.168.50.7` |
| **Target** | WIN11-VICTIM `192.168.50.6` |
| **Tool** | `nmap -sS -Pn -T4 192.168.50.6` |
| **Default detection** | ❌ None |
| **After engineering** | ✅ Rule 100101, level 10 |

## 1. Attack
A TCP SYN scan of the 1,000 most common ports. Windows Firewall silently dropped every probe
(`1000 filtered tcp ports`).

## 2. Initial result — blind spot
Wazuh showed **zero events** from `192.168.50.7`. An attacker could map the network unseen.

## 3. Root cause (two layers)
1. **Windows doesn't audit dropped packets by default.** No Event 5152/5157 was generated.
2. **The Wazuh agent filters 5152/5157 by default.** Its Security-channel query contains
   `EventID != 5152 and ... != 5157` because these events are extremely noisy on real networks.
   Even after enabling auditing, the events were discarded on the endpoint before reaching the SIEM.

## 4. Fix
| Layer | Change |
|---|---|
| Endpoint audit policy | `auditpol` → Filtering Platform Packet Drop / Connection (failure) |
| Agent collection | Removed 5152/5157 from the agent's `ossec.conf` query filter |
| Detection | **Rule 100100** — inbound TCP drop to a service port (lvl 3, evidence) |
| Correlation | **Rule 100101** — ≥20 drops from the same source IP within 30 s → *Possible port scan* (lvl 10, T1046) |

## 5. Validation
Re-ran the scan → 572 rule-100100 events from `192.168.50.7` across random ports and a
level-10 correlation alert for the source IP.

## 6. Tuning (later)
Rule 100100 initially also fired on **outbound** drops and **late replies to ephemeral ports**
(e.g. Microsoft servers replying to port 59748). Fixed by matching only
`direction = %%14592` (inbound) and destination ports **< 49152**, plus tuning rules 100204/100205.

## 7. Lesson
Default tool configs are tuned for noise, not visibility. Detection required changes at
**three** layers: OS auditing, agent collection, and SIEM correlation.
