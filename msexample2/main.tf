# -*- mode: hcl; coding: utf-8; -*-
# vim: set syntax=hcl fileencoding=utf-8

terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "azurerm" {
  version                 = ">=2.20"
  subscription_id         = var.subscription_id
  client_id               = var.client_id
  client_certificate_path = var.client_certificate_path
  tenant_id               = var.tenant_id
  features {}
}

provider "random" {
  version = "~> 2.3"
}

resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "grp" {
  name     = "PGSQLResourceGroup"
  location = var.location

  tags = {
    environment = "Terraform Demo"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${random_string.random.result}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.grp.location
  resource_group_name = azurerm_resource_group.grp.name
}

resource "azurerm_subnet" "example" {
  name                                           = "${random_string.random.result}-subnet"
  resource_group_name                            = azurerm_resource_group.grp.name
  virtual_network_name                           = azurerm_virtual_network.example.name
  address_prefixes                               = ["10.0.1.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_postgresql_server" "example" {
  name                = "${random_string.random.result}-pg"
  location            = azurerm_resource_group.grp.location
  resource_group_name = azurerm_resource_group.grp.name

  sku_name = "GP_Gen5_2"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  storage_mb                   = 51200
  auto_grow_enabled            = true
  administrator_login          = "mysqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "11"
  ssl_enforcement_enabled      = true
}

resource "azurerm_private_endpoint" "example" {
  name                = "${random_string.random.result}-endpoint"
  location            = azurerm_resource_group.grp.location
  resource_group_name = azurerm_resource_group.grp.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "${random_string.random.result}-privateserviceconnection"
    private_connection_resource_id = azurerm_postgresql_server.example.id
    subresource_names              = ["postgresServer"]
    is_manual_connection           = false
  }
}
