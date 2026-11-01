# Run Codex in Docker container
[arg("args", help="Command arguments")]
codex *args:
    @docker compose run --rm codex {{ args }}

# Run Claude in Docker container
[arg("args", help="Command arguments")]
claude *args:
    @docker compose run --rm claude {{ args }}
