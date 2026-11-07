# Troubleshooting Log — Real Problems Hit While Building the Lab

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | Wazuh installer "stuck" 30+ min at manager step | `restore-permissions.sh` walking thousands of files on a slow VM disk | Wait; confirmed progress via `ps -ef --forest` CPU time |
| 2 | Install failed: *Wazuh API user wazuh does not exist* | 4 GB RAM — API not ready before the installer's check | Increased VM to 6 GB / 6 vCPU, reinstalled |
| 3 | VM settings files (`.vbox`) wiped to 0 KB | Host D: drive filled up while VirtualBox was saving | Restored from `.vbox-prev` backups |
| 4 | VM paused with `VERR_DISK_FULL` | Snapshot differencing disks (~41 GB) + Windows updates on D: | Deleted old snapshots (merges disks), removed ISOs, disabled Windows Update in victim |
| 5 | Windows 11 VM black screen | VirtualBox 3D acceleration | Disabled 3D acceleration (VBoxSVGA) |
| 6 | *Wazuh dashboard server is not ready yet* after boot | Indexer crash-recovery exceeded systemd's 3-min start timeout | `TimeoutStartSec=900` override for indexer & manager |
| 7 | Dashboard *timeout of 20000ms exceeded* | Indexer still warming up | `opensearch.requestTimeout: 120000` |
| 8 | Dashboard *No API available to connect* | Dashboard retry storm during manager restart triggered the Wazuh API's **own login rate-limit** (`IP blocked due to exceeded number of logins attempts: 127.0.0.1`) | Stop dashboard → wait for block to expire → restart manager → start dashboard |
| 9 | API error 1017 *wazuh-modulesd stopped* | Module crash under memory pressure (no swap) | `wazuh-control start`, added 2 GB swap |
| 10 | Port-scan rule never fired | Agent filters Event 5152/5157 by default | Edited agent query filter |
| 11 | Tuning rules silently didn't match | Escaped backslashes in Windows paths | Regex `\\\\` |

**Safe restart sequence after rule changes:**
```bash
sudo /var/ossec/bin/wazuh-analysisd -t && sudo systemctl stop wazuh-dashboard \
  && sudo systemctl restart wazuh-manager && sleep 60 && sudo systemctl start wazuh-dashboard
```
