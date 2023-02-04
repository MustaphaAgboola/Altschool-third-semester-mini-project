# Load balancer output

output "elb_target_group_arn" {
    value = aws_lb_target_group.mp_taget_group.arn
}

output "elb_load_balancer_dns_name" {
    value = aws_lb.mini_project_load_balancer
}

output "elastic_load_balancer_zone_id" {
    value = aws_lb.mini_project_load_balancer.zone_id
}

