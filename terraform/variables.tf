variable "project_id" {
  default = "testterraform-507511"
}

variable "region" {
  default = "us-central1"
}
variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}