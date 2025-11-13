# Non-flake compatibility wrapper
# Allows using this package without flakes enabled
# Usage: nix-build -A temporal

(import (
  fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
    sha256 = "0jm6nzb83wa6ai17ly9fzpqc40wg1viib8klq8lby54agpl213w5";
  }
) {
  src = ./.;
}).defaultNix
