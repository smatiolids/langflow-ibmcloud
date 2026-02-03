# 🚀 Quick Start Guide - Langflow on IBM Cloud

Get Langflow running on IBM Cloud in under 20 minutes!

## ⚡ Prerequisites Checklist

- [ ] IBM Cloud account with billing enabled
- [ ] IBM Cloud API key ([Create one](https://cloud.ibm.com/iam/apikeys))
- [ ] Terraform installed ([Download](https://www.terraform.io/downloads))
- [ ] 15-20 minutes of time

## 📝 Step-by-Step Deployment

### Step 1: Prepare Your Environment (2 minutes)

```bash
# Clone or navigate to the project directory
cd langflow-ibmcloud

# Navigate to terraform directory
cd terraform
```

### Step 2: Configure Your Deployment (3 minutes)

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the file with your API key
nano terraform.tfvars  # or use your preferred editor
```

**Minimum required configuration:**
```hcl
ibmcloud_api_key = "your-actual-api-key-here"
```

**Optional customizations:**
```hcl
region              = "us-south"        # or eu-de, jp-tok, etc.
resource_group_name = "langflow-resources"
project_name        = "my-langflow"
```

### Step 3: Initialize Terraform (1 minute)

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
- Finding IBM-Cloud/ibm versions matching "~> 1.63"...
- Installing IBM-Cloud/ibm v1.63.x...

Terraform has been successfully initialized!
```

### Step 4: Preview the Deployment (1 minute)

```bash
terraform plan
```

This shows you what will be created:
- ✅ 1 Code Engine project
- ✅ 1 PostgreSQL database
- ✅ 2 Code Engine applications (frontend + backend)
- ✅ 1 Secret for database credentials

### Step 5: Deploy! (15-20 minutes)

```bash
terraform apply
```

Type `yes` when prompted.

**What happens during deployment:**
1. ⏳ Creating Code Engine project (1 min)
2. ⏳ Provisioning PostgreSQL database (10-15 min) ☕
3. ⏳ Deploying backend application (2 min)
4. ⏳ Deploying frontend application (2 min)
5. ✅ Done!

### Step 6: Access Your Application (30 seconds)

After deployment completes, you'll see:

```
Outputs:

frontend_url = "https://langflow-frontend.xxxxx.us-south.codeengine.appdomain.cloud"
backend_url = "https://langflow-backend.xxxxx.us-south.codeengine.appdomain.cloud"

access_instructions = <<EOT
╔════════════════════════════════════════════════════════════════╗
║           Langflow Deployment Successful!                      ║
╚════════════════════════════════════════════════════════════════╝
...
```

**Open the frontend URL in your browser!**

⚠️ **First access may take 10-30 seconds** (cold start from scale-to-zero)

## 🎯 What You Get

- ✅ Fully functional Langflow installation
- ✅ Secure PostgreSQL database
- ✅ Auto-scaling (0-1 instances)
- ✅ HTTPS enabled by default
- ✅ Cost-optimized configuration (~$30-58/month)

## 🔧 Common Post-Deployment Tasks

### View Application Logs

```bash
# Install IBM Cloud CLI if not already installed
# https://cloud.ibm.com/docs/cli

# Login
ibmcloud login --apikey your-api-key

# Select project
ibmcloud ce project select --name langflow-project

# View logs
ibmcloud ce app logs --name langflow-backend --tail 50
ibmcloud ce app logs --name langflow-frontend --tail 50
```

### Update Environment Variables

1. Go to [IBM Cloud Console](https://cloud.ibm.com/codeengine/projects)
2. Select your project
3. Click on application (backend or frontend)
4. Navigate to **Environment variables**
5. Add/modify variables
6. Save (auto-redeploys)

### Scale Up for Production

Edit `terraform.tfvars`:

```hcl
# Increase max instances
backend_max_scale  = 3
frontend_max_scale = 2

# Increase resources
backend_cpu    = "1"
backend_memory = "2G"
```

Apply changes:
```bash
terraform apply
```

## 🐛 Troubleshooting

### Issue: "Resource group not found"

**Solution:** Create the resource group first:
```bash
ibmcloud resource group-create langflow-resources
```

Or use an existing one in `terraform.tfvars`:
```hcl
resource_group_name = "Default"
```

### Issue: "Application not responding"

**Cause:** Cold start delay (scale-to-zero)

**Solution:** Wait 10-30 seconds and refresh. First request after idle period takes longer.

### Issue: "Database connection failed"

**Check database status:**
```bash
ibmcloud resource service-instance langflow-postgres
```

**View backend logs:**
```bash
ibmcloud ce app logs --name langflow-backend --tail 100
```

### Issue: Terraform state locked

**Solution:**
```bash
terraform force-unlock <lock-id>
```

## 🧹 Cleanup (Remove Everything)

⚠️ **Warning:** This deletes all resources and data!

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm.

**What gets deleted:**
- All Code Engine applications
- PostgreSQL database (and all data)
- Code Engine project
- All configurations

## 📊 Cost Management Tips

1. **Scale-to-zero is enabled** - Apps scale down when idle
2. **Monitor usage** in IBM Cloud Console
3. **Set up billing alerts** in IBM Cloud
4. **Use smallest database plan** (already configured)
5. **Delete when not in use** - Run `terraform destroy`

## 🎓 Next Steps

1. **Explore Langflow**: Build your first AI workflow
2. **Read full README**: [README.md](README.md)
3. **Check deployment plan**: [DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md)
4. **Configure authentication**: Add custom auth settings
5. **Set up monitoring**: Enable IBM Cloud monitoring

## 📚 Helpful Links

- [Langflow Documentation](https://docs.langflow.org/)
- [IBM Cloud Code Engine](https://cloud.ibm.com/docs/codeengine)
- [Terraform IBM Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)

## 💬 Need Help?

- Check [README.md](README.md) for detailed documentation
- Review [DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md) for architecture details
- Open an issue on GitHub
- Contact IBM Cloud Support

---

**Happy Building! 🎉**