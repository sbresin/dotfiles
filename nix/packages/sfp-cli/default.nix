{
  lib,
  fetchFromGitHub,
  npmHooks,
  buildNpmPackage,
  nodejs_22,
  apple-sdk,
  stdenv,
}:
let
  version = "39.8.0";
in
buildNpmPackage {
  inherit version;
  pname = "sfp-cli";

  src = fetchFromGitHub {
    owner = "flxbl-io";
    repo = "sfp";
    rev = "refs/tags/v${version}";
    hash = "sha256-ilbmbvCLaTFfpRJ+1b/QK7qGryxu8eVgBmu9RrFXhjQ=";
  };

  patches = [
    # ./add-plugins-plugin.patch
  ];
  # sha256-uY7C+5G5Uh9UwIWuhrsdSRfSevfp7zcU4Q7ELgpgRmg=
  npmDepsHash = "sha256-vmPaRqNeD1NNT6wprcWpIDeiY+bbsrzzs8TlIkzqsdA=";

  nodejs = nodejs_22;

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ apple-sdk ];

  # workaround to use the same nodejs version in the wrapper as the one used in the install script
  npmInstallHook =
    (npmHooks.override (previous: {
      nodejsInstallExecutables = previous.nodejsInstallExecutables.override {
        nodejs = nodejs_22;
      };
    })).npmInstallHook;

  meta = with lib; {
    description = "A build system for modular development in Salesforce";
    homepage = "docs.flxbl.io/sfp";
    longDescription = ''
      sfp is an purpose built cli based tool specifically designed for modular Salesforce development and release management.
      sfp is aimed at streamlining and automating the build, test, and deployment processes of Salesforce metadata, code and data.
      It extends sf cli functionalities, focusing on artifact-driven development to enhance DevOps practices within Salesforce projects.
    '';
    license = licenses.mit;
    # maintainers = with maintainers; [ sbresin ];
    mainProgram = "sfp";
  };
}
