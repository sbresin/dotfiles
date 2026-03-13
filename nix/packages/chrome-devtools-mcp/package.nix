{
  lib,
  fetchurl,
  nodejs_22,
  makeWrapper,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "chrome-devtools-mcp";
  version = "0.20.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha512-wBnt8901lAXdac3AB7WdONYTAXGW+YqqIVVg7PztxYVNPs3VVgM2UZnZT/ICYPIofKTuRBOkRdEE/VYm90ZgYA==";
  };

  sourceRoot = "package";
  dontBuild = true;

  nativeBuildInputs = [makeWrapper];

  # Disable telemetry by default
  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/${pname} $out/bin
    cp -r build LICENSE package.json $out/libexec/${pname}/

    makeWrapper ${nodejs_22}/bin/node $out/bin/chrome-devtools-mcp \
      --add-flags $out/libexec/${pname}/build/src/bin/chrome-devtools-mcp.js \
      --set CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS "1"

    makeWrapper ${nodejs_22}/bin/node $out/bin/chrome-devtools \
      --add-flags $out/libexec/${pname}/build/src/bin/chrome-devtools.js \
      --set CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS "1"

    runHook postInstall
  '';

  meta = with lib; {
    description = "MCP server for Chrome DevTools - enables AI assistants to control Chrome";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
  };
}
