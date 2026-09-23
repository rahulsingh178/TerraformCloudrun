# --- The service account GitHub Actions will act as ---

resource "google_service_account" "github_deployer" {
  account_id   = "github-actions-deployer"
  display_name = "GitHub Actions Deployer"
}

# --- Permissions that service account needs ---

resource "google_project_iam_member" "deployer_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

resource "google_project_iam_member" "deployer_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_deployer.email}"
}

# State bucket wasn't created by Terraform, so grant access directly on it
resource "google_storage_bucket_iam_member" "deployer_state_access" {
  bucket = "terraform-state-rahul178-lab"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_deployer.email}"
}

# --- The Workload Identity Pool: a "trust boundary" GCP checks against ---

resource "google_iam_workload_identity_pool" "github_pool" {
  depends_on                = [google_project_service.iam, google_project_service.iamcredentials, google_project_service.sts]
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
}

# --- The Provider: teaches the pool to trust GitHub's tokens specifically ---

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id         = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Only accept tokens claiming to be from this exact repo
  attribute_condition = "assertion.repository == \"rahulsingh178/TerraformCloudrun\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# --- Let that specific repo impersonate the deployer service account ---

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.github_deployer.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/rahulsingh178/TerraformCloudrun"
}