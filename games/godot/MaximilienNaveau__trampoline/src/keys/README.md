The Android debug signing key used by `nix build .#android` (see
../flake.nix). Not a secret: its password is the usual "android", and it
only signs test builds, so each one installs over the previous one. A
release key must never be stored here.
(The empty .gdignore beside this file tells Godot to skip the folder.)
