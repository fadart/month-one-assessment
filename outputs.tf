output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "Load balancer DNS name — paste this in your browser to access the app"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host — use this to SSH in"
  value       = aws_eip.bastion.public_ip
}