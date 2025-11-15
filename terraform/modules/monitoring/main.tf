resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Email alerts ${var.env}"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_alert_policy" "cpu_high" {
  project      = var.project_id
  display_name = "VM CPU high (${var.env})"
  combiner     = "OR"

  documentation {
    mime_type = "text/markdown"
    content   = "High VM (ID: ${var.instance_id}) CPU usage"
  }

  conditions {
    display_name = "CPU > 80% for 5 minutes"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8    # 80%
      duration        = "300s" # 5 minut

      filter = <<-EOT
        resource.type = "gce_instance"
        AND metric.type = "compute.googleapis.com/instance/cpu/utilization"
        AND resource.label.instance_id = "${var.instance_id}"
      EOT

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_NONE"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  user_labels = {
    env      = var.env
    severity = "warning"
  }
}

resource "google_monitoring_alert_policy" "disk_high" {
  project      = var.project_id
  display_name = "VM disk usage high (${var.env})"
  combiner     = "OR"

  documentation {
    mime_type = "text/markdown"
    content   = "VM (ID: ${var.instance_id}) disc with high usage (> 90%)."
  }

  conditions {
    display_name = "Disk used > 90% for 5 minutes"

    condition_threshold {
      comparison      = "COMPARISON_GT"
      threshold_value = 90 # percent_used
      duration        = "300s"

      filter = <<-EOT
        resource.type = "gce_instance"
        AND metric.type = "agent.googleapis.com/disk/percent_used"
        AND resource.label.instance_id = "${var.instance_id}"
        AND metric.label.state = "used"
      EOT

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  user_labels = {
    env      = var.env
    severity = "high"
  }
}
