# Phase 2: Source Control & Versioning

## Git and Azure Repos Basics

- **Definition**: Git is a distributed version control system that tracks changes in source code, allowing multiple developers to work on the same codebase without conflicts. Azure Repos provides hosted Git repositories within Azure DevOps.
- **Practical Use**: Facilitates team collaboration on code by maintaining a history of changes, enabling rollbacks, and supporting branch-based development without overwriting each other's work.

### Lab Task: Set up and use Git for version control in Azure DevOps.

#### Step-by-Step:
1. **Initialize Repository**:
   - In your Azure DevOps project, navigate to *Repos* > *Files* and select *Initialize Repository* to set up a new Git repository.
2. **Clone the Repository Locally**:
   - Clone the repository to your local machine:
     ```bash
     git clone <repo-url>
     ```
3. **Create a New Branch**:
   - Create a branch for a new feature or bug fix:
     ```bash
     git checkout -b feature/my-new-feature
     ```
4. **Commit and Push Changes**:
   - Stage and commit your changes, then push them to Azure Repos:
     ```bash
     git add .
     git commit -m "Add new feature"
     git push origin feature/my-new-feature
     ```
5. **Submit a Pull Request (PR)**:
   - In Azure DevOps, navigate to *Repos* > *Pull Requests* and create a pull request to merge your feature branch back to the main branch.

---

## Branching Strategies

- **Definition**: A branching strategy defines how branches are organized and managed within a repository, supporting efficient code collaboration and release management.
- **Common Strategies**:
  - **Feature Branching**: Developers work on individual features in isolated branches.
  - **Git Flow**: A structured model with branches for releases, development, and hotfixes.

### Lab Task: Implement a feature branching strategy in Azure DevOps.

#### Step-by-Step:
1. **Create Branches for Different Environments**:
   - In Azure Repos, create branches for different stages of development, such as `development`, `staging`, and `production`.
2. **Set Branch Policies**:
   - Apply branch policies to enforce code quality, such as requiring code reviews for the production branch:
     - In *Project Settings* > *Repositories*, select *Branches*, then configure branch policies, such as requiring a minimum number of reviewers or enforcing successful builds before merging to production.
