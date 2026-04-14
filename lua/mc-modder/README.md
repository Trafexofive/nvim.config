# MC Modder - Minecraft Modding IDE for Neovim

A comprehensive Neovim plugin that transforms your editor into a powerful Minecraft modding IDE. Provides project scaffolding, build tool integration, and language server support for Java and Kotlin Minecraft mod development.

## Features

- **Project Scaffolding**: Quickly create new Minecraft mod projects for Fabric, Forge, or Quilt
- **Build Tool Integration**: Full support for Gradle and Maven with real-time output display
- **Language Server Support**: Advanced Java and Kotlin language server integration
- **Minecraft-Specific Templates**: Pre-built templates for common mod components (blocks, items, entities, etc.)
- **Optimized Key Mappings**: Intuitive shortcuts for common modding tasks

## Requirements

- Neovim >= 0.8
- Java Development Kit (JDK) 17 or higher
- Gradle or Maven (for build tool integration)
- [jdtls](https://github.com/eclipse/eclipse.jdt.ls) (for Java language server)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) (for LSP support)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (for async jobs)

## Installation

### Using Lazy.nvim

```lua
{
  "your-username/mc-modder.nvim",  -- Replace with actual repository when published
  dependencies = {
    "neovim/nvim-lspconfig",
    "nvim-lua/plenary.nvim",
    "mfussenegger/nvim-jdtls",  -- For Java support
  },
  config = function()
    require('mc-modder').setup({
      -- Your configuration here
      java = {
        java_home = os.getenv("JAVA_HOME") or "",
        jdtls_path = "~/tools/jdtls",  -- Path to your jdtls installation
      },
      kotlin = {
        ktls_path = "~/tools/kotlin-language-server",  -- Path to your KLS installation
      },
      minecraft = {
        default_version = "1.20.1",
        default_mod_type = "fabric",
      },
      mappings = {
        gradle = {
          build = "<leader>mgb",      -- Build project
          run_client = "<leader>mrc",  -- Run Minecraft client
          run_server = "<leader>mrs",  -- Run Minecraft server
          clean = "<leader>mgc",       -- Clean project
          gen_sources = "<leader>mgs", -- Generate sources
        },
        maven = {
          compile = "<leader>mmc",     -- Compile project
          install = "<leader>mmi",     -- Install project
          test = "<leader>mnt",        -- Run tests
        },
        lsp = {
          reload = "<leader>mlr",      -- Reload LSP
          organize_imports = "<leader>mo", -- Organize imports
        },
        scaffold = {
          create_mod = "<leader>msc",  -- Create new mod project
        }
      }
    })
  end
}
```

## Usage

### Creating a New Mod Project

1. Navigate to your desired parent directory
2. Use the key mapping to create a new mod project (default: `<leader>msc`)
3. Enter the mod type (fabric/forge/quilt), Minecraft version, and project name
4. The plugin will generate the appropriate project structure with all necessary files

### Building Your Project

- Use `<leader>mgb` to build your project with Gradle
- Use `<leader>mmc` to compile your project with Maven
- Build output will appear in a floating window at the bottom of your screen

### Running Minecraft

- Use `<leader>mrc` to run the Minecraft client
- Use `<leader>mrs` to run the Minecraft server
- These commands execute the appropriate Gradle/Maven tasks

### Language Server Features

The plugin automatically detects Java/Kotlin projects and sets up the appropriate language server with Minecraft-specific configurations. You'll get:

- Code completion
- Error detection
- Go to definition
- Find references
- Rename refactoring
- Import organization

## Commands

The plugin creates several user commands:

- `JavaProjectReload` - Reload the Java project
- `JavaImportOrganize` - Organize Java imports
- `JavaTestFinder` - Find Java tests

## Configuration

The plugin supports extensive customization through the setup function. See the installation example above for available options.

## Key Mappings

| Mode | Mapping | Description |
|------|---------|-------------|
| Normal | `<leader>mgb` | Build project with Gradle |
| Normal | `<leader>mrc` | Run Minecraft client |
| Normal | `<leader>mrs` | Run Minecraft server |
| Normal | `<leader>mgc` | Clean project |
| Normal | `<leader>mgs` | Generate sources |
| Normal | `<leader>mmc` | Compile project with Maven |
| Normal | `<leader>mmi` | Install project with Maven |
| Normal | `<leader>mnt` | Run tests with Maven |
| Normal | `<leader>mlr` | Reload LSP |
| Normal | `<leader>mo` | Organize imports |
| Normal | `<leader>msc` | Create new mod project |

## Supported Mod Types

The plugin supports scaffolding for:

- **Fabric**: Modern lightweight modding framework
- **Forge**: Popular modding framework with extensive community
- **Quilt**: Upcoming modding framework designed as a successor to Fabric

## Troubleshooting

### Language Server Not Starting

Make sure you have the Java Development Kit installed and that `JAVA_HOME` is set correctly. Also verify that the path to jdtls in your configuration is correct.

### Build Tools Not Found

Ensure that Gradle or Maven is installed and accessible from your command line. The plugin will try to use `./gradlew` first, then fall back to the global `gradle` command.

### Plugin Not Working in Existing Projects

Try running the LSP reload command (`<leader>mlr`) to force the language server to restart and recognize your project.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

MIT