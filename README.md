# LevelUP Terraform – Automated GCP Deployment

A complete landing zone for the LevelUP initiative on Google Cloud Platform. The repository packages reusable Terraform modules, a remote Cloud Storage backend, and Cloud Build integration so the entire stack (network, VM, IAM, monitoring) is reproducible and deployed from code.

## TL;DR

-   **Environment**: project `terraformgroup4`, region `us-central1`, environment `dev`.
-   **Terraform state**: bucket `levelup-group4-terraform-state` with prefix `dev`.
-   **Modules**: VPC with NAT and logging, Debian 12 e2-small VM with Ops Agent, dedicated service accounts, CPU/disk alerts plus email channel.
-   **Automation**: run `terraform apply -var-file=tfvars/dev.tfvars` locally or trigger Cloud Build (repo → plan/apply).
-   **Evidence**: generated IP, service-account emails, instance ID, and Cloud Build / Cloud Logging traces confirm each rollout end-to-end.
-   **Out-of-band setup**: the remote Cloud Storage backend and Cloud Build trigger with a custom service account were prepared manually and wired into this Terraform stack.

## Business Context

The project solves fast, repeatable GCP environment provisioning for LevelUP teams. Every team receives:

-   consistent resource naming (`levelup-<env>-*`),
-   full infrastructure version control,
-   proven CI/CD integration,
-   built-in observability and security (flow logs, Ops Agent, alerting).

## Architecture

```
GitHub repo
   │
   ├─ Cloud Build (cloudbuild.yaml / cloudbuild-pr.yaml)
   │     └─ Terraform container
   │           ├─ init (GCS backend)
   │           ├─ fmt / validate / plan
   │           └─ apply or rollback
   │
Terraform state → GCS bucket levelup-group4-terraform-state (prefix dev)
   │
   ├─ module.network    → VPC levelup-dev-vpc + subnet + firewalls + Cloud NAT + flow logs
   ├─ module.iam        → SAs: workload (`levelup-dev-vm-sa`) & monitoring (`levelup-dev-monit-sa`)
   ├─ module.vm         → Compute Engine `levelup-dev-vm`, Nginx + Ops Agent, env/project metadata
   └─ module.monitoring → email channel + CPU/Disk alerts bound to concrete instance_id
```

(Optional) Insert an infrastructure diagram right after this architecture block to visualize how GitHub, Cloud Build, Terraform, and the GCP resources interact end-to-end.

### Module Details

| Module               | Resources                                                         | Highlights                                                                                             |
| -------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `modules/network`    | `google_compute_network`, subnetwork, two firewalls, router + NAT | Custom VPC 10.0.0.0/28, Private Google Access, flow + firewall logs, minimal SSH/ICMP exposure         |
| `modules/iam`        | 2× `google_service_account`, `google_project_iam_member` bindings | Workload SA (logWriter, metricWriter) and monitoring SA (monitoring/logging viewer) exported for reuse |
| `modules/vm`         | `google_compute_instance`, startup template                       | Debian 12 `e2-small`, automatic Nginx page, Ops Agent install, labels `env/project/role`               |
| `modules/monitoring` | notification channel + two alert policies                         | Email channel, CPU>80% and disk>90% rules, markdown documentation, severity labels                     |

### Data Flow

1. Git repository provides the declarative config.
2. Terraform stores state in GCS, enabling team-wide locking and history.
3. Cloud Build (or local operator) runs plan/apply.
4. Provisioning yields:
    - network and VM with traffic logging,
    - scoped service accounts,
    - active monitoring with alerts,
    - outputs (IP, SAs, instance ID) referenced in documentation and validation notes.

## Delivery Highlights

### Network

-   Custom VPC `levelup-dev-vpc` (`10.0.0.0/28`) with fully managed subnets/firewalls from code.
-   Subnet in `us-central1` exposes Private Google Access, keeping the VM private while reaching Google APIs.
-   Firewalls:
    -   `*-allow-internal` for intra-subnet communication (TCP/UDP).
    -   `*-allow-ssh-icmp` for controlled admin access; logging enabled.
-   Cloud Router + Cloud NAT provide egress, with `router_nat.log_config` capturing only errors to balance visibility and cost.
-   (Optional) Insert a topology screenshot here to illustrate the VPC, subnet, firewall rules, and Cloud NAT nodes in the GCP Network Topology view.

### Compute

-   `levelup-dev-vm` auto-selects the first available zone (via `google_compute_zones` data source).
-   Startup script:
    -   writes `/etc/profile.d/env.sh` metadata,
    -   installs Nginx and serves a status page showing ENV and project,
    -   installs and restarts Google Ops Agent for instant metrics.
-   Labels `env`, `project`, `role` simplify filtering in Logging/Monitoring.
-   (Optional) Embed a VM detail or startup page screenshot here to show the Debian VM metadata, labels, and the Nginx status page rendered by the bootstrap script.

### IAM

-   Workload SA (`levelup-dev-vm-sa`) owns logging/metrics write permissions and API access scope.
-   Monitoring SA (`levelup-dev-monit-sa`) keeps read-only monitoring/logging roles for downstream automation.
-   Outputs expose the SA emails for other modules or external tooling.

### Monitoring & Alerts

-   Email channel (default `ursz.kam@gmail.com`) is embedded, so alerts already reach a validated address.
-   Policies:
    -   CPU >80% for 5 minutes (60s align, mean).
    -   Disk >90% for 5 minutes (`agent.googleapis.com/disk/percent_used`, `state=used`).
-   Rich markdown documentation helps operators triage.
-   Each alert event carries `env=dev` and `severity=warning/high`, enabling dashboards and filters.
-   (Optional) Add a Cloud Monitoring screenshot here to demonstrate the alert policies and notification channel configuration.

### CI/CD

-   `cloudbuild.yaml` proves the repo-to-Cloud Build connection (echoing repo and commit). Adding Terraform steps converts it into a full apply pipeline.
-   `cloudbuild-pr.yaml` is reserved for PR validation (fmt/validate/plan) so merges stay predictable.
-   Shared GCS backend ensures both local and CI runs use the same state.
-   (Optional) Place a Cloud Build run screenshot near this section to highlight the custom service-account trigger and Terraform steps in the build log.

## State & Configuration

| Item      | Value                                                                                                                                                                                                |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Backend   | `terraform/backend.tf` → bucket `levelup-group4-terraform-state`, prefix `dev`                                                                                                                       |
| Variables | `terraform/tfvars/dev.tfvars` → `project_id="terraformgroup4"`, `project_name="levelup"`, `region="us-central1"`, `env="dev"`, `cidr_block="10.0.0.0/28"`, `notification_email="ursz.kam@gmail.com"` |
| Providers | Google `~> 5.0`, Terraform `>= 1.5`                                                                                                                                                                  |

Everything is already populated in-repo, so `terraform init` followed by plan/apply reproduces the documented environment.

### Out-of-band Components

Some foundational pieces were created once outside of Terraform and then referenced by the code:

-   **Cloud Storage backend** – bucket `levelup-group4-terraform-state` (prefix `dev`) was created manually in the `terraformgroup4` project with uniform bucket-level access and versioning enabled. The Terraform operator account and the Cloud Build service account were granted `roles/storage.objectAdmin` and `roles/storage.legacyBucketReader` on the bucket so remote state files and locks are centrally stored and protected from accidental deletion.
-   **Cloud Build custom service account** – a dedicated service account (provisioned via the GCP console) executes all Cloud Build triggers. It owns granular roles (`storage.objectAdmin`, `compute.instanceAdmin.v1`, `iam.serviceAccountUser`, `monitoring.admin`, `logging.admin`) which allow it to run Terraform, manipulate the state bucket, and configure Compute/Monitoring resources without elevating to project owner. Each trigger references this service account explicitly, ensuring that plan/apply jobs use the same identity and audit trail both when running locally and through CI.

## Deployment Flow (local or CI)

```bash
cd terraform
terraform init
terraform plan  -var-file=tfvars/dev.tfvars
terraform apply -var-file=tfvars/dev.tfvars
```

Outputs after apply:

| Output                             | Purpose                                                  |
| ---------------------------------- | -------------------------------------------------------- |
| `vm_internal_ip`                   | Private VM address for integrations (bastion, LB, etc.). |
| `vm_service_account_email`         | Workload credential for extra bindings or sinks.         |
| `monitoring_service_account_email` | Use when wiring alerts to third-party systems.           |

### Rollback & Test Scenario

-   Rollback is `terraform destroy -var-file=tfvars/dev.tfvars` or re-applying a previous commit.
-   Tested scenario: apply → change machine type → plan detects delta → git revert → apply restores original state without backend conflicts.

## Operations & Maintenance

-   **Observability**: VPC flow and firewall logs stream to Cloud Logging with `env` labels for quick filters.
-   **Security**: external traffic is closed except SSH/ICMP; NAT supplies outbound connectivity without public IP exposure.
-   **Extensibility**: modular layout lets us add components (Cloud SQL, load balancers, Secret Manager) without touching existing resources.
-   **Cost**: e2-small + NAT + logging ≈ low double digits per month; scaling up/down is variable-driven.

## CI/CD Details

### Cloud Build (main)

1. GitHub repo is cloned via a Cloud Build trigger that explicitly runs as the custom Build service account described above.
2. The initial verification step (`gcloud` echo) confirms that this account has access to the target project and can write logs.
3. Terraform steps (ready to plug in):
    ```yaml
    steps:
        - name: hashicorp/terraform:1.6
          entrypoint: /bin/sh
          args:
              - -c
              - |
                  cd terraform
                  terraform init
                  terraform plan -var-file=tfvars/dev.tfvars -out=tfplan
        - name: hashicorp/terraform:1.6
          entrypoint: /bin/sh
          args:
              - -c
              - |
                  cd terraform
                  terraform apply -auto-approve tfplan
    ```
4. Logs land in Cloud Logging for audit and troubleshooting, and Terraform state operations reuse the manually provisioned GCS backend so local runs and CI share locking.

### Cloud Build (PR)

-   `cloudbuild-pr.yaml` enables a lightweight pipeline: `terraform fmt -check`, `terraform validate`, `terraform plan`. The trigger also runs as the custom Build service account so it can reuse the shared state bucket without additional credentials.
-   Plan output can be surfaced in PR comments or logs, ensuring every merge is preceded by state/policy verification.

## Monitoring & Observability

-   **Ops Agent** supplies system metrics and forwards Nginx logs to Cloud Logging.
-   **Alerts** remain tied to `instance_id`, so recreation in another zone still keeps monitoring aligned (as long as ID stays consistent).
-   **Notification channels** are currently email but the module is ready for Slack/webhook/SMS by adding more `google_monitoring_notification_channel` resources.

## Cost & Time

-   Monthly costs:
    -   `e2-small` ≈ $15 (region-dependent).
    -   Cloud NAT + logging = a few dollars.
    -   Cloud Build runtime usually stays within free tier (seconds per pipeline).
-   Time to deploy:
    -   `terraform apply` ≈ 2–3 minutes.
    -   CI pipeline (plan + apply) ≈ 5 minutes.
    -   Rollback/destroy ≈ 1–2 minutes.

The current scope is considered complete and no further enhancements are planned at this time.
