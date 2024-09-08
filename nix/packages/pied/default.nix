{
  lib,
  pkgs,
  flutter,
  ...
}:
flutter.buildFlutterApplication {
  pname = "pied";
  version = "0.2.1";

  # src = pkgs.fetchFromGitHub {
  #   owner = "Elleo";
  #   repo = "pied";
  #   rev = "c91e2093d50cccb3692afb4cfe175265c6c1007d";
  #   sha256 = "sha256-3H5GHPaa7Dxtowjk6LpXxomif1AGtkI6joET5sE0njY=";
  # };

  src = pkgs.fetchFromGitHub {
    owner = "Elleo";
    repo = "pied";
    rev = "4e3ed06f9fe89e6ab69475cdb91c4a1e99473f0e";
    sha256 = "sha256-RGJBXIZ0ihL8ohk4m4Y6dkGzjhXE2fxtGTq7E6IhyeA=";
  };

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  nativeBuildInputs = with pkgs; [libunwind orc];
  buildInputs = with pkgs; [gst_all_1.gstreamer gst_all_1.gst-plugins-base];

  # buildPhase = ''
  #   cmake --build ./linux/ --target=install --config=Release
  # '';
  # installPhase = "mkdir -p $out/bin; install -t $out/bin foo";

  # installPhase = "mkdir -p $out/bin;";
}
