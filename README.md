![What it looks like once installation is complete](images/what-it-looks-like-failing.png)

# Version Forget-Me-Not

![Forget-me-not flower by Tauno Erik](images/flower.jpg)

A Github Action that checks that the semantic version has been updated in a pull request.

The aim is to remind engineers to update the version before merging, since this step is often forgotten and requires a retroactive fix.

It is operational on Ruby, Python and Javascript projects.

## Installation

1. Create a file called `.github/workflows/version-forget-me-not.yml` in your repository with the following YAML (modify as instructed in the comments):

   ```yaml
   name: Version Forget-Me-Not
   
   on:
     pull_request:
       branches:
         - main # Change if your default branch is different
       types: [opened, synchronize]
   permissions:
     contents: read
     statuses: write
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: simplybusiness/version-forget-me-not@v2
           env:
             ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
             # Change to the file path where you keep the version.
             # It is usually `lib/<gem name>/version.rb` or in the gemspec file for Ruby.
             # It is usually 'package.json' for Javascript/Typescript.
             # It can often be 'pyproject.toml' for Python.
             VERSION_FILE_PATH: "<PATH>"
   
   ```

1. Create a new Pull Request to kick off this GitHub Action. You’ll notice it show up at the bottom of your pull request.

   ![Gem Version status check failing after initial installation](images/after-initial-installation.png)

1. Go to Settings → Branches → Your default branch → Mark `Version check` as required.

   ![The required status check that needs to be ticked](images/required-status-checks.png)
