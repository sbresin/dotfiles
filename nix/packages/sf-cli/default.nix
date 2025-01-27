{
  lib,
  nodejs_22,
  fetchurl,
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

    NODE="${nodejs_22}/bin/node"

    if [ "$DEBUG" == "*" ]; then
      echoerr "$NODE" "$DIR/run" "$@"
    fi

    SF_BINPATH="$DIR" SF_REDIRECTED="$SF_REDIRECTED" "$NODE" --no-deprecation "$DIR/run" "$@"
  '';
in
  stdenvNoCC.mkDerivation {
    pname = "sf-cli";
    version = "2.71.6";

    # TODO: install from npm instead, but set SF_INSTALLER, so auto updates work
    src = fetchurl {
      url = "https://developer.salesforce.com/media/salesforce-cli/sf/versions/2.71.6/df87f59/sf-v2.71.6-df87f59-linux-x64.tar.xz";
      hash = "sha256-8l4Vu+WAwHPBdTBYTZn86+mRP9lm/xCIvU0ihfLJ94k=";
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
