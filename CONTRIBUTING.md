# Contributing to Bonfire

Thanks for your interest in contributing to Bonfire! This document describes the conventions we follow to keep the repository healthy and predictable.

## Branching Strategy

We use a simple trunk-based flow. All work happens on short-lived branches that merge back into `main` via pull requests.

* Feature work must branch from `main` using the pattern `feature/<summary>`.
* Bug fixes must branch from `main` using the pattern `fix/<issue-id-or-summary>`.
* Maintenance or chore tasks can use `chore/<summary>` if needed.

Before opening a pull request, make sure your branch is up to date with `main` and that you have resolved any merge conflicts locally.

## Commit Messages

Please keep commits focused and descriptive. We follow a lightweight conventional style:

```
<type>: <short summary>
```

Where `type` is one of `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, or `ci`. The summary should be written in the imperative mood (e.g., "add tab bar layout"). When necessary, include additional context in the commit body separated by a blank line.

## Pull Requests

* Ensure the project builds and passes all available tests before submitting a PR.
* Provide a clear description of the change, including screenshots or recordings when UI changes are involved.
* Reference any related issues and describe testing performed.

Thank you for helping us build Bonfire!
