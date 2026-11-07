#!/usr/bin/env bash
# Alert-noise analysis used for tuning. Run on the Wazuh manager.
# fromjson? skips lines truncated by a disk-full event.
ALERTS=/var/ossec/logs/alerts/alerts.json
AGENT=${1:-WIN11-VICTIM}

echo "== Top rules for $AGENT =="
sudo jq -R -r --arg a "$AGENT" 'fromjson? | select(.agent.name==$a) |
  "\(.rule.id) | lvl \(.rule.level) | \(.rule.description[0:70])"' "$ALERTS" \
  | sort | uniq -c | sort -rn | head -15

echo; echo "== Alerts per hour (UTC) =="
sudo jq -R -r --arg a "$AGENT" 'fromjson? | select(.agent.name==$a) | .timestamp[0:13]' "$ALERTS" \
  | sort | uniq -c

echo; echo "== What triggers each noisy rule =="
for r in 60104 92205 92213 92307 92217 92058; do
  echo "--- $r ---"
  sudo jq -R -r --arg r "$r" 'fromjson? | select(.rule.id==$r) |
    "\(.data.win.system.eventID) | \(.data.win.eventdata.image // "-") -> \(.data.win.eventdata.targetFilename // .data.win.eventdata.targetObject // .data.win.eventdata.destAddress // "-")"' "$ALERTS" \
    | cut -c1-140 | sort | uniq -c | sort -rn | head -3
done
