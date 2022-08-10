resource "random_password" "master" {
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "password" {
  name = "${var.name}-credentials-sm"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = <<EOF
{
  "username": "${aws_db_instance.sonar.name}",
  "password": "${random_password.master.result}",
  "engine": "mysql",
  "host": "${aws_db_instance.sonar.address}",
  "port": ${aws_db_instance.sonar.port}
}
EOF
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-db-sg"
  description = "RDS MySQL sg"
  vpc_id      = var.vpc_id
  # Keep the instance private by only allowing traffic from the web server.
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }
  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "sonar" {
  allocated_storage         = 20
  engine                    = "postgres"
  engine_version            = "13.7"
  instance_class            = "db.t3.micro"
  db_name                   = "sonar"
  username                  = "sonar"
  multi_az                  = true
  identifier                = "${var.name}-db"
  final_snapshot_identifier = "${var.name}-final-snapshot"
  vpc_security_group_ids    = ["${aws_security_group.rds.id}"]
  backup_retention_period   = 7
  password                  = random_password.master.result
  db_subnet_group_name      = var.db_subnet_group_name
}