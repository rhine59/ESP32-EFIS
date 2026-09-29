# Server and Container Platform

**Status:** proposed infrastructure baseline — 29 September 2026

This document records the current hardware and virtualisation direction for the server-side services supporting **MicroSky Horizon / ESP32-EFIS**. It is deliberately separate from the aircraft EFIS hardware baseline. Nothing in this document is flight-critical hardware.

## Purpose

The platform is intended to host the project's growing Docker workloads, including:

- `efis-ota` and OTA administration
- Horizon customer support/chat services
- account/device/licensing services
- PostgreSQL data stores
- monitoring and administration services
- development, integration and regression-test workloads
- future scalable services where Kubernetes adds a demonstrable benefit

The current Synology-hosted services can remain in use during migration and can continue to provide bulk/backup storage.

## Budget and hardware target

The current budget ceiling is **£750** for the server platform.

Target specification:

| Component | Target |
|---|---|
| CPU | modern AMD Ryzen 7/9 class, approximately 8 cores / 16 threads |
| RAM | **64 GB DDR5** preferred; 32 GB is the absolute minimum |
| Primary storage | **1 TB NVMe SSD minimum** |
| Expansion | at least one additional M.2/NVMe slot preferred |
| Networking | **dual 2.5 GbE preferred** |
| Virtualisation | AMD-V/VT-x capable; Proxmox VE no-subscription baseline (£0) |
| Power profile | suitable for quiet 24x7 operation |
| UPS | desirable if it can be accommodated within/alongside budget |

Candidate mini-PC platforms discussed include the **GMKtec K8 Plus** (Ryzen 7 8845HS class) and **Minisforum UM890 Pro** (Ryzen 9 8945HS class). The preferred purchasing pattern is a barebones or sensibly configured unit plus known-quality 64 GB RAM and 1 TB NVMe, provided the complete system remains within the £750 ceiling.

These are candidate platforms, not frozen procurement choices. Price, warranty, UK availability, RAM/SSD compatibility and NIC support must be checked at purchase time.

## Why a modern mini-PC rather than an old rack server

For this workload the priorities are:

- strong multi-core performance
- 64 GB RAM capability
- fast NVMe storage
- low idle power for 24x7 operation
- low noise
- small physical footprint
- multiple Ethernet interfaces
- enough expansion for a second SSD

Used enterprise rack hardware remains an option where ECC, IPMI, many disks or enterprise RAID are required, but those features do not currently justify the higher power/noise/space cost for this project.

## Virtualisation baseline: Proxmox VE (no-subscription)

The proposed host layer is **Proxmox VE using the no-subscription repository**, with a software subscription cost of **£0** for the initial self-managed platform.

A paid Proxmox subscription is not required to run the hypervisor. The no-subscription repository is suitable for this development/self-hosted baseline, while a supported Enterprise subscription can be reconsidered later if MicroSky Horizon becomes a commercial production service requiring vendor support and the more heavily tested enterprise package stream.

The principal fully open-source alternative is **Incus**, which supports both system containers and QEMU virtual machines and can scale to clustered hosts. Incus should remain documented as the fallback/alternative rather than changing the initial architecture, because Proxmox provides the more convenient integrated VM, storage, snapshot, backup and web-management environment for this deployment.

Proxmox provides VM isolation, snapshots, backup/restore, resource allocation, networking and a web management interface. Application containers should not normally run directly on the Proxmox host; they run inside dedicated Linux VMs.

Initial architecture:

```text
Physical server — 64 GB RAM / 1 TB NVMe
                |
             Proxmox VE
                |
     +----------+-----------+-----------+
     |                      |           |
 prod-docker             dev-docker   monitor
     |                      |           |
 production             build/test   metrics/
 Compose stacks          workloads    alerting

                 + k3s-lab (optional)
```

## Initial VM layout

### 1. prod-docker

**Purpose:** stable production Docker/Compose workloads.

Initial allocation:

- 6–8 vCPU
- approximately 24 GB RAM
- approximately 300 GB virtual disk
- Debian or Ubuntu Server LTS
- Docker Engine + Docker Compose

Candidate workloads include OTA, support service, account/licensing APIs, web services and project databases.

Existing Compose deployments should be migrated with minimal architectural change first. Kubernetes is not a prerequisite for migration.

### 2. dev-docker

**Purpose:** builds, integration tests, regression tests, simulators/test harness services and pre-production container validation.

Initial allocation:

- 4–6 vCPU
- approximately 12 GB RAM
- approximately 150 GB virtual disk

Expected flow:

```text
source -> build -> container build -> unit tests -> integration tests
       -> simulation/regression tests -> PASS -> production deployment
```

This prevents experimental builds from destabilising production services.

### 3. monitor

**Purpose:** independent infrastructure monitoring.

Initial allocation:

- 2 vCPU
- approximately 4 GB RAM
- 50–100 GB virtual disk

Likely stack:

- Prometheus
- Grafana
- Alertmanager
- host/container exporters

Monitoring should remain outside `prod-docker` so a complete production-VM failure can still be observed and alerted.

### 4. k3s-lab

**Purpose:** optional Kubernetes learning and migration environment.

Initial allocation:

- approximately 4 vCPU
- approximately 12 GB RAM
- 100–150 GB virtual disk

**k3s** is a lightweight Kubernetes distribution. It should initially be treated as an experimental environment, not the default production platform.

A small non-critical service should be migrated first to exercise Deployments, Services, Ingress, persistent volumes, Secrets and ConfigMaps. Kubernetes adoption should then be based on demonstrated operational benefit rather than migration for its own sake.

If k3s does not provide sufficient value, this VM can simply be removed and its resources returned to the host.

## RAM policy

Do not allocate all 64 GB permanently. A representative starting point is:

| Use | RAM |
|---|---:|
| Proxmox/host reserve | ~4 GB |
| prod-docker | 24 GB |
| dev-docker | 12 GB |
| monitor | 4 GB |
| k3s-lab | 12 GB |
| remaining operational headroom | ~8 GB |

Allocations are starting values, not hard capacity requirements. Actual utilisation should drive later tuning.

## Database placement

Initially, PostgreSQL/PostGIS may remain within the production Docker environment to minimise migration complexity.

A later dedicated database VM is reasonable if operational needs justify it:

```text
Proxmox
  +-- prod-docker
  +-- database
  |     +-- PostgreSQL
  |     +-- PostGIS (where required)
  +-- dev-docker
  +-- monitor
  +-- k3s-lab
```

Database separation should be driven by backup, performance, security and failure-domain requirements rather than done automatically.

## Storage

Start with a good-quality **1 TB NVMe** drive. Prefer a platform with a second M.2 slot.

A future second 2–4 TB NVMe drive can provide additional database/container storage, VM storage or local backup staging. The Synology can continue to provide independent bulk storage and backups.

Important data must not rely solely on VM snapshots. Establish tested off-host backups.

## Networking

Dual 2.5 GbE is preferred because it permits later separation of management and service/storage traffic, bonding or other topology changes without replacing the server.

Do not expose Proxmox management directly to the public Internet. Public EFIS services should continue to use controlled reverse-proxy/firewall/TLS boundaries.

## Docker first, Kubernetes deliberately

The migration principle is:

1. install Proxmox;
2. create the production Docker VM;
3. migrate existing Compose stacks with minimal changes;
4. create independent monitoring;
5. establish backup/restore and deployment testing;
6. create the development/test VM;
7. introduce k3s only as a controlled lab;
8. migrate services to Kubernetes only where resilience, scaling or operational management clearly improves.

Docker Compose remains entirely valid for a single production host. k3s becomes substantially more useful if the platform later expands to multiple physical nodes.

## Future resilience

A single Proxmox server improves isolation and manageability but is still a **single physical failure domain**.

True host-level high availability requires additional physical nodes and suitable replicated/shared storage and network design. A future three-node k3s or Proxmox cluster can therefore be considered separately from this first £750 server.

## Procurement checkpoint

Before purchase:

- verify current UK price and warranty;
- confirm two SODIMM slots and 64 GB support;
- confirm included/barebones RAM arrangement;
- confirm 1 TB NVMe compatibility and available second M.2 slot;
- confirm both Ethernet controllers are supported by the chosen Proxmox release;
- confirm BIOS virtualisation options;
- confirm cooling/noise characteristics for sustained 24x7 use;
- reserve budget for backup and preferably UPS protection.

The immediate objective is not a Kubernetes cluster. It is a reliable, expandable virtualisation host that can run the existing Docker estate cleanly today and provide a low-risk path to k3s/multi-node infrastructure later.


## Hypervisor cost and alternative

The initial hypervisor/software budget is **£0**:

- **Proxmox VE no-subscription:** selected baseline; no paid subscription required for the self-managed installation.
- **Incus:** principal open-source alternative if a future decision favours a more Linux-native container/VM management model.
- **Debian + KVM/libvirt:** viable lower-level alternative, but would require more manual assembly and administration.

The £750 platform budget should therefore be spent on hardware, RAM, NVMe storage and power protection rather than a hypervisor licence.

## Native Proxmox LXC containers

Proxmox VE supports **LXC containers directly on the hypervisor** alongside full KVM virtual machines. Lightweight infrastructure services should use LXC where they do not require a separate kernel or stronger VM security/failure boundary.

The default should be **unprivileged LXC containers**.

Initial proposed LXC services:

| Container | OS/userspace | CPU | RAM | Disk | Purpose |
|---|---|---:|---:|---:|---|
| `dns01` | Debian | 1 core | 512 MB–1 GB | 8 GB | Internal DNS, e.g. AdGuard Home |
| `utility01` | Debian | 1 core | ~1 GB | 8–16 GB | Optional lightweight network/admin tools |

A representative host layout is therefore:

```text
Proxmox VE
|
+-- LXC dns01
|     +-- Debian userspace
|     +-- AdGuard Home
|
+-- LXC utility01          [optional]
|
+-- VM prod-docker
|     +-- Debian 13
|     +-- Docker/Compose
|
+-- VM dev-docker
|     +-- Debian 13
|     +-- Docker/Compose
|
+-- VM monitor
|     +-- Debian 13
|
+-- VM k3s-lab
      +-- Debian 13
      +-- k3s
```

LXC guests share the Proxmox Linux kernel, so they have substantially less overhead than full VMs and start quickly. Full VMs remain preferable for the production Docker estate, development/test Docker environment, k3s and workloads requiring a stronger isolation boundary.

### Docker policy

Do **not** make Docker-inside-LXC the default architecture. Although nested Docker in LXC is possible, it adds nesting, permission and kernel-feature dependencies that are unnecessary on a 64 GB host. Docker environments should remain in full Debian VMs unless a specific measured benefit justifies changing this policy.

### DNS container

The initial internal DNS service can run directly as `dns01` under Proxmox rather than consuming a complete VM.

Suggested starting configuration:

```text
Hostname:       dns01
Type:           unprivileged LXC
Userspace:      Debian
CPU:            1 core
RAM:            512 MB initially
Swap:           512 MB
Disk:           8 GB
Network:        vmbr0
Address:        static LAN address
Start at boot:  enabled
```

The local DHCP service/router should advertise `dns01` as a resolver only after the DNS configuration has been tested.

Use the reserved `.home.arpa` namespace for private home-network names rather than inventing a public-looking internal domain.

Example:

```text
proxmox.home.arpa
prod.home.arpa
dev.home.arpa
monitor.home.arpa
nas.home.arpa
```

### DNS resilience

A single `dns01` container on Proxmox would disappear whenever the physical host is rebooted or unavailable. The preferred later design is therefore two DNS instances in separate physical failure domains:

```text
dns01  -> new Proxmox server
dns02  -> Synology or another independent device
```

Clients can then be given both resolver addresses through DHCP. DNS availability should not depend solely on the new Proxmox host.

Public authoritative DNS for MicroSky/Horizon customer-facing services should remain with a hosted DNS provider; the internal LXC DNS service is not intended to become a public authoritative DNS server.
