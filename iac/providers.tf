provider "proxmox" {
  pm_api_url = "https://localhost:8006/api2/json"
  pm_tls_insecure = true
  pm_user = var.pm_user
  pm_password= var.pm_password
  pm_minimum_permission_check = false
}