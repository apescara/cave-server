provider "proxmox" {
  pm_api_url = "https://192.168.100.17:8006/api2/json"
  pm_tls_insecure = true
  pm_user = var.user
  pm_password= var.password
  pm_minimum_permission_check = false
}