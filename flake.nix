{
  description = "Golden tests for command-line interfaces.";

  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.idris = {
    url = github:teto/Idris2/fix-flake;
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, idris, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      npkgs = import nixpkgs { inherit system; };
      idrisPkgs = idris.packages.${system};
      buildIdris = idris.buildIdris.${system};
      pkgs = buildIdris {
        projectName = "replica";
        src = ./.;
        idrisLibraries = [];
        patchPhase = ''
          # I haven't tested this, might have escaped incorrectly
          sed "s/\`git describe --tags\`/v0.4.0-${self.shortRev or "dirty"}/" -i Makefile
        '';
        # targets = "build";
        # preBuild=''
        #   make src/Replica/Version.idr
        # '';
        preBuild = ''
          make
        '';

      };
    in rec {
      packages = pkgs // idrisPkgs;
      defaultPackage = pkgs.build;
      devShell = npkgs.mkShell {
        buildInputs = [ idrisPkgs.idris2 npkgs.rlwrap ];
        shellHook = ''
          alias idris2="rlwrap -s 1000 idris2 --no-banner"
        '';
      };
    }
  );
}
