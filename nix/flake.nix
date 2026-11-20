{
  description = "IronCalc, lilith fork: engine performance work and the WASM build for lilith_ui_vue";

  inputs = {
    pins.url = "path:/etc/nixos/pins";
    nixpkgs.follows = "pins/nixpkgs";
  };

  outputs =
    inputs@{
      self,
      pins,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # One package from unstable, on purpose: wasm-bindgen-cli must equal the crate's locked
      # wasm-bindgen exactly (Cargo.lock: 0.2.129), and stable carries up to 0.2.126.
      # Changing Cargo.lock instead would break rebasing onto upstream (DESIGN.md "Upstream").
      # When upstream bumps wasm-bindgen, bump this attribute to match.
      unstable = pins.inputs.nixpkgs-unstable.legacyPackages.${system};

      rust = with pkgs; [
        rustc
        cargo
        clippy
        rustfmt
      ];

      wasm = [
        unstable.wasm-bindgen-cli_0_2_129
        pkgs.binaryen
      ];

      coverage = [ pkgs.cargo-llvm-cov ];

      tools = with pkgs; [ nushell ];

      llvm = pkgs.rustc.llvmPackages.llvm;
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = rust ++ wasm ++ coverage ++ tools;

        # Cargo's registry and git checkouts go to the allowed cache scope, not ~/.cargo.
        CARGO_HOME = "/media/luna/work/cache/ironcalc_cache/cargo";
        # cargo-llvm-cov needs llvm-cov / llvm-profdata from the LLVM rustc was built with.
        LLVM_COV = "${llvm}/bin/llvm-cov";
        LLVM_PROFDATA = "${llvm}/bin/llvm-profdata";

        shellHook = ''
          echo "ironcalc (lilith fork) dev shell"
          echo "  rustc:        $(rustc --version)"
          echo "  wasm-bindgen: $(wasm-bindgen --version)"
          echo "  wasm-opt:     $(wasm-opt --version)"
          echo "  CARGO_HOME:   $CARGO_HOME"
          echo "  LLVM_COV:     $LLVM_COV"
          echo "  build WASM:   nu develop/build-wasm.nu (not written yet)"
        '';
      };
    };
}
