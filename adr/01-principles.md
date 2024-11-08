# Principles of the Scalable Git Branching Tools

The Scalable Git Branching Tools are based off of the [Scalable Git Branching
Model][scalable-git], as recommended by [Principle
Studios][principle-scalable-git]. This model includes the following
principles:

1. Isolation until finalized
2. Multiple bases
3. Immediate downstream propagation

These tools are designed to assist with the principles of this model, as opposed
to some of the more specific workflows around it. This is because the model is
more of a way of thinking about branching and git than it is a prescribed way to
perform a git workflow. [Some strategies that leverage this model are detailed on
the Principle Tools site.][principle-tools-branching]

## What these tools will not do

Since each workflow is slightly different to meet the scalable needs, any
particular repository may have a number of differences with its workflow.
Specifically, the following responsibilities not a part of these tools:

* Identify branch types (service line, feature, integration, infrastructure, or
  release candidate)
* Enforce naming conventions
* Enforcing any specific workflow

## What these tools will do

At the point of time of writing of this ADR, these tools aim to assist
developers in the following tasks:

* Creating new branches
* Tracking upstream branches
* Keeping downstream branches updated
* Checking if a branch is updated with its upstreams
* Keeping branches isolated
* Recreating a branch if an upstream needs to be removed
* Recreating a branch from its upstream branches
* Identifying conflicting upstream branches when adding a new upstream
* Visualize dependencies of branches
* Clean up a repository

Several of these tasks are direct actions within a workflow (such as creating
new branches.) Others may be more generalized cleanup, or verification
tasks to be used with branch protections and PR checks, like GitHub actions.

## Authoring Tools

Tools should be written with the following in mind:

- Tools may be called from git command line as aliases or directly from
  PowerShell. As a result, some `[string[]]` parameters may get passed as a
  single string with commas (because git bash won't translate the array.)
- Tools should be primarily non-interactive scripts that can be called from
  other scriptable systems, such as Azure DevOps pipelines or GitHub actions.
  Interactive versions may be provided, but should call the original
  non-interactive script.
- Unit tests should be written both with mocks and as full end-to-end tests
  within Docker.
- Most configuration should be local to a repository. (Remote aliases can change
  per clone, aliases should not be installed globally, etc.) The current
  exception is the "upstream" branch configuration, which is stored within the
  repository itself.

[scalable-git]: https://dekrey.net/articles/scaled-git-flow/
[principle-scalable-git]: https://www.principlestudios.com/article/a-scalable-git-branching-model/
[principle-tools-branching]: https://principle.tools/branching/