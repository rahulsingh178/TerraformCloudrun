output "service_url" {
  value = google_cloud_run_v2_service.app.uri
}

output "wif_provider" {
  value = google_iam_workload_identity_pool_provider.github_provider.name
}

output "deployer_sa_email" {
  value = google_service_account.github_deployer.email
}