# Lab Architecture

How the lab is wired, segmented, and monitored.

```mermaid
flowchart TB

%%----------Layer 1: The Network----------

ISP[ISP MODEM] --> FLINT[GL-iNet Flint 2<br/>Upstream Router · VLAN 10 gateway]

%%Flint sends ONE cable (a trunk) to the TP-Link Switch.
%%That cable carries VLANs 10-40, each tagged with its number.
FLINT -->| trunk: VLANS 10-40| TPL[TP-Link TL-SG2008<br/>Managed Core Switch]

%%Everything below hangs off the TP-Link.

%%Second Trunk to netgear switch, carrying only VLANs 10 and 40.
TPL -->|trunk: VLANs 10, 40| NG[Netgear GS308E<br/>Downstream switch]

%%Pihole plugs into a regular (untagged) port on VLAN 10.
TPL --> PIHOLE[Pi-hole<br/>DNS Filtering · VLAN 10]

%%Laptop's wired port is on VLAN 50 (Management).
%%Admin access only works over this cable, never on Wi-Fi.

TPL --> LAPTOP[Admin laptop<br/>VLAN 50 · Wired Only.]


%%-----------------Layer 2: Proxmox Host--------------------------

%%Ome physical server runs the firewall and every lab machine in VMs/containers.

%%The TP-Link trunks VLANs 10-50 into a single cable.

subgraph PVE[Proxmox VE Host]

  %%OPNsense is the firewall/router for vlans 20-50.
  %%Its "WAN" side sits on VLAN 10 behind Flint 2 Router, not the real internet.
  OPN[OPNsense VM<br/>Firewall + Router for VLANs 20-50]

  %%VLAN 30 plays a small business: the Windows Server is the real monitored endpoint
  %%Where Atomic Red Team simulates attacker TTPs.
  subgraph V30[VLAN 30 · Simulated Business]
    WIN[Windows Server 2022<br/>Sysmon + Elastic Agent<br/>Atomic Red Team]
    FS[File Share + Media Server]
  end

  %%VLAN 40 is the isolated attack range: an attacker bot, intentionally
  %%Vulnerable targets, and a container that generates background traffic.
    subgraph V40[VLAN 40 · Attack lab]
      KALI[Kali Linux]
      MS2[Metasploitable2]
      DVWA[DVWA]
      NOISE[Traffic Generator]
    end
  end

TPL -->| trunk: VLANs 10-50| PVE

%%The attack lab also has its own uplink from the netgear on a separate adapter.
NG -->|VLAN 40| V40

%%---------------Layer 3: Security Onion----------------------

%%Dedicated bare-metal sensor + SIEM, reachable only from the Management VLAN.

subgraph SO[Security Onion · bare metal · VLAN 50]
  SUR[Suricata IDS]
  ZEEL[Zeek]
  ELK[Elasticsearch + Kibana<br/>Sigma Rules Via ElasticAlert]
end

%%---------------------Layor 4: How Security Onion sees everything----------------------

%%Dotted arrows = copies of traffic or logs, not normal network paths.

%%1. The TP-Link copies traffic from its ports to Security Onions Monitor port.
TPL -. SPAN port mirror .-> SO

%%2. Attack traffic between VMs stays inside Proxmox and never reaches the Physical Switch. Open vSwicth copies VLAN 40's traffic and sends it to security onion through a GRE Tunnel. 
%%mirrors VLAN 40 and sends the copy to Security Onion through a GRE tunnel.
V40 -. OVS Mirror over the GRE tunnel .-> SO

%%3. Host activity on the Windows Server is logged by Sysmon and shipped by Elastic Agent.
WIN -. Sysmon Logs .-> ELK


```

## Network Segmentation

<!-- Each VLAN is on its own network. OPNsense decides what can talk to what. -->

| VLAN | Name | Subnet | What lives there | Gateway |
|------|------|--------|------------------|---------|
| 10 | Personal | 192.168.10.0/24 | Home Devices, Pi-hole, switch and hypervisor management | Flint 2 |
| 20 | Guest | 192.168.20.0/24 | Guest Wi-Fi | OPNsense |
| 30 | Simulated Business | 192.168.30.0/24 | Windows Server Endpoint, file and media server | OPNsense |
| 40 | Attack Lab | 192.168.40.0/24 | Kali, Metasploitable2, DVWA, Traffic Generator | Opnsense |
| 50 | Management | 192.168.50.0/24 | Admin Laptop (Wired-only), Security Onion | OPNsense |

<!-- Rules that make the segmentation real, not just labels. -->

**Isolation Rules**
- Guest cannot reach any internal VLAN.
- Management reaches the lab VLANs only through narrow SSH and web allow rules; everything else is blocked by default.
- The attack lab is kept separate intentionally so vulnerable machines never sit next to personal devices.

## How monitoring works
<!-- Two kinds of visibility: Network (what crosses the wire) and host (What happens inside the machine). --> 
| Source | What it captures | Analyzed by|
|--------|------------------|------------|
| Switch SPAN mirror | Traffic crossing the physical switch | Suricata (alerts), Zeek (connection, DNS, HTTP logs) |
| Open vSwicth Mirror over GRE | VM-To-VM Traffic inside the attack lab, which never touches the physical switch | Suricata, Zeek |
| Sysmon + Elastic Agent | Process creation, registry changes, account changes on the Windows endpoint | Custom Sigma rules via ElastAlert |

<!-- The loop every detection in this repo goes through. -->
**Detection Workflow**
1. Run an Atomic Red Team test mapped to MITRE ATT&CK Technique.
2. Confirm the activity shows up in the logs.
3. Write or adjust the rule, then confirm it alerts.
4. Run a test's cleanup and confirm it does **not** alert (This is how false positives get caught)
5. Document the result in `detections/` and `writeups/`
