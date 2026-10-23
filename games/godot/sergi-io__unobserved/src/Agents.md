# Agents Guide

## Project Overview

This repository contains the Godot project **Unobserved**.

- Engine target: Godot `4.6`
- Main scene: `res://scenes/galaxy.tscn`
- Root node: `Galaxy` (`Node2D`)
- Viewport: `1600x900`
- Renderer: Mobile rendering method
- Physics: Jolt Physics

The project is currently minimal. Prefer small, explicit changes that keep the structure easy to grow.

## Repository Layout

- `project.godot` - Godot project configuration. Prefer editing this through Godot unless a targeted text change is clearly safe.
- `scenes/` - Scene files. Keep scene names lowercase with descriptive nouns unless the project establishes another convention.
- `icon.svg` - Project icon.
- `.godot/` - Generated editor/cache data. Do not edit or commit this directory unless there is a deliberate project policy requiring it.

## Development Commands

Whenever possible use MCP: godot-ai for interacting with Godot.

Additionally use the installed Godot 4.6 binary for local validation.

```sh
godot --headless --path . --quit
```

If the `godot` command is not on `PATH`, use the local Godot application binary directly.

Always run Godot outside the sandbox.

```sh
/../../Godot.app/Contents/MacOS/Godot --headless --path /Users/sortegam/Projects/Godot/projects/unobserved --quit
```

Run the project from the editor when visual or interaction behavior needs verification.

## Editing Guidelines

- Always work in English.
- Preserve Godot resource paths in `res://...` form.
- Avoid manual scene rewrites when a focused editor operation or small text patch is safer.
- Keep generated UIDs and scene metadata intact unless intentionally creating or replacing resources.
- Use ASCII for new text unless the project file already requires otherwise.
- Keep new scripts and scenes organized by feature once the project grows, rather than placing all files at the root.
- Do not modify generated import/cache files such as `.import` files or `.godot/` contents without a clear reason.

## GDScript Conventions

When adding scripts:

- Use Godot 4 typed GDScript where it improves clarity.
- Prefer `@export` properties for tunable gameplay/editor values.
- Keep node paths and scene references resilient; avoid brittle absolute paths when a local exported reference or `%UniqueName` is clearer.
- Keep `_process` and `_physics_process` work minimal and deterministic.
- Name files in `snake_case.gd`.
- Name classes and scene root nodes in `PascalCase`.

## Validation Checklist

Before handing off changes:

1. Confirm the project loads headlessly without errors.
2. Do not open affected scenes in Godot.
3. Do not run any relevant gameplay path manually if interaction logic changed.
4. Check that generated files were not edited accidentally.
5. Do not summarize the changes.

## Agent Workflow

- Inspect existing files before making assumptions about structure or conventions.
- Keep changes scoped to the requested task.
- Do not revert user changes.
- If the workspace is not a Git repository, state that when reporting verification or change status.
- Ask before taking destructive actions such as deleting assets, replacing scenes wholesale, or resetting generated data.
- Do not generate tests or scripts to check the behavior after implementation.
