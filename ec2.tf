resource "aws_launch_template" "ecs_lt" {
    name_prefix = "ecs_template"
    image_id = "ami-0c45946ade6066f3d" # ECS Optimized AMI
    instance_type = "t2.micro"

    key_name = "ecs-key-pir"

    vpc_security_group_ids = [aws_security_group.cluster_sg.id]
    iam_instance_profile {
        name = "ecsInstanceRole"
    }

    block_device_mappings {
      device_name = "/dev/xvda"
      ebs {
        volume_size = 30
        volume_type = "gp2"
        delete_on_termination = true
      }
    }
    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "ecs_instance"
      }
    }
    user_data = filebase64("${path.module}/ecs.sh")
}

resource "aws_autoscaling_group" "esc_asg" {
    name = "ecs_asg"
    vpc_zone_identifier = [aws_subnet.subnet_public_1.id, aws_subnet.subnet_public_2.id]
    max_size = 5
    min_size = 1
    desired_capacity = 1

    launch_template {
        id = aws_launch_template.ecs_lt.id
        version = "$Latest" 
    }

    depends_on = [aws_internet_gateway.procat-igw]
    tag {
        key = "AmazonECSManaged"
        value = "true"
        propagate_at_launch = true
    }
}

resource "aws_lb" "ecs_alb" {
    name                = "ecs-alb"
    internal            = "false"
    load_balancer_type  = "application"
    security_groups     = [aws_security_group.cluster_sg.id]
    subnets             = [aws_subnet.subnet_public_1.id, aws_subnet.subnet_public_2.id]

    tags = {
        Name = "ecs-alb"
    }
}

resource "aws_lb_target_group" "ecs_tg" {
    name    = "ecs-target-group"
    port    = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = aws_vpc.procat-vpc.id
    
    health_check {
        path = "/"
    }
}

resource "aws_lb_listener" "esc_alb_listner" {
    load_balancer_arn = aws_lb.ecs_alb.arn
    port = "80"
    protocol = "HTTP"
    
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.ecs_tg.arn
    } 
}
