# Hetzner Cloud Infrastructure

## Current Setup
- **Provider:** Hetzner Cloud
- **Server:** `craig` (CCX33 — 8 dedicated vCPU, 32 GB RAM, 240 GB NVMe)
- **IP:** `178.156.251.179`
- **Location:** Ashburn, VA (ash)
- **Cost:** ~$54/mo
- **SSH:** `ssh -i ~/.ssh/hetzner-craig ubuntu@178.156.251.179`
- **CLI:** `hcloud server list`

## History
- **2026-02-11:** Started on AWS EC2 t3.small (2 GB RAM). OOM incident — OpenClaw
  gateway hit ~866 MB RSS, OOM killer looped, SSH starved.
- **2026-02-11:** Resized to t3.large (2 vCPU, 8 GB RAM, ~$61/mo).
- **2026-02-13:** EBS volume expanded from 25 GB to 100 GB.
- **2026-02-15:** Migrated from AWS EC2 to Hetzner Cloud CCX33. 4x CPU, 4x RAM,
  dedicated cores, $7/mo cheaper. See `.claude/migration-hetzner.md` for the
  full migration plan.

## Resize procedure

Quota increase request submitted for CCX43+ (pending approval).

```bash
# 1. Stop server
hcloud server shutdown craig

# 2. Change type (e.g. upgrade to CCX43: 16 vCPU, 64 GB)
hcloud server change-type craig --server-type ccx43

# 3. Start server
hcloud server poweron craig

# 4. Verify
ssh -i ~/.ssh/hetzner-craig ubuntu@178.156.251.179 "nproc && free -h"
```

## AWS teardown (pending)

Old EC2 is stopped but not terminated. After 24h+ of stable Hetzner operation:

```bash
aws ec2 terminate-instances --instance-ids i-0e2fb16c6e0fb83d0 --region us-east-1
aws ec2 release-address --allocation-id eipalloc-0155d2c49a8667e13 --region us-east-1
```
