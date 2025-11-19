# WP3 - Project 3 Workflows

> [!WARNING]
> This repo is a work in progress. Contact authors for more info.

Repo for the development of Workflows for the WP3 - Project 3 "Framework for AI-driven Immunogenic Peptide Prediction". See sub-directories for more details.

### `docs`
Documentation related to softwares, their installation and usage.

### `md`
Workflow for a MD simulation based on the official [GROMACS introductory MD tutorial](https://tutorials.gromacs.org/docs/md-intro-tutorial.html).


## Use this repo as a template
To use the implemented workflows as starting point for your workflow, follow these steps (`git` and the possibility to clone from your GitHub account are required, see [contribution](./docs/contribution.md) for more info):

1. [Fork this repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo?tool=webui) to your GitHub account.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/WP3-P3-md-workflow.git
   ```
3. (Optional) Create a new branch for your work:
   ```bash
   git switch -c feat-branch-name
   ```
   This is suggested to keep the orginal workflow and update it, through a `git pull`, if necessary.

> TODO
>
> FAIR Principles for workflows. We need a registry where to save all generated workflows to make them discoverable. Multiple solutions are possible.
> One of this is to use a GH repo in the official GANANA GH to store all workflows, another could be upload them into public registries such as [Workflowhub](https://workflowhub.eu/).

## How to contribute

See the [contribution documentation](./docs/contribution.md).

## Authors

Leonardo Salicari (CINECA)