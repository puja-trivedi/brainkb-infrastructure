module "brainkb" {
  source = "../../modules/brainkb"

  environment       = "sandbox"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids
  instance_type     = var.instance_type
  ssh_key_name      = var.ssh_key_name
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  hosted_zone_id    = var.hosted_zone_id

  # Same ports as production. The +10000 shift (13000, 18004, ...) was
  # only needed while sandbox shared prod's EC2; on its own instance
  # there's nothing to collide with.
  ui_port      = 3000
  backend_port = 8000

  alb_targets         = var.alb_targets
  dns_allow_overwrite = var.dns_allow_overwrite

  create_app_dns_records = var.create_app_dns_records

  enable_fsx = var.enable_fsx
}
