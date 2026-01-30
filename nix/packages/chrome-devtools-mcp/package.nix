{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage rec {
  pname = "chrome-devtools-mcp";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "ChromeDevTools";
    repo = "chrome-devtools-mcp";
    rev = "chrome-devtools-mcp-v${version}";
    hash = "sha256-IcnphWQDjf+VQkhPJgtreeKtEkXDyD3WcLXYoX3OoqM=";
  };

  npmDepsHash = "sha256-e/xB+PRExG32b36unPix2lq2jLp7LsgezdZcZuBbJTo=";

  nodejs = nodejs_22;

  # Skip Puppeteer's Chrome download - we connect to external browser
  env = {
    PUPPETEER_SKIP_DOWNLOAD = "1";
  };

  nativeBuildInputs = [makeWrapper];

  # Use "bundle" instead of "build" - this runs rollup to bundle all dependencies
  # into a single file, which is required for the package to work standalone
  npmBuildScript = "bundle";

  # Disable telemetry by default
  postInstall = ''
    wrapProgram $out/bin/chrome-devtools-mcp \
      --set CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS "1"
  '';

  meta = with lib; {
    description = "MCP server for Chrome DevTools - enables AI assistants to control Chrome";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    license = licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
  };
}
