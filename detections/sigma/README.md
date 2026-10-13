# Sigma Rules

Custom rules deployed in Security Onion, each tested with Atomic Red Team.

| Rule | ATT&CK | TEST | STATUS |
|------|--------|------|--------|
| [Registry Run Key Persistence](registry-run-key-persistence.yml) | T1547.001 | ART T1547.001 #1 | Tuned 9/30/26 |


**Tuning Notes

**Registry Run Key Persistence** The first version also fired when the ART cleanup *deleted" the Run value. Security Onion coverts Sigma 'registry_set' to 'event.type:"Change"', which covers Sysmon Event 12 (create/delete) as well as Event 13 (value set). Ading 'EventID:13' fixed it. Verified: the test run alerted, and cleanup did not.
