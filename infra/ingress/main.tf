resource "aws_security_group" "ingress_alb" {
  name   = "alb-sg-smartlogix-${var.environment}"
  vpc_id = var.vpc_id

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

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lb" "ingress" {
  name               = "alb-smartlogix-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ingress_alb.id]
  subnets            = var.public_subnets

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Ingress ready, no active rollout target configured"
      status_code  = "503"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
