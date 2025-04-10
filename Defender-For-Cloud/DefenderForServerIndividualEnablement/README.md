# Defender for Servers Per-VM Management Script

**Author**: Shaun Hardneck – [ThatLazyAdmin](https://www.thatlazyadmin.com) | Microsoft Defender 

---

## 📌 Overview

This PowerShell script allows users to **enable, disable, or exclude** individual **Azure VMs** from **Defender for Servers** using **Microsoft Defender for Cloud APIs**.

Previously, **Defender for Servers** could only be enabled at the **subscription level**, but Microsoft now supports per-VM management using API calls.

---

## 🚀 Features

✔ **Enable Defender for Servers Plan 1 (P1) on a single VM**  
✔ **Disable Defender for Servers on a specific VM**  
✔ **Exclude a VM from Defender for Servers while it's enabled at the subscription level**  
✔ **Automatic installation of required PowerShell modules**  
✔ **Token-based authentication using Azure REST APIs**  
✔ **User-friendly prompts and color-coded output**  

---

## ⚠ Prerequisites

Before running the script, ensure that:

1. You have **PowerShell 7+** installed.
2. You have the **Az PowerShell module** installed (`Az.Accounts`).
3. You **connect to Azure** by running:

   ```powershell
   az login
    ```
If the Az module isn’t installed, run:

```powershell
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
```

## 📌 How to Use the Script
### 1️⃣ Run the Script

```powershell
    ./DefenderForServers.ps1
```

It will prompt you for:
 **- Subscription ID**
 **- Resource Group Name**
 **- Virtual Machine Name**
 **- Action to perform (Enable, Disable, or Exclude)**

## 2️⃣ Select an Action
### You’ll be asked to choose:
**- Enable-P1 → Enable Defender for Servers Plan 1 for a VM**
**- Disable → Remove Defender for Servers from a VM**
**- Exclude → Exclude the VM from Defender for Servers (if enabled at the subscription level)**

## 📸 Screenshots

**Defender For Server Enabled**
![alt text](https://github.com/thatlazyadmin/DeathStarScriptHub/blob/main/Defender-For-Cloud/DefenderForServerIndividualEnablement/Enable-DefenderServerP1-01.png)

**Following screenshot we can see Defender enabled on the server**

![alt text](https://github.com/thatlazyadmin/DeathStarScriptHub/blob/main/Defender-For-Cloud/DefenderForServerIndividualEnablement/Enable-DefenderServerP1-02.png)

**Disable Defender on a Server**

![alt text](https://github.com/thatlazyadmin/DeathStarScriptHub/blob/main/Defender-For-Cloud/DefenderForServerIndividualEnablement/disable-DefenderforServerPerServer-01.png)

**Defender showing as "Off"**

![alt text](https://github.com/thatlazyadmin/DeathStarScriptHub/blob/main/Defender-For-Cloud/DefenderForServerIndividualEnablement/DefenderServer-Disabled-02.png)

## 📌 Example Usage
### Enable Defender for a VM

```powershell
Enter your Azure Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Enter the Resource Group Name: RG-Security
Enter the Virtual Machine Name: VM-Prod-01
Enter 'Enable-P1' to enable Defender for Servers P1, 'Disable' to remove Defender protection, or 'Exclude' to exclude this VM if Defender is set at the subscription level: Enable-P1
✅ Successfully updated Defender for Servers configuration for VM 'VM-Prod-01'
```

### Disable Defender for a VM

```powershell
    Enter 'Enable-P1' to enable Defender for Servers P1, 'Disable' to remove Defender protection, or 'Exclude' to exclude this VM if Defender is set at the subscription level: Disable
✅ Successfully removed Defender for Servers from VM 'VM-Prod-01'
```

### Exclude a VM from Defender

```powershell
    Enter 'Enable-P1' to enable Defender for Servers P1, 'Disable' to remove Defender protection, or 'Exclude' to exclude this VM if Defender is set at the subscription level: Exclude
✅ Successfully excluded VM 'VM-Prod-01' from Defender for Servers.
```

## 📜 License

This project is licensed under the MIT License.

## 📜 Learn More

From the following Microsoft document you can learn more about the differnet options available to enable Microsoft Defender for Server.
[Read More](https://learn.microsoft.com/en-us/azure/defender-for-cloud/plan-defender-for-servers-select-plan)

## 📌 Contributors

👤 **Shaun Hardneck**  
📧 Email: [Shaun@thatlazyadmin.com](mailto:Shaun@thatlazyadmin.com)  
🌍 Blog: [ThatLazyAdmin](https://www.thatlazyadmin.com)  

🔗 Feel free to reach out for support! 🚀

