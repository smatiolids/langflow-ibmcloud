# Langflow on IBM Cloud - Terraform Deployment

Deploy Langflow on IBM Cloud using Terraform with a backend-only Code Engine app and minimal cost configuration.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    IBM Cloud (us-south)                  │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │         Code Engine Project                     │    │
│  │                                                  │    │
│  │         ┌──────────────┐                        │    │
│  │         │   Langflow   │                        │    │
│  │         │  (0-1 inst)  │                        │    │
│  │         │  0.5 vCPU    │                        │    │
│  │         │  1 GB RAM    │                        │    │
│  │         └──────┬───────┘                        │    │
│  │                │                                 │    │
│  └────────────────┼────────────────────────────────┘    │
│                   │                                     │
│  ┌────────────────────────────────▼────────────────┐   │
│  │     PostgreSQL Database (Minimal Config)        │   │
│  │     - 1 GB Memory                               │   │
│  │     - 5 GB Disk                                 │   │
│  │     - SSL/TLS Enabled                           │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 📋 Components

- **Application**: Langflow (`langflowai/langflow:1.7.3`)
- **Database**: IBM Cloud Databases for PostgreSQL (minimal plan)
- **Compute**: IBM Cloud Code Engine (serverless, scale-to-zero)

## 💰 Cost Estimation

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| Code Engine (Langflow) | 0-1 instances, 0.5 vCPU, 1GB RAM | $0-5 |
| PostgreSQL | Shared, 1GB RAM, 5GB disk | $30-50 |
| **Total** | | **~$30-55/month** |

*Note: Code Engine charges only for actual usage with scale-to-zero enabled*

## 🚀 Prerequisites

1. **IBM Cloud Account** with billing enabled
2. **IBM Cloud API Key** - [Create one here](https://cloud.ibm.com/iam/apikeys)
3. **Terraform** (v1.0+) - [Install Terraform](https://www.terraform.io/downloads)
4. **Git** (optional, for version control)
5. **IBM Cloud CLI** - [Install the CLI](https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli)
6. **IBM Cloud CLI Code Engine PLugin** [Install the Code Engine Plugin](https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli)

### Creating an IBM Cloud API Key

1. Log in to [IBM Cloud Console](https://cloud.ibm.com)
2. Navigate to **Manage** → **Access (IAM)** → **API keys**
3. Click **Create an IBM Cloud API key**
4. Give it a name (e.g., "terraform-langflow")
5. Click **Create** and **Download** the key
6. Save it securely - you'll need it for deployment

## 📦 Installation

### 1. Clone or Download This Repository

```bash
git clone <your-repo-url>
cd langflow-ibmcloud
```

### 2. Create Terraform Variables File

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 3. Edit `terraform.tfvars`

```hcl
# Required: Your IBM Cloud API Key
ibmcloud_api_key = "your-api-key-here"

# Optional: Customize these if needed
region               = "us-south"
resource_group_name  = "langflow-resources"
project_name         = "langflow-project"
database_name        = "langflow-postgres"

# Scaling configuration (already optimized for minimal cost)
backend_min_scale    = 0
backend_max_scale    = 1
```

## 🎯 Deployment Steps


### 1. Connect to IBM Cloud

```bash
ibmcloud login --sso
ibmcloud target -g langflow-resources
ibmcloud ce project select --name langflow-project
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

This downloads the IBM Cloud provider and initializes the working directory.

### 3. Review the Deployment Plan

```bash
terraform plan
```

This shows what resources will be created without actually creating them.

### 4. Deploy the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

**⏱️ Deployment Time**: Approximately 15-20 minutes
- PostgreSQL provisioning: ~10-15 minutes
- Code Engine app: ~2-5 minutes

Note: Liveness/readiness probes are configured via IBM Cloud CLI during apply (`GET /health_check`), so your CLI session must be authenticated and the Code Engine plugin must be installed.

### 4. Access Your Application

After successful deployment, Terraform will output:

```
Outputs:

backend_url = "https://langflow-backend.xxxxxx.us-south.codeengine.appdomain.cloud"

access_instructions = <<EOT
╔════════════════════════════════════════════════════════════════╗
║           Langflow Deployment Successful!                      ║
╚════════════════════════════════════════════════════════════════╝

🌐 Langflow URL: https://langflow-backend.xxxxxx...
...
EOT
```

## 🔧 Post-Deployment Configuration

### Accessing the Application

1. Open the **Langflow URL** in your browser
2. Wait 10-30 seconds on first access (cold start from scale-to-zero)
3. Configure Langflow settings as needed

### Viewing Logs

```bash
# Using IBM Cloud CLI
ibmcloud ce project select --name langflow-project
ibmcloud ce app logs --name langflow-backend
```

Or via [IBM Cloud Console](https://cloud.ibm.com/codeengine/projects)

## 🧭 IBM Cloud CLI Basics (Login, Project Selection, Debugging)

### 1) Login and target region

```bash
ibmcloud login --sso
ibmcloud target -r us-south
```

### 2) Select your Code Engine project

```bash
ibmcloud ce project list
ibmcloud ce project select --name langflow-project
```

### 3) Debugging a failing app

```bash
# App status/details
ibmcloud ce application get --name langflow-backend

# Logs (follow, include all containers)
ibmcloud ce application logs --name langflow-backend --all-containers --follow

# List instances (use with --instance to narrow logs)
ibmcloud ce application get --name langflow-backend --output json
```

Notes:
- `ibmcloud ce application logs` does **not** accept `--project`; select the project first.
- If the app shows "Revision failed to start", logs will usually contain the exact error (missing env vars, image pull error, crash on boot).

### Updating Environment Variables

1. Go to [IBM Cloud Code Engine Console](https://cloud.ibm.com/codeengine/projects)
2. Select your project
3. Click on the backend application
4. Go to **Environment variables** tab
5. Add or modify variables
6. Save changes (app will automatically redeploy)

### Scaling Configuration

To adjust scaling limits, edit `terraform.tfvars`:

```hcl
# Increase max instances for higher traffic
backend_max_scale  = 3
```

Then apply changes:

```bash
terraform apply
```

## 📊 Monitoring

### IBM Cloud Console

1. Navigate to [Code Engine Projects](https://cloud.ibm.com/codeengine/projects)
2. Select your project
3. View application metrics, logs, and events

### Key Metrics to Monitor

- **Request count**: Number of requests per application
- **Response time**: Application latency
- **Instance count**: Current running instances
- **CPU/Memory usage**: Resource utilization
- **Database connections**: PostgreSQL connection pool

## 🔒 Security Best Practices

1. **API Key Storage**: Never commit `terraform.tfvars` to version control
2. **Database Access**: Only accessible from Code Engine applications
3. **HTTPS**: All traffic is encrypted (Code Engine provides SSL/TLS)
4. **Secrets Management**: Database credentials stored in Code Engine secrets
5. **IAM Policies**: Use least-privilege access for API keys

## 🛠️ Maintenance

### Updating Langflow Version

Edit `terraform/variables.tf` or `terraform.tfvars`:

```hcl
backend_image  = "langflowai/langflow:v1.7.3"
```

Apply changes:

```bash
terraform apply
```

### Backing Up Database

IBM Cloud Databases automatically creates daily backups. To create a manual backup:

1. Go to [IBM Cloud Resources](https://cloud.ibm.com/resources)
2. Find your PostgreSQL instance
3. Click **Backups** → **Create backup**

### Destroying Resources

⚠️ **Warning**: This will delete all resources and data!

```bash
terraform destroy
```

Type `yes` to confirm.

## 🐛 Troubleshooting

### Application Not Responding

Setup:

```bash
ibmcloud login --sso
ibmcloud target -g langflow-resources
ibmcloud ce project select -n langflow-project
```

1. **Check application status**:
   ```bash
   ibmcloud ce app get --name langflow-backend
   ```

2. **View logs**:
   ```bash
   ibmcloud ce app logs --name langflow-backend --tail 100
   ```

3. **Common issues**:
   - Cold start delay (10-30 seconds on first request)
   - Database connection timeout (check database status)
   - Image pull errors (verify image names)

### Database Connection Issues

1. **Verify database is running**:
   ```bash
   ibmcloud resource service-instance langflow-postgres
   ```

2. **Check connection string** (in Code Engine secrets):
   ```bash
   ibmcloud ce secret get --name langflow-db-secret
   ```

3. **Test connectivity** from backend logs

### Terraform Errors

1. **State lock issues**:
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **Provider version conflicts**:
   ```bash
   terraform init -upgrade
   ```

3. **Resource already exists**:
   ```bash
   terraform import <resource_type>.<name> <resource_id>
   ```

## 📚 Additional Resources

- [Langflow Documentation](https://docs.langflow.org/)
- [Langflow GitHub](https://github.com/langflow-ai/langflow)
- [IBM Cloud Code Engine Docs](https://cloud.ibm.com/docs/codeengine)
- [IBM Cloud Databases for PostgreSQL](https://cloud.ibm.com/docs/databases-for-postgresql)
- [Terraform IBM Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)

## 🤝 Support

- **Langflow Issues**: [GitHub Issues](https://github.com/langflow-ai/langflow/issues)
- **IBM Cloud Support**: [Support Center](https://cloud.ibm.com/unifiedsupport/supportcenter)
- **Terraform Issues**: [Terraform IBM Provider Issues](https://github.com/IBM-Cloud/terraform-provider-ibm/issues)

## 📝 License

This deployment configuration is provided as-is. Langflow has its own license terms.

## 🎉 What's Next?

1. **Explore Langflow**: Build AI workflows and applications
2. **Custom Domain**: Set up a custom domain for your deployment
3. **CI/CD**: Automate deployments with GitHub Actions or IBM Cloud Toolchain
4. **Monitoring**: Set up alerts and monitoring dashboards
5. **Backup Strategy**: Configure automated backup schedules

---

**Happy Building! 🚀**
