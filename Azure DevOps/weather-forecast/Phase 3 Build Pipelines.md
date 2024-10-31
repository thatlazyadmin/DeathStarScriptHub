# Phase 3: Build Pipelines

## Continuous Integration (CI) Pipelines

- **Definition**: Continuous Integration (CI) is an automated process that builds and tests code each time a team member commits changes, ensuring that code integrates smoothly.
- **Use Case**: CI helps identify defects early in the development process, catching issues before they reach production and facilitating faster feedback loops.

### Lab Task: Set up a YAML Build Pipeline in Azure Pipelines

#### Step-by-Step:

1. **Create a Pipeline**:
   - In your Azure DevOps project, navigate to *Pipelines* and select *Create Pipeline*.

2. **Connect Repository**:
   - Choose the repository that contains your project code.
   - Select **YAML** as the pipeline configuration type to create a pipeline file that you can version control.

3. **Write a YAML Configuration File**:
   - Define a YAML file (`azure-pipelines.yml`) that compiles and tests your code. Here’s an example setup for a .NET project:

   ```yaml
   trigger:
     branches:
       include:
         - main

   pool:
     vmImage: 'windows-latest'

   steps:
     - task: UseDotNet@2
       inputs:
         packageType: 'sdk'
         version: '5.x'

     - script: dotnet build
       displayName: 'Build Project'

     - script: dotnet test
       displayName: 'Run Tests'
    ```
4. **Save and Run the Pipeline:
- Save the YAML file and queue the pipeline. Azure DevOps will automatically start the build and run tests whenever changes are pushed to the main branch.

This pipeline example sets up a simple CI process that includes:
- **Trigger:** Builds on commits to the main branch.
- **Pool:** Specifies the agent (in this case, windows-latest) to run the tasks.
- **Steps:** Defines tasks for using the .NET SDK, building the project, and running tests.

This configuration ensures that code is built and teted automatically, allowing you to identify issues as soon as new changes are pushed.