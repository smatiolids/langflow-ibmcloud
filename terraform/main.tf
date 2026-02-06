# Resource group (created by Terraform)
resource "ibm_resource_group" "group" {
  name = var.resource_group_name
}

# Code Engine Project
resource "ibm_code_engine_project" "langflow_project" {
  name              = var.project_name
  resource_group_id = ibm_resource_group.group.id
}

# COS bucket name suffix (used when cos_bucket_name is not set)
resource "random_id" "cos_bucket_suffix" {
  byte_length = 4
}

# Cloud Object Storage instance for shared app data
resource "ibm_resource_instance" "cos" {
  name              = var.cos_instance_name
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.cos_location
  resource_group_id = ibm_resource_group.group.id
  tags              = var.tags
}

# COS bucket that backs the Code Engine persistent data store
resource "ibm_cos_bucket" "langflow_bucket" {
  bucket_name          = local.cos_bucket_name
  resource_instance_id = ibm_resource_instance.cos.id
  storage_class        = var.cos_storage_class
  region_location      = local.cos_bucket_region
}

# HMAC credentials for Code Engine to access the COS bucket
resource "ibm_resource_key" "cos_hmac" {
  name                 = "${var.project_name}-cos-hmac"
  role                 = "Writer"
  resource_instance_id = ibm_resource_instance.cos.id
  parameters = {
    HMAC = true
  }
}

# Wait for Code Engine project to be fully ready
resource "time_sleep" "wait_for_project" {
  depends_on = [ibm_code_engine_project.langflow_project]

  create_duration = "5m"
}

# PostgreSQL Database Instance
resource "ibm_database" "postgresql" {
  name              = var.database_name
  plan              = var.database_plan
  location          = var.region
  service           = "databases-for-postgresql"
  resource_group_id = ibm_resource_group.group.id
  service_endpoints = var.database_service_endpoints
  adminpassword     = var.database_password

  # Minimal configuration for cost optimization
  group {
    group_id = "member"
    memory {
      allocation_mb = var.database_memory_mb
    }
    disk {
      allocation_mb = var.database_disk_mb
    }
  }

  # Backup configuration (minimal retention)
  backup_id = null

  tags = var.tags

  # Wait for the database to be fully provisioned
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

# Wait for database to be ready
resource "time_sleep" "wait_for_database" {
  depends_on = [ibm_database.postgresql]

  create_duration = "5m"
}

# Data source to get database connection details
data "ibm_database_connection" "postgresql_connection" {
  deployment_id = ibm_database.postgresql.id
  user_id       = ibm_database.postgresql.adminuser
  user_type     = "database"
  endpoint_type = var.database_connection_endpoint_type

  depends_on = [time_sleep.wait_for_database]
}

# Build database URL using database_user/database_password, with override support.
locals {
  postgres_url_raw = data.ibm_database_connection.postgresql_connection.postgres[0].composed[0]
  postgres_password_effective = var.database_password != "" ? var.database_password : try(
    data.ibm_database_connection.postgresql_connection.postgres[0].authentication[0].password,
    ""
  )
  postgres_url_with_password = replace(
    replace(local.postgres_url_raw, "$PASSWORD", local.postgres_password_effective),
    "$${PASSWORD}",
    local.postgres_password_effective
  )
  # Rebuild credentials section using user/password variables to avoid provider placeholders.
  postgres_url_parts         = split("://", local.postgres_url_with_password)
  postgres_url_scheme        = local.postgres_url_parts[0] == "postgres" ? "postgresql" : local.postgres_url_parts[0]
  postgres_url_tail_parts    = split("@", local.postgres_url_parts[1])
  postgres_url_host_and_path = join("@", slice(local.postgres_url_tail_parts, 1, length(local.postgres_url_tail_parts)))
  postgres_url_with_user = format(
    "%s://%s:%s@%s",
    local.postgres_url_scheme,
    urlencode(var.database_user),
    urlencode(local.postgres_password_effective),
    local.postgres_url_host_and_path
  )
  postgres_url_with_sslmode = replace(
    local.postgres_url_with_user,
    "sslmode=verify-full",
    "sslmode=${var.database_sslmode}"
  )
  postgres_url_final = var.database_url_override != "" ? var.database_url_override : local.postgres_url_with_sslmode
}

locals {
  cos_bucket_name   = var.cos_bucket_name != "" ? var.cos_bucket_name : "${var.cos_bucket_prefix}-${random_id.cos_bucket_suffix.hex}"
  cos_bucket_region = var.cos_bucket_region != "" ? var.cos_bucket_region : var.region
  cos_hmac_keys = try(
    jsondecode(ibm_resource_key.cos_hmac.credentials["cos_hmac_keys"]),
    {}
  )
  cos_hmac_access_key_id = try(
    ibm_resource_key.cos_hmac.credentials["cos_hmac_keys.access_key_id"],
    local.cos_hmac_keys.access_key_id,
    ""
  )
  cos_hmac_secret_access_key = try(
    ibm_resource_key.cos_hmac.credentials["cos_hmac_keys.secret_access_key"],
    local.cos_hmac_keys.secret_access_key,
    ""
  )
  cos_hmac_secret_name        = "${var.project_name}-cos-hmac-secret"
}

# Code Engine Secret for Database Connection
resource "ibm_code_engine_secret" "database_secret" {
  project_id = ibm_code_engine_project.langflow_project.project_id
  name       = "langflow-db-secret"
  format     = "generic"

  data = {
    LANGFLOW_DATABASE_URL       = local.postgres_url_final
    LANGFLOW_SECRET_KEY         = var.langflow_secret_key
    LANGFLOW_SUPERUSER          = var.langflow_superuser
    LANGFLOW_SUPERUSER_PASSWORD = var.langflow_superuser_password
    ASTRA_DB_APPLICATION_TOKEN  = var.astra_db_application_token
  }

  depends_on = [data.ibm_database_connection.postgresql_connection]
}

# Backend Application
resource "ibm_code_engine_app" "backend" {
  project_id = ibm_code_engine_project.langflow_project.project_id
  name       = "langflow-backend"

  image_reference = var.backend_image
  image_port      = var.backend_port

  # Minimal scaling configuration
  scale_min_instances = var.backend_min_scale
  scale_max_instances = var.backend_max_scale

  # Resource allocation
  scale_cpu_limit    = var.backend_cpu
  scale_memory_limit = var.backend_memory

  # Environment variables from secret
  run_env_variables {
    type  = "literal"
    name  = "LANGFLOW_CONFIG_DIR"
    value = var.cos_mount_path
  }

  run_env_variables {
    type      = "secret_full_reference"
    name      = "LANGFLOW_DATABASE_URL"
    reference = ibm_code_engine_secret.database_secret.name
  }

  run_env_variables {
    type      = "secret_full_reference"
    name      = "LANGFLOW_SECRET_KEY"
    reference = ibm_code_engine_secret.database_secret.name
  }

  run_env_variables {
    type      = "secret_full_reference"
    name      = "LANGFLOW_SUPERUSER"
    reference = ibm_code_engine_secret.database_secret.name
  }

  run_env_variables {
    type      = "secret_full_reference"
    name      = "LANGFLOW_SUPERUSER_PASSWORD"
    reference = ibm_code_engine_secret.database_secret.name
  }

  run_env_variables {
    type  = "literal"
    name  = "LANGFLOW_AUTO_LOGIN"
    value = "false"
  }

  run_env_variables {
    type  = "literal"
    name  = "LANGFLOW_PORT"
    value = tostring(var.backend_port)
  }

  # Code Engine app provisioning can exceed default 10m
  timeouts {
    create = "30m"
    update = "30m"
  }

  depends_on = [
    time_sleep.wait_for_project,
    ibm_code_engine_secret.database_secret
  ]
}

# Create Code Engine persistent data store and mount it into the app
resource "null_resource" "backend_persistent_data_store" {
  triggers = {
    project_name   = var.project_name
    bucket_name    = local.cos_bucket_name
    pds_name       = var.cos_pds_name
    mount_path     = var.cos_mount_path
    hmac_secret    = local.cos_hmac_secret_name
    backend_app_id = ibm_code_engine_app.backend.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      ibmcloud ce project select --name ${var.project_name}

      if [ -z "${local.cos_hmac_access_key_id}" ] || [ -z "${local.cos_hmac_secret_access_key}" ]; then
        echo "Missing COS HMAC credentials. Ensure the COS service key includes HMAC keys." >&2
        exit 1
      fi

      if ! ibmcloud ce secret get --name ${local.cos_hmac_secret_name} >/dev/null 2>&1; then
        ibmcloud ce secret create --name ${local.cos_hmac_secret_name} --format hmac \
          --access-key-id "${local.cos_hmac_access_key_id}" \
          --secret-access-key "${local.cos_hmac_secret_access_key}"
      fi

      if ! ibmcloud ce persistentdatastore get --name ${var.cos_pds_name} >/dev/null 2>&1; then
        ibmcloud ce persistentdatastore create --name ${var.cos_pds_name} \
          --cos-bucket-name ${local.cos_bucket_name} \
          --cos-access-secret ${local.cos_hmac_secret_name}
      fi

      ibmcloud ce application update --name ${ibm_code_engine_app.backend.name} \
        --mount-data-store ${var.cos_mount_path}=${var.cos_pds_name}
    EOT
  }

  depends_on = [
    ibm_code_engine_app.backend,
    ibm_resource_key.cos_hmac,
    ibm_cos_bucket.langflow_bucket
  ]
}

# Configure backend liveness/readiness probes via IBM Cloud CLI.
# Terraform provider v1.87.3 does not expose probe settings on ibm_code_engine_app.
resource "null_resource" "backend_health_check" {
  triggers = {
    app_name     = ibm_code_engine_app.backend.name
    project_name = var.project_name
    path         = var.backend_health_check_path
    port         = tostring(var.backend_port)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ibmcloud ce project select --name ${var.project_name}
      ibmcloud ce application update --name ${ibm_code_engine_app.backend.name} \
        --no-wait \
        --probe-live type=http \
        --probe-live path=${var.backend_health_check_path} \
        --probe-live port=${var.backend_port} \
        --probe-live timeout=10 \
        --probe-live interval=60 \
        --probe-live initial-delay=10 \
        --probe-live failure-threshold=10 \
        --probe-ready type=http \
        --probe-ready path=${var.backend_health_check_path} \
        --probe-ready port=${var.backend_port} \
        --probe-ready timeout=10 \
        --probe-ready interval=60 \
        --probe-ready initial-delay=10 \
        --probe-ready failure-threshold=10
    EOT
  }

  depends_on = [ibm_code_engine_app.backend]
}

# Time sleep resource to allow for proper initialization
resource "time_sleep" "wait_for_apps" {
  depends_on = [
    ibm_code_engine_app.backend,
    null_resource.backend_health_check
  ]

  create_duration = "30s"
}
