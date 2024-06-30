{
  description = "My CV";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    latex-cv-class.url = "github:Cybolic/latex-cv-class";
  };

  outputs = { self, nixpkgs, flake-utils, latex-cv-class }:
    with flake-utils.lib; eachSystem allSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        cvBuildPkgs = latex-cv-class.packages.${system};
      in rec{
        packages = {

          pdf = cvBuildPkgs.yamlToPdf {
            inputYaml = ./resume.yaml;
          };

          lint = pkgs.writeShellApplication {
            name = "lint";
            runtimeInputs = [ cvBuildPkgs.lint ];
            text = /* bash */ ''
              lintYaml ./resume.yaml
            '';
          };

        };
        defaultPackage = packages.pdf;
      }
    );
}
