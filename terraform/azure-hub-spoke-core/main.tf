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


variable "HUB-VM-NAME" {
  type    = list(any)
  default = ["HUB-VM-01", "HUB-VM-02", "HUB-VM-03", "HUB-VM-04"]
}

variable "SPOKE1-VM-NAME" {
  type    = list(any)
  default = ["SPOKE1-VM-01", "SPOKE1-VM-02", "SPOKE1-VM-03", "SPOKE1-VM-04"]
}

variable "SPOKE2-VM-NAME" {
  type    = list(any)
  default = ["SPOKE2-VM-01", "SPOKE2-VM-02", "SPOKE2-VM-03", "SPOKE2-VM-04"]

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
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  environment     = var.azureRegion
}

data "azurerm_client_config" "current" {}


#########################
# Modules 
# Resource Group
# Network
# Recovery Vault
# Backup Policy
# Enroll in Vault
# Create replicated VM
########################






module "dod_azure_rgp" {
  source              = "./modules/resource-group"
  resource_group_name = ["USDOD-HUB-01", "USDOD-SPOKE-01", "USDOD-SPOKE-02"]
  azureRegion         = "usdodcentral"
}

module "gov-azure-rgp" {
  source              = "./modules/resource-group"
  resource_group_name = ["USGOV-HUB-01", "USGOV-SPOKE-01", "USGOV-SPOKE-02"]
  azureRegion         = "usgovvirginia"
}


module "dod-hub-network" {
  source = "./modules/network"
  #resource_group_name = azurerm_resource_group.PRI-HUB.name
  resource_group_name = "USDOD-HUB-01"
  location            = "usdodcentral"
  vnet_name           = "USDOD-HUB-VNT-1"
  address_spaces      = ["10.0.0.0/24"]
  subnets = [
    {
      name : "GatewaySubnet"
      address_prefixes : ["10.0.0.0/27"]
    },
    {
      name : "HUB-SUBNET-1"
      address_prefixes : ["10.0.0.32/27"]
    },
    {
      name : "AzureBastionSubnet"
      address_prefixes : ["10.0.0.64/27"]
    }
  ]
  depends_on = [
    module.dod_azure_rgp
  ]
}

module "dod-spoke1-network" {
  source              = "./modules/network"
  resource_group_name = "USDOD-SPOKE-01"
  location            = "usdodcentral"
  vnet_name           = "${var.primaryRegionAcronym}-SPOKE-VNT-1"
  address_spaces      = ["10.0.1.0/24"]
  subnets = [
    {
      name : "GatewaySubnet"
      address_prefixes : ["10.0.1.0/27"]
    },
    {
      name : "SPOKE1-SUBNET-1"
      address_prefixes : ["10.0.1.32/27"]
    }
  ]
  depends_on = [
    module.dod_azure_rgp
  ]

}

module "dod-spoke2-network" {
  source              = "./modules/network"
  resource_group_name = "USDOD-SPOKE-02"
  location            = "usdodcentral"
  vnet_name           = "USDOD-SPOKE-VNT-2"
  address_spaces      = ["10.0.2.0/24"]
  subnets = [
    {
      name : "GatewaySubnet"
      address_prefixes : ["10.0.2.0/27"]
    },
    {
      name : "SPOKE2-SUBNET-1"
      address_prefixes : ["10.0.2.32/27"]
    }
  ]
  depends_on = [
    module.dod_azure_rgp
  ]

}
/*

module "gov-hub-network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.SEC-HUB.name
  location            = azurerm_resource_group.SEC-HUB.location
  vnet_name           = "SEC-HUB-VNT-1"
  address_spaces      = ["10.1.0.0/24"]
  subnets = [
    {
      name : "GatewaySubnet"
      address_prefixes : ["10.1.0.0/27"]
    },
    {
      name : "HUB-SUBNET-1"
      address_prefixes : ["10.1.0.32/27"]
    },
    {
      name : "AzureBastionSubnet"
      address_prefixes : ["10.1.0.64/27"]
    }
  ]
}

module "gov-spoke1-network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.SEC-SPOKE1.name
  location            = azurerm_resource_group.SEC-SPOKE1.location
  vnet_name           = "USGOV-SPOKE-VNT-1"
  address_spaces      = ["10.1.1.0/24"]
  subnets = [
    {
      name : "GatewaySubnet"
      address_prefixes : ["10.1.1.0/27"]
    },
    {
      name : "SPOKE1-SUBNET-1"
      address_prefixes : ["10.1.1.32/27"]
    }
  ]
}

module "gov-spoke2-network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.SEC-SPOKE2.name
  location            = azurerm_resource_group.SEC-SPOKE2.location
  vnet_name           = "USGOV-SPOKE-VNT-2"
  address_spaces      = ["10.1.2.0/24"]
  subnets = [
    {
      name : "GatewaySubnet"
      address_prefixes : ["10.1.2.0/27"]
    },
    {
      name : "SPOKE2-SUBNET-1"
      address_prefixes : ["10.1.2.32/27"]
    }
  ]
}

module "recovery-vault" {
  source              = "./modules/backup-vault"
  resource_group_name = azurerm_resource_group.SEC-HUB.name
  location            = "usgovvirginia"
  vault_name          = "USGOV-VAULT-01"

}

module "hub-vm-deploy" {
  source              = "./modules/virtual-machine"
  VMs                 = var.HUB-VM-NAME
  location            = azurerm_resource_group.PRI-HUB.location
  resource_group_name = azurerm_resource_group.PRI-HUB.name
  subnetId            = module.dod-hub-network.subnet_ids["HUB-SUBNET-1"]
}

module "spoke1-vm-deploy" {
  source              = "./modules/virtual-machine"
  VMs                 = var.SPOKE1-VM-NAME
  resource_group_name = azurerm_resource_group.PRI-SPOKE1.name
  location            = azurerm_resource_group.PRI-SPOKE1.location
  subnetId            = module.dod-spoke1-network.subnet_ids["SPOKE1-SUBNET-1"]
}

module "spoke2-vm-deploy" {
  source              = "./modules/virtual-machine"
  VMs                 = var.SPOKE2-VM-NAME
  resource_group_name = azurerm_resource_group.PRI-SPOKE2.name
  location            = azurerm_resource_group.PRI-SPOKE2.location
  subnetId            = module.dod-spoke2-network.subnet_ids["SPOKE2-SUBNET-1"]
}

module "site-recovery-hub" {
  source                        = "./modules/site-recovery"
  vault_name                    = "USGOV-VAULT-01"
  primary_resource_group_name   = azurerm_resource_group.PRI-HUB.name
  primary_location              = azurerm_resource_group.PRI-HUB.location
  secondary_resource_group_name = azurerm_resource_group.SEC-HUB.name
  secondary_location            = azurerm_resource_group.SEC-HUB.location
  secondary_rgp_id              = azurerm_resource_group.SEC-HUB.id
  vm_id                         = module.hub-vm-deploy.vm-ids
}
*/