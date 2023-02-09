#declarando chaves para o acesso das instancias
resource "aws_key_pair" "key" {
  key_name   = "aws-key"
  public_key = file("./aws-key.pub")
}
#Declarando que a vpc default da conta será usada
data "aws_vpc" "default" {
  default = true
}
#Pagando a id da vpc para as subnets
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

#Criando o launch_configuration com a security group do Load Balance
resource "aws_launch_configuration" "launchconfig_tf" {
  image_id        = "ami-00874d747dde814fa" #ami do ubuntu 22.04
  instance_type   = "t2.micro"              #Instancia que está na Fre Tier da aws
  key_name        = aws_key_pair.key.key_name
  security_groups = [aws_security_group.security_group_lb_tf.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "<h1>Hello, World from $(hostname -f)</h1>" > index.html
    nohup busybox httpd -f -p 80 &
    EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Criando a security group do Load Balance
resource "aws_security_group" "security_group_lb_tf" {
  name = "security-group-lb-tf"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Criando o AutoScaling Group
resource "aws_autoscaling_group" "ec2_tf" {
  launch_configuration = aws_launch_configuration.launchconfig_tf.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns    = [aws_lb_target_group.target_group_tf.arn]
  min_size             = 3
  max_size             = 6
  tag {
    key                 = "Name"
    value               = "terraform.ubuntu"
    propagate_at_launch = true
  }
}

#Criando o Load Balance
resource "aws_lb" "loadbalance_tf" {
  name               = "loadbalance-tf"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.security_group_lb_tf.id]
}

#Criando o Listener do load balance
resource "aws_lb_listener" "http_tf" {
  load_balancer_arn = aws_lb.loadbalance_tf.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

#Criando o target group do load balance
resource "aws_lb_target_group" "target_group_tf" {
  name     = "target-group-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#Configurando as regras do Listener
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http_tf.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_tf.arn
  }
}
