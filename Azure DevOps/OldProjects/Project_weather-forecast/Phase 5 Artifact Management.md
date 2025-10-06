# Phase 5: Artifact Management

## Azure Artifacts Setup

- **Definition**: Azure Artifacts is a package management tool within Azure DevOps that supports popular package types, including NuGet, npm, Maven, and Python packages. It allows teams to create and share packages across projects and pipelines.
- **Use Case**: Manages dependencies effectively, ensuring consistent package versions are available for your development and production environments.

### Lab Task: Publish and Retrieve Packages Using Azure Artifacts

#### Step-by-Step:

1. **Create a Package Feed**:
   - In Azure DevOps, navigate to *Artifacts* and select *Create Feed*.
   - Name the feed (e.g., `MyPackageFeed`) and set visibility to **public** or **private** depending on your requirements.

2. **Publish a Package to the Feed**:
   - Publish a package (e.g., NuGet, npm, Maven, or Python) to the feed. 
   - For example, if publishing a NuGet package:
     ```bash
     dotnet pack <project-file> --output <path>
     dotnet nuget push <package-file> -s <feed-url>
     ```
   - Follow the instructions in Azure Artifacts to connect and publish based on your package type.

3. **Configure a Pipeline to Retrieve the Package**:
   - Set up a pipeline to retrieve the package as a dependency by adding the feed to your project’s dependencies.
   - Example YAML configuration to restore a NuGet package from Azure Artifacts:
     ```yaml
     steps:
       - task: UseDotNet@2
         inputs:
           packageType: 'sdk'
           version: '5.x'

       - script: dotnet restore
         displayName: 'Restore Dependencies'
     ```

By using Azure Artifacts, you create a centralized repository for dependencies, simplifying package management and ensuring consistency across builds and environments.
