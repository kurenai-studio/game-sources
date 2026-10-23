# Pull Request

A checklist for change class, behavior, safeguards, and audit records.

## What this changes

<!-- One or two sentences on what changes and why. -->

## Class

<!-- See "Rules for changes" in REQUIREMENTS.md. Tick every class that applies. -->

* [ ] **Refactor:** game code changes, behavior does not. Requirement entries are unchanged and the tests pass; tests change only to follow renamed or moved code.
* [ ] **Bug Fix:** game code is brought back in line with an existing requirement. Which requirement, and which test failed before the fix?
* [ ] **Intentional Change:** behavior is added, changed or removed. Which requirement entries changed in the same commit, and which tests now check them?
* [ ] **Clarification:** requirement entries now describe behavior the game already has. Which entries, and which tests check them?
* [ ] **No Class Needed:** no game code (`public/`) and no requirement entries change. The three rules still apply.

## Review questions

* **Behavior:** does this change what the player sees, does, saves or can load? If so, which requirement entries changed in the same commit?
* **Protection:** does this loosen, remove or move a runtime check, or a test that proves one works? If so, which requirement change allows it and what replaces it, or which test proves the same input still gets the same outcome at the same boundary? Types don't count.
* **Gates:** does this lower or remove a gate in QA-1 to QA-6? That is not allowed.
* **Description:** is any new behavior described by a requirement entry and a test? Behavior that isn't has no guarantee.
* **Audit:** does this confirm, fix or reject a finding, or make a verification decision? If so, record it in DECISIONS.md in the same pull request.
