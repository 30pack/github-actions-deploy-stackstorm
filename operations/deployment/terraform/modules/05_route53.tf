data "aws_route53_zone" "selected" {
  count        = var.domain_name != "" ? 1 : 0
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "dev" {
  count   = local.fqdn_provided ? (var.root_domain == "true" ? 0 : 1) : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "${var.sub_domain_name}.${var.domain_name}"
  type    = "A"

  # NOTE: using the array syntax (aws_elb.vm_ssl[0]) because the aws_elb is optional via the count property
  #       which causes the properties to exist as a list
  alias {
    name                   = aws_elb.vm_lb.dns_name
    zone_id                = aws_elb.vm_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root-a" {
  count   = local.fqdn_provided ? (var.root_domain == "true" ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_elb.vm_lb.dns_name
    zone_id                = aws_elb.vm_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www-a" {
  count   = local.fqdn_provided ? (var.root_domain == "true" ? 1 : 0) : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_elb.vm_lb.dns_name
    zone_id                = aws_elb.vm_lb.zone_id
    evaluate_target_health = true
  }
}

output "application_public_dns" {
  description = "Public DNS address for the application or load balancer public DNS"
  value       = local.url
}

locals {
  fqdn_provided = (
    (var.domain_name != "") ?
    (var.sub_domain_name != "" ?
      true :
      var.root_domain == "true" ? true : false
    ) :
    false
  )
}

locals {
  protocol    = local.cert_available ? "https://" : "http://"
  public_port = var.lb_port != "" ? ":${var.lb_port}" : ""
  url = (local.fqdn_provided ?
    (var.root_domain == "true" ?
      "${local.protocol}${var.domain_name}${local.public_port}" :
      "${local.protocol}${var.sub_domain_name}.${var.domain_name}${local.public_port}"
    ) :
  "http://${aws_elb.vm_lb.dns_name}${local.public_port}")
}

output "vm_url" {
  value = local.url
}