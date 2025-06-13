### CodePipeline IAM Role & Policy ###
### CodePipeline-Assume Role ###
data "aws_iam_policy_document" "pipe_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    
    principals {
      type = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}
### CodePipeline-Role ###
resource "aws_iam_role" "pipe_role" {
  name = "pipe-role"
  assume_role_policy = data.aws_iam_policy_document.pipe_role.json
}
### CodePipeline-policy ###
resource "aws_iam_role_policy_attachment" "AWSCodePipeline_FullAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "AWSCodeBuildAdminAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}
resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "AmazonECS_FullAccess" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
/*
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRoleForECS" {
  role = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}
*/
resource "aws_iam_role_policy_attachment" "AWSCodeCommitReadOnlyAccess" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"
}
### CodePipeline ###
resource "aws_codepipeline" "codepipeline" {
  name     = "test-pipeline"
  role_arn = aws_iam_role.pipe_role.arn
 
  artifact_store {
    location = var.s3-bucket
    type = "S3"
  }

  stage {
    name = "Source"
 
    action {
      name = "Source"
      category = "Source"
      owner = "AWS" 
      provider = "CodeCommit"
      version = "1"
      output_artifacts = ["source_output"]
 
      configuration = {
        RepositoryName = "MyCommitRepository"
        BranchName = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "MyBuildProject"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = "my_cluster"
        ServiceName = "service"
        FileName = "imagedefinitions.json"
      }
    }
  }
}