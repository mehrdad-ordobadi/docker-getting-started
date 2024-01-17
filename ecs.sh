#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name}" >> /etc/ecs/ecs.config
echo "ECS_LOGFILE=/log/ecs-agent.log" >> /etc/ecs/ecs.config
echo "ECS_LOGLEVEL=info" >> /etc/ecs/ecs.config
echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"awslogs\"]" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config
