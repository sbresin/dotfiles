{
  lib,
  pkgs,
  stdenvNoCC,
  nerd-font-patcher,
}:
stdenvNoCC.mkDerivation {
  pname = "dank-mono-nerd";
  version = "0.1";

  src = pkgs.sebe.dank-mono;

  nativeBuildInputs = [ nerd-font-patcher ];

  dontUnpack = true;
  dontConfigure = true;

  # Only patch Powerline + Powerline Extra glyphs into Dank Mono. These are the
  # chevron/arrow/rounded/diagonal separators (U+E0A0-E0A3, U+E0B0-E0D7) used by
  # statuslines (lualine, tmux, starship, etc.) that need to span the full cell
  # height and be vertically centered. Baking them into the primary font avoids
  # misalignment when rendered from a fallback font.
  #
  # All other Nerd Font icons (file types, Font Awesome, Codicons, etc.) are left
  # to the "Symbols Nerd Font Mono" fallback — they're small square glyphs that
  # don't suffer from alignment issues and can be scaled independently.
  #
  # --metrics TYPO:  prevents the patcher from redistributing the HHEA lineGap
  #                  (140 units) into ascent/descent, which would bloat the cell
  #                  height from 1200 to 1370. With TYPO, the effective line height
  #                  stays at 1200 — identical to the unpatched Dank Mono.
  buildPhase = ''
    runHook preBuild

    mkdir -p $TMPDIR/out
    for font in $src/share/fonts/opentype/*.otf; do
      nerd-font-patcher "$font" \
        --powerline \
        --powerlineextra \
        --mono \
        --adjust-line-height \
        --metrics TYPO \
        --outputdir $TMPDIR/out \
        --no-progressbars \
        --quiet
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 $TMPDIR/out/*.otf -t $out/share/fonts/opentype/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Dank Mono with Powerline glyphs patched in for proper vertical alignment";
    homepage = "https://philpl.gumroad.com/l/dank-mono";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}
