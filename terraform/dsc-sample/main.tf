variable "subscription_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "tenant_id" {
  type = string
}
variable "azureRegion" {
  type = string
}
variable "primaryRegionAcronym" {
  type = string
}
variable "secondaryRegionAcronym" {
  type = string
}
variable "primaryRegion" {
  type = string
}
variable "secondaryRegion" {
  type = string
}
variable "resource-prefix" {
  type = string
}

variable "RGP-MAPPING" {
  type = map(any)
  default = {
    core-svc    = "COR-GV-1"
    network-svc = "NET-GV-1"
    app-svc     = "APP-GV-1"
  }

}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  environment     = var.azureRegion
}

data "azurerm_client_config" "current" {}


module "gov-azure-rgp" {
  source              = "./resource-group"
  resource_group_name = ["COR-GV-1", "APP-GV-1", "NET-GV-1"]
  azureRegion         = var.secondaryRegion
}

resource "azurerm_automation_account" "az_aaa_01" {
  name                = "AZ-GV-AAA-01"
  location            = var.secondaryRegion
  resource_group_name = var.RGP-MAPPING["core-svc"]

  sku_name = "Basic"

  tags = {
    environment = "Development"
  }
}

module "automation_module_import" {
  source                  = "./automation"
  resource_group_name     = var.RGP-MAPPING["core-svc"]
  automation_account_name = azurerm_automation_account.az_aaa_01.name
  module_list             = ["xActiveDirectory", "Az.Accounts", "xPowerShellExecutionPolicy", "xPSDesiredStateConfiguration", "AuditPolicyDsc", "AuditSystemDsc", "AccessControlDsc", "ComputerManagementDsc", "FileContentDsc", "GPRegistryPolicyDsc", "PSDscResources", "SecurityPolicyDsc", "SqlServerDsc", "WindowsDefenderDsc", "xDnsServer", "xWebAdministration", "CertificateDsc", "nx", "PowerSTIG"]
}