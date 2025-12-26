variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
}

variable "logic_app_name" {
  description = "Name of the Logic App"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "email_address" {
  description = "Email address to send to (default for testing)"
  type        = string
  default     = "admin@example.com"
}
