{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm,
  pnpmConfigHook,
}:

buildNpmPackage rec {
  pname = "opencode-quota";
  version = "3.8.7";

  src = fetchFromGitHub {
    owner = "slkiser";
    repo = "opencode-quota";
    rev = "v${version}";
    hash = "sha256-QtHBmLvGimkuY1QsBURXgW8utDT7rntO63KtIqlVDlU=";
  };

  # Upstream tags the release commit before bumping package.json; the npm
  # publish workflow bumps the version in-flight. Mirror that so the build
  # reports the released version instead of the previous one.
  postPatch = ''
    sed -i 's/"version": "[0-9][0-9.]*"/"version": "${version}"/' package.json
  '';

  npmDeps = null;
  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    hash = "sha256-v9jKI+ALrGicKVIqudfezjSWst7z4YOBWjGvT1IlPY4=";
  };

  nativeBuildInputs = [ pnpm ];
  npmConfigHook = pnpmConfigHook;

  dontNpmPrune = true;

  passthru.category = "Usage Analytics";

  meta = with lib; {
    description = "OpenCode quota and token usage tracker with zero context window pollution";
    homepage = "https://github.com/slkiser/opencode-quota";
    changelog = "https://github.com/slkiser/opencode-quota/releases/tag/v${version}";
    license = licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = platforms.all;
    mainProgram = "opencode-quota";
  };
}
