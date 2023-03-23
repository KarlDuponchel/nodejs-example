terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.48.0"
    }
  }

  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

# Database Postgres
resource "azurerm_postgresql_server" "pg-server" {
  name                = "${var.project_name}-pg-server"
  location            = data.azurerm_resource_group.rg-tp.location
  resource_group_name = data.azurerm_resource_group.rg-tp.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = data.azurerm_key_vault_secret.database-login.value
  administrator_login_password = data.azurerm_key_vault_secret.database-password.value
  version                      = "9.5"
  ssl_enforcement_enabled      = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
}

resource "azurerm_postgresql_firewall_rule" "pg-fw-rule" {
  name                = "${var.project_name}-fw-rule"
  resource_group_name = data.azurerm_resource_group.rg-tp.name
  server_name         = azurerm_postgresql_server.pg-server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# WEB APP
resource "azurerm_service_plan" "kdu-service-plan" {
  name                = "${var.project_name}-appplan${var.environment_suffix}"
  resource_group_name = data.azurerm_resource_group.rg-tp.name
  location            = data.azurerm_resource_group.rg-tp.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "kdu-web-app" {
  name                = "${var.project_name}-webapp"
  resource_group_name = data.azurerm_resource_group.rg-tp.name
  location            = data.azurerm_resource_group.rg-tp.location
  service_plan_id     = azurerm_service_plan.kdu-service-plan.id

  site_config {
  }
}

# API
resource "azurerm_container_group" "kdu-api" {
    name = "${var.project_name}-api${var.environment_suffix}"
    resource_group_name = data.azurerm_resource_group.rg-tp.name
    location            = data.azurerm_resource_group.rg-tp.location
    ip_address_type = "Public"
    dns_name_label = "${var.project_name}-api${var.environment_suffix}"
    os_type = "Linux"

    container {
      name = "api"
      image = "gabrieldela/nodejs-example:1.0"
      cpu = "0.5"
      memory = "1.5"

      ports {
        port = 3000
        protocol = "TCP"
      }

      environment_variables = {
        "PORT"        = var.api_port
        "DB_HOST"     = azurerm_postgresql_server.pg-server.fqdn
        "DB_USERNAME" = "${data.azurerm_key_vault_secret.database-login.value}@${azurerm_postgresql_server.pg-server.name}"
        "DB_PASSWORD" = data.azurerm_key_vault_secret.database-password.value
        "DB_DATABASE" = var.database_name
        "DB_DAILECT"  = var.database_dialect
        "DB_PORT"     = var.database_port

        "ACCESS_TOKEN_SECRET"       = data.azurerm_key_vault_secret.access-token.value
        "REFRESH_TOKEN_SECRET"      = data.azurerm_key_vault_secret.refresh-token.value
        "ACCESS_TOKEN_EXPIRY"       = var.access_token_expiry
        "REFRESH_TOKEN_EXPIRY"      = var.refresh_token_expiry
        "REFRESH_TOKEN_COOKIE_NAME" = var.refresh_token_cookie_name
       }
    }
}

# PG ADMIN
resource "azurerm_container_group" "kdu-pgadmin" {
  name                = "kdu-${var.project_name}-pgadmin${var.environment_suffix}"
  location            = data.azurerm_resource_group.rg-tp.location
  resource_group_name = data.azurerm_resource_group.rg-tp.name
  ip_address_type     = "Public"
  dns_name_label      = "kdu-${var.project_name}-pgadmin${var.environment_suffix}"
  os_type             = "Linux"

  container {
    name   = "pgadmin"
    image  = "dpage/pgadmin4:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "PGADMIN_DEFAULT_EMAIL"    = data.azurerm_key_vault_secret.postgres-login.value
      "PGADMIN_DEFAULT_PASSWORD" = data.azurerm_key_vault_secret.postgres-password.value
    }
  }
}