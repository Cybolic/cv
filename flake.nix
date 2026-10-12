{
  description = "My CV";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = nixpkgs.lib.systems.flakeExposed;
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
      withSystemPkgs = fun: forAllSystems (system: let
        pkgs = nixpkgsFor.${system};
      in fun { inherit system pkgs; });

      mkFonts = pkgs: pkgs.symlinkJoin {
        name = "typst-fonts";
        paths = [
          # pkgs.iosevka
          # pkgs.inconsolata-nerdfont
          pkgs.lato
        ];
      };

      packages = withSystemPkgs ({ pkgs, ... }:
        let
          vale = import ./lint.nix { inherit pkgs; };
          fonts = mkFonts pkgs;

          lint = pkgs.writeShellApplication {
            name = "lint";
            text = ''
              ${vale}/bin/vale-custom ./resume.yaml
            '';
          };

          typst-cv = pkgs.writeShellApplication {
            name = "typst-cv";
            runtimeInputs = [ pkgs.typst ];
            text = ''
              if (($# == 0)); then
                echo "Missing file argument" >&2
                exit 1
              fi
              FILE=$1; shift
              YAML_FILE="''${CV_YAML_FILE:-resume.yaml}"
              LANGUAGE="''${CV_LANG:-en}"
              typst "$FILE" \
                --root ./ \
                --creation-timestamp="$(date '+%s')" \
                --font-path ${fonts} \
                --input "yaml-file=/$YAML_FILE" \
                --input "language=$LANGUAGE" \
                typst/main.typ \
                "$@"
            '';
          };

          watch = pkgs.writeShellApplication {
            name = "typst-cv-watch";
            text = ''
              PDF_FILE="''${3:-typst-cv.pdf}"
              ${typst-cv}/bin/typst-cv watch "$PDF_FILE"
            '';
          };

          pdf = pkgs.stdenv.mkDerivation {
            name = "build-typst-pdfs";
            buildInputs = [ pkgs.typst ];
            phases = "installPhase";
            installPhase = ''
              cp ${./resume.yaml} resume.yaml
              cp -a ${./typst} typst
              mkdir -p $out

              export CV_LANG=en
              ${typst-cv}/bin/typst-cv compile \
                $out/cv-christian-dannie-storgaard.pdf
              export CV_LANG=da
              ${typst-cv}/bin/typst-cv compile \
                $out/cv-christian-dannie-storgaard-da.pdf
            '';
          };
        in {
          inherit vale lint typst-cv watch pdf;
        }
      );
    in {
      inherit packages;

      defaultPackage = forAllSystems (system:
        packages.${system}.pdf
      );

      devShells = withSystemPkgs ({ pkgs, system }: {
        default = pkgs.mkShell {
          buildInputs = [
            packages.${system}.vale
            packages.${system}.typst-cv
            packages.${system}.watch
            pkgs.typst
            pkgs.yq
          ];
        };
      });
    };
}
