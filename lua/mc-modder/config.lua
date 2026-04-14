local M = {}

-- Default configuration
M.defaults = {
  -- Java settings
  java = {
    java_home = os.getenv("JAVA_HOME") or "",
    jdtls_path = vim.fn.expand("~/tools/jdtls"),
  },
  
  -- Kotlin settings
  kotlin = {
    ktls_path = vim.fn.expand("~/tools/kotlin-language-server"),
    jvm_target = "17",
  },
  
  -- Build tool settings
  build_tools = {
    gradle = {
      use_wrapper = true,  -- Prefer ./gradlew over global gradle
    },
    maven = {
      -- No specific settings needed for Maven at the moment
    }
  },
  
  -- Minecraft-specific settings
  minecraft = {
    default_version = "1.20.1",
    mod_types = {"fabric", "forge", "quilt"},  -- Supported mod types
    default_mod_type = "fabric",  -- Default mod type to use
  },
  
  -- UI settings
  ui = {
    build_output_position = "bottom",  -- Position of build output window
    build_output_height = 15,  -- Height of build output window in lines
  },
  
  -- Key mappings
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
      add_block = "<leader>msb",   -- Add new block
      add_item = "<leader>msi",    -- Add new item
      add_entity = "<leader>mse",   -- Add new entity
    }
  }
}

-- Current configuration (will be set during setup)
M.current = {}

-- Function to validate configuration
function M.validate(config)
  local errors = {}
  
  -- Validate java settings
  if config.java then
    if type(config.java) ~= "table" then
      table.insert(errors, "config.java must be a table")
    else
      if config.java.java_home and type(config.java.java_home) ~= "string" then
        table.insert(errors, "config.java.java_home must be a string")
      end
      if config.java.jdtls_path and type(config.java.jdtls_path) ~= "string" then
        table.insert(errors, "config.java.jdtls_path must be a string")
      end
    end
  end
  
  -- Validate kotlin settings
  if config.kotlin then
    if type(config.kotlin) ~= "table" then
      table.insert(errors, "config.kotlin must be a table")
    else
      if config.kotlin.ktls_path and type(config.kotlin.ktls_path) ~= "string" then
        table.insert(errors, "config.kotlin.ktls_path must be a string")
      end
      if config.kotlin.jvm_target and type(config.kotlin.jvm_target) ~= "string" then
        table.insert(errors, "config.kotlin.jvm_target must be a string")
      end
    end
  end
  
  -- Validate build_tools settings
  if config.build_tools then
    if type(config.build_tools) ~= "table" then
      table.insert(errors, "config.build_tools must be a table")
    else
      if config.build_tools.gradle then
        if type(config.build_tools.gradle) ~= "table" then
          table.insert(errors, "config.build_tools.gradle must be a table")
        elseif config.build_tools.gradle.use_wrapper ~= nil and type(config.build_tools.gradle.use_wrapper) ~= "boolean" then
          table.insert(errors, "config.build_tools.gradle.use_wrapper must be a boolean")
        end
      end
    end
  end
  
  -- Validate minecraft settings
  if config.minecraft then
    if type(config.minecraft) ~= "table" then
      table.insert(errors, "config.minecraft must be a table")
    else
      if config.minecraft.default_version and type(config.minecraft.default_version) ~= "string" then
        table.insert(errors, "config.minecraft.default_version must be a string")
      end
      if config.minecraft.mod_types then
        if type(config.minecraft.mod_types) ~= "table" then
          table.insert(errors, "config.minecraft.mod_types must be a table")
        else
          for i, mod_type in ipairs(config.minecraft.mod_types) do
            if type(mod_type) ~= "string" then
              table.insert(errors, "config.minecraft.mod_types[" .. i .. "] must be a string")
            end
          end
        end
      end
      if config.minecraft.default_mod_type and type(config.minecraft.default_mod_type) ~= "string" then
        table.insert(errors, "config.minecraft.default_mod_type must be a string")
      end
    end
  end
  
  -- Validate ui settings
  if config.ui then
    if type(config.ui) ~= "table" then
      table.insert(errors, "config.ui must be a table")
    else
      if config.ui.build_output_position and type(config.ui.build_output_position) ~= "string" then
        table.insert(errors, "config.ui.build_output_position must be a string")
      end
      if config.ui.build_output_height and type(config.ui.build_output_height) ~= "number" then
        table.insert(errors, "config.ui.build_output_height must be a number")
      end
    end
  end
  
  -- Validate mappings settings
  if config.mappings then
    if type(config.mappings) ~= "table" then
      table.insert(errors, "config.mappings must be a table")
    end
    -- We won't validate the actual key mappings since they can be complex strings
  end
  
  return #errors == 0, errors
end

-- Function to merge user config with defaults
function M.merge(user_config)
  user_config = user_config or {}
  
  -- Validate configuration
  local is_valid, errors = M.validate(user_config)
  if not is_valid then
    for _, error in ipairs(errors) do
      vim.notify("MC Modder Config Error: " .. error, vim.log.levels.ERROR)
    end
    return nil
  end
  
  -- Merge configurations deeply
  local merged_config = vim.tbl_deep_extend("force", M.defaults, user_config)
  
  return merged_config
end

-- Function to get the current configuration
function M.get()
  if vim.tbl_isempty(M.current) then
    return M.defaults
  end
  return M.current
end

-- Function to set the current configuration
function M.set(config)
  M.current = config or M.defaults
end

return M