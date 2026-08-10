{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  git,
  versionCheckHook,
}:

let
  tslpVersion = "1.13.7";

  parserSources = fetchurl {
    url = "https://github.com/xberg-io/tree-sitter-language-pack/releases/download/v${tslpVersion}/parser-sources-${tslpVersion}.tar.zst";
    hash = "sha256-9tJTNlVDZzFTyd46lfN7Rhflv1YgZdn9+DT0ggNRrLI=";
  };

  tslpLanguages = [
    "bash"
    "c"
    "clojure"
    "cpp"
    "csharp"
    "css"
    "dart"
    "dockerfile"
    "elixir"
    "elm"
    "erlang"
    "fish"
    "fortran"
    "go"
    "groovy"
    "haskell"
    "hcl"
    "html"
    "ini"
    "java"
    "javascript"
    "json"
    "julia"
    "kotlin"
    "latex"
    "lua"
    "make"
    "nix"
    "ocaml"
    "perl"
    "php"
    "powershell"
    "proto"
    "python"
    "r"
    "ruby"
    "rust"
    "scala"
    "scss"
    "sql"
    "svelte"
    "swift"
    "toml"
    "tsx"
    "typescript"
    "vue"
    "xml"
    "yaml"
    "zig"
  ];

  registeredLanguages = 50;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "uncomment";
  version = "3.5.2";

  src = fetchFromGitHub {
    owner = "Goldziher";
    repo = "uncomment";
    tag = "v${finalAttrs.version}";
    hash = "sha256-in/5ptO4WHRquDusDzg6cG2VAl1+4x1/ihohR6LRwrA=";
  };

  cargoHash = "sha256-nkwMWctuJ4NItPGmyAIKUAFcMIBSkEOoLoHCEZjIAX0=";

  postPatch = ''
    lockedTslp=$(sed -n '/^name = "tree-sitter-language-pack"$/{n;s/^version = "\(.*\)"$/\1/p;}' Cargo.lock)
    if [ "$lockedTslp" != "${tslpVersion}" ]; then
      echo "Cargo.lock pins tree-sitter-language-pack $lockedTslp but packages/uncomment/package.nix fetches grammar sources for ${tslpVersion}." >&2
      echo "Update tslpVersion and the parserSources hash." >&2
      exit 1
    fi

    registered=$(grep -c '^            LanguageConfig::' src/languages/registry.rs)
    if [ "$registered" != "${toString registeredLanguages}" ]; then
      echo "uncomment now registers $registered languages (expected ${toString registeredLanguages})." >&2
      echo "Refresh tslpLanguages in packages/uncomment/package.nix from the last argument of each LanguageConfig::new call in src/languages/config.rs, then bump registeredLanguages." >&2
      exit 1
    fi

    # Default features pull in an on-demand grammar downloader that fetches and
    # dlopens shared libraries from GitHub at runtime. Every grammar uncomment
    # can reach is linked in below, so drop it.
    substituteInPlace Cargo.toml \
      --replace-fail 'tree-sitter-language-pack = "${tslpVersion}"' \
        'tree-sitter-language-pack = { version = "${tslpVersion}", default-features = false }'
  '';

  env = {
    TSLP_SOURCE_BUNDLE_URL = "file://${parserSources}";
    TSLP_LINK_MODE = "static";
    TSLP_LANGUAGES = lib.concatStringsSep "," tslpLanguages;
  };

  nativeCheckInputs = [ git ];

  checkFlags = [
    "--skip=test_comprehensive_config_repositories"
    "--skip=test_init_command_end_to_end"
    "--skip=test_init_error_scenarios"
    "--skip=test_init_help"
  ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.category = "Utilities";

  meta = {
    description = "CLI to remove comments from code using tree-sitter";
    longDescription = ''
      uncomment strips comments from source files by parsing them with
      tree-sitter, so it never mistakes comment-like text inside strings for a
      comment. Doc comments, TODO/FIXME notes and anything marked `~keep` are
      preserved by default, and extra patterns can be kept via `--ignore` or an
      `.uncommentrc.toml`.

      This build links the grammars for all 50 supported languages into the
      binary; upstream would otherwise download them at runtime.
    '';
    homepage = "https://github.com/Goldziher/uncomment";
    changelog = "https://github.com/Goldziher/uncomment/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "uncomment";
    maintainers = with lib.maintainers; [ qubasa ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = lib.platforms.unix;
  };
})
