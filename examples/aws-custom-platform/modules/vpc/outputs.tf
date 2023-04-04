output "id" {
  value = aws_vpc.network.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}
