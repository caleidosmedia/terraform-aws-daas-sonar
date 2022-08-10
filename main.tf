data "aws_region" "current" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = "${var.name}-task-def"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name = "sonar-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.fs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube_data.id
      }

    }
  }

  volume {
    name = "sonar-extensions"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.fs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube_extensions.id
      }
    }
  }

  volume {
    name = "sonar-logs"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.fs.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sonarqube_logs.id
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "${var.name}"
      essential = true
      image     = "${var.container_image}"
      user      = "sonarqube:sonarqube"
      command = [
        "-Dsonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false"
      ]
      environment = [
        {
          name  = "SONAR_JDBC_USERNAME"
          value = "sonar"
        },
        {
          name  = "SONAR_JDBC_URL"
          value = "jdbc:postgresql://${aws_db_instance.sonar.endpoint}/${aws_db_instance.sonar.db_name}?useUnicode=true&characterEncoding=utf8"
        }
      ]
      secrets = [
        {
          name      = "SONAR_JDBC_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.password.arn}:password::"
        }
      ]
      Ulimits = [
        {
          HardLimit = 65535
          Name      = "nofile"
          SoftLimit = 65535
        }
      ]
      portMappings = [{
        protocol      = "tcp"
        containerPort = var.container_port
        hostPort      = var.container_port
      }]
      MountPoints = [
        {
          SourceVolume  = "sonar-data"
          ContainerPath = "/opt/sonarqube/data"
        },
        {
          SourceVolume  = "sonar-extensions"
          ContainerPath = "/opt/sonarqube/extensions"
        },
        {
          SourceVolume  = "sonar-logs"
          ContainerPath = "/opt/sonarqube/logs"
        }
      ]
      LogConfiguration = {
        LogDriver = "awslogs"
        Options = {
          "awslogs-create-group"  = "true",
          "awslogs-group"         = "${var.name}"
          "awslogs-region"        = "${data.aws_region.current.name}"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name                               = "${var.name}-service"
  cluster                            = aws_ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.service.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}