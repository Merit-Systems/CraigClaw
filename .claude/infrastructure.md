# EC2 Infrastructure

## Current Setup
- **Instance:** `i-0e2fb16c6e0fb83d0` (t3.large — 2 vCPU, 8 GB RAM)
- **Volume:** `vol-0ce6db6bfe7959e24` (gp3, 100 GB)
- **Elastic IP:** `100.31.229.192` (eipalloc-0155d2c49a8667e13)
- **Security group:** `sg-083530ad37dce5694` (craigclaw-sg)
- **Region:** us-east-1
- **SSH:** `ssh -i ~/.ssh/craigclaw-key.pem ubuntu@100.31.229.192`

## Volume History
- Originally 25 GB (default), expanded to 100 GB on 2026-02-13
- Snapshot `snap-02aef7fb07c1e218a` taken pre-resize as backup
- Expansion was in-place (growpart + resize2fs), no reboot needed

## Instance History
- Started as t3.small (2 GB RAM). OOM incident 2026-02-11 — OpenClaw gateway
  hit ~866 MB RSS, OOM killer looped, SSH starved. Resized to t3.large (8 GB).

## Disk Usage (as of 2026-02-13, post-expansion)
Major consumers: pnpm store (~6 GB), poncho + StableStudio + x402email repos
with node_modules (~7.4 GB), npm cache (~1.3 GB). These are leftover from
other projects and can be cleaned up if space gets tight again.

## Recommended Next Resize: t3.xlarge

When Craig needs more power, the recommended upgrade is **t3.xlarge**
(4 vCPU, 16 GB RAM, ~$121/mo vs current ~$61/mo).

**Why t3.xlarge:**
- Craig's workload is bursty (agent gets task, builds, idles). Burstable
  instances are designed for this — accumulate CPU credits while idle, spend
  them during builds.
- 4 vCPU doubles parallel build capacity.
- 16 GB RAM gives headroom for OpenClaw gateway (~900 MB peak) + builds +
  pnpm installs running simultaneously. No more OOM risk.
- Zero-migration resize: stop instance, change type, start. ~1 min downtime.
  Elastic IP stays attached.

**Why not dedicated CPU (c7i/m7i):**
- Dedicated cores matter for sustained CPU (CI servers, databases). Craig is
  idle most of the time — paying for dedicated cores he won't use is waste.
- c7i.xlarge is $130/mo for the same 4 vCPU / 8 GB but without burst credits.

**Why not ARM/Graviton (c7g/m7g):**
- ~20% cheaper per core, but requires full instance migration (new AMI, rebuild
  environment, transfer secrets, re-test deploy pipeline). Hours of work to
  save ~$15-20/mo.
- Revisit if we ever rebuild the box from scratch.

**Resize procedure:**
```bash
# 1. Stop instance
aws ec2 stop-instances --instance-ids i-0e2fb16c6e0fb83d0 --region us-east-1
aws ec2 wait instance-stopped --instance-ids i-0e2fb16c6e0fb83d0 --region us-east-1

# 2. Change type
aws ec2 modify-instance-attribute --instance-id i-0e2fb16c6e0fb83d0 \
  --instance-type '{"Value":"t3.xlarge"}' --region us-east-1

# 3. Start instance (Elastic IP re-associates automatically)
aws ec2 start-instances --instance-ids i-0e2fb16c6e0fb83d0 --region us-east-1
aws ec2 wait instance-running --instance-ids i-0e2fb16c6e0fb83d0 --region us-east-1

# 4. Verify
ssh -i ~/.ssh/craigclaw-key.pem ubuntu@100.31.229.192 "nproc && free -h"
```
