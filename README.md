# Lava Action

This action runs [Lava] in your GitHub Actions workflows.

Lava is an open source vulnerability scanner that makes it easy to run
security checks in your local and CI/CD environments.

## Usage

Create a new workflow with the following content in your GitHub
repository.

```yaml
name: Lava
on: [push, pull_request]
jobs:
  lava:
    name: Lava
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      - name: Run Lava
        uses: adevinta/lava-action@v0
```

You can also add the following steps to any existing job:

```yaml
steps:
  - name: Checkout repository
    uses: actions/checkout@v4
  - name: Run Lava
    uses: adevinta/lava-action@v0
```

Refer to the [GitHub Actions documentation] for more information about
GitHub Actions workflows.

## Settings

### Pinning a Lava version

The `version` input parameter specifies the version of Lava to use.
The default value is `latest`.

```yaml
- name: Run Lava
  uses: adevinta/lava-action@v0
  with:
    version: latest
```

### Providing a Lava configuration file

The `config` input parameter specifies the path of the configuration
file passed to Lava.
The path is relative to the root of the repository.

```yaml
- name: Run Lava
  uses: adevinta/lava-action@v0
  with:
    config: lava.yaml
```

If the `config` input parameter is not specified, the action will try
to find a `lava.yaml` file in the root of the repository.
If it does not exist, [default.yaml] will be used.

```yaml
- name: Run Lava
  uses: adevinta/lava-action@v0
```

### Enabling pull request comments

The `comment-pr` input parameter specifies whether the action should
post a comment on the pull request with a summary of the findings.
The `pull-requests: write` permission is required.
The default value is `false`.

```yaml
name: Lava
on: [push, pull_request]
jobs:
  lava:
    name: Lava
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      - name: Run Lava
        uses: adevinta/lava-action@v0
        with:
          comment-pr: "true"
```

## Contributing

**This project is in an early stage, we are not accepting external
contributions yet.**

To contribute, please read the [contribution guidelines].


[Lava]: https://github.com/adevinta/lava
[GitHub Actions documentation]: https://docs.github.com/en/actions
[default.yaml]: /default.yaml
[contribution guidelines]: /CONTRIBUTING.md
