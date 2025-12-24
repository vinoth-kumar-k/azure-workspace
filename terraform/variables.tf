variable "location" {
  description = "Azure Region"
  type        = string
  default     = "southeastasia"
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
  default     = "cloud-shell-rg"
}

variable "storage_account_name" {
  description = "Name of the Storage Account (must be unique globally)"
  type        = string
}

variable "file_share_name" {
  description = "Name of the File Share"
  type        = string
  default     = "cloudshell" # Often default is similar, but we can set it.
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
