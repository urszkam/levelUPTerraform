output "subnet_self_link" {
  description = ""
  value       = module.network.subnet_self_link
}

output "router_name" {
  description = "T"
  value       = module.network.router_name
}

output "nat_name" {
  description = ""
  value       = module.network.nat_name
}

output "vpc_name" {
  description = ""
  value       = module.network.vpc_name
}
