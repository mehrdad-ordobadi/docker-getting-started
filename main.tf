resource "aws_ecs_cluster" "ecs_cluster" {
    name = "my_ecs_cluster"
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "mehrdad-ecs-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.esc_asg.arn
    managed_scaling {
        maximum_scaling_step_size = 3
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base                = 1
    weight              = 100
    capacity_provider   = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}


resource "aws_cloudwatch_log_group" "ecs_agent_log_group" {
  name = "/ecs/agent-logs"
}
# resource "aws_cloudwatch_log_group" "ecs_log_group" {
#   name = "/ecs/my_ecs_service"
# }

resource "aws_ecs_task_definition" "aws_ecs_task_definition" {
    family              = "my_ecs_task"
    network_mode        = "bridge"
    execution_role_arn  = "arn:aws:iam::746706907394:role/ecsTaskExecutionRole" # has ecsTaskExecutionRole policy
    cpu                 = 256
    memory              = 512
    container_definitions = jsonencode([
        {
        name            = "x86-1"
        image           = "public.ecr.aws/m5w3n3i6/gettingstarted:x86-1" # verified the link is correct!
        cpu             = 256
        memory          = 512
        essential       = true
        portMappings    = [
            {
            containerPort   = 80
            hostPort        = 80
            protocol        = "tcp"
            }
        ]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
                awslogs-group =  aws_cloudwatch_log_group.ecs_agent_log_group.name
                awslogs-region = "us-east-1"
                awslogs-stream-prefix = "ecs"
            }
        }  
        }
    ])
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecs_policy" {
  name = "ecs_policy"
  role = aws_iam_role.ecs_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_service" "esc_service" {
    name            = "my_ecs_service"
    cluster         = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.aws_ecs_task_definition.arn
    desired_count   = 2

    # network_configuration {
    #   subnets           = [aws_subnet.subnet_public_1.id, aws_subnet.subnet_public_2.id]
    #   security_groups   = [aws_security_group.cluster_sg.id]
    # }

    force_new_deployment = true
    placement_constraints {
      type = "distinctInstance"
    }

    triggers = {
        redeployment = timestamp()
    }

    capacity_provider_strategy {
      capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
      weight            = 100
    }

    load_balancer {
      target_group_arn = aws_lb_target_group.ecs_tg.arn
      container_name = "x86-1"
      container_port = 80
    }

    depends_on = [ aws_autoscaling_group.esc_asg, aws_iam_role_policy.ecs_policy, aws_internet_gateway.procat-igw ]
}

