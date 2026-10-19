# Lab Architecture

How the lab is wired, segmented, and monitored.

```mermaid
flowchart TB

%%----------Layer 1: The Network----------

ISP[ISP MODEM] --> FLINT[GL-inet Flint 2<br/>Upstream Router · VLAN 10 gateway]

%%Flint sends ONE cable (a trunk) to the TP-Link Switch.
%%That cable carries VLANs 10-40, each tagged with its number.
FLINT -->| trunk: VLANS 10-40| TPL[TP-Link TL-SG2008<br/>Managed Cored Switch]

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
  %%Its "WAN" side sits on VLAN 10 behind Flint 2 ROuter, not the real internet.
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

%%2. VM-to-VM traffic inside Proxmox never touches the switch, so Open vSwitch
%%mirrors VLAN 40 and sends the copy to Security Onion through a GRE tunnel.
V40 -. OVS Mirror over the GRE tunnel .-> SO

%%3. Host activity on the Windows Server is logged by Sysmon and shipped by Elastic Agent.
WIN -. Sysmon Logs .-> ELK


```

