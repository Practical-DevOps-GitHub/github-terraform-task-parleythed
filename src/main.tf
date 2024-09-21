terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token
}

# Set 'develop' as the default branch after the repository is created
resource "github_branch_default" "default" {
  repository = github_repository.repo.name
  branch     = "develop"
}

# Create the GitHub repository
resource "github_repository" "repo" {
  name        = var.repository_name
  description = "Terraform managed repository"
  visibility  = "private"
}

# Assign the user 'softservedata' as a collaborator
resource "github_repository_collaborator" "collaborator" {
  repository = github_repository.repo.name
  username   = "softservedata"
  permission = "admin"  # Can also be 'push' or 'pull'
}

# Protect the 'main' branch
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1  # Only the owner can approve
  }
}

# Protect the 'develop' branch
resource "github_branch_protection" "develop" {
  repository_id = github_repository.repo.node_id
  pattern       = "develop"

  required_pull_request_reviews {
    required_approving_review_count = 2  # Require 2 approvals for merging
  }
}

# Add pull request template
resource "github_repository_file" "pr_template" {
  repository      = github_repository.repo.name
  file            = ".github/pull_request_template.md"
  content         = file("templates/pull_request_template.md")  # Template file path
  branch          = "develop"
  commit_message  = "Add pull request template"
}

# Add CODEOWNERS file to 'main' branch
resource "github_repository_file" "codeowners" {
  repository      = github_repository.repo.name
  file            = "CODEOWNERS"
  content         = "@softservedata"  # Code owner for main branch
  branch          = "main"
  commit_message  = "Add code owner"
}

# Add the deploy key to the repository
resource "github_repository_deploy_key" "deploy_key" {
  repository = github_repository.repo.name
  title      = "Deploy Key"
  key        = var.deploy_key  # Deploy key variable
  read_only  = false  # Set to true if the key should be read-only
}

# Add the PAT to GitHub Secrets for GitHub Actions
resource "github_actions_secret" "pat_secret" {
  repository     = github_repository.repo.name
  secret_name    = "PAT"
  plaintext_value = var.github_pat  # GitHub Personal Access Token (PAT)
}
