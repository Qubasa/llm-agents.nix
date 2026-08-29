{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "lemmalog";
  version = "0.1.0-unstable-2026-08-28";

  src = fetchFromGitHub {
    owner = "JordyZomer";
    repo = "lemmalog";
    rev = "7d6f1541130aba53949a2da90cc3e134cb0aac01";
    hash = "sha256-N+Q8NTG4NXesNBQvNExpKJrQ2sjmYicgXCCgeChQAdU=";
  };

  cargoHash = "sha256-v/RP0bLvxllkIqzNQzhVlSw9oXF4E86nag0hVxhOTEg=";

  # llm: OpenAI-compatible chat/embeddings client (ureq).
  # mcp: the lemmalog-mcp stdio server binary.
  buildFeatures = [
    "llm"
    "mcp"
  ];

  postInstall = ''
    mkdir -p $out/share/lemmalog
    cp -r skills $out/share/lemmalog/skills
  '';

  # Nothing here accepts --version (the REPL reads a script on stdin, the MCP
  # server speaks JSON-RPC), so exercise derivation instead of versionCheckHook.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    printf '%s\n' \
      'rule current(E,R,O) :- edge(E,R,O,VF,VT,_), now(T), VF =< T, T < VT.' \
      'rule reports_to(X,Y) :- current(X,"manager",Y).' \
      'rule trans: reports_to(X,Z) :- reports_to(X,Y), reports_to(Y,Z).' \
      '+ edge(alice, manager, bob, 0, MAX, 1) @0.9 #ep1' \
      '+ edge(bob, manager, carol, 0, MAX, 1) @0.9 #ep2' \
      'now 10' \
      'run' \
      '? reports_to("alice", Y)' \
      'why reports_to(alice, carol)' \
      | $out/bin/lemmalog > repl.out
    cat repl.out
    grep -q 'Y=carol' repl.out
    grep -q 'via trans' repl.out
    ! grep -q '^error:' repl.out

    export LEMMALOG_MCP_PATH=$TMPDIR/memory.snapshot
    printf '%s\n' \
      '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
      '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"lemmalog_install_rules","arguments":{"rules":"reports_to(X,Y) :- current(X,\"manager\",Y).\ntrans: reports_to(X,Z) :- reports_to(X,Y), reports_to(Y,Z)."}}}' \
      '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"lemmalog_observe","arguments":{"facts":"Alice --manager--> Bob\nBob --manager--> Carol","ts":100}}}' \
      '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"lemmalog_query","arguments":{"goal":"reports_to(\"Alice\", Y)"}}}' \
      '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"lemmalog_why","arguments":{"fact":"reports_to(Alice, Carol)"}}}' \
      '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"lemmalog_save","arguments":{}}}' \
      | $out/bin/lemmalog-mcp > mcp.out
    cat mcp.out
    grep -q '"serverInfo"' mcp.out
    grep -q 'Y=Carol' mcp.out
    grep -q 'via trans' mcp.out
    ! grep -q '"isError":true' mcp.out

    # snapshot restore: a fresh server picks the episodes back up
    printf '%s\n' \
      '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"lemmalog_dump","arguments":{}}}' \
      | $out/bin/lemmalog-mcp > restore.out
    cat restore.out
    grep -q 'edge(Alice, manager, Bob' restore.out

    test -f $out/share/lemmalog/skills/lemmalog/SKILL.md

    runHook postInstallCheck
  '';

  passthru.category = "Memory & Code Intelligence";

  meta = {
    description = "Datalog engine for LLM agent memory with provenance, bi-temporal facts, and an MCP server";
    homepage = "https://github.com/JordyZomer/lemmalog";
    changelog = "https://github.com/JordyZomer/lemmalog/commits/main";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    maintainers = with lib.maintainers; [ qubasa ];
    mainProgram = "lemmalog";
    platforms = lib.platforms.unix;
  };
}
