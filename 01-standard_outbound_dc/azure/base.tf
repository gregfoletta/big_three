terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

# Azure the is provider for this lab.
provider "azurerm" {
  features {}
}

# We create a distinct resource group to hold all of the contents
# of the lab.
resource "azurerm_resource_group" "prod" {
    name = "big_three"
    location = "australiasoutheast"
}

resource "azurerm_virtual_network" "prod" {
  name                = "candidate_lab"
  address_space       = ["10.32.0.0/16"]
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
}

resource "azurerm_subnet" "prod_a" {
  name = "prod_a"
  resource_group_name = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes = ["10.32.0.0/24"]
}

resource "azurerm_subnet" "prod_b" {
  name = "prod_b"
  resource_group_name = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes = ["10.32.1.0/24"]
}

resource "azurerm_route_table" "prod" {
  name = "prod_route_table"
  location = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
}

resource "azurerm_route" "prod" {
  name = "default_route"
  resource_group_name = azurerm_resource_group.prod.name
  route_table_name = azurerm_route_table.prod.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}
