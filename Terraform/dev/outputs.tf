output "postgres_server_name" {
  value = module.postgres.name
}

output "asms" {
  value = var.rg_context.asms
}

output "environment" {
  value = var.rg_context.environment
}

output "location" {
  value = var.rg_context.location
}

output "resource_group_name" {
  value = var.rg_context.new_resource_group
}
