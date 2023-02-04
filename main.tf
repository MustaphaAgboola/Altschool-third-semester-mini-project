provider "aws" {
    region = "us-east-1"
}

# This block will create VPC

resource "aws_vpc" "mp_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "mini_project_vpc"
    }
  
}

# This block will create internet gateway

resource "aws_internet_gateway" "mp_internet_gateway" {
  vpc_id = aws_vpc.mp_vpc.id

  tags = {
    Name = "main"
  }
}

# This block will create public route table

resource "aws_route_table" "mp_route_table" {
    vpc_id = aws_vpc.mp_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.mp_internet_gateway.id
    }
  
  tags = {
    Name = "miniproject_public_route_table"
  }
}

# Create a Public subnet 1

resource "aws_subnet" "mp_public_subnet1" {
    vpc_id = aws_vpc.mp_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
        Name = "mp_public_subnet1"
    }
  
}

# Create Public subnet 2
resource "aws_subnet" "mp_public_subnet2" {
    vpc_id = aws_vpc.mp_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1b"
    tags = {
        Name = "mp_public_subnet2"
    }
}

# Associate public  subnet 1 with public route table

resource "aws_route_table_association" "mp_public_subnet1_association" {
    subnet_id = aws_subnet.mp_public_subnet1.id
    route_table_id = aws_route_table.mp_route_table.id
}

# Associate public subnet 2 with public route table

resource "aws_route_table_association" "mp_public_subnet2_association" {
    subnet_id = aws_subnet.mp_public_subnet2.id
    route_table_id = aws_route_table.mp_route_table.id
}

# Create network acl

resource "aws_network_acl" "mp_network_acl" {
    vpc_id = aws_vpc.mp_vpc.id
    subnet_ids = [aws_subnet.mp_public_subnet1.id, aws_subnet.mp_public_subnet2.id]
  
  ingress {
    rule_no = 100
    protocol = "-1"
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  egress {
    rule_no = 100
    protocol = "-1"
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
}

# Create a security group for load balancer

resource "aws_security_group" "mp_load_balancer_sg" {
    name = "mp_load_balancer_sg"
    description = "Security group for the load balancer"
    vpc_id = aws_vpc.mp_vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

# Create security group to allow port 22, 80 and 43

resource "aws_security_group" "mp_sgp" {
    name = "allow_ssh_http_https"
    description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
    vpc_id = aws_vpc.mp_vpc.id

    ingress {
        description = "HTTPS"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
        security_groups = [aws_security_group.mp_load_balancer_sg.id]
    }

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
        security_groups = [aws_security_group.mp_load_balancer_sg.id]
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  tags = {
    Name = "mp_security_group_rule"
  }
}

# Create EC2 instances

resource "aws_instance" "mini_project1" {
  ami = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  key_name = "accesskey"
  security_groups = [aws_security_group.mp_sgp.id]
  subnet_id = aws_subnet.mp_public_subnet1.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "mini_project1"
    source = "terraform"
  }
}

resource "aws_instance" "mini_project2" {
  ami = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  key_name = "accesskey"
  security_groups = [aws_security_group.mp_sgp.id]
  subnet_id = aws_subnet.mp_public_subnet2.id
  availability_zone = "us-east-1b"

  tags = {
    Name = "mini_project2"
    source = "terraform"
  }
}

resource "aws_instance" "mini_project3" {
  ami = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  key_name = "accesskey"
  security_groups = [aws_security_group.mp_sgp.id]
  subnet_id = aws_subnet.mp_public_subnet1.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "mini_project3"
    source = "terraform"
  }
}

# Create a file to store the IP addresses of the instances

resource "local_file" "Ip_address" {
    filename = "/home/mustapha/Desktop/mini_project/host-inventory"
    content = <<EOT
    ${aws_instance.mini_project1.public_ip}
    ${aws_instance.mini_project2.public_ip}
    ${aws_instance.mini_project3.public_ip}
    EOT    
}

# Create an Application Load balancer

resource "aws_lb" "mini_project_load_balancer" {
    name = "mini-project-load-balancer"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.mp_load_balancer_sg.id]
    subnets = [aws_subnet.mp_public_subnet1.id, aws_subnet.mp_public_subnet2.id]
    #enable cross zone load balancing
    enable_deletion_protection = false  
    depends_on = [
      aws_instance.mini_project1, aws_instance.mini_project2, aws_instance.mini_project3
    ]
}

# Create the target group

resource "aws_lb_target_group" "mp_taget_group" {
  name = "mini-project-target-group"
  target_type = "instance"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.mp_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

# Create the listener

resource "aws_lb_listener" "mp_listener" {
  load_balancer_arn = aws_lb.mini_project_load_balancer.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.mp_taget_group.arn
  }
}

# Create the listener rule 

resource "aws_lb_listener_rule" "mp_listener_rule" {
  listener_arn = aws_lb_listener.mp_listener.arn
  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.mp_taget_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# Attach the target group to the load balancer

resource "aws_lb_target_group_attachment" "mini_project_target_group_attachment1" {
  target_group_arn = aws_lb_target_group.mp_taget_group.arn
  target_id = aws_instance.mini_project1.id
  port = "80"
}

resource "aws_lb_target_group_attachment" "mini_project_target_group_attachment2" {
  target_group_arn = aws_lb_target_group.mp_taget_group.arn
  target_id = aws_instance.mini_project2.id
  port = "80"
}

resource "aws_lb_target_group_attachment" "mini_project_target_group_attachment3" {
  target_group_arn = aws_lb_target_group.mp_taget_group.arn
  target_id = aws_instance.mini_project3.id
  port = "80"
}


