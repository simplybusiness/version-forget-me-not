![forget-me-not flowers by Noah Boyer on Unsplash](https://images.unsplash.com/photo-1558633155-f9864ef70d94?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80)

# Version forget-me-not
A Github Action for Ruby projects that checks that the semantic version has been updated in a pull request.

The aim is to remind engineers to update the version before merging, since this step is often forgotten and requires a retroactive fix.

# Installation

1. Create a file called `.github/workflows/version-forget-me-not.yml` in your repository.

   ```yaml
    name: Check version

    on:
      pull_request:
        branches:
          - master # default branch
        types: [opened, synchronize]
    jobs:
      build:
        runs-on: ubuntu-18.04

        steps:
          - uses: simplybusiness/version-forget-me-not@v1
            env:
              ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
              # The file path where you keep the version of gem.
              # It is usually `lib/<gem name>/version.rb` or in the gemspec file.
              VERSION_FILE_PATH: "<PATH>"
   ```

Here is an [example workflow](https://github.com/simplybusiness/version-forget-me-not/blob/master/example/workflow/version_forget_me_not.yml)
