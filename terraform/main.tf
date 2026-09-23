resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "app_repo" {
  depends_on    = [google_project_service.artifactregistry]
  location      = var.region
  repository_id = "cloudrun-cicd-repo"
  format        = "DOCKER"
  description   = "Container images for the Cloud Run CI/CD demo"
}

# --- Cloud Run service (new — Session 2) ---
resource "google_cloud_run_v2_service" "app" {
  depends_on = [google_project_service.run, google_project_service.cloudbuild]
  name       = "cloudrun-cicd-demo"
  location   = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/cloudrun-cicd-repo/app:${var.image_tag}"
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.app.location
  name     = google_cloud_run_v2_service.app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_project_iam_member" "deployer_serviceusage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:github-actions-deployer@testterraform-507511.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "deployer_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:github-actions-deployer@testterraform-507511.iam.gserviceaccount.com"
}

resource "google_project_service" "iam" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iamcredentials" {
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sts" {
  service            = "sts.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

