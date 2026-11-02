# Production, adopted as-is.
#
# Every resource here already exists in AWS (built by hand; inventory
# in discovery.md) and is brought under tofu via the import blocks in
# imports.tf. The config describes production exactly as it runs
# today — including the parts decisions.md wants to change (SSH and
# app ports open to 0.0.0.0/0, no IAM role). Changes come later, one
# reviewed PR at a time; adoption itself must be a no-op.
#
# This environment deliberately does not use modules/brainkb yet:
# that module creates a fresh SG, IAM role and single host-routed ALB,
# which is the target shape, not what production is today.

resource "aws_instance" "app" {
  ami                    = "ami-0f5fcdfbd140e4ab7"
  instance_type          = "c5.4xlarge"
  subnet_id              = "subnet-04b630da6d9b3674c" # us-east-2a
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = "rabbit-mq-server"

  metadata_options {
    http_tokens = "required" # IMDSv2 required
  }

  # root_block_device is intentionally omitted: the root volume's size
  # isn't in discovery.md, and leaving the block out means tofu doesn't
  # try to manage it.

  tags = {
    Name = "BrainKB"
  }

  lifecycle {
    # Replacing this instance would destroy production. Any plan that
    # wants to must fail, not be applied.
    prevent_destroy = true

    # The AMI it was launched from is history, not desired state —
    # a changed AMI ID would otherwise force a replacement.
    ignore_changes = [ami, user_data, user_data_base64]
  }
}

# launch-wizard-25, the only SG on the production instance. Rules are
# inline so a single import (by SG ID) adopts the group and every rule.
# Rules and descriptions match AWS as reported by the first
# `tofu plan` (2026-11-02), including the typos — changing a
# description revokes and re-adds that rule.
resource "aws_security_group" "app" {
  name   = "launch-wizard-25"
  vpc_id = "vpc-056bce0f8a2a73bfe"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "UI"
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "pgAdmin"
    protocol    = "tcp"
    from_port   = 5051
    to_port     = 5051
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Oxigraph"
    protocol    = "tcp"
    from_port   = 7878
    to_port     = 7878
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "api token manager"
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "oauth callback user management"
    protocol    = "tcp"
    from_port   = 8004
    to_port     = 8004
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ml structsense"
    protocol    = "tcp"
    from_port   = 8007
    to_port     = 8007
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "query service"
    protocol    = "tcp"
    from_port   = 8010
    to_port     = 8010
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "mcp"
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Lustre client protocol from the FSx SG.
  ingress {
    description     = "lusture"
    protocol        = "tcp"
    from_port       = 988
    to_port         = 988
    security_groups = ["sg-09898d5bd183b7f15"]
  }

  ingress {
    description     = "lusture"
    protocol        = "tcp"
    from_port       = 1018
    to_port         = 1023
    security_groups = ["sg-09898d5bd183b7f15"]
  }

  # Co-tenant sandbox ports. These go away in the PR #5 cutover, once
  # sandbox runs on its own instance — delete them here in the same
  # change.
  ingress {
    description     = "sandbox UI"
    protocol        = "tcp"
    from_port       = 13000
    to_port         = 13000
    security_groups = ["sg-02e6912482926898b"]
  }

  ingress {
    description     = "sandbox oauth callback user management"
    protocol        = "tcp"
    from_port       = 18004
    to_port         = 18004
    security_groups = ["sg-02e6912482926898b"]
  }

  ingress {
    description     = "sandbox ml structsense"
    protocol        = "tcp"
    from_port       = 18007
    to_port         = 18007
    security_groups = ["sg-02e6912482926898b"]
  }

  ingress {
    description     = "sandbox sb"
    protocol        = "tcp"
    from_port       = 18080
    to_port         = 18080
    security_groups = ["sg-02e6912482926898b"]
  }

  # Unlike the other sandbox ports, this one is open to the internet,
  # not just the sandbox SG.
  ingress {
    description = "sandbox query_service"
    protocol    = "tcp"
    from_port   = 18010
    to_port     = 18010
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # The "redundant explicit outbound to port 8004" from discovery.md.
  egress {
    protocol    = "tcp"
    from_port   = 8004
    to_port     = 8004
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BrainKB-SG"
  }

  lifecycle {
    prevent_destroy = true

    # Changing the group's own description forces a replacement, so
    # don't manage it. revoke_rules_on_delete is tofu-only (no AWS
    # setting); ignoring it keeps the import from showing as a change.
    ignore_changes = [description, revoke_rules_on_delete]
  }
}
