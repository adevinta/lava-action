# Lava Action

This action runs [Lava][lava] in your GitHub Actions workflows.

Lava is an open source vulnerability scanner that makes it easy to run
security checks in your local and CI/CD environments.

## Usage

Create a file with the name `.github/workflows/lava.yaml` and the
following content in your repository.

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
      - name: Run Lava Action
        uses: adevinta/lava-action@v0
```

## Settings

### Pinning a Lava version

The `version` input parameter specifies the version of Lava to use.

```yaml
- name: Run Lava Action
  uses: adevinta/lava-action@v0
  with:
    version: latest
```

### Providing a Lava configuration file

The `config` input parameter specifies the path of the configuration
file passed to Lava.
The path is relative to the root of the repository.

```yaml
- name: Run Lava Action
  uses: adevinta/lava-action@v0
  with:
    config: lava.yaml
```

If the parameter is missing the action will use an existing `lava.yaml` file,
or the [default.yaml] otherwhise.

```yaml
- name: Run Lava Action
  uses: adevinta/lava-action@v0
```

### Disabling commenting pull requests

The `comment-pr` input parameter specifies if the action generates a comment on
the pull request with a summary of the findings.
The `pull_request: write` permission is required.
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
      pull_request: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      - name: Run Lava Action
        uses: adevinta/lava-action@v0
        with:
          comment-pr: "true"
```

## Contributing

**This project is in an early stage, we are not accepting external
contributions yet.**

To contribute, please read the [contribution
guidelines][contributing].


[lava]: https://github.com/adevinta/lava
[contributing]: /CONTRIBUTING.md
[default.yaml]: /default.yaml
