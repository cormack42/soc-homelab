# Scripts

Automation and maintenance scripts used in the lab. Each script's header covers what it does, why it exists, its limits, and how to install it. 

| Script | Runs on | What it does |
|--------|---------|--------------|
| [bond0-watchdog.sh](bond0-watchdog.sh) | Security Onion Sensor (root con, every minute) | Detects the monitor NIC freezing while still reporting IP (RX counter stops for 2 checks), bounces it, and logs whether traffic resumed. | 
