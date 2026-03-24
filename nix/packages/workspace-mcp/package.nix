{
  lib,
  stdenvNoCC,
  stdenv,
  python312,
  makeWrapper,
  autoPatchelfHook,
  zlib,
}:
let
  python = python312;
  pythonWithPip = python.withPackages (ps: [ ps.pip ]);
  version = "1.14.3";

  # Fixed-output derivation: download all wheels from PyPI
  deps = stdenvNoCC.mkDerivation {
    name = "workspace-mcp-deps-${version}";

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-ND0bIJvoTUnAFj3rNL+YqslgxJqKs/uELXsZ097n4kY=";

    nativeBuildInputs = [ pythonWithPip ];

    dontUnpack = true;

    buildPhase = ''
      export HOME=$TMPDIR
      pip download \
        --dest $out \
        --only-binary=:all: \
        --python-version 312 \
        --platform manylinux2014_x86_64 \
        --platform manylinux_2_17_x86_64 \
        --platform linux_x86_64 \
        --platform any \
        --implementation cp \
        --abi cp312 \
        --abi none \
        "workspace-mcp==${version}"
    '';

    dontInstall = true;
    dontFixup = true;
  };
in
stdenvNoCC.mkDerivation {
  pname = "workspace-mcp";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    pythonWithPip
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib # libstdc++
    zlib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/workspace-mcp $out/bin

    # Install all downloaded wheels into a single site-packages-like directory
    pip install \
      --target $out/lib/workspace-mcp \
      --no-index \
      --find-links ${deps} \
      --no-cache-dir \
      --no-deps \
      ${deps}/*.whl

    # Patch debug log path: write to XDG_STATE_HOME instead of the read-only Nix store
    ${python}/bin/python3 -c "
    import pathlib, re
    p = pathlib.Path('$out/lib/workspace-mcp/core/log_formatter.py')
    src = p.read_text()
    src = src.replace(
        'log_file_dir = os.path.dirname(os.path.abspath(__file__))',
        'log_file_dir = os.path.join(os.environ.get(\"XDG_STATE_HOME\", os.path.expanduser(\"~/.local/state\")), \"workspace-mcp\")',
    )
    src = src.replace(
        '# Go up one level since we' + chr(39) + 're in core/ subdirectory',
        '# Create log directory if needed',
    )
    src = src.replace(
        'log_file_dir = os.path.dirname(log_file_dir)',
        'os.makedirs(log_file_dir, exist_ok=True)',
    )
    p.write_text(src)
    "

    # Create wrapper that sets PYTHONPATH and invokes the entry point
    makeWrapper ${python}/bin/python3 $out/bin/workspace-mcp \
      --prefix PYTHONPATH : "$out/lib/workspace-mcp" \
      --add-flags "-c 'from main import main; main()'"

    runHook postInstall
  '';

  # autoPatchelf runs during fixup on $out, patching any manylinux .so files

  meta = with lib; {
    description = "Google Workspace MCP server for Calendar, Gmail, Drive, Docs, Sheets & more";
    homepage = "https://workspacemcp.com";
    license = licenses.mit;
    mainProgram = "workspace-mcp";
  };
}
