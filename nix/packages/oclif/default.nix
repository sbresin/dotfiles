{
  stdenv,
  lib,
  fetchFromGitHub,
  fetchYarnDeps,
  makeWrapper,
  fixup-yarn-lock,
  nodejs_20,
  yarn,
}:
stdenv.mkDerivation rec {
  pname = "oclif";
  version = "4.4.21";

  src = fetchFromGitHub {
    owner = "oclif";
    repo = "oclif";
    rev = "refs/tags/${version}";
    hash = "sha256-xaRbsU4+iIrTSs79XGfgH0xZtfIgBFEITIrcDbHY9MY=";
  };

  nativeBuildInputs = [makeWrapper yarn fixup-yarn-lock];
  buildInputs = [nodejs_20];

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-BuMiN4T+SIF6hr5OPeEO6UwKUcIWetSZ2m84KkLXHkE=";
  };

  configurePhase = ''
    export HOME=$(mktemp -d)/yarn_home
  '';

  buildPhase = ''
    runHook preBuild

    yarn config --offline set yarn-offline-mirror $yarnOfflineCache
    fixup-yarn-lock yarn.lock

    yarn install --offline \
      --frozen-lockfile \
      --ignore-engines --ignore-scripts
    patchShebangs node_modules/
    yarn --offline build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/oclif
    mv bin lib node_modules package.json $out/share/oclif/

    node_modules=$out/share/oclif/node_modules
    bin=$out/share/oclif/bin

    makeWrapper ${nodejs_20}/bin/node $out/bin/oclif \
      --add-flags $bin/run.js \
      --set NODE_ENV production \
      --set NODE_PATH $node_modules \

    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI for generating, building, and releasing oclif CLIs";
    homepage = "https://oclif.io";
    longDescription = ''
      oclif is an open source framework for building a command line interface (CLI) in Node.js and Typescript.
      Create CLIs with a few flags or advanced CLIs that have subcommands.
      oclif makes it easy for you to build CLIs for your company, service, or your own development needs.
    '';
    license = licenses.mit;
    # maintainers = with maintainers; [ sbresin ];
    mainProgram = "oclif";
  };
}
