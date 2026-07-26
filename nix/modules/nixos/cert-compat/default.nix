{ config, ... }:
{
  # Compatibility for prebuilt tools whose OpenSSL defaults to this cafile path.
  environment.etc."ssl/cert.pem".source = config.security.pki.caBundle;
}
