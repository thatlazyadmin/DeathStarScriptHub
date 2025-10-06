# Values Modification Checklist

Use this checklist to ensure you've updated all required values before deployment.

## ✅ Pre-Deployment Checklist

### 🔑 Authentication (REQUIRED - Will Fail Without This!)

- [ ] **adminPasswordOrKey** - Set your SSH public key OR strong password
  - For Linux: `cat ~/.ssh/id_rsa.pub` and copy the output
  - For Windows: Create password with 12+ chars (mix of upper, lower, numbers, symbols)
  - ⚠️ **NEVER commit passwords to Git!**

### 🏷️ Basic Configuration (REQUIRED)

- [ ] **environmentName** - Set to `dev`, `staging`, or `prod`
- [ ] **workloadName** - Set to your app name (3-10 chars, e.g., `webapp`, `api`)
- [ ] **location** - Set to your Azure region (e.g., `eastus`, `westeurope`)

### 💻 VM Configuration (Review and Modify as Needed)

- [ ] **osType** - Choose `Linux` or `Windows`
- [ ] **vmSize** - Select appropriate size for your workload
  - Dev/Test: `Standard_B2s` (~$30/month)
  - Small Production: `Standard_D2s_v3` (~$70/month)
  - Medium Production: `Standard_D4s_v3` (~$140/month)
  - High Performance: `Standard_D8s_v3` (~$280/month)
- [ ] **adminUsername** - Change if you want custom username (default: `azureuser` or `azureadmin`)
- [ ] **authenticationType** - Should match your OS choice:
  - Linux → `sshPublicKey` (recommended)
  - Windows → `password`

### 🌍 Environment-Specific Settings

- [ ] **availabilityZone** - Set based on environment:
  - Development: `""` (empty, no zone)
  - Production: `"1"`, `"2"`, or `"3"`
- [ ] **enablePublicIP** - Set based on access needs:
  - Development: `true` (easy remote access)
  - Production: `false` (use VPN/Bastion for security)

### 🏷️ Tags (OPTIONAL but Recommended)

- [ ] **tags.CostCenter** - Your department's cost center code
- [ ] **tags.Owner** - Team or person responsible
- [ ] **tags.Project** - Project name or identifier
- [ ] **tags.Criticality** - Add for production (e.g., `High`, `Medium`, `Low`)

## 📝 Quick Reference: What to Change for Common Scenarios

### Scenario 1: Linux Development VM

```json
{
  "environmentName": "dev",
  "workloadName": "myapp",           // ← CHANGE THIS
  "location": "eastus",               // ← CHANGE IF NEEDED
  "osType": "Linux",
  "vmSize": "Standard_B2s",
  "adminUsername": "azureuser",
  "adminPasswordOrKey": "SSH_KEY",    // ← CHANGE THIS
  "authenticationType": "sshPublicKey",
  "availabilityZone": "",
  "enablePublicIP": true
}
```

**Must Change:**
- workloadName
- location (if not in East US)
- adminPasswordOrKey (paste your SSH public key)

### Scenario 2: Windows Production VM

```json
{
  "environmentName": "prod",
  "workloadName": "winapp",           // ← CHANGE THIS
  "location": "eastus",               // ← CHANGE IF NEEDED
  "osType": "Windows",
  "vmSize": "Standard_D4s_v3",
  "adminUsername": "azureadmin",
  "adminPasswordOrKey": "PASSWORD",   // ← CHANGE THIS
  "authenticationType": "password",
  "availabilityZone": "1",
  "enablePublicIP": false
}
```

**Must Change:**
- workloadName
- location (if not in East US)
- adminPasswordOrKey (use strong password)

### Scenario 3: Linux Production VM

```json
{
  "environmentName": "prod",
  "workloadName": "webapp",           // ← CHANGE THIS
  "location": "westeurope",           // ← CHANGE IF NEEDED
  "osType": "Linux",
  "vmSize": "Standard_D4s_v3",
  "adminUsername": "azureuser",
  "adminPasswordOrKey": "SSH_KEY",    // ← CHANGE THIS
  "authenticationType": "sshPublicKey",
  "availabilityZone": "1",
  "enablePublicIP": false
}
```

**Must Change:**
- workloadName
- location (if not in West Europe)
- adminPasswordOrKey (paste your SSH public key)

## 🔒 Security Reminders

### SSH Key Generation (Linux VMs)

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Display public key (this is what you paste into adminPasswordOrKey)
cat ~/.ssh/id_rsa.pub
```

### Password Requirements (Windows VMs)

Your password **MUST**:
- Be 12-123 characters long
- Contain at least 3 of the following:
  - Uppercase letters (A-Z)
  - Lowercase letters (a-z)
  - Numbers (0-9)
  - Special characters (!@#$%^&*)

**Good Examples:**
- `MyS3cur3P@ssw0rd!`
- `Azur3Vm!2024Prod`
- `C0mpl3x!P@ssword`

**Bad Examples:**
- `password123` (too simple, no uppercase/special)
- `Password` (too short, no numbers/special)
- `admin` (way too simple)

## 🚀 Deployment Command with Parameters

### Option 1: Use Parameter File + Override

```bash
az deployment group create \
  --resource-group rg-myapp-dev \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --parameters adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)" \
  --parameters workloadName=myapp \
  --parameters location=eastus
```

### Option 2: All Parameters in Command Line

```bash
az deployment group create \
  --resource-group rg-myapp-dev \
  --template-file main.bicep \
  --parameters environmentName=dev \
  --parameters workloadName=myapp \
  --parameters location=eastus \
  --parameters osType=Linux \
  --parameters vmSize=Standard_D2s_v3 \
  --parameters adminUsername=azureuser \
  --parameters adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)" \
  --parameters authenticationType=sshPublicKey \
  --parameters availabilityZone="" \
  --parameters enablePublicIP=true
```

## ⚠️ Common Mistakes to Avoid

1. ❌ **Using same password across environments**
   - ✅ Use different passwords for dev/staging/prod

2. ❌ **Enabling public IP in production**
   - ✅ Use `enablePublicIP=false` for prod, access via VPN/Bastion

3. ❌ **Committing passwords to Git**
   - ✅ Always override sensitive params at deployment time

4. ❌ **Using wrong authentication type for OS**
   - ✅ Linux → sshPublicKey, Windows → password

5. ❌ **Forgetting to change workloadName**
   - ✅ Each deployment should have unique workloadName

6. ❌ **Not setting availability zones for production**
   - ✅ Production should use zones 1, 2, or 3

## 📊 After Deployment - Verify Your Settings

```bash
# Check what was deployed
az deployment group show \
  --resource-group rg-myapp-dev \
  --name main \
  --query 'properties.outputs' -o table

# Get VM details
az vm show \
  --resource-group rg-myapp-dev \
  --name vm-myapp-dev-xxxxx \
  --query '{Name:name, Size:hardwareProfile.vmSize, OS:storageProfile.osDisk.osType, Zone:zones[0]}' \
  --output table
```

---

**Need Help?** See [README.md](README.md) for detailed documentation.

**Created by:** Shaun Hardneck | [thatlazyadmin.com](https://thatlazyadmin.com)
