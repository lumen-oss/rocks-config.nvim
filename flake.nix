{
  description = "Allow lux.nvim to help configure your plugins";

  nixConfig = {
    extra-substituters = "https://lumen-labs.cachix.org";
    extra-trusted-public-keys = "lumen-labs.cachix.org-1:WmGwJxPmN6cIqKJHYTq/C1WIaqIUneH+t+BAT34Qag0=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lux.url = "github:lumen-oss/lux";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {self, ...}: let
    foreach = xs: f:
      with inputs.nixpkgs.lib;
        foldr recursiveUpdate {} (
          if isList xs
          then map f xs
          else if isAttrs xs
          then mapAttrsToList f xs
          else throw "foreach: expected list or attrset but got ${typeOf xs}"
        );
  in
    foreach inputs.nixpkgs.legacyPackages (
      system: pkgs: let
        pkgs = inputs.nixpkgs.legacyPackages.${system}.extend inputs.lux.overlays.default;

        pre-commit-check = inputs.git-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            stylua.enable = true;
            luacheck.enable = true;
            editorconfig-checker.enable = true;
            panvimdoc = {
              enable = true;
              name = "panvimdoc";
              entry = "${pkgs.panvimdoc}/bin/panvimdoc --project-name lux-config --toc true --treesitter true --demojify true --description ' Configure Neovim plugins from lux.toml ' --input-file";
              files = "docs/.*\\.md$";
            };
          };
        };
      in {
        devShells.${system}.default = pkgs.mkShell {
          name = "lux-config.nvim-devShell";
          buildInputs = with pkgs; [
            lux-cli
            luajit
            rustc
            cargo
            stylua
            lua52Packages.luacheck
            emmylua-ls
          ];
          shellHook = ''
            ${pre-commit-check.shellHook}
            if command -v nvim >/dev/null 2>&1; then
              export VIMRUNTIME="$(nvim --clean --headless -c 'lua io.write(vim.env.VIMRUNTIME)' +q)";
            else
              export VIMRUNTIME="${pkgs.neovim-unwrapped}/share/nvim/runtime";
            fi
          '';
        };
      }
    );
}
