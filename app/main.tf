terraform {
    backend "s3" {
        bucket = "terraform-tutorial-directive-tf-state"
        key = "tf-infra/terraform.tfstate"
        region = "us-east-2"
        dynamodb_table = "terraform-tutorial-state-locking"
        encrypt = true
    }

  required_providers {
  aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
        }
    }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "instance_1" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  user_data = <<-EOF
              #!/bin/bash
              echo "The mocked app was successfully deployed via terraform" > index.html
              python3 -m http.server 8080 &
              EOF
}


resource "aws_s3_bucket" "bucket" {
    bucket = "terraform-tutorial-mocked-web-app-data"
    force_destroy = true
    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}


resource "aws_s3_bucket_versioning" "bucket_versioning" {
    bucket = aws_s3_bucket.bucket.id
    versioning_configuration {
      status = "Suspended"
    }
  }

data "aws_vpc" "default_vpc" {
    default = true
}

data "aws_subnet_ids" "default_subnets" {
    vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_security_group" "instances" {
  name = "terraform-tutorial-instance-security-group"
  }

resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.instances.id

    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.load_balancer.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = "404"
        }
    }
}

resource "aws_lb_target_group" "instances" {
    name = "example-target-group"
    port = 8080
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default_vpc.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        timeout = 5
        interval = 15
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_target_group_attachment" "instance_1" {
    target_group_arn = aws_lb_target_group.instances.arn
    target_id = aws_instance.instance_1.id
    port = 8080
}

resource "aws_lb_listener_rule" "instances" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
        values = ["*"]
        }
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.instances.arn
        }
    }

resource "aws_security_group" "alb" {
    name = "terraform-tutorial-alb-security-group"
}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id

    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balancer" {
    name = "web-app-lb"
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb.id]
    subnets = data.aws_subnet_ids.default_subnets.ids
}


resource "aws_route53_zone" "primary" {
    name = "terraformtutorialwebapp.com"
}

resource "aws_route53_record" "root" {
    zone_id = aws_route53_zone.primary.zone_id
    name = "terraformtutorialwebapp.com"
    type = "A"
    alias {
        name = aws_lb.load_balancer.dns_name
        zone_id = aws_lb.load_balancer.zone_id
        evaluate_target_health = true
    }
}

resource "aws_db_instance" "db_instance" {
allocated_storage = 20
storage_type = "standard"
engine = "postgres"
engine_version = "16.1"
instance_class = "db.t3.micro"
name = "terraformtutorialappdb"
username = "foo"
password = "foobarbaz"
skip_final_snapshot = true
}