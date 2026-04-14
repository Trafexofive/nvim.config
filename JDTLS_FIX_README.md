# JDTLS Fix Strategy

We have been battling a persistent issue where `jdtls` crashes or fails to attach, preventing "Go to Definition" (`gd`) from working. The core problem is that `jdtls` requires Java 21+ to run itself, but the default wrapper script (Python) tries to validate the Java version and gets confused when we inject the environment manually.

## The Solution: Total Override

We have now replaced the fragile Python wrapper mechanism with a **Direct Bash Launcher** (`jdtls_wrapper.sh`).

### How it works:
1.  **Direct Execution**: The wrapper script (`jdtls_wrapper.sh`) manually constructs the full `java` command line arguments needed to start the Eclipse Equinox launcher.
2.  **Hardcoded Java 21**: It points directly to `/usr/lib/jvm/java-21-openjdk/bin/java`, bypassing any PATH ambiguity.
3.  **Bypassed Python**: It completely ignores the Mason-provided `jdtls.py` script, which was the source of the version validation errors.
4.  **LSP Integration**: `lsp.lua` now calls this bash script directly.

### Verification Results
The latest test run of the wrapper script produced:
```
{"jsonrpc":"2.0","method":"window/logMessage","params":{"type":3,"message":"... class org.eclipse.jdt.ls.core.internal.JavaLanguageServerPlugin is started"}}
```
This confirms the server **successfully starts** and initializes its components (Buildship/Gradle, M2E/Maven) without crashing.

### Next Steps for You
1.  Restart Neovim.
2.  Open your project.
3.  Wait a moment for the "Setting up JDTLS with wrapper..." notification.
4.  `gd` should now work correctly.
