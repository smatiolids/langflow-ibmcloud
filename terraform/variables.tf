variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region for deployment"
  type        = string
  default     = "us-south"
}

variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
  default     = "langflow-resources"
}

variable "project_name" {
  description = "Name for the Code Engine project"
  type        = string
  default     = "langflow-project"
}

variable "database_name" {
  description = "Name for the PostgreSQL database instance"
  type        = string
  default     = "langflow-postgres"
}

variable "langflow_secret_key" {
  description = "Secret key used by Langflow"
  type        = string
  sensitive   = true
  default     = ""
}

variable "langflow_superuser" {
  description = "Langflow superuser username"
  type        = string
  sensitive   = true
  default     = ""
}

variable "langflow_superuser_password" {
  description = "Langflow superuser password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "database_url_override" {
  description = "Optional: full PostgreSQL URL to use instead of provider-composed URL"
  type        = string
  default     = ""
}

variable "database_user" {
  description = "Optional: PostgreSQL user for composing LANGFLOW_DATABASE_URL"
  type        = string
  default     = "admin"
}

variable "database_password" {
  description = "Optional: PostgreSQL admin password to replace $PASSWORD in composed URL"
  type        = string
  sensitive   = true
  default     = ""
}

variable "database_sslmode" {
  description = "SSL mode for PostgreSQL connection URL (use require to avoid certificate verification)"
  type        = string
  default     = "require"
}

variable "database_service_endpoints" {
  description = "Database service endpoints exposure: private, public, or public-and-private"
  type        = string
  default     = "private"
}

variable "database_connection_endpoint_type" {
  description = "Database endpoint type used in connection details: private or public"
  type        = string
  default     = "private"
}

variable "database_plan" {
  description = "PostgreSQL service plan (standard for minimal cost)"
  type        = string
  default     = "standard"
}

variable "database_memory_mb" {
  description = "Memory allocation for PostgreSQL in MB (minimum 8192)"
  type        = number
  default     = 8192
}

variable "database_disk_mb" {
  description = "Disk allocation for PostgreSQL in MB (minimum 5120)"
  type        = number
  default     = 5120
}

variable "backend_image" {
  description = "Docker image for Langflow application"
  type        = string
  default     = "langflowai/langflow:1.7.3"
}

variable "backend_cpu" {
  description = "CPU allocation for backend (in vCPU)"
  type        = string
  default     = "0.5"
}

variable "backend_memory" {
  description = "Memory allocation for backend (in GB)"
  type        = string
  default     = "1G"
}

variable "backend_min_scale" {
  description = "Minimum number of backend instances (0 for scale-to-zero)"
  type        = number
  default     = 0
}

variable "backend_max_scale" {
  description = "Maximum number of backend instances"
  type        = number
  default     = 1
}

variable "backend_port" {
  description = "Port for backend application"
  type        = number
  default     = 7860
}

variable "backend_health_check_path" {
  description = "HTTP path used for backend liveness/readiness probes"
  type        = string
  default     = "/health_check"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["langflow", "terraform"]
}
