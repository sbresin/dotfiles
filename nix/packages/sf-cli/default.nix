{
  lib,
  pkgs,
  stdenvNoCC,
  writeShellScript,
  ...
}: let
  # the original launch scripts redirects to the updated node executable, but we only want the updated JS
  launchScript = writeShellScript "sf" ''
    set -e
    echoerr() { echo "$@" 1>&2; }

    DIR="@out@/bin"

    CLI_HOME=$(cd && pwd)
    XDG_DATA_HOME=''${XDG_DATA_HOME:="$CLI_HOME/.local/share"}
    CLIENT_HOME=''${SF_OCLIF_CLIENT_HOME:=$XDG_DATA_HOME/sf/client}
    RUN_DIR="$CLIENT_HOME/current/bin"
    SF_REDIRECTED=0
    if [[ -x "$RUN_DIR" ]]; then
      DIR=$RUN_DIR
      SF_REDIRECTED=1
    fi

    NODE="${pkgs.nodejs_20}/bin/node"

    if [ "$DEBUG" == "*" ]; then
      echoerr "$NODE" "$DIR/run" "$@"
    fi

    SF_BINPATH="$DIR" SF_REDIRECTED="$SF_REDIRECTED" "$NODE" "$DIR/run" "$@"
  '';
in
  stdenvNoCC.mkDerivation {
    pname = "sf-cli";
    version = "2.57.7";

    src = pkgs.fetchurl {
      url = "https://developer.salesforce.com/media/salesforce-cli/sf/versions/2.57.7/291554e/sf-v2.57.7-291554e-linux-x64.tar.gz";
      hash = "sha256-N80ZXnM+aJDP61iEulH6ojYIZpTHgt+W44PJ3cJGbuo=";
    };

    installPhase = ''
      mkdir $out
      cp -R ./* "$out/"
      rm "$out/bin/node"
      install -D ${launchScript} "$out/bin/sf"
      substituteInPlace "$out/bin/sf" --subst-var out
      ln -fs "$out/bin/sf" "$out/bin/sfdx"
    '';

    meta = {
      description = "Salesforce CLI is a command-line interface that simplifies development and build automation when working with your Salesforce org.";
      homepage = "https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm";
      license = lib.licenses.bsd3;
      # maintainers = with lib.maintainers; [ "sbresin" ];
    };
  }
