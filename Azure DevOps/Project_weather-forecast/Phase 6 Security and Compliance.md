# Phase 6: Security and Compliance

## Implementing DevSecOps

- **Definition**: DevSecOps is the practice of integrating security into DevOps workflows to ensure secure code deployment. It embeds security practices into CI/CD pipelines, promoting proactive identification and mitigation of vulnerabilities.
- **Use Case**: By incorporating security early, DevSecOps minimizes vulnerabilities, ensures compliance, and protects application integrity across development and production environments.

### Lab Task: Integrate Security Checks into CI/CD

#### Step-by-Step:

1. **Add a Security Tool to the Build Pipeline**:
   - Integrate a security scanning tool like *Microsoft Security Code Analysis* or a third-party option (e.g., *SonarQube*, *Whitesource Bolt*) into your build pipeline.
   - Example YAML snippet for a security scan (using Microsoft Security Code Analysis):
     ```yaml
     steps:
       - task: MicrosoftSecurityCodeAnalysis@1
         inputs:
           codeAnalysisTool: 'SecurityCodeScan'
           severity: 'High'
     ```

2. **Configure Azure Key Vault for Secrets Management**:
   - Set up an **Azure Key Vault** to securely store sensitive information such as API keys, credentials, and certificates.
   - In Azure DevOps, configure a pipeline task to retrieve secrets from Azure Key Vault:
     - Add an *Azure Key Vault* task to connect the Key Vault to your pipeline:
       ```yaml
       - task: AzureKeyVault@2
         inputs:
           azureSubscription: '<Your Subscription>'
           keyVaultName: '<Your Key Vault>'
           secretsFilter: '*'
           runAsPreJob: true
       ```

3. **Set Policies for Code Reviews and Deployment Approvals**:
   - Apply policies in Azure DevOps to enforce code reviews and approval gates:
     - **Code Review Policies**: Navigate to *Project Settings* > *Repositories*, select the repository, then configure **Branch Policies** to require a code review for specific branches (e.g., `main` or `production`).
     - **Deployment Approvals**: In the release pipeline, go to each stage’s **Pre-deployment conditions** and add manual approvals to control deployments to sensitive environments like production.

By embedding security checks and managing secrets and policies, DevSecOps ensures that security is consistently applied throughout the development lifecycle, reducing the risk of security vulnerabilities reaching production.
