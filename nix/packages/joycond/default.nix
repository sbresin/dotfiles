{
  fetchFromGitHub,
  joycond,
}:
joycond.overrideAttrs (previousAttrs: {
  version = "unstable-2025-04-12";

  src = fetchFromGitHub {
    owner = "DanielOgorchock";
    repo = "joycond";
    rev = "39d5728d41b70840342ddc116a59125b337fbde2";
    sha256 = "sha256-VT433rrgZ6ltdXLQRjtjRy7rhMl1g9dan9SRqlsCPTk=";
  };

  patches = [./fix_sdl.patch];

  installPhase = ''
    mkdir -p $out/{bin,etc/{systemd/system,udev/rules.d},lib/modules-load.d}

    cp ./joycond $out/bin
    cp ../udev/{89,72}-joycond.rules $out/etc/udev/rules.d
    cp ../systemd/joycond.service $out/etc/systemd/system
    cp ../systemd/joycond.conf $out/lib/modules-load.d

    substituteInPlace $out/etc/systemd/system/joycond.service --replace-fail \
      "ExecStart=/usr/bin/joycond" "ExecStart=$out/bin/joycond"
  '';
})
