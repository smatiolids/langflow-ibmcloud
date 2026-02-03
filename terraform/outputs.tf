# Project Information
output "project_id" {
  description = "Code Engine project ID"
  value       = ibm_code_engine_project.langflow_project.project_id
}

output "project_name" {
  description = "Code Engine project name"
  value       = ibm_code_engine_project.langflow_project.name
}

# Database Information
output "database_id" {
  description = "PostgreSQL database instance ID"
  value       = ibm_database.postgresql.id
}

output "database_name" {
  description = "PostgreSQL database name"
  value       = ibm_database.postgresql.name
}

output "database_version" {
  description = "PostgreSQL database version"
  value       = ibm_database.postgresql.version
}

output "database_connection_string" {
  description = "PostgreSQL connection string (sensitive)"
  value       = data.ibm_database_connection.postgresql_connection.postgres[0].composed[0]
  sensitive   = true
}

# Backend Application
output "backend_url" {
  description = "Langflow backend application URL"
  value       = ibm_code_engine_app.backend.endpoint
}

output "backend_app_name" {
  description = "Backend application name"
  value       = ibm_code_engine_app.backend.name
}

output "backend_status" {
  description = "Backend application status"
  value       = ibm_code_engine_app.backend.status
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region          = var.region
    resource_group  = var.resource_group_name
    project_name    = ibm_code_engine_project.langflow_project.name
    database_name   = ibm_database.postgresql.name
    backend_url     = ibm_code_engine_app.backend.endpoint
    backend_scaling = "${var.backend_min_scale}-${var.backend_max_scale} instances"
  }
}

# Access Instructions
output "access_instructions" {
  description = "Instructions for accessing the deployed application"
  value       = <<-EOT
    
    ╔════════════════════════════════════════════════════════════════╗
    ║           Langflow Deployment Successful!                      ║
    ╚════════════════════════════════════════════════════════════════╝
    
    🌐 Langflow URL: ${ibm_code_engine_app.backend.endpoint}
    
    📊 Resource Details:
    - Region: ${var.region}
    - Project: ${ibm_code_engine_project.langflow_project.name}
    - Database: ${ibm_database.postgresql.name}
    
    ⚙️  Scaling Configuration:
    - App: ${var.backend_min_scale}-${var.backend_max_scale} instances (${var.backend_cpu} vCPU, ${var.backend_memory} RAM)
    
    📝 Next Steps:
    1. Access the Langflow URL to start using Langflow
    2. Configure additional settings via IBM Cloud Console
    3. Monitor application logs in Code Engine dashboard
    4. Set up custom domain (optional)
    
    💡 Tips:
    - Applications scale to zero when idle to minimize costs
    - First request after idle may take 10-30 seconds (cold start)
    - Database connection string is stored securely in Code Engine secrets
    
    🔗 IBM Cloud Console:
    https://cloud.ibm.com/codeengine/projects
    
  EOT
}
