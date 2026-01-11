terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~>3.70.0"
        }
    }

    backend "azurerm" {
      resource_group_name  = "storageA"
      storage_account_name = "khablob1"
      container_name       = "tfstate"
      key                  = "vm-lab/terraform.tfstate"
  }
}

provider "azurerm"{
    features {}

    skip_provider_registration = true
}

resource "azurerm_resource_group" "rg" {
    name = "rg-tf-vm-lab"
    location = "Australia Southeast"
}

resource "azurerm_virtual_network" "vnet" {
    name = "vnet-tf-lab"
    address_space = ["10.0.0.0/16"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet"{
    name = "subnet-1"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.1.0/24"]

}

resource "azurerm_public_ip" "pip" {
  name                = "pip-vm-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-vm-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

data "azurerm_ssh_public_key" "azure_key" {
  name                = "openssh-privatekey-elearning"
  resource_group_name = "storageA"
}



resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-tf-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2als_v6"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.azure_key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
}