variable "region" {
  type    = string
  default = "us-central"
}
variable "project" {
  type = string
}

variable "user" {
  type = string
}

variable "email" {
  type = string
}
variable "privatekeypath" {
  type    = string
  default = "C:\\Users\\NUppalapati\\.ssh\\id_rsa"
}

variable "cmek_crypto_key" {
  type = string
  default = "projects/vpc-host-nonprod-xd806-rw998/locations/us-central1/keyRings/shared-citco-keyring/cryptoKeys/shared-citco-key"
}
variable "publickeypath" {
  type    = string
  default = "C:\\Users\\NUppalapati\\.ssh\\id_rsa.pub"
}
