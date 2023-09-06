variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "rg" {
  type = string
  default = "rg-library-dev"
}

variable "subnet1" {
  type = string
  default = "snet-web"
}
variable "subnet2" {
  type = string
  default = "snet-db"
}
output "nsg1_public_ips" {
  value = [
    for rule in azurerm_network_security_group.nsg1.security_rule :
    rule.source_address_prefix
  ]
}

