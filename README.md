# Git shortcuts for implementing the scalable git branching model

The Scalable Git Branching Model has recently been updated; see the new
terminology in [A scalable Git branching model,
Revisited](https://dekrey.net/articles/scalable-git-branching-model-revisited/).

## Prerequisites

- Powershell Core (7+)
- git 2.41+

## Installation

### Install Powershell tools for macOS

[Microsoft has instructions to install PowerShell for macOS.][install-powershell-macos] Alternatively, if you already have the latest .NET Runtime installed, you can install PowerShell as a .NET Global tool.

	dotnet tool install --global PowerShell

Note: if you have an older version installed, such as .NET 7, you can [install an older version of PowerShell][dotnet-7-powershell].

### Install Git Shortcuts

1. See the above prerequisites.
2. Clone this repository. If you are working on multiple projects and need specific versions of the tools, clone it once for each project (or use git workspaces).
3. In your terminal, navigate to the git directory in which you want to use the commands. Then run the `init.ps1` from this repository. For example, if this was cloned in `C:\Users\Matt\Source\scalable-git-branching-tools` and you want to use them in "MyProject", run:

        C:\Users\Matt\Source\scalable-git-branching-tools\init.ps1

    Relative paths work, too. To clone and run, you may use the following commands:

        git clone https://github.com/DarkPatternsDigital/scalable-git-branching-tools.git ../scalable-git-branching-tools
        ../scalable-git-branching-tools/init.ps1

## Commands

[`git tool-update`](./docs/tool-update.md) - Attempts to update these tools

[`git tool-config`](./docs/tool-config.md) - Configures these tools

[`git new`](./docs/new.md) - Create a new branch with tracked dependencies

[`git pull-deps`](./docs/pull-deps.md) - Pull dependencies into your current branch

[`git show-dependants`](./docs/show-dependants.md) - Shows dependants of the current branch

[`git show-deps`](./docs/show-deps.md) - Shows dependencies of the current branch

[`git add-deps`](./docs/add-deps.md) - Adds one or more dependencies to the current branch

[`git rc`](./docs/rc.md) - Creates a release candidate out of one or more dependencies

[`git rebuild-rc`](./docs/rebuild-rc.md) - Recreates a release candidate, modifying its dependencies.

[`git verify-updated`](./docs/verify-updated.md) - Verifies if the current branch is up-to-date wit its dependencies

[`git refactor-deps`](./docs/refactor-deps.md) - Rewrites the dependencies tree as directed

[`git release`](./docs/release.md) - Releases and cleans up branches

## Development

### Tests

Install the latest version of Pester:

    Install-Module Pester -Force
    Import-Module Pester -PassThru

From the git-tools folder, run:

    Invoke-Pester

There are also docker integration tests that actually run the git commands; run:

    docker build .

Note that, due to the use of `Import-Module`, PowerShell caches scripts in the local environment. This won't affect users when updating, since each git alias launches a new `pwsh` scope. However, for developers, you can use the following command to pick up changes in any `.psm1` files within this project:

    ./reset.ps1

### Demo

If you want to test it locally, but don't have a git repository set up, you can use one of the samples via Docker! Run one of the following:

    docker build . -t git-tools-demo -f Dockerfile.demo
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=local
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=remote-release
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=remote-without-config
    docker build . -t git-tools-demo -f Dockerfile.demo --build-arg demo=remote
    # build arg matches ./demos/demo-<arg>.ps1

Then take the resulting image SHA hash and run:

    docker run --rm -ti git-tools-demo

This will give you a PowerShell prompt in the repos directory; `cd local` and try out the commands!

[install-powershell-macos]: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.4
[dotnet-7-powershell]: https://www.nuget.org/packages/PowerShell/7.3.11
