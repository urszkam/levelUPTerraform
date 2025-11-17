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

This project aims to deploy Google Cloud Platform (GCP) infrastructure in a fully automated way using Terraform and Cloud Build. The goal is to establish a repeatable, version-controlled Infrastructure as Code (IaC) workflow that ensures consistency and efficiency across environments.

The project scope includes:

-   Configuring Terraform files for VPC, virtual machines, firewall rules, and IAM policies.
-   Using Cloud Storage as the backend for managing Terraform state.
-   Integrating Terraform with Cloud Build to automatically trigger `terraform plan` and `terraform apply` through CI/CD pipelines.
-   Enabling monitoring, logging, and alerting in Cloud Monitoring for infrastructure observability.

Technologies used: Terraform, Cloud Build, Compute Engine, Cloud Storage, IAM, and Cloud Monitoring.

Team responsibilities:

1. Develop Terraform modules for networking, VM instances, and IAM configuration.
2. Integrate the Git repository with Cloud Build for automated deployment.
3. Execute automated deployments and verify rollback procedures.
4. Analyze automation time and cost efficiency.

The final outcome is a fully automated GCP infrastructure deployment, reproducible from version-controlled source code.

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

### 🌐 Network

-   Custom VPC `levelup-dev-vpc` (`10.0.0.0/28`) is created with `auto_create_subnetworks = false`, so every subnet or route is expressed in Terraform rather than inherited from Google’s default network; /28 gives 13 usable addresses, enough for a single VM plus future helpers without wasting IP space.
-   The single subnet (`levelup-dev-subnet`) lives in `us-central1`, takes advantage of its four zones (for resilience) and lower-cost e2 pricing, turns on Private Google Access, and pushes flow logs with 30% sampling + full metadata—enough for troubleshooting without flooding logs.
-   Firewall rules are limited to two cases: internal TCP/UDP within the CIDR and SSH/ICMP from anywhere for administrators. Both rules keep `log_config` enabled so access attempts show up in Cloud Logging.
-   A Cloud Router + Cloud NAT pair provides outbound internet for the subnet. NAT logging is set to `ERRORS_ONLY`, which proves translations work while keeping log volume (and cost) under control.

### 🖥️ Compute

-   `levelup-dev-vm` is a single `e2-small` Compute Engine VM running the Debian 12 image with a 20 GB boot disk. That size is the smallest that comfortably runs Ops Agent plus the demo workload.
-   Terraform queries `google_compute_zones` and picks the first zone in `us-central1`, so builds continue even if a specific zone is unavailable.
-   OS Login/OS Config metadata is enabled, the VM attaches the dedicated service account with full Cloud Platform scope, and startup automation writes env metadata, installs Nginx, and runs Google Ops Agent.
-   The instance carries consistent labels (`env`, `project`, `role=app-vm`) and tags (`dev`, `vm`) so firewall rules, IAM conditions, and monitoring filters line up with the rest of the stack.

### IAM

-   Workload Service Account (`levelup-dev-vm-sa`) owns logging/metrics write permissions and API access scope (`Logs Writer`, `Monitoring Metric Writer`).
-   Monitoring Service Account (`levelup-dev-monit-sa`) keeps read-only monitoring/logging roles for downstream automation (`Logs Viewer`, `Monitoring Viewer`)
-   Outputs expose the SA emails for other modules or external tooling.

### 📟 Monitoring & Alerts

-   A single email notification channel (`Email alerts dev`) sends incidents to `ursz.kam@gmail.com`, so no extra wiring is needed after deploy.
-   Two alert policies ship with the stack: CPU utilization above 80 % for 5 minutes and disk usage above 90 % (Ops Agent metric `disk/percent_used` with `state=used`) for the VM instance ID.
-   Both policies include short markdown docs that name the VM and condition, so responders know what failed straight from the email.
-   Labels `env=dev` plus `severity=warning`/`high` accompany each alert, which keeps dashboards and filters consistent with the rest of the configuration.

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
-   **Cloud Build custom service account** – a dedicated service account (provisioned via the GCP console) executes all Cloud Build triggers. It owns granular roles (`Cloud Build Editor`, `Cloud Build Service Account`, `Cloud Build Service Agent`, `Compute Instance Admin (v1)`, `Compute Network Admin`, `Compute Security Admin`, `Logging Admin`, `Monitoring Admin`, `Security Admin`, `Service Account Admin`, `Service Account User`, `Storage Object Admin`) which allow it to run Terraform, manipulate the state bucket, and configure Compute/Monitoring resources without elevating to project owner. Each trigger references this service account explicitly, ensuring that plan/apply jobs use the same identity and audit trail both when running locally and through CI.

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

The cloudbuild.yaml file is used for continuous integration between the repository and Cloud Build. It automatically triggers Cloud Build pipelines whenever changes are pushed to the repository. The image hashicorp/terraform:1.13.0 is used.

1. GitHub repo is cloned via a Cloud Build trigger that explicitly runs as the custom Build service account.
2. The initial verification step (`gcloud` echo) confirms that this account has access to the target project and can write logs.
3. The cloudbuild.yaml file is the main deployment pipeline for running each step:

   - terraform fmt with a -recursive flag format all the terraform configuration to keep the code clean and uniform.
The result is stored in the terraform-fmt.log.

   ```yaml
   - name: hashicorp/terraform:1.13.0
      id: terraform-fmt
      entrypoint: sh
      args:
          - -c
          - |
              terraform fmt -recursive | tee /workspace/terraform-fmt.log
      dir: "terraform"
   ```
   
   - terraform init initializes Terraform, downloads providers and connects to the remote Google Cloud Storage backend. The logs for this step are stored in the terraform-init.log.
  
   ```yaml
   - name: hashicorp/terraform:1.13.0
      id: "terraform-init"
      entrypoint: sh
      args:
          - -c
          - |
              terraform init -input=false \
              | tee /workspace/terraform-init.log
      dir: "terraform"
   ```

   - terraform validate checks that the code and the structure are correct. The result is logged into the terraform-validate.log

   ```yaml
   - name: hashicorp/terraform:1.13.0
      id: terraform-validate
      entrypoint: sh
      args:
          - -c
          - |
              terraform validate | tee /workspace/terraform-validate.log
      dir: "terraform"
   ```

   - download tfplan downloads a Terraform plan from the Google Cloud Storage bucket. The plan is generated by the cloudbuild-pr.yaml pipeline.

   ```yaml
   - name: gcr.io/cloud-builders/gsutil
      id: "download-tfplan"
      entrypoint: bash
      args:
          - -c
          - |
              gsutil cp gs://levelup-group4-terraform-state/plans/default.tfplan terraform/tfplan
   ```

   - terraform apply applies the Terraform plan to the cloud environment. The auto-approve flag keeps the CI/CD deplyments fully automated.

   ```yaml
   - name: hashicorp/terraform:1.13.0
      id: "terraform-apply"
      entrypoint: sh
      args:
          - -c
          - |
              terraform apply -input=false -auto-approve tfplan \
              | tee /workspace/terraform-apply.log
      dir: "terraform"
   ```

   - cleanup tfplan removes the used plan file from the Google Cloud Storage bucket.

   ```yaml
   - name: gcr.io/cloud-builders/gsutil
      id: "cleanup-tfplan"
      entrypoint: bash
      args:
          - -c
          - |
              gsutil rm -f gs://levelup-group4-terraform-state/plans/default.tfplan
   ```
   
4. Logs land in Cloud Logging for audit and troubleshooting, and Terraform state operations reuse the manually provisioned GCS backend so local runs and CI share locking.
   
   ```yaml
   options:
   logging: CLOUD_LOGGING_ONLY


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
