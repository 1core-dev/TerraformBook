provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "The port server will be used for HTTP requests"
  type        = number
  default     = 8080
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

# resource "aws_instance" "example" {
#   ami                    = "ami-0fb653ca2d3203ac1"
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   user_data                   = <<-EOF
#   #!/bin/bash
#   echo "Hello world" > index.html
#   nohup busybox httpd -f -p ${var.server_port} &
#   EOF
#   user_data_replace_on_change = true
#   tags = {
#     Name = "terraform-example"
#   }
# }

resource "aws_launch_configuration" "example" {
  image_id        = "ami-0fb653ca2d3203ac1"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
  #!/bin/bash
  echo "Hello world" > index.html
  nohup busybox httpd -f -p ${var.server_port} &
  EOF

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnet.default.ids

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
