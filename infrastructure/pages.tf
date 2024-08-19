resource "cloudflare_pages_project" "ezgpg_website" {
  account_id        = local.cloudflare_account_id
  name              = "ezgpg-com"
  production_branch = "main"
  source {
    type = "github"
    config {
      owner                         = "alexnorell"
      repo_name                     = "ezgpg"
      production_branch             = "main"
      pr_comments_enabled           = true
      deployments_enabled           = true
    }
  }
  build_config {
    build_command       = "hugo --minify"
    destination_dir     = "build"
    root_dir            = "website"
  }
}
