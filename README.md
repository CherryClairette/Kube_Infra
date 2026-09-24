# KubeQuest — Sailing Through the Clouds

Epitech MSc Pro 2027 · T-CLO-901-PAR-9-1 · Team of 4

## Status

**Planning.** Architecture and tech stack are decided; implementation starts after the team kickoff meeting. This README will grow as the project does — right now it's a starting point, not a spec.

## What this is

We're building a fully-equipped Kubernetes cluster on 3 dedicated AWS nodes: not just hosting an app, but the management and observability tooling around it (ingress, dashboard, monitoring, logging, GitOps) — provisioned reproducibly with Ansible, secured with OIDC + an admission policy, and deployed the whole way through GitOps.

## How we work

- **Protected learning time.** Before anyone touches their assigned piece for real, they get dedicated time to actually understand it — not just copy commands from a tutorial. That time is scheduled, not squeezed in around building.
- **Understanding over speed.** The final defense tests whether we understand Kubernetes itself, not just whether the cluster runs. If a shortcut would leave someone unable to explain their piece, we don't take it.

## Architecture

Full diagrams (cluster layout, traffic paths, GitOps flow, rollout mechanism, and every tech choice with a plain-language "why"): **[Reference Architecture](https://whimsical.com/cia547/kubekuby-FdNqP5i9U6GAwjxE3WtCyR)**

At a glance, the platform is six jobs wrapped by two cross-cutting concerns, sitting on three physical nodes:

| Job     | Tool                                 |
| ------- | ------------------------------------ |
| Expose  | Traefik (Gateway API) + cert-manager |
| Manage  | Headlamp                             |
| Observe | kube-prometheus-stack                |
| Log     | Loki + Grafana Alloy                 |
| Ship    | Argo CD                              |
| Store   | Harbor + EFS-backed PVC              |

Wrapping all six: **Identity** (dex + Keycloak, OIDC on every tool and the API server) and **Security** (Sealed Secrets, a native `ValidatingAdmissionPolicy`).

## Repository structure

The brief asks for a clean split between infrastructure and application concerns, each with its own GitOps repository. We're running that as **two repos, not three**: this repo doubles as `infra-repo` (docs, Ansible, and everything Argo CD reconciles for the platform); `app-repo` is separate and holds the app's Helm chart + GitOps config.

**This repo's proposed layout** (starting point for the kickoff meeting, not final):

```
T-CLO-901-PAR-9-1-kube-5/          # this repo = infra-repo
├── README.md
├── ansible/                  # provisions the 3 nodes — runs BEFORE any of the below exists
│   ├── inventory/
│   ├── playbooks/
│   │   └── site.yml
│   └── roles/
├── bootstrap/
│   └── root-app.yaml         # the one Application we point Argo CD at manually — "app of apps"
├── apps/                     # one Argo CD Application per component, watched by root-app
│   ├── networking.yaml
│   ├── identity.yaml
│   ├── observability.yaml
│   ├── logging.yaml
│   ├── dashboard.yaml
│   ├── security.yaml
│   ├── registry.yaml
│   └── storage.yaml
└── components/
    ├── networking/            # EXPOSE — Traefik, cert-manager, Cilium
    │   ├── base/
    │   │   └── kustomization.yaml
    │   └── overlays/cluster/
    │       └── kustomization.yaml
    ├── identity/              # IDENTITY — dex, Keycloak
    ├── observability/         # OBSERVE — kube-prometheus-stack
    ├── logging/               # LOG — Loki + Grafana Alloy
    ├── dashboard/             # MANAGE — Headlamp
    ├── security/              # SECURITY — Sealed Secrets, admission policy
    ├── registry/              # STORE (images) — Harbor
    └── storage/               # STORE (data) — EFS CSI driver, StorageClass
        # each component/* follows the same base/ + overlays/cluster/ pattern as networking/
```

`ansible/` sits outside every path Argo CD is ever pointed at (`bootstrap/`, `apps/`, `components/`) — Argo CD only syncs the exact path each `Application` names, never the whole repo, so the two coexist safely.

Three ideas worth keeping even if the folder names change:

- **`ansible/` runs first, alone.** Nothing else in this repo exists until it's done — there's no Argo CD, no cluster, until `site.yml` finishes.
- **`bootstrap/` vs `apps/`** — only `root-app.yaml` ever gets applied by hand; it points at `apps/`, and every other Application gets created _by_ Argo CD from there. One manual step, then the repo manages itself.
- **`base/` + `overlays/`** — every component is defined once in `base/`, and `overlays/cluster/` is where cluster-specific values (URLs, replica counts) patch it. This is the actual reason the brief asks for kustomize, not just a folder-naming preference.

`app-repo`'s layout is still TBD — Questions: does it need the app's source code, or just the Helm chart + GitOps config for an app that lives elsewhere?

## Environment access

Quick reference — full details in [`Project Wiki: AWS Access Runbook`](https://github.com/EpitechMscProPromo2027/T-CLO-901-PAR-9-1-kube-5/wiki/IV.-AWS-Access-Runbook):

- Access via Epitech's AWS IAM Identity Center portal, role `kubequest2-student`
- No SSH keys by default — connect through **AWS SSM Session Manager** (console or CLI)
- `kube-1` has the stable public IP; `kube-2`/`kube-3` are private-only
- Shared storage at `/mnt/efs` on all three nodes — **20 GB hard limit**, becomes read-only if exceeded
- Only ports **80/443** are open inbound — worth confirming early how Traefik binds to those from a NodePort setup
- Instances auto-shutdown daily at **9 PM Paris time**; restart anytime

## Roadmap

- [x] Architecture, tech stack, and initial project plan drafted
- [x] Team kickoff meeting — walk the architecture, assign ownership, lock the working schedule
- [ ] Follow Up # 1: present architecture, tech choices, and plan (no working cluster required yet)
- [ ] Cluster provisioning (Ansible)
- [ ] Platform layer (the 6 jobs above)
- [ ] App conversion + GitOps deployment
- [ ] Follow Up # 2 (End of November 2026)
- [ ] Follow Up # 3
- [ ] Keynote (Feburary 2027)

## References

- [`kube-project.pdf`](./kube-project.pdf) — the brief (not tracked in git)
- [`KubeQuest2 - User Guide_0923.pdf`](./KubeQuest2%20-%20User%20Guide_0923.pdf) — AWS environment access
- [Reference Architecture](https://whimsical.com/cia547/kubekuby-FdNqP5i9U6GAwjxE3WtCyR) — diagrams
- [Tech decisions](https://github.com/EpitechMscProPromo2027/T-CLO-901-PAR-9-1-kube-5/wiki/III.-Technical-solutions) - technical solutions
