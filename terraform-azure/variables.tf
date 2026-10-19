
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for CartFlow resources"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Existing CartFlow resource group"
  type        = string
  default     = "cartflow-rg"
}