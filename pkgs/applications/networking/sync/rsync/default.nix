{
  lib,
  stdenv,
  fetchurl,
  updateAutotoolsGnuConfigScriptsHook,
  perl,
  python3,
  libiconv,
  zlib,
  popt,
  enableACLs ? lib.meta.availableOn stdenv.hostPlatform acl,
  acl,
  enableLZ4 ? true,
  lz4,
  enableOpenSSL ? true,
  openssl,
  enableXXHash ? true,
  xxhash,
  enableZstd ? true,
  zstd,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "rsync";
  version = "3.4.2";

  src = fetchurl {
    # signed with key 9FEF 112D CE19 A0DC 7E88  2CB8 1BB2 4997 A853 5F6F
    url = "mirror://samba/rsync/src/rsync-${version}.tar.gz";
    hash = "sha256-/xCqLBUc1LLbvmE1Em28hUBGET0t+0lXKjSCMyZ+sxU=";
  };

  nativeBuildInputs = [
    updateAutotoolsGnuConfigScriptsHook
    perl
  ];

  nativeCheckInputs = [
    python3
  ];

  postPatch = ''
    substituteInPlace runtests.py \
      --replace-fail "/usr/bin/env python3" "${lib.getExe python3}"
  '';

  buildInputs = [
    libiconv
    zlib
    popt
  ]
  ++ lib.optional enableACLs acl
  ++ lib.optional enableZstd zstd
  ++ lib.optional enableLZ4 lz4
  ++ lib.optional enableOpenSSL openssl
  ++ lib.optional enableXXHash xxhash;

  configureFlags = [
    (lib.enableFeature enableLZ4 "lz4")
    (lib.enableFeature enableOpenSSL "openssl")
    (lib.enableFeature enableXXHash "xxhash")
    (lib.enableFeature enableZstd "zstd")
    # Feature detection does a runtime check which varies according to ipv6
    # availability, so force it on to make reproducible, see #360152.
    (lib.enableFeature true "ipv6")
    "--with-nobody-group=nogroup"

    # disable the included zlib explicitly as it otherwise still compiles and
    # links them even.
    "--with-included-zlib=no"
  ]
  ++ lib.optionals (stdenv.hostPlatform.isMusl && stdenv.hostPlatform.isx86_64) [
    # fix `multiversioning needs 'ifunc' which is not supported on this target` error
    "--disable-roll-simd"
  ];

  enableParallelBuilding = true;

  passthru.tests = { inherit (nixosTests) rsyncd; };

  doCheck = true;

  __darwinAllowLocalNetworking = true;

  meta = {
    description = "Fast incremental file transfer utility";
    homepage = "https://rsync.samba.org/";
    license = lib.licenses.gpl3Plus;
    mainProgram = "rsync";
    maintainers = [
    ];
    teams = [ lib.teams.security-review ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "samba";
      inherit version;
      update = "-";
    };
  };
}
