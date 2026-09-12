# How to contribute to the project

There are two possible ways to exploit this repo. The first one is to fork, i.e. copy, this repo and use it as a template or starting point to generate your workflow. On the other hand, if you want to improve it, you can copy, modify it and then open a Pull Request to the original repo.

## Open issues

If you find bugs or have feature requests, please [open an issue](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/issues). We provide issue templates to guide the process.

## Contribute to the code (a.k.a. open a Pull Request)

!!! info
      This guide assumes that you are able to clone repositories from your GitHub account. One way to do this is by means of [ssh keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key), however other [ways are possible](https://docs.github.com/en/authentication).

To contribute code improvements or new features, follow these steps:

1. [Fork this repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo?tool=webui) to your GitHub account.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/WP3-P3-md-workflow.git
   ```
3. Create a new branch for your work:
   ```bash
   git switch -c feat-branch-name
   ```
4. Make your changes and commit them with clear messages:
   ```bash
   git add .
   git commit -m "Describe your changes"
   ```
5. Push your branch to your fork:
   ```bash
   git push origin feat-branch-name
   ```
6. Open a Pull Request (PR) to the [main repo’s default branch](https://github.com/GANANA-EU-INDIA/WP3-P3-md-workflow/pulls).
7. Wait for a review before merge.

### Python style

Python code uses the [`ruff` linter and formatter](https://docs.astral.sh/ruff/) in its defauilt configuration. This can be installed, used through a supported IDE, used with a container etc.

To ensure uniform style, format your code using:

```bash
ruff format path/to/file.py
```

to format `file.py`.

## Contribute to the documentation

Documentation is built with [MkDocs](https://www.mkdocs.org/) using the Material theme and hosted on GitHub Pages.
Documentation is built to be displayed both on GitHub and in a HTML form, hence graphical artifacs might be present.

### Preview locally

If using [`uv`](https://docs.astral.sh/uv/):
```bash
uvx --with mkdocs-material mkdocs serve
```

otherwise

```bash
python -m venv .venv
. .venv/bin/activate
python -m pip install -r docs/requirements.txt
```

Then, open [http://127.0.0.1:8000](http://127.0.0.1:8000).

### Edit workflow

1. Edit `.md` files in `docs/`
2. Preview changes as described above
3. Commit and push — docs deploy automatically

### Style

- Use [Material alerts](https://squidfunk.github.io/mkdocs-material/reference/admonitions/#supported-types)
- Use GitHub Flavored Markdown (tables, code blocks)
- Keep filenames lowercase with underscores
- One `#` heading per file (becomes page title)
