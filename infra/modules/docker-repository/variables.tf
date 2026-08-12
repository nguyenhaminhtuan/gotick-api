variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "repository_id" {
  description = "Repository name."
  type        = string
}

variable "description" {
  type    = string
  default = null
}

variable "untagged_retention_days" {
  description = "Delete untagged images older than this. null disables the policy."
  type        = number
  default     = 7
}

variable "tagged_keep_count" {
  description = "Tagged versions kept regardless of age. null disables the policy."
  type        = number
  default     = 20
}

variable "writer_members" {
  description = "IAM members granted push access, in serviceAccount:... form."
  type        = list(string)
  default     = []
}

variable "reader_members" {
  description = "IAM members granted pull access."
  type        = list(string)
  default     = []
}
