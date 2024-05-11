resource "aws_instance" "instance_1" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = [aws_security_group.instances.name]
  user_data = <<-EOF
              #!/bin/bash
              echo "The mocked app was successfully deployed via terraform" > index.html
              python3 -m http.server 8080 &
              EOF
}