# Certificate
variable "fullchain_pem" {}
variable "private_key_pem" {}

# Server
variable "fqdn" {}
variable "server_id" {}
variable "ssh_key_file" {
  default = "~/.ssh/id_rsa"
}
