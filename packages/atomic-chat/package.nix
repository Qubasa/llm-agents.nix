{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "atomic-chat";
  version = "2.0.14";

  src = fetchurl {
    url = "https://github.com/AtomicBot-ai/Atomic-Chat/releases/download/v${version}/Atomic.Chat_${version}_amd64.AppImage";
    hash = "sha256-8BMmEfDfC2DABa9sOtFePyvi6/FXcXrRMu9SB156Tcg=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The AppImage bundles its GTK/WebKit stack, but the Tauri binary still
  # dlopens the tray and TLS libraries from the host.
  extraPkgs =
    pkgs: with pkgs; [
      libayatana-appindicator
      libsoup_3
      openssl
      webkitgtk_4_1
    ];

  extraInstallCommands = ''
    install -Dm444 "${appimageContents}/usr/share/applications/Atomic Chat.desktop" \
      $out/share/applications/atomic-chat.desktop
    substituteInPlace $out/share/applications/atomic-chat.desktop \
      --replace-fail 'Exec=Atomic-Chat' 'Exec=atomic-chat'
    cp -r ${appimageContents}/usr/share/icons $out/share/icons
  '';

  passthru.category = "AI Assistants";

  meta = {
    description = "Local AI chat app and inference engine for open-weight models";
    longDescription = ''
      Atomic Chat runs open-weight LLMs on your own machine, fully offline, with
      a chat UI, an OpenAI-compatible local API server and agent extensions. It
      is a fork of Jan by Menlo Research.
    '';
    homepage = "https://atomic.chat";
    changelog = "https://github.com/AtomicBot-ai/Atomic-Chat/releases/tag/v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ qubasa ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "atomic-chat";
  };
}
