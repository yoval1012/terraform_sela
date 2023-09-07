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

variable "user" {
  type = string
}


