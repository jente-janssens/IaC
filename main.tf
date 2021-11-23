 terraform {

   required_version = ">=0.12"

   required_providers {
     azurerm = {
       source = "hashicorp/azurerm"
       version = "~>2.0"
     }
   }
 }


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = "70b0cad6-067d-4520-942c-e19cd37c2001"
  client_id       = "0d8724bd-8858-4914-9cb4-1d234b8ebedc"
  client_secret   = "TVQBTZ.k~BGhTC_-oz0EXumsUkFzhzCzx2"
  tenant_id       = "77d33cc5-c9b4-4766-95c7-ed5b515e1cce"
}

# Configure Microsoft Azure resource group
resource "azurerm_resource_group" "IaC-Webserver" {
  name     = "IaC-Webserver"
  location = "West Europe"
}

# Configure Microsoft Azure virtual network
resource "azurerm_virtual_network" "vNetwork" {
  name                = "IaC-Webserver-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.IaC-Webserver.location
  resource_group_name = azurerm_resource_group.IaC-Webserver.name
}

# Configure Microsoft Azure subnet
resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.IaC-Webserver.name
  virtual_network_name = azurerm_virtual_network.vNetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Configure Microsoft Azure Public Ip
resource "azurerm_public_ip" "IaC-Webserver-jenkins-ip" {
  name                = "IaC-Webserver-jenkins-ip"
  resource_group_name = azurerm_resource_group.IaC-Webserver.name
  location            = azurerm_resource_group.IaC-Webserver.location
  allocation_method   = "Dynamic"
  domain_name_label   = "iac-webserver"
}

# Configure Microsoft Azure network interface
resource "azurerm_network_interface" "IaC-Webserver-jenkins743" {
  name                = "IaC-Webserver-jenkins743"
  location            = azurerm_resource_group.IaC-Webserver.location
  resource_group_name = azurerm_resource_group.IaC-Webserver.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.IaC-Webserver-jenkins-ip.id
  }
}

# Configure Microsoft Azure security group
resource "azurerm_network_security_group" "IaC-Webserver-jenkins-nsg" {
  name                = "IaC-Webserver-jenkins-nsg"
  location            = azurerm_resource_group.IaC-Webserver.location
  resource_group_name = azurerm_resource_group.IaC-Webserver.name
  security_rule {
    access                 = "Allow"
    direction              = "Inbound"
    name                   = "ssh access"
    priority               = 110
    protocol               = "Tcp"
    source_port_range      = "*"
    source_address_prefix  = "*"
    destination_port_range = "22"
    destination_address_prefix = "*"
  }
  security_rule {
    access                 = "Allow"
    direction              = "Inbound"
    name                   = "http access"
    priority               = 120
    protocol               = "Tcp"
    source_port_range      = "*"
    source_address_prefix  = "*"
    destination_port_range = "80"
    destination_address_prefix = "*"
  }
  security_rule {
    access                 = "Allow"
    direction              = "Inbound"
    name                   = "https access"
    priority               = 130
    protocol               = "Tcp"
    source_port_range      = "*"
    source_address_prefix  = "*"
    destination_port_range = "443"
    destination_address_prefix = "*"
  }
}

# Configure Microsoft Azure SSH Key
resource "tls_private_key" "sshKey" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Configure Microsoft Azure virtual machine
resource "azurerm_linux_virtual_machine" "IaC-Webserver_Website" {
  name                = "IaC-Webserver-Website"
  computer_name       = "IaC-Webserver-Website"
  resource_group_name = azurerm_resource_group.IaC-Webserver.name
  location            = azurerm_resource_group.IaC-Webserver.location
  size                = "Standard_B1s"
  admin_username      = "Jenkins"
  admin_password      = "JenkinsUser1"
  network_interface_ids = [
    azurerm_network_interface.IaC-Webserver-jenkins743.id,
  ]

  admin_ssh_key {
    username   = "Jenkins"
    public_key = tls_private_key.sshKey.public_key_openssh
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "local_file" "keyFile" {
  content           = tls_private_key.sshKey.private_key_pem
  filename          = "/.ssh-key/IaC-Webserver-Website_key.pem"
  file_permission   = "0600"
}

