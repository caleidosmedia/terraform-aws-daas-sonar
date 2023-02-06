resource "aws_efs_file_system" "fs" {
  tags = {
    Name = "${var.name}-fs"
  }
}

resource "aws_efs_access_point" "sonarqube_data" {
  file_system_id = aws_efs_file_system.fs.id
  root_directory {
    path = "/opt/sonarqube/data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 777
    }
  }
}

resource "aws_efs_access_point" "sonarqube_extensions" {
  file_system_id = aws_efs_file_system.fs.id
  root_directory {
    path = "/opt/sonarqube/extensions"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 777
    }
  }
}

resource "aws_efs_access_point" "sonarqube_logs" {
  file_system_id = aws_efs_file_system.fs.id
  root_directory {
    path = "/opt/sonarqube/logs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 777
    }
  }
}

resource "aws_efs_file_system_policy" "policy" {
  file_system_id = aws_efs_file_system.fs.id

  bypass_policy_lockout_safety_check = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ExamplePolicy01",
    "Statement": [
        {
            "Sid": "ExampleStatement01",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": [
                "${aws_efs_file_system.fs.arn}"
            ],
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:ClientRootAccess"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
POLICY
}


resource "aws_efs_mount_target" "fs" {
  for_each = { for s in var.subnets : s => s }

  file_system_id  = aws_efs_file_system.fs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}