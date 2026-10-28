# Sigma Rules

Custom rules deployed in Security Onion, each tested with Atomic Red Team.

| Rule | ATT&CK | TEST | STATUS |
|------|--------|------|--------|
| [Registry Run Key Persistence](registry-run-key-persistence.yml) | T1547.001 | ART T1547.001 #1 | Tuned 9/30/26 |
|[Local User Created Via Net.exe](local-user-created-net-exe.yml) | T1136.001 | ART T1136.001 #1| Verified 9/30/26 |


** Tuning Notes

**Registry Run Key Persistence** The first version also fired when the ART cleanup *deleted" the Run value. Security Onion coverts Sigma 'registry_set' to 'event.type:"Change"', which covers Sysmon Event 12 (create/delete) as well as Event 13 (value set). Adding 'EventID:13' fixed it. Verified: the test run alerted, and cleanup did not.

**Local User Created Via Net.EXE:** Matches 'net user /add' only, so the ART cleanup ('net user /del') correctly does not alert. Fires twice per run because 'net.exe' hands the command to 'net1.exe', and both process creations match. Left as-is for now; deduplicating to one alert per action is an open item. 
