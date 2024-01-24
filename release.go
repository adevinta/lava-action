// Copyright 2024 Adevinta

/*
Release publishes a new GitHub release.

It expects an environment variable with the name GITHUB_REF_NAME. The
value of GITHUB_REF_NAME must be a git tag with a valid semantic
version (e.g. v1.2.3).

For a given tag, it creates three releases:

  - vMAJOR
  - vMAJOR.MINOR
  - vMAJOR.MINOR.PATCH

If the version in the tag name corresponds to a prerelease, only
vMAJOR.MINOR.PATCH-PRERELEASE is created.

For instance, if the tag is v1.2.3, the following releases will be
created:

  - v1     (updated if it already exists)
  - v1.2   (updated if it already exists)
  - v1.2.3

This release schema allows users to pin versions depending on their
needs. In other words,

  - v1.2.3  :=  ==v1.2.3
  - v1.2    :=  >=v1.2.0, <v1.3.0
  - v1      :=  >=v1.0.0, <v2.0.0
  - v0.2.3  :=  ==v0.2.3
  - v0.2    :=  >=v0.2.0, <v0.3.0
  - v0      :=  >=v0.0.0, <v1.0.0
*/
package main

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"

	"golang.org/x/mod/semver"
)

func main() {
	log.SetFlags(0)

	refName := os.Getenv("GITHUB_REF_NAME")
	if refName == "" {
		log.Fatalf("error: missing env var GITHUB_REF_NAME")
	}

	if !semver.IsValid(refName) {
		log.Fatalf("error: invalid version %q", refName)
	}

	hash, err := gitHash(refName)
	if err != nil {
		log.Fatalf("error: get hash: %v", err)
	}

	var releases []string

	// Do not create vMAJOR and vMAJOR.MINOR for pre-releases.
	if semver.Prerelease(refName) == "" {
		releases = []string{semver.Major(refName), semver.MajorMinor(refName)}
	}

	releases = append(releases, refName)

	for _, r := range releases {
		// Do not update vMAJOR.MINOR.PATCH.
		update := r != refName

		if err := ghRelease(r, hash, update); err != nil {
			log.Fatalf("error: create GitHub release %q: %v", r, err)
		}
	}
}

// gitHash returns the hash corresponding to the specified reference
// using "git show-ref".
func gitHash(ref string) (string, error) {
	hash, err := cmdOutput("git", "show-ref", "--hash", ref)
	if err != nil {
		return "", fmt.Errorf("git show-ref: %w", err)
	}
	return hash, nil
}

// ghRelease creates a GitHub release using "gh release". If update is
// true, it first tries to delete any existing release with the same
// tag.
func ghRelease(tag, target string, update bool) error {
	if update {
		if _, err := cmdOutput("gh", "release", "delete", "--cleanup-tag", "--yes", tag); err != nil {
			log.Printf("warn: could not delete release %q", tag)
		}

		// BUG(rm): If a release is deleted and then created
		// again to update its reference, the new release is
		// created as draft. This happens because of a race
		// condition on the GitHub side.
		//
		// A 30s delay should mitigate the issue while it is
		// not fixed by GitHub.
		//
		// For more information, see
		// https://github.com/cli/cli/issues/8458
		time.Sleep(30 * time.Second)
	}

	args := []string{"release", "create", "--target", target, tag}
	if _, err := cmdOutput("gh", args...); err != nil {
		return fmt.Errorf("gh release create: %w", err)
	}

	return nil
}

// cmdOutput runs the specified command and returns its standard
// output. The returned output is trimmed. In case of error, it
// returns stderr along with the error.
func cmdOutput(name string, arg ...string) (string, error) {
	stderr := &bytes.Buffer{}
	cmd := exec.Command(name, arg...)
	cmd.Stderr = stderr
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("cmd output: %w: %#q", err, stderr)
	}
	return strings.TrimSpace(string(out)), nil
}
