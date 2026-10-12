{ pkgs, ... }:
let
  accept = [
    "APIs?"
    "[Aa]gentic"
    "[Aa]nthropic('s)?"
    "[Aa]rchitect(ed)?"
    "[Dd]emoable"
    "[Dd]ev"
    "[Oo]nboarding"
    "[Pp]olyfills?"
    "TypeScript"
    "calc" "flexbox"
    "Cockos"
    "Cordova"
    "CDLow"
    "transmediale"
    "sourcehut"
    "(?i)cutscenes?"
    "(?i)ol"
    "(?i)themeable"
    "(?i)impactful"
  ];
  reject = [];
  extractAcceptedWords = let
    script = pkgs.writeText "jq-script" /* jq */ ''
      [
        (.basics.name | split(" ")[]),
        (.references[]?.name | split(" ")[]),

        (.work[]?.companies[]?),
        (.work[]?.keywords[]? | split(" / ")[]),
        (.work[]?.ATSkeywords[]? | split(" / ")[]),
        (.skills[]?.keywords[]? | split(" / ")[])
      ] | flatten | unique | map( gsub("\\((?<x>.*?)\\)"; "\(.x)") ) | .[] | select(length > 1)
    '';
  in pkgs.writeShellApplication {
    name = "extract-accepted-words-from-resume";
    runtimeInputs = [ pkgs.yq ];
    text = ''
      yq --raw-output --from-file ${script} resume.yaml
    '';
  };
  vocab = (let
    acceptFile = pkgs.writeTextFile {
      name = "vale-vocab-accept";
      destination = "/config/vocabularies/Nix/accept.txt";
      text = builtins.concatStringsSep "\n" accept;
    };
    rejectFile = pkgs.writeTextFile {
      name = "vale-vocab-reject";
      destination = "/config/vocabularies/Nix/reject.txt";
      text = builtins.concatStringsSep "\n" reject;
    };
  in
    pkgs.symlinkJoin {
      name = "vale-vocab";
      paths = [acceptFile rejectFile];
    }
  );
  config = pkgs.writeTextFile {
    name = "vale-config.ini";
    text = /* ini */ ''
      MinAlertLevel=warning
      Packages=proselint, Readability
      StylesPath=${pkgs.symlinkJoin {
        name = "vale-vocab";
        paths = [
          vocab
          pkgs.valeStyles.proselint
          pkgs.valeStyles.readability
        ];
        postBuild = ''
          for style in $out/share/vale/styles/*; do
            mv "$style" "$out/$(basename $style)"
          done
          rm -r $out/share
        '';
      }}
      Vocab=Nix

      [*]
      BasedOnStyles=Vale, proselint, Readability
    '';
  };
in pkgs.writeShellApplication {
  name = "vale-custom";
  runtimeInputs = [
    pkgs.vale
    pkgs.gnused
  ];
  text = ''
    INPUT_RESUME="''${1:-"resume.yaml"}"
    WORKDIR="$(readlink -f "$(dirname "$INPUT_RESUME")")"
    VALE_STYLES_PATH="$WORKDIR/.vale"
    rm -rf "$VALE_STYLES_PATH" || true
    mkdir -p "$VALE_STYLES_PATH"
    export VALE_STYLES_PATH

    mkdir -p "$VALE_STYLES_PATH/config/vocabularies/Nix"
    ${extractAcceptedWords}/bin/extract-accepted-words-from-resume "$INPUT_RESUME" \
      > "$VALE_STYLES_PATH/config/vocabularies/Nix/accept.txt"
    cat "${vocab + "/config/vocabularies/Nix/accept.txt"}" \
      >> "$VALE_STYLES_PATH/config/vocabularies/Nix/accept.txt"

    sed --in-place '/LESS/d' "$VALE_STYLES_PATH/config/vocabularies/Nix/accept.txt"

    TEMP_RESUME_DIR="$(mktemp -d)"
    TEMP_RESUME_YAML="$TEMP_RESUME_DIR/$(basename "$INPUT_RESUME")"
    # Create a copy of the resume with non-prose parts blanked (so line-numbers still match)
    cp "$INPUT_RESUME" "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*#.*//gm' "$TEMP_RESUME_YAML" # remove comments
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}url: .*$//gm' "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}archiveURL: .*$//gm' "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}email: .*$//gm' "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}location: .*$//gm' "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}address: .*$//gm' "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}network: .*$//gm' "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}url: .*$//gm' "$TEMP_RESUME_YAML"
    sed --in-place 's/^[ \t]*\(- \)\{0,1\}username: .*$//gm' "$TEMP_RESUME_YAML"

    # Blank out sections written by other people - we don't change their words
    awk '
    /^[ ]*reference:[ ]*[>|]/ {
      print ""
      base = match($0, /[^ ]/) - 1
      in_block = 1
      next
    }
    in_block {
      if ($0 ~ /^[ ]*$/ || match($0, /[^ ]/) - 1 > base) {
        print ""
        next
      }
      in_block = 0
    }
    { print }
    ' "$TEMP_RESUME_YAML" > "$TEMP_RESUME_YAML.tmp"
    mv "$TEMP_RESUME_YAML.tmp" "$TEMP_RESUME_YAML"

    sed --in-place 's/^[ \t]*\(- \)\{0,1\}[a-zA-Z0-9_-]\{1,\}: *\([>|]-\{0,1\}\)\{0,1\} *//gm' "$TEMP_RESUME_YAML" # remove key names

    exec vale --ignore-syntax --config="${config}" "$TEMP_RESUME_YAML" \
      | sed "s:$TEMP_RESUME_YAML:$INPUT_RESUME:g"
    RETVAL=$?
    rm -rf "$TEMP_RESUME_DIR"
    exit $RETVAL
  '';
}
