# Tailscale-Firewall-Setup
A bash script that updates UFW rules based on Tailscale’s DERP map. It fetches the DERP map, extracts IPs for a specified region, removes outdated UFW rules, and adds new ones to allow UDP traffic from those IPs to a target server. Ensures single execution and checks for required dependencies.
