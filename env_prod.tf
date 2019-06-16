
resource "random_string" "cookie_secret_key_production" {
    length = "64"
}
resource "random_string" "session_secret_key_production" {
    length = "64"
}
resource "heroku_app" "production" {
  name   = "${var.app_name}-prod"
  region = "us"
  stack  = "container"
  config_vars = {
    NODE_ENV = "production"
    COOKIE_SECRET_KEY = "${random_string.cookie_secret_key_production.result}"
    SESSION_SECRET_KEY = "${random_string.session_secret_key_production.result}"
  }
  organization = {
    name = "${var.heroku_team}"
    locked = "false"
    personal = "false"
  }
}

resource "heroku_addon" "database_production" {
  app  = "${heroku_app.production.name}"
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_addon" "sendgrid_production" {
  app  = "${heroku_app.production.name}"
  plan = "sendgrid:starter"
}

resource "heroku_domain" "cb_domain" {
  app      = "${heroku_app.production.name}"
  hostname = "${var.app_name}.botics.co"
}

resource "cloudflare_record" "cb_domain_record" {
  domain = "botics.co"
  name   = "${var.app_name}"
  value  = "${heroku_domain.cb_domain.cname}"
  type   = "CNAME"
  // ttl of 1 is automatic
  ttl    = 1
}

resource "heroku_pipeline" "pipeline" {
  name = "${var.app_name}"
}

resource "heroku_pipeline_coupling" "production" {
  app      = "${heroku_app.production.name}"
  pipeline = "${heroku_pipeline.pipeline.id}"
  stage    = "production"
}

resource "heroku_build" "production" {
  app = "${heroku_app.production.id}"

  source = {
    url = "${var.repo_url}/archive/master.tar.gz"
  }
}

resource "heroku_formation" "formation_prod" {
  app = "${heroku_app.production.name}"
  type = "web"
  quantity = 1
  size = "${var.dyno_size}"

  depends_on = ["heroku_build.production"]
}

output "app_id" {
  value = "${heroku_app.production.uuid}"
}
output "app_name" {
  value = "${heroku_app.production.name}"
}
output "web_url" {
  value = "${heroku_app.production.web_url}"
}

