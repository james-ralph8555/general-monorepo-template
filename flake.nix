{
  description = "A polyglot monorepo with Bazel and Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bazel
            uv
            python314
            nodejs_24
            cargo
            rustc
            go
            protobuf
            awscli2
            git
            graphviz
          ];

          shellHook = ''
            echo "Entering polyglot monorepo environment with Bazel + Nix"
            echo "Available tools: bazel, uv, node, cargo, go, protoc, aws, dot"
            echo "Run 'bazel build //...' to build all targets"
            echo "Run 'bazel test //...' to run all tests"
          '';
        };
      }
    );
}
