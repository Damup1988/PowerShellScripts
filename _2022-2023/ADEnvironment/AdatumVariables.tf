variable "vmname" {
  type    = string
  default = "ADATUMDC001"
}

variable "active_directory_domain" {
  description = "The name of the Active Directory domain, for example `consoto.local`"
  type        = string
  default     = "ADATUM.local"
}

variable "admin_password" {
  description = "The password associated with the local administrator account on the virtual machine"
  type        = string
  default     = "BArakuda@123"
}

variable "active_directory_netbios_name" {
  description = "The netbios name of the Active Directory domain, for example `consoto`"
  type        = string
  default     = "ADATUM"
}