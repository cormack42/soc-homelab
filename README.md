# soc-homelab
Home SOC Lab: Proxmox, OPNsense VLANs, Security Onion, Sysmon, Atomic Red Team detections.

A home security operations lab build to practice detection engineering, alert triage, and network troubleshooting. 

**Me: ** Navy aviation structural mechanic turned cybersecurity student. CompTIA Sec+ Certified.

## What's in the lab
-**Hypervisor:** Proxmox VE
-**Firewall/Segmentation:** OPNsense with 5 VLANs (home, Guest, Simulated Business, Attack lab, Management)
-**SIEM/NSM:** Security Onion (Suricata, Zeek, Elastic)
-**Endpoint telemetry:** Windows Server 2022 with Sysmon (Olaf Hartong config) and Elastic Agent
-**Adversary simulation:** Atomic Red Team, Kali, Metasploitable2, DVWA
-**DNS Filtering:** Pi-hole

Full diagram, VLAN layout, and monitoring design: [Lab Architecture](docs/architecture.md)

##Repo Layout
|Folder | Contents|
|-------|---------|
|'detections/' | Custom Sigma and Suricata Rules |
|'scripts/'    | Automation scripts |
|'configs/'    | Sanitized configs |
|'docs/'       | Architecture diagram |
|'writeups/'   | Investigation Write-ups |

##Status:
Core detection pipeline working end-to-end. Two tested Sigma rules published; write ups in progress. 
