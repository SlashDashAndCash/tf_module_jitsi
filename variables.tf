# Certificate
variable "fullchain_pem" {}
variable "private_key_pem" {}

# Server
variable "fqdn" {}
variable "ssh_key_file" {
  default = "~/.ssh/id_rsa"
}
