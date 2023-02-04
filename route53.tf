variable "domain_name" {
  default = "tapha.me"
  type = string
  description = "Domain name"
}

# Get hosted zone details 
resource "aws_route53_zone" "hosted_zone" {
    name = var.domain_name

    tags = {
      Environment = "dev"
    }
}

# Create a record set in route 53
# terraform aws route 53 record

resource "aws_route53_record" "hosted_zone" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name = "terraform-test.$(var.domain_name)"
  type = "A"

  alias {
    name = aws_lb.mini_project_load_balancer.dns_name
    zone_id = aws_lb.mini_project_load_balancer.zone_id
    evaluate_target_health = true
  }
}