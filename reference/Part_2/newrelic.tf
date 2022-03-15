# This is what your newrelic.tf should look like after completeing the exercise.

variable "NEW_RELIC_ACCOUNT_ID" { type = string }

resource "newrelic_alert_policy" "policy" {
  name = "jbuchanan terraform alert policy"
  incident_preference = "PER_POLICY"
}

resource "newrelic_nrql_alert_condition" "demo" {
  account_id                     = var.NEW_RELIC_ACCOUNT_ID
  policy_id                      = newrelic_alert_policy.policy.id
  type                           = "static"
  name                           = "Demo alert condition"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  value_function                 = "single_value"
  fill_option                    = "static"
  fill_value                     = 1.0
  aggregation_window             = 60
  aggregation_method             = "event_timer"
  aggregation_timer              = 60
  slide_by                       = 0

  nrql {
    query = "select count(*) from tfdemo"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 120
    threshold_occurrences = "at_least_once"
  }
}

resource "newrelic_alert_channel" "sko_slack" {
  name = "jbuchanan SKO Slack Channel"
  type = "slack"

  config {
    url     = "https://hooks.slack.com/services/XXX/PROVIDED-DURING-SESSION"
    channel = "sko-oac"
  }
}

resource "newrelic_alert_policy_channel" "subscribe" {
  policy_id  = newrelic_alert_policy.policy.id
  channel_ids = [newrelic_alert_channel.sko_slack.id]
}

locals {  
  pingURLs = [
    { 
      name = "New Relic"
      uri = "https://newrelic.com"
    },
    { 
      name = "NR Developer Site"
      uri = "https://developer.newrelic.com"
    },
    { 
      name = "NR Learn Site"
      uri = "https://learn.newrelic.com"
    }
  ]
}

resource "newrelic_synthetics_monitor" "ping" {
  count = length(local.pingURLs)
  name = "SKO Ping ${local.pingURLs[count.index].name}"
  type = "SIMPLE"
  frequency = 5
  status = "ENABLED"
  locations = ["AWS_US_EAST_1"]
  uri = local.pingURLs[count.index].uri        
  verify_ssl = true
}

# This is what the single ping resource looked like
# resource "newrelic_synthetics_monitor" "ping" {
#   name = "SKO Ping New Relic"
#   type = "SIMPLE"
#   frequency = 5
#   status = "ENABLED"
#   locations = ["AWS_US_EAST_1"]
#   uri = "https://newrelic.com"
#   verify_ssl = true
# }