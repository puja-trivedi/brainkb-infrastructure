output "instance_id" {
  description = "Production EC2 instance ID."
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "Production EC2 public IP."
  value       = aws_instance.app.public_ip
}

output "instance_private_ip" {
  description = "Production EC2 private IP."
  value       = aws_instance.app.private_ip
}

output "security_group_id" {
  description = "ID of the production instance's security group (launch-wizard-25)."
  value       = aws_security_group.app.id
}
