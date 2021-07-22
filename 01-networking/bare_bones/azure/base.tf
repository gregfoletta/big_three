terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

variable "rg_name" {
  type = string
  default = "study"
}

variable "rg_location" {
  type = string
  default = "australiasoutheast"
}

# Azure the is provider for this lab.
provider "azurerm" {
  features {}

  subscription_id             = "251d8e18-0d26-4645-ae17-8db0b1f2f0b6"
  client_id                   = "5a9e35fa-1da9-499a-95e7-5b18af9b69a4"
  client_certificate_path     = pathexpand("~/.azure/sp.pfx")
  tenant_id                   = "c58cb715-fe75-4057-ae57-5a88a3dd7fa4"
}

resource "azurerm_virtual_network" "prod" {
  name                = "candidate_lab"
  address_space       = ["10.32.0.0/16"]
  location            = var.rg_location
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "prod_a" {
  name = "prod_a"
  resource_group_name = var.rg_name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes = ["10.32.0.0/24"]
}

resource "azurerm_subnet" "prod_b" {
  name = "prod_b"
  resource_group_name = var.rg_name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes = ["10.32.1.0/24"]
}

resource "azurerm_route_table" "prod" {
  name = "prod_route_table"
  location = var.rg_location
  resource_group_name = var.rg_name
}

resource "azurerm_route" "prod" {
  name = "default_route"
  resource_group_name = var.rg_name
  route_table_name = azurerm_route_table.prod.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}
