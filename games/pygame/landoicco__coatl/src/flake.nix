{
  description = "Coatl - A classic Snake game made with Python and Pygame-CE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Change to "aarch64-linux" if you are developing on an ARM machine
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          # GitHub CLI for repository management
          pkgs.gh

          # Python development environment with pinned dependencies matching pyproject.toml
          (pkgs.python3.withPackages (ps: [
            ps.pygame-ce   # Optimized community edition of Pygame (recommended for NixOS)
            ps.pyinstaller # For compiling the game into a standalone binary
            ps.ruff        # Fast linter and formatter declared in your dev-dependencies
          ]))
        ];

        shellHook = ''
          echo "🐍 Welcome to the Coatl development environment!"
          echo "================================================="
          echo " 🎮 Pygame:      Ready to build!"
          echo " ⚡ Python:      $(python3 --version)"
          echo " 🛠️  Ruff:        $(ruff --version)"
          echo " 📦 PyInstaller: Enabled"
          echo " 🐙 GitHub CLI:  $(gh --version | head -n 1)"
          echo "================================================="
          echo "🚀 Run your game using: python src/main.py"
        '';
      };
    };
}
