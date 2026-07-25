variable "ssh_public_key_path" {
  description = "Path to thr SSH public key"
  type = string
  default = "/var/jenkins_home/.ssh/id_ed25519.pub"
}

variable "ubuntu_image_url" {
  description = "Ubuntu Cloud Image URL"
  type = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}
