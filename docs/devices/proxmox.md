# Proxmox VE Host

The hypervisor that runs the firewall and every lab machine except for the Security Onion sensor.

## Why it's in the lab

Running the lab as virtual machines on one host means I can build, break, and restore systems in minutes instead of buying a PC for each one. Snapshots let me run an attack against a target and roll it back to a clean state afterward. It also keeps the firewall, the simulated business, and the attack lab on separate virtual networks while sharing one physical machine.

## At a glance

| | |
|---|---|
| **Hardware / Host** | Dell XPS 8930, Intel Core i7-8700 (6 cores / 12 threads), 16 GB RAM (non-ECC) |
| **Storage** | 1 TB internal disk for guest devices; 5.5 TB external drive for the file share and media |
| **Software** | Proxmox VE 9.1.1 (Debian 13), Open vSwitch 3.5.0 |
| **Network** | Management at 192.168.10.50 (VLAN 10), web UI on port 8006 |

## How it connects

The host has three wired network ports, and each one feeds its own bridge (a virtual switch inside proxmox)

| Bridge | Type | Plugged into | Purpose |
|--------|------|--------------|---------|
| `vmbr0` | Linux bridge, VLAN-aware | Built-in NIC -> TP-Link trunk (vlans 10-50) | Main connection. Each guest picks its VLAN with a tag. The host's own management address lives here. |
| `vmbr1` | Linux brudge | USB Adapter -> TP-Link VLAN 10 port | OPNsense's WAN only, so the firewall's outside connection has its own cable. |
| `vmbr40` | Open vSwitch | USB Adapter -> Netgear VLAN 40 port | Attack Lab. Uses Open vSwitch because it can monitor traffic; Linkex bridges cannot. |

Traffic between two VMs on the same host never reaches the physical switch, so the switch's mirror port can't see it. To cover the attack lab, Open vSwitch copies all traffic on `vmbr40` into a GRE tunnel that delivers it to the Security Onion sensor. The tunnel port is named `erspan1`, but it is plain GRE: ERSPAN was the original plan, and the sensor's kernel rejected it while GRE with the same settings worked.

Sanitized config: [configs/proxmox/interfaces](../../configs/proxmox/interfaces)


## What it runs

| Job | Guests | Details |
|-----|--------|---------|
| Firewall / router | VM 100 opnsense | [OPNsense](opnsense.md) |
| Simulated business (VLAN 30) | VM 205 win-detect-lab, CT 101 samba-share, CT 102 jellyfin | [Simulated Business](simulated-business.md) |
| Attack Lab (VLAN 40) | VM 201 kali-attacker, VM 202 metasploitable2, CT 203 dvwa, CT 204 noisegen | [Attack Lab](attack-lab.md) |

VMs have their own kernel, so they're used for Windows, OPNsense (FreeBSD), and older targets like metasploitable2. LXC containers share the host's Linux kernel, which makes them lighter, so Linux services that don't need their own kernel run as containers.

## How it's monitored or protected

- Attack lab traffic is mirrored to Security Onion over the GRE tunnel.
- Every Guest except the Windows endpoint starts automatically at boot. The Windows VM only runs during test sessions.
- A scheduled job backs every guest each Sunday and keeps the last two copies

  ## Design choices

  - **One hypervisor instead of many PCs:** cheaper, quieter, and targets can be rebuilt from snapshots
  - **Open vSwitch only where its needed:** the attack lab needs mirroring, so it gets OVS. Everything else stays on simpler Linux bridges.
  - **Security Onion on its own hardware:** the sensor is resource-heavy, and it shouldn't go down with the machines it watches.
 
## Known limitations

- Everything virtual runs on one consumer desktop without ECC memory, so it's a single point of failure.
- Traffic between VMs in VLAN 30 uses a Linux bridge, so it isn't mirrored. Sysmon on the Windows endpoint covers that gap with host logs.
