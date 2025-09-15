# Generate random chracters to use with VM
# see reference https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password for details
resource "random_password" "vm_random_password" {
  length  = 32
  special = false
}

# generate chracters to add to the end of the username
resource "random_string" "vm_random_username" {
  length  = 8
  special = false
}