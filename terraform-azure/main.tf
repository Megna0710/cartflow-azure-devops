
data "azurerm_resource_group" "cartflow" {
  name = var.resource_group_name
}

data "azurerm_container_registry" "cartflow" {
  name                = "cartflowmegna2026"
  resource_group_name = data.azurerm_resource_group.cartflow.name
}

data "azurerm_container_app_environment" "cartflow" {
  name                = "cartflow-env"
  resource_group_name = data.azurerm_resource_group.cartflow.name
}

output "resource_group_name" {
  value = data.azurerm_resource_group.cartflow.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.cartflow.location
}

output "container_registry_name" {
  value = data.azurerm_container_registry.cartflow.name
}

output "container_registry_login_server" {
  value = data.azurerm_container_registry.cartflow.login_server
}

output "container_registry_sku" {
  value = data.azurerm_container_registry.cartflow.sku
}


resource "azurerm_container_app" "cartflow" {
  name                         = "cartflow-api"
  resource_group_name          = data.azurerm_resource_group.cartflow.name
  container_app_environment_id = data.azurerm_container_app_environment.cartflow.id
  revision_mode                = "Single"
  max_inactive_revisions       = 100
  workload_profile_name        = "Consumption"

  tags = {
    project = "cartflow"
  }

  identity {
    type = "SystemAssigned"
  }

  registry {
    server   = data.azurerm_container_registry.cartflow.login_server
    identity = "system-environment"
  }

  secret {
    name                = "cartflow-demo-message"
    identity            = "System"
    key_vault_secret_id = "https://cartflow-kv-megna-2026.vault.azure.net/secrets/cartflow-demo-message"
  }

  ingress {
    external_enabled           = true
    target_port                = 5000
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas                = 0
    max_replicas                = 10
    cooldown_period_in_seconds  = 300
    polling_interval_in_seconds = 30

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 10
    }

    container {
      name   = "cartflow-api"
      image = "cartflowmegna2026.azurecr.io/cartflow:e76e7a34dd21b39968c6915941e33c942f17f651"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "APP_VERSION"
        value = "2.0.0"
      }

      env {
        name  = "ENVIRONMENT"
        value = "production"
      }

      env {
        name        = "CARTFLOW_DEMO_MESSAGE"
        secret_name = "cartflow-demo-message"
      }

      liveness_probe {
        transport               = "TCP"
        port                    = 5000
        failure_count_threshold = 3
        initial_delay           = 0
        interval_seconds        = 10
        timeout                 = 5
      }

      readiness_probe {
        transport               = "TCP"
        port                    = 5000
        failure_count_threshold = 48
        interval_seconds        = 5
        success_count_threshold = 1
        timeout                 = 5
      }

      startup_probe {
        transport               = "TCP"
        port                    = 5000
        failure_count_threshold = 240
        initial_delay           = 1
        interval_seconds        = 1
        timeout                 = 3
      }
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      secret
    ]
  }
}
