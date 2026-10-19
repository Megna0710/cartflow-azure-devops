
data "azurerm_resource_group" "cartflow" {
  name = var.resource_group_name
}

output "resource_group_name" {
  value = data.azurerm_resource_group.cartflow.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.cartflow.location
}