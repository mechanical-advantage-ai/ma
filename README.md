# Mechanical Advantage CLI Toolkit

The agent-first CLI toolkit for [Mechanical Advantage](https://mechanical-advantage.ai). Every outbound action queues for human approval — the agent proposes, the human decides.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/mechanical-advantage-ai/ma/main/install.sh | sh
```

This installs the `ma` binary to `~/.ma/bin` and adds it to your PATH. Restart your shell after installation.

## Supported platforms

- macOS (Apple Silicon & Intel)
- Linux (amd64 & arm64)
- Windows (amd64 & arm64)

## Usage

```sh
ma --help
```

## Updating

The CLI automatically checks for updates and installs them on the next run. You can also update manually:

```sh
ma update
```
