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

        resumeShortYaml = pkgs.runCommand "processed-resume.yaml" {
          buildInputs = [ pkgs.yq-go ];
        } ''
          # Remove:
          # - `projects`
          # _ my initial project based position at TrainAway (we don't need two positions for the same company)
          # - my initial frontend position at Anthill
          yq 'del(.projects) | .work |= map(select(.startDate != "2017-04-11" and .startDate != "2011-11-16"))' ${./resume.yaml} > $out
        '';
      in rec{
        packages = {

          pdfFull = cvBuildPkgs.yamlToPdf {
            inputYaml = ./resume.yaml;
          };

          pdf = cvBuildPkgs.yamlToPdf {
            inputYaml = resumeShortYaml;
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
