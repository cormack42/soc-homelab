# Suricata Rules

Custom Suricata network rules deployed in Security Onion. Each file's header covers what it detects, its ATT&CK mapping, known limits, and how to deploy it.

| Rule | SID | ATT&CK | Notes |
|------|-----|--------|-------|
| [Custom Nmap Scan Detected](nmap-syn-scan-1308843.rules) | 1308843 | T1046 | 5+ SYNs from one source in 10 s. Noisy as written; tuning is an open item. |
| [Possible SSH Brute Force](ssh-brute-force-1391221.rules) | 1391221 | T1110.001 | 5+ new SSH connections from one source in 120 s. |
| [Possible SQL Injection - OR Pattern](sqli-or-pattern-1391223.rules) | 1391223 | T1190 | Matches `'+OR+` in HTTP URIs. Narrow by design. |

**Deploy:**
Security Onion -> Detections -> add as Suricata (NIDS) rule, or append to `local.rules` on any Suricata sensor. All rules use `$HOME_NET`.
