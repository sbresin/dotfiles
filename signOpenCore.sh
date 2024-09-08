#!/usr/bin/env bash
for f in /efi/EFI/OC/{**/,}*.efi; do
	echo "File -> $f"
	# TODO: check if not already signed and then move to nixos activation script
	sbsign --key /etc/secureboot/keys/db/db.key --cert /etc/secureboot/keys/db/db.pem --output "$f" "$f"
done
