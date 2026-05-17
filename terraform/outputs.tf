output "vpc_id" {
	value = aws_vpc.main.id
}
output "subnet_id" {
	value = aws_subnet.main.id
}
output "instance_id" {
	value = aws_instance.my_instance.id
}
output "instance_public_ip" {
  value = aws_instance.my_instance.public_ip
}
output "instance_public_dns" {
	value = aws_instance.my_instance.public_dns
}
output "security_group_id" {
	value = aws_security_group.main.id
}
output "key_name" {
  value = aws_key_pair.my_key.key_name
} 
