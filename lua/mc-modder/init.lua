local M = {}

-- Lazy-loaded modules
local function get_config() return require("mc-modder.config") end
local function get_scaffold() return require("mc-modder.scaffold") end
local function get_gradle() return require("mc-modder.gradle") end
local function get_maven() return require("mc-modder.maven") end
local function get_lsp() return require("mc-modder.lsp") end

-- Setup function for the mc-modder plugin
function M.setup(user_config)
  local config = get_config()
  
  -- Merge user config with defaults
  local final_config = config.merge(user_config)
  if not final_config then
    return
  end
  
  -- Set the current configuration
  config.set(final_config)
  
  -- Setup LSP if enabled
  -- We don't want mc-modder managing LSP anymore, we use lsp.lua and mason for that
  -- if final_config.lsp_enabled ~= false then
  --   get_lsp().setup_minecraft_lsp(final_config)
  -- end
  
  -- Setup key mappings
  M.setup_mappings(final_config.mappings)
end

-- Function to setup key mappings
function M.setup_mappings(mappings)
  -- Gradle mappings
  if mappings.gradle then
    if mappings.gradle.build then
      vim.keymap.set("n", mappings.gradle.build, function()
        get_gradle().run_common_task("build", { use_wrapper = true })
      end, { desc = "MC Modder: Build project with Gradle" })
    end
    
    if mappings.gradle.run_client then
      vim.keymap.set("n", mappings.gradle.run_client, function()
        get_gradle().run_common_task("run_client", { use_wrapper = true })
      end, { desc = "MC Modder: Run Minecraft client" })
    end
    
    if mappings.gradle.run_server then
      vim.keymap.set("n", mappings.gradle.run_server, function()
        get_gradle().run_common_task("run_server", { use_wrapper = true })
      end, { desc = "MC Modder: Run Minecraft server" })
    end
    
    if mappings.gradle.clean then
      vim.keymap.set("n", mappings.gradle.clean, function()
        get_gradle().run_common_task("clean", { use_wrapper = true })
      end, { desc = "MC Modder: Clean project" })
    end
    
    if mappings.gradle.gen_sources then
      vim.keymap.set("n", mappings.gradle.gen_sources, function()
        get_gradle().run_common_task("gen_sources", { use_wrapper = true })
      end, { desc = "MC Modder: Generate sources" })
    end
  end
  
  -- Maven mappings
  if mappings.maven then
    if mappings.maven.compile then
      vim.keymap.set("n", mappings.maven.compile, function()
        get_maven().run_common_task("build", {})
      end, { desc = "MC Modder: Compile project with Maven" })
    end
    
    if mappings.maven.install then
      vim.keymap.set("n", mappings.maven.install, function()
        get_maven().run_common_task("install", {})
      end, { desc = "MC Modder: Install project with Maven" })
    end
    
    if mappings.maven.test then
      vim.keymap.set("n", mappings.maven.test, function()
        get_maven().run_common_task("test", {})
      end, { desc = "MC Modder: Run tests with Maven" })
    end
  end
  
  -- LSP mappings
  if mappings.lsp then
    if mappings.lsp.reload then
      vim.keymap.set("n", mappings.lsp.reload, function()
        get_lsp().setup_minecraft_lsp(get_config().get())
      end, { desc = "MC Modder: Reload LSP" })
    end
    
    if mappings.lsp.organize_imports then
      vim.keymap.set("n", mappings.lsp.organize_imports, function()
        -- This would call the Java LSP to organize imports
        vim.lsp.buf.code_action({
          filter = function(code_action)
            return code_action.kind == "source.organizeImports"
          end,
          apply = true,
        })
      end, { desc = "MC Modder: Organize imports" })
    end
  end
  
  -- Scaffolding mappings
  if mappings.scaffold then
    if mappings.scaffold.create_mod then
      vim.keymap.set("n", mappings.scaffold.create_mod, function()
        local mod_type = vim.fn.input("Enter mod type (fabric/forge/quilt) [fabric]: ", "fabric", "customlist,v:lua.require'mc-modder'.get_mod_types")
        local version = vim.fn.input("Enter Minecraft version [1.20.1]: ", "1.20.1")
        local project_name = vim.fn.input("Enter project name: ")
        if project_name ~= "" then
          get_scaffold().create_mod_project(project_name, mod_type, version)
        end
      end, { desc = "MC Modder: Create new mod project" })
    end
  end
end

-- Function to get available mod types for completion
function M.get_mod_types(arg_lead)
  local mod_types = get_config().get().minecraft.mod_types
  local matches = {}
  for _, type in ipairs(mod_types) do
    if type:sub(1, #arg_lead) == arg_lead then
      table.insert(matches, type)
    end
  end
  return matches
end

return M