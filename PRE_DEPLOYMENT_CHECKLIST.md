# 📋 Pre-Deployment Checklist

Use this checklist before running `terraform apply` to ensure a smooth deployment.

## ✅ IBM Cloud Account Setup

- [ ] IBM Cloud account created and verified
- [ ] Billing information added to account
- [ ] Account is in good standing (no payment issues)
- [ ] Sufficient quota for resources:
  - [ ] Code Engine projects (need 1)
  - [ ] Database instances (need 1)
  - [ ] Code Engine applications (need 2)

## 🔑 Authentication & Access

- [ ] IBM Cloud API key created
- [ ] API key has necessary permissions:
  - [ ] Editor role on Resource Group
  - [ ] Manager role on Code Engine
  - [ ] Editor role on Databases
- [ ] API key saved securely
- [ ] API key tested (can login via CLI)

## 📦 Local Environment

- [ ] Terraform installed (v1.0 or higher)
  ```bash
  terraform version
  ```
- [ ] Git installed (optional, for version control)
- [ ] Text editor available for editing configuration files
- [ ] Terminal/command line access

## 📁 Project Configuration

- [ ] Project files downloaded/cloned
- [ ] In correct directory (`langflow-ibmcloud`)
- [ ] `terraform.tfvars` file created from example
  ```bash
  cd terraform
  cp terraform.tfvars.example terraform.tfvars
  ```
- [ ] API key added to `terraform.tfvars`
- [ ] Region configured (default: us-south)
- [ ] Resource group name set (must exist or will be created)

## 🔍 Resource Group Verification

Check if your resource group exists:

```bash
# Login to IBM Cloud
ibmcloud login --apikey YOUR_API_KEY

# List resource groups
ibmcloud resource groups
```

**Options:**
- [ ] Using existing resource group (update name in terraform.tfvars)
- [ ] Creating new resource group (ensure name doesn't conflict)
- [ ] Using "Default" resource group

## 💰 Cost Awareness

- [ ] Reviewed estimated costs (~$30-58/month)
- [ ] Billing alerts configured in IBM Cloud
- [ ] Understand scale-to-zero reduces costs when idle
- [ ] Plan for database costs (always running)
- [ ] Budget approved for deployment

## 🌐 Network & Connectivity

- [ ] Internet connection stable
- [ ] No VPN/proxy issues that might block IBM Cloud API
- [ ] Firewall allows outbound HTTPS connections
- [ ] DNS resolution working properly

## 📖 Documentation Review

- [ ] Read [QUICKSTART.md](QUICKSTART.md) for quick deployment
- [ ] Reviewed [README.md](README.md) for detailed instructions
- [ ] Checked [DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md) for architecture
- [ ] Understand deployment will take 15-20 minutes

## 🔧 Terraform Validation

Run these commands to validate setup:

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format check
terraform fmt -check

# Preview deployment
terraform plan
```

Expected results:
- [ ] `terraform init` completes successfully
- [ ] `terraform validate` shows "Success!"
- [ ] `terraform plan` shows resources to be created
- [ ] No errors in plan output

## ⚠️ Important Considerations

- [ ] Understand that database provisioning takes 10-15 minutes
- [ ] First application access may have 10-30 second delay (cold start)
- [ ] Database will incur costs even when applications are idle
- [ ] Terraform state will be stored locally (consider remote backend for production)
- [ ] Destroying resources will delete all data permanently

## 🎯 Deployment Readiness

### Quick Validation Commands

```bash
# Check Terraform version
terraform version

# Verify IBM Cloud CLI (optional)
ibmcloud --version

# Test API key (optional)
ibmcloud login --apikey YOUR_API_KEY
ibmcloud target
```

### Final Checks

- [ ] All above items checked
- [ ] Configuration file reviewed
- [ ] API key verified
- [ ] Ready to commit 15-20 minutes for deployment
- [ ] Understand how to access deployed application
- [ ] Know how to view logs and troubleshoot

## 🚀 Ready to Deploy?

If all items are checked, proceed with deployment:

```bash
cd terraform
terraform apply
```

Type `yes` when prompted.

## 📞 Support Resources

If you encounter issues:

1. **Check troubleshooting section** in [README.md](README.md)
2. **Review Terraform errors** carefully
3. **Check IBM Cloud status**: https://cloud.ibm.com/status
4. **Verify API key permissions** in IAM console
5. **Contact IBM Cloud support** if needed

## 🔄 Post-Deployment Checklist

After successful deployment:

- [ ] Frontend URL accessible
- [ ] Backend URL responding
- [ ] Application loads (may take 30 seconds first time)
- [ ] Database connection working
- [ ] Outputs saved/documented
- [ ] Terraform state backed up
- [ ] Monitoring configured (optional)
- [ ] Custom domain configured (optional)

---

**Good luck with your deployment! 🎉**

For quick start instructions, see [QUICKSTART.md](QUICKSTART.md)