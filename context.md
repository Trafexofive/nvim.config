# AI Project Analysis - nvim
- Generated on: Wed Apr 23 11:42:25 PM +01 2025
- System: Linux 6.12.21-1-lts x86_64
- Arch Linux: 1649 packages installed
- Directory: /home/mlamkadm/.config/nvim

## Directory Structure
```
../nvim
├── gemini.lua
├── init.lua
├── lazy-lock.json
├── lua
│   └── mlamkadm
│       ├── core
│       ├── lazy.lua
│       └── plugs
├── main.lua
├── test.lua
└── tests
    └── test.lua
```

## Project Statistics
- Total Files: 56
- Total Lines of Code: 4673
- Languages: .lua(49),.sample(14),.rev(1),.pack(1),.json(1),.idx(1)

## Project Files

### File: gemini.lua
```
-- simple_gemini.lua
-- A simpler Lua interface for Google Gemini API

local SimpleGemini = {}
SimpleGemini.__index = SimpleGemini

-- Required Dependencies (Must be installed in your Lua environment)
local json = require('lunajson') -- Or require('cjson'), require('dkjson')
local http = require('socket.http')
local ltn12 = require('ltn12')
local url = require('socket.url') -- For URL encoding the API key

-- Default configuration
local DEFAULTS = {
    model = "gemini-2.0-flash", -- Changed to flash for potentially faster/cheaper default
    base_url = "https://generativelanguage.googleapis.com/v1beta/models",
    temperature = 0.5,
    max_tokens = 1024,
    api_key = os.getenv("GEMINI_API_KEY") -- Prefer environment variable
}

-- Error checking for dependencies
if not json then error("JSON library (lunajson, cjson, dkjson) not found.") end
if not http then error("socket.http library not found.") end
if not ltn12 then error("ltn12 library not found (required by socket.http for POST).") end
if not url then error("socket.url library not found.") end


-- Internal: Make the HTTP request
local function make_request(req_url, api_key, payload)
    local body, json_err = json.encode(payload)
    if not body then
        return nil, "JSON encode error: " .. tostring(json_err)
    end

    -- Construct the final URL with the API key as a query parameter
    local final_url = req_url .. "?key=" .. url.escape(api_key)

    local response_body_tbl = {}
    local code, status_line, headers_tbl -- Use code for the status code

    -- Perform the HTTP POST request
    local ok, err = pcall(function()
        code = http.request {
            url = final_url,
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = #body
                -- Note: Google API Key goes in the URL query, not usually as an Authorization header
            },
            source = ltn12.source.string(body),
            sink = ltn12.sink.table(response_body_tbl)
        }
    end)

    if not ok then
        return nil, "HTTP request failed (pcall): " .. tostring(err)
    end
    -- LuaSocket's http.request returns the status code directly as the first return value on success.
    -- If it fails network-wise *before* getting a status, 'code' might be nil or an error message.
    -- The pcall handles lower-level errors, now check the HTTP status code.

    if not code or type(code) ~= "number" then
         -- This might happen if the request failed very early (e.g., DNS lookup)
         -- and err from pcall might be more informative if it exists.
        return nil, "HTTP request failed: No status code received. Detail: " .. tostring(code or "unknown error")
    end

    local response_body_str = table.concat(response_body_tbl)

    if code ~= 200 then
        local error_detail = response_body_str or "No response body"
        -- Attempt to parse error message from Google's JSON response if possible
        local decoded_error, decode_err = json.decode(error_detail)
        if decoded_error and decoded_error.error and decoded_error.error.message then
            error_detail = decoded_error.error.message
        end
        return nil, string.format("HTTP error %d: %s", code, error_detail)
    end

    -- Decode the successful JSON response
    local data, json_decode_err = json.decode(response_body_str)
    if not data then
        return nil, "JSON decode error: " .. tostring(json_decode_err) .. "\nRaw response: " .. response_body_str
    end

    -- Check for API-level errors within the 200 OK response
    if data.error then
       return nil, "API Error: " .. (data.error.message or "Unknown API error format")
    end

    return data -- Return the decoded Lua table
end

-- Constructor for a new Gemini client instance
function SimpleGemini:new(config)
    config = config or {}
    local instance = {}

    -- Merge provided config with defaults
    instance.api_key = config.api_key or DEFAULTS.api_key
    instance.model = config.model or DEFAULTS.model
    instance.base_url = config.base_url or DEFAULTS.base_url
    instance.temperature = config.temperature or DEFAULTS.temperature
    instance.max_tokens = config.max_tokens or DEFAULTS.max_tokens

    if not instance.api_key then
        error("Gemini API key is required. Provide it in config or set GEMINI_API_KEY environment variable.")
    end

    setmetatable(instance, self)
    return instance
end

-- Generate content from a single prompt
-- Returns: string (response text), nil | nil, string (error message)
function SimpleGemini:generate(prompt, options)
    options = options or {}

    local url = string.format("%s/%s:generateContent",
        self.base_url,
        options.model or self.model -- Allow overriding model per call
    )

    local payload = {
        contents = {
            -- The API expects a 'contents' array. For simple generation,
            -- it contains one item representing the user's prompt.
            {
                role = "user", -- Role is optional for single-turn but good practice
                parts = { { text = prompt } }
            }
        },
        generationConfig = {
            temperature = options.temperature or self.temperature,
            maxOutputTokens = options.max_tokens or self.max_tokens
            -- Add other generationConfig options here if needed: topP, topK, stopSequences
        }
        -- Add safetySettings if needed via options
        -- safetySettings = options.safetySettings or self.safetySettings
    }

    local data, err = make_request(url, self.api_key, payload)
    if err then
        return nil, err
    end

    -- Extract response text carefully
    if data.candidates and data.candidates[1] and data.candidates[1].content and
       data.candidates[1].content.parts and data.candidates[1].content.parts[1] and
       data.candidates[1].content.parts[1].text then
        return data.candidates[1].content.parts[1].text
    else
        -- Handle cases like blocked prompts indicated in feedback
        if data.promptFeedback and data.promptFeedback.blockReason then
           return nil, "API Error: Prompt blocked - Reason: " .. data.promptFeedback.blockReason
        end
        -- General structural error
        local raw_response, _ = json.encode(data) -- Try to show raw response in error
        return nil, "API Error: Unexpected response structure. Raw: " .. (raw_response or tostring(data))
    end
end

-- Send chat history and get the next response
-- IMPORTANT: This function is stateless regarding history.
-- You must manage the history list externally.
-- Parameters:
--   history: table - Array of {role="user|model", parts={{text="..."}}} objects
--   prompt: string - The new user prompt to add to the conversation
--   options: table (optional) - Override generation options for this call
-- Returns: string (response text), nil | nil, string (error message)
function SimpleGemini:chat(history, prompt, options)
    if type(history) ~= "table" then
        return nil, "Invalid argument: history must be a table."
    end
     if type(prompt) ~= "string" or prompt == "" then
        return nil, "Invalid argument: prompt must be a non-empty string."
    end
    options = options or {}

    local url = string.format("%s/%s:generateContent",
        self.base_url,
        options.model or self.model -- Allow overriding model per call
    )

    -- Create the payload contents by *copying* the existing history
    -- and adding the new user prompt. Don't modify the original history table here.
    local current_contents = {}
    for i, msg in ipairs(history) do
        table.insert(current_contents, msg)
    end
    table.insert(current_contents, { role = "user", parts = { { text = prompt } } })

    local payload = {
        contents = current_contents,
        generationConfig = {
            temperature = options.temperature or self.temperature,
            maxOutputTokens = options.max_tokens or self.max_tokens
            -- Add other generationConfig options if needed
        }
        -- Add safetySettings if needed
    }

    local data, err = make_request(url, self.api_key, payload)
    if err then
        return nil, err -- Error message already formatted by make_request
    end

    -- Extract response text carefully
    if data.candidates and data.candidates[1] and data.candidates[1].content and
       data.candidates[1].content.parts and data.candidates[1].content.parts[1] and
       data.candidates[1].content.parts[1].text then

        -- IMPORTANT: The caller should add *both* the user prompt *and* this
        -- successful model response to their history list for the next turn.
        -- We return only the text here.
        return data.candidates[1].content.parts[1].text
    else
       if data.promptFeedback and data.promptFeedback.blockReason then
           return nil, "API Error: Prompt blocked - Reason: " .. data.promptFeedback.blockReason
       end
       local raw_response, _ = json.encode(data)
       return nil, "API Error: Unexpected response structure. Raw: " .. (raw_response or tostring(data))
    end
end

return SimpleGemini
```

### File: init.lua
```
-- ************************************************************************** --
--                                                                            --
--                                                        :::      ::::::::   --
--   init.lua                                           :+:      :+:    :+:   --
--                                                    +:+ +:+         +:+     --
--   By: mlamkadm <mlamkadm@student.42.fr>          +#+  +:+       +#+        --
--                                                +#+#+#+#+#+   +#+           --
--   Created: 2025/01/01 11:20:17 by mlamkadm          #+#    #+#             --
--   Updated: 2025/01/01 11:20:17 by mlamkadm         ###   ########.fr       --
--                                                                            --
-- ************************************************************************** --

-- Core settings and lazy loading
require("mlamkadm.core")
require("mlamkadm.lazy")
require("mlamkadm.core.sessions")
require("mlamkadm.core.terminal")
require("mlamkadm.core.cmp")
require("mlamkadm.core.winshift")
require("mlamkadm.core.gemini-integration").setup()
-- require("mlamkadm.core.ollama-mk2").setup()
-- require("mlamkadm.core.ollama-vi-mk2").setup()
-- require("mlamkadm.core.ollama").setup()
-- require("mlamkadm.core.ollama-mk2").setup({
--     -- Custom configuration (optional)
--     host = "http://localhost",
--     port = 11434,
--     default_model = "llama2",
--     keymaps = {
--         prompt = "<leader>op",
--         inline = "<leader>oi",
--         selection = "<leader>os",
--         chat = "<leader>oc",
--     }
-- })
-- Comment.nvim setup
require('Comment').setup()

-- Mason and LSP setup
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "clangd", "typos_lsp", "rust_analyzer", "jsonls", "html", "cssls", "dockerls", "bashls", "vimls", "pyright", "gopls", "diagnosticls" },
})

local lspconfig = require("lspconfig")
local server_configs = {
    lua_ls = {
        settings = {
            Lua = {
                diagnostics = { globals = { "vim" } },
            },
        },
    },
    clangd = {},
    typos_lsp = {},
}

for server, config in pairs(server_configs) do
    lspconfig[server].setup(config)
end

-- Automatically stop terminal jobs on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        vim.cmd("silent! call jobstop(b:terminal_job_id)")
    end,
})

-- Glow.nvim setup
require('glow').setup({
    glow_path = "/home/linuxbrew/.linuxbrew/bin/glow",
    install_path = "~/.local/bin",
    border = "shadow",
    style = "dark",
    width = 80,
    height = 100,
    width_ratio = 1,
    height_ratio = 1,
})

-- Cmp_zsh setup
require 'cmp_zsh'.setup {
    zshrc = true,
    filetypes = { "deoledit", "zsh" },
}

-- Nvim-web-devicons setup
require 'nvim-web-devicons'.setup {
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    color_icons = true,
    default = true,
    strict = true,
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "Gitignore"
        }
    },
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        }
    },
    override_by_operating_system = {
        ["apple"] = {
            icon = "",
            color = "#A2AAAD",
            cterm_color = "248",
            name = "Apple",
        },
    },
}

-- Symbols-outline setup
require("symbols-outline").setup()

-- Placeholder for advanced functionality (future-proofing with comments)
-- require('img-clip').setup({
--     -- configuration here
-- })
-- require('render-markdown').setup({
--     -- configuration here
-- })
-- require('avante_lib').load()
-- require('avante').setup({
--   provider = "copilot",
--   auto_suggestions_provider = "copilot",
--   mappings = {
--     suggestion = {
--       accept = "<M-l>",
--       next = "<M-]>",
--       prev = "<M-[>",
--       dismiss = "<C-]>",
--     },
--   },
-- })
--
```

### File: lazy-lock.json
```json
{
  "42-C-Formatter.nvim": { "branch": "main", "commit": "f925bedf740e39f500298251e9eaa062667e10e3" },
  "42-header.nvim": { "branch": "main", "commit": "4303be09d9615e9169661b3e5d5a98c3eecee0ff" },
  "Comment.nvim": { "branch": "master", "commit": "e30b7f2008e52442154b66f7c519bfd2f1e32acb" },
  "LuaSnip": { "branch": "master", "commit": "03c8e67eb7293c404845b3982db895d59c0d1538" },
  "auto-save.nvim": { "branch": "main", "commit": "979b6c82f60cfa80f4cf437d77446d0ded0addf0" },
  "auto-session": { "branch": "main", "commit": "00334ee24b9a05001ad50221c8daffbeedaa0842" },
  "cmp-buffer": { "branch": "main", "commit": "b74fab3656eea9de20a9b8116afa3cfc4ec09657" },
  "cmp-fuzzy-path": { "branch": "master", "commit": "9953c11a2510a04111b7b152cf50ae1e83f00798" },
  "cmp-nvim-lsp": { "branch": "main", "commit": "a8912b88ce488f411177fc8aed358b04dc246d7b" },
  "cmp-nvim-lua": { "branch": "main", "commit": "f12408bdb54c39c23e67cab726264c10db33ada8" },
  "cmp-path": { "branch": "main", "commit": "c6635aae33a50d6010bf1aa756ac2398a2d54c32" },
  "cmp-zsh": { "branch": "main", "commit": "c24db8e58fac9006ec23d93f236749288d00dec9" },
  "cmp_luasnip": { "branch": "master", "commit": "98d9cb5c2c38532bd9bdb481067b20fea8f32e90" },
  "copilot-cmp": { "branch": "master", "commit": "15fc12af3d0109fa76b60b5cffa1373697e261d1" },
  "copilot.lua": { "branch": "master", "commit": "fc015b7dbd09b3ce262a076b065a536ed3b5ae45" },
  "deol.nvim": { "branch": "master", "commit": "9c2c97b99b236bc9a0a768e696aea466b959a396" },
  "friendly-snippets": { "branch": "main", "commit": "fc8f183479a472df60aa86f00e295462f2308178" },
  "fuzzy.nvim": { "branch": "master", "commit": "68608f6a232f7e73ccf81437bf12108128f15bd4" },
  "fzf-lua": { "branch": "main", "commit": "6fd79d9c2531efca68e359cea43ebe689df8e064" },
  "glow.nvim": { "branch": "main", "commit": "5d5954b2f22e109d4a6eba8b2618c5b96e4ee7a2" },
  "go.nvim": { "branch": "master", "commit": "ecffa1757ac8e84e1e128f12e0fdbf8418354f6f" },
  "gruvbox.nvim": { "branch": "main", "commit": "a933d8666dad9363dc6908ae72cfc832299c2f59" },
  "guihua.lua": { "branch": "master", "commit": "0cc9631914ffcbe3e474e809c610d12a75b660cf" },
  "lazy.nvim": { "branch": "main", "commit": "6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a" },
  "lsp-zero.nvim": { "branch": "v2.x", "commit": "320d5913bc5a0b0f15537e32777331d2323ab7f8" },
  "mason-lspconfig.nvim": { "branch": "main", "commit": "1a31f824b9cd5bc6f342fc29e9a53b60d74af245" },
  "mason.nvim": { "branch": "main", "commit": "fc98833b6da5de5a9c5b1446ac541577059555be" },
  "material.nvim": { "branch": "main", "commit": "96285a62923ea8e38aea7b603099752da2a97e97" },
  "mini.icons": { "branch": "main", "commit": "397ed3807e96b59709ef3292f0a3e253d5c1dc0a" },
  "mkdnflow.nvim": { "branch": "main", "commit": "d459bd7ce68910272038ed037c028180161fd14d" },
  "neo-tree.nvim": { "branch": "v3.x", "commit": "1ef260eb4f54515fe121a2267b477efb054d108a" },
  "nui.nvim": { "branch": "main", "commit": "8d5b0b568517935d3c84f257f272ef004d9f5a59" },
  "nvim-autopairs": { "branch": "master", "commit": "4d74e75913832866aa7de35e4202463ddf6efd1b" },
  "nvim-cmp": { "branch": "main", "commit": "b5311ab3ed9c846b585c0c15b7559be131ec4be9" },
  "nvim-lspconfig": { "branch": "master", "commit": "8b0f47d851ee5343d38fe194a06ad16b9b9bd086" },
  "nvim-treesitter": { "branch": "master", "commit": "684eeac91ed8e297685a97ef70031d19ac1de25a" },
  "nvim-treesitter-refactor": { "branch": "master", "commit": "d8b74fa87afc6a1e97b18da23e762efb032dc270" },
  "nvim-web-devicons": { "branch": "master", "commit": "855c97005c8eebcdd19846f2e54706bffd40ee96" },
  "persistence.nvim": { "branch": "main", "commit": "166a79a55bfa7a4db3e26fc031b4d92af71d0b51" },
  "plenary.nvim": { "branch": "master", "commit": "857c5ac632080dba10aae49dba902ce3abf91b35" },
  "startup.nvim": { "branch": "master", "commit": "9ca3b9a55f2f2196ef90b39a52029b46fdde5226" },
  "sttusline": { "branch": "main", "commit": "133bb40d249e0167c89bb352ff8442b821fb07e9" },
  "symbols-outline.nvim": { "branch": "master", "commit": "564ee65dfc9024bdde73a6621820866987cbb256" },
  "telescope-cmdline.nvim": { "branch": "main", "commit": "e1e4a5bfd043bd6f940384b211177ee54f5aa881" },
  "telescope-frecency.nvim": { "branch": "master", "commit": "df79efdce0edcb48cfe3cffd3ac00c449bc6407f" },
  "telescope-fzf-native.nvim": { "branch": "main", "commit": "1f08ed60cafc8f6168b72b80be2b2ea149813e55" },
  "telescope-live-grep-args.nvim": { "branch": "master", "commit": "b80ec2c70ec4f32571478b501218c8979fab5201" },
  "telescope-lsp-handlers.nvim": { "branch": "trunk", "commit": "de02085d6af1633942549a238bc7a5524fa9b201" },
  "telescope-ui-select.nvim": { "branch": "master", "commit": "6e51d7da30bd139a6950adf2a47fda6df9fa06d2" },
  "telescope-undo.nvim": { "branch": "main", "commit": "928d0c2dc9606e01e2cc547196f48d2eaecf58e5" },
  "telescope.nvim": { "branch": "master", "commit": "d90956833d7c27e73c621a61f20b29fdb7122709" },
  "toggleterm.nvim": { "branch": "main", "commit": "50ea089fc548917cc3cc16b46a8211833b9e3c7c" },
  "which-key.nvim": { "branch": "main", "commit": "370ec46f710e058c9c1646273e6b225acf47cbed" },
  "winshift.nvim": { "branch": "main", "commit": "37468ed6f385dfb50402368669766504c0e15583" }
}
```

### File: lua/mlamkadm/core/42-formatter.lua
```

return {
  {
    "Diogo-ss/42-C-Formatter.nvim",
    cmd = "CFormat42",  -- Ensures plugin loads when command is called
    config = function()
      local formatter = require("42-formatter")
      formatter.setup({
        formatter = "c_formatter_42",  -- Must be installed system-wide
        filetypes = {
          c = true,
          h = true,
          cpp = true,
          hpp = true
        }
      })

      -- Format on save for C-family files
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.c", "*.h", "*.cpp", "*.hpp" },
        group = vim.api.nvim_create_augroup("42AutoFormat", {}),
        callback = function()
          vim.cmd("CFormat42")
        end
      })

      -- Key mapping for manual formatting
      vim.keymap.set("n", "<leader>cf", "<cmd>CFormat42<CR>", { desc = "Format with 42 Norm" })
    end
  }
}
```

### File: lua/mlamkadm/core/cmp.lua
```
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' },
        { name = "copilot" },
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping.select_next_item(),
        ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        ['<C-e>'] = cmp.mapping.abort(),
    }),
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
})

-- Add capabilities for nvim-cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

```

### File: lua/mlamkadm/core/gemini-integration.lua
```
local M = {}

-- Configuration
local config = {
    api_key = "AIzaSyDRKg7kYPJPSCxYhsSWC73xK1iCoaDA3Z4",
    model = "gemini-1.5-pro-latest",
    max_tokens = 2048,
    temperature = 0.3,
    popup_border = "rounded",
    prompt_prefix = "%% " -- Trigger for copilot suggestions
}

-- Custom prompts registry
local prompts = {
    explain = "Explain this code in simple terms:",
    improve = "Improve this code with better practices:",
    docstring = "Write a detailed docstring for this code:",
    debug = "Help debug this code. What's wrong with it?"
}

-- Track floating windows
local windows = {}

local function close_windows()
    for _, win in ipairs(windows) do
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end
    windows = {}
end

local function show_popup(content, title)
    close_windows()

    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.min(math.floor(vim.o.columns * 0.8), 80)
    local height = math.min(math.floor(vim.o.lines * 0.8), 20)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = "minimal",
        border = config.popup_border,
        title = title or "Gemini Response"
    })

    table.insert(windows, win)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
    vim.api.nvim_buf_set_option(buf, "modifiable", false)

    vim.api.nvim_create_autocmd({ "BufHidden", "BufLeave" }, {
        buffer = buf,
        callback = close_windows,
        once = true
    })
end

local function get_visual_selection()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local lines = vim.fn.getline(s_start[2], s_end[2])

    if #lines == 0 then return "" end

    lines[1] = string.sub(lines[1], s_start[3], -1)
    if #lines == 1 then
        lines[#lines] = string.sub(lines[#lines], 1, s_end[3] - s_start[3] + 1)
    else
        lines[#lines] = string.sub(lines[#lines], 1, s_end[3])
    end

    return table.concat(lines, "\n")
end

local function query_gemini(prompt, context)
    local full_prompt = context and (context .. "\n\n" .. prompt) or prompt

    local cmd = string.format(
        [[curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s" ]] ..
        [[-H "Content-Type: application/json" ]] ..
        [[-d '{"contents":[{"parts":[{"text":"%s"}]}],"generationConfig":{"temperature":%f,"maxOutputTokens":%d}}']],
        config.model,
        config.api_key,
        full_prompt:gsub('"', '\\"'):gsub("\n", "\\n"),
        config.temperature,
        config.max_tokens
    )

    local handle = io.popen(cmd)
    if not handle then return nil, "Failed to execute curl command" end

    local result = handle:read("*a")
    handle:close()

    local ok, response = pcall(vim.json.decode, result)
    if not ok then return nil, "Failed to parse JSON response" end

    if response.error then
        return nil, response.error.message
    end

    if response.candidates and response.candidates[1] then
        return response.candidates[1].content.parts[1].text
    end

    return nil, "No response from API"
end

-- Auto-complete handler
local function copilot_complete()
    local line = vim.api.nvim_get_current_line()
    local prefix = line:match(config.prompt_prefix .. "(.*)$")
    if not prefix then return {} end

    local response, err = query_gemini(prefix)
    if not response then
        vim.notify("Gemini error: " .. err, vim.log.levels.ERROR)
        return {}
    end

    local suggestions = {}
    for line in response:gmatch("[^\n]+") do
        table.insert(suggestions, {
            word = line:gsub("^%s+", ""),
            menu = "[Gemini]"
        })
    end

    return suggestions
end

-- Visual mode prompt application
function M.apply_prompt(prompt_name)
    local context = get_visual_selection()
    local prompt = prompts[prompt_name]

    if not prompt then
        vim.notify("Unknown prompt: " .. prompt_name, vim.log.levels.ERROR)
        return
    end

    vim.schedule(function()
        local response, err = query_gemini(prompt, context)
        if not response then
            vim.notify("Gemini error: " .. err, vim.log.levels.ERROR)
            return
        end

        show_popup(response, "Gemini: " .. prompt_name)
    end)
end

-- Custom query interface
function M.custom_query()
    vim.ui.input({ prompt = "Gemini Query: " }, function(input)
        if not input or input == "" then return end

        local context = get_visual_selection()
        vim.schedule(function()
            local response, err = query_gemini(input, context)
            if not response then
                vim.notify("Gemini error: " .. err, vim.log.levels.ERROR)
                return
            end

            show_popup(response, "Gemini Response")
        end)
    end)
end

-- Setup function
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})

    -- -- Set up auto-complete
    -- vim.api.nvim_create_autocmd("FileType", {
    --     pattern = "*",
    --     callback = function()
    --         vim.bo.omnifunc = "v:lua.require'gemini'.copilot_complete"
    --     end
    -- })

    -- Add user commands
    vim.api.nvim_create_user_command("GeminiPrompt", function(args)
        M.apply_prompt(args.args)
    end, { nargs = 1, complete = function() return vim.tbl_keys(prompts) end })

    vim.api.nvim_create_user_command("GeminiQuery", function()
        M.custom_query()
    end, {})

    -- Example key mappings
    vim.keymap.set("v", "<leader>ge", function() M.apply_prompt("explain") end)
    vim.keymap.set("v", "<leader>gi", function() M.apply_prompt("improve") end)
    vim.keymap.set("v", "<leader>gq", M.custom_query)
end

return M
```

### File: lua/mlamkadm/core/gemini.lua
```
-- ************************************************************************** --
--                                                                            --
--                                                        :::      ::::::::   --
--   gemini.lua                                         :+:      :+:    :+:   --
--                                                    +:+ +:+         +:+     --
--   By: mlamkadm <mlamkadm@student.42.fr>          +#+  +:+       +#+        --
--                                                +#+#+#+#+#+   +#+           --
--   Created: 2025/04/01 11:26:49 by mlamkadm          #+#    #+#             --
--   Updated: 2025/04/01 11:26:49 by mlamkadm         ###   ########.fr       --
--                                                                            --
-- ************************************************************************** --

local gemini = {}

-- Configuration
local config = {
    api_key = "AIzaSyDRKg7kYPJPSCxYhsSWC73xK1iCoaDA3Z4",
    model = "gemini-1.5-pro-latest",
    base_url = "https://generativelanguage.googleapis.com/v1beta/models",
    temperature = 0.3,
    max_tokens = 2048
}

-- Dependencies (these would need to be available in your Lua environment)
local json
local http

json = require('lunajson')
-- -- Try to load required libraries
-- if pcall(require, 'lunajson') then
--     json = require('lunajson')
-- elseif pcall(require, 'cjson') then
--     json = require('cjson')
-- elseif pcall(require, 'json') then
--     json = require('json')
-- else
--     error("JSON library required (dkjson, cjson, or similar)")
-- end

if pcall(require, 'socket.http') then
    http = require('socket.http')
elseif pcall(require, 'resty.http') then
    http = require('resty.http')
else
    error("HTTP library required (socket.http, resty.http, or similar)")
end

-- Helper function for HTTP requests
local function make_request(url, payload)
    local body = json.encode(payload)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #body
    }

    local res, status, response_headers
    if http.request then -- LuaSocket style
        local request_body = {}
        res, status, response_headers = http.request {
            url = url,
            method = "POST",
            headers = headers,
            source = ltn12.source.string(body),
            sink = ltn12.sink.table(request_body)
        }
        res = table.concat(request_body)
    else -- OpenResty style
        local client = http.new()
        res, err = client:request_uri(url, {
            method = "POST",
            body = body,
            headers = headers
        })
        if not res then
            return nil, err
        end
        status = res.status
        res = res.body
    end

    if status ~= 200 then
        return nil, "HTTP error: " .. tostring(status)
    end

    local data, err = json.decode(res)
    if not data then
        return nil, "JSON decode error: " .. tostring(err)
    end

    return data
end

-- Main generation function
function gemini.generate(prompt, options)
    options = options or {}
    local url = string.format("%s/%s:generateContent?key=%s",
        config.base_url,
        options.model or config.model,
        options.api_key or config.api_key)

    local payload = {
        contents = {
            {
                parts = {
                    {
                        text = prompt
                    }
                }
            }
        },
        generationConfig = {
            temperature = options.temperature or config.temperature,
            maxOutputTokens = options.max_tokens or config.max_tokens
        }
    }

    local data, err = make_request(url, payload)
    if not data then
        return nil, err
    end

    -- Extract response text
    if data.candidates and data.candidates[1] and data.candidates[1].content and data.candidates[1].content.parts then
        return data.candidates[1].content.parts[1].text
    else
        local error_msg = data.error and data.error.message or "Unknown error"
        return nil, "API Error: " .. error_msg
    end
end

-- Simple chat interface
function gemini.chat(options)
    options = options or {}
    local history = options.history or {}

    return function(prompt)
        table.insert(history, { role = "user", parts = { { text = prompt } } })

        local url = string.format("%s/%s:generateContent?key=%s",
            config.base_url,
            options.model or config.model,
            options.api_key or config.api_key)

        local payload = {
            contents = history,
            generationConfig = {
                temperature = options.temperature or config.temperature,
                maxOutputTokens = options.max_tokens or config.max_tokens
            }
        }

        local data, err = make_request(url, payload)
        if not data then
            return nil, err
        end

        -- Extract response
        if data.candidates and data.candidates[1] and data.candidates[1].content then
            local response = data.candidates[1].content
            table.insert(history, response)

            if response.parts and response.parts[1] then
                return response.parts[1].text
            end
        end

        local error_msg = data.error and data.error.message or "Unknown error"
        return nil, "API Error: " .. error_msg
    end
end

-- Tool calling support (basic implementation)
function gemini.tool_prompt(system_prompt, tools, history, user_input)
    local prompt = system_prompt .. "\n\n"

    if tools and next(tools) ~= nil then
        prompt = prompt .. "Available tools:\n"
        for name, tool in pairs(tools) do
            prompt = prompt .. string.format("- %s: %s\n", name, tool.description)
            prompt = prompt .. string.format("  Parameters: %s\n", json.encode(tool.params_schema))
        end
        prompt = prompt .. "\n"
    end

    if history and next(history) ~= nil then
        prompt = prompt .. "Conversation history:\n"
        for _, msg in ipairs(history) do
            prompt = prompt .. string.format("%s: %s\n", msg.role, msg.content)
        end
        prompt = prompt .. "\n"
    end

    prompt = prompt .. string.format("User: %s\n\nAssistant: ", user_input)

    return prompt
end

return gemini
```

### File: lua/mlamkadm/core/init.lua
```
require("mlamkadm.core.options")
require("mlamkadm.core.keymaps")

```

### File: lua/mlamkadm/core/keymaps.lua
```
-----------------------------------------------------------
-- Define keymaps of Neovim and installed plugins.
-----------------------------------------------------------

local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.g.mapleader = ' '

-----------------------------------------------------------
-- Neovim shortcuts
-----------------------------------------------------------

--
-- Disable arrow keys
map('', '<up>', '<nop>')
map('', '<down>', '<nop>')
map('', '<left>', '<nop>')
map('', '<right>', '<nop>')

-- Clear search highlighting with <leader> and c
map('n', '<leader>c', ':nohl<CR>')

-- Toggle auto-indenting for code paste
--
--map('n', '<F2>', ':set invpaste paste?<CR>')
--vim.opt.pastetoggle = '<F2>'

-- Change split orientation
map('n', '<leader>tk', '<C-w>t<C-w>K') -- change vertical to horizontal
map('n', '<leader>th', '<C-w>t<C-w>H') -- change horizontal to vertical

-- Move around splits using Ctrl + {h,j,k,l}
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- split keymaps
map('n', '<leader>-', '<cmd>split<cr>')
map('n', '<leader>=', '<cmd>vsplit<cr>')

map('n', '<C-Left>', '<cmd>vertical resize -7<cr>')
map('n', '<C-Right>', '<cmd>vertical resize +7<cr>')
map('n', '<C-Up>', '<cmd>horizontal resize +7<cr>')
map('n', '<C-Down>', '<cmd>horizontal resize -7<cr>')

-- Reload configuration without restart nvim
map('n', '<leader>r', ':so %<CR>')

-- Fast saving with <leader> and s
map('n', '<leader>s', ':w<CR>')


map('n', '<leader>q', ':qall!<CR>')

-----------------------------------------------------------
-- Applications and Plugins shortcuts
-----------------------------------------------------------

-- Terminal mappings
map('n', '<C-t>', ':ToggleTerm<CR>', { noremap = true }) -- open
map('t', '<C-t>', '<C-\\><C-n>')                   -- exit

-- NvimTree
map('n', '<C-n>', ':NvimTreeToggle<CR>')       -- open/close
map('n', '<leader>f', ':NvimTreeRefresh<CR>')  -- refresh
map('n', '<leader>n', ':NvimTreeFindFile<CR>') -- search file

-- Tagbar
map('n', '<leader>z', ':TagbarToggle<CR>') -- open/close

map('n', '<leader>g', ':Glow<CR>')

-- Formatting

-- map('n', '<leader>p', '<cmd>LspZeroFormat<CR>', { noremap = true, silent = true })
map('n', '<leader>p', ':CFormat42<CR>', { noremap = true, silent = true })
```

### File: lua/mlamkadm/core/ollama.lua
```
-- ollama.nvim: A Neovim plugin for interacting with Ollama local LLMs
-- Author: Claude
-- License: MIT

local M = {}
local api = vim.api
local fn = vim.fn

-- Default configuration
M.config = {
    host = "http://localhost",
    port = 11434,
    default_model = "mistral:7b",
    models = {
        "llama2",
        "codellama",
        "mistral",
        "phi2",
        "gemma"
    },
    keymaps = {
        prompt = "<leader>op", -- Open prompt
        inline = "<leader>oi", -- Generate inline completion
        selection = "<leader>os", -- Process selection
        chat = "<leader>oc",  -- Open chat window
    },
    window = {
        width = 0.8, -- Percentage of screen width
        height = 0.7, -- Percentage of screen height
        border = "rounded",
    },
    timeout = 30000, -- Request timeout in ms
    stream = true, -- Stream responses
}

-- Store the buffer for chat interface
M.buf = nil
M.win = nil
M.prompt_history = {}
M.history_index = 0
M.chat_history = {}
M.model = nil

-- Utility function to make API requests to Ollama
local function ollama_request(endpoint, data, callback)
    local curl_cmd = string.format(
        "curl -s -X POST %s:%d/api/%s -H 'Content-Type: application/json' -d '%s'",
        M.config.host,
        M.config.port,
        endpoint,
        vim.json.encode(data)
    )

    local handle = io.popen(curl_cmd)
    if not handle then
        vim.notify("Failed to execute curl command", vim.log.levels.ERROR)
        return
    end

    local result = handle:read("*a")
    handle:close()

    local ok, parsed = pcall(vim.json.decode, result)
    if not ok then
        vim.notify("Failed to parse JSON response: " .. result, vim.log.levels.ERROR)
        return
    end

    if callback then
        callback(parsed)
    end

    return parsed
end

-- Get available models from Ollama
function M.get_models(callback)
    ollama_request("tags", {}, function(response)
        if response and response.models then
            callback(response.models)
        else
            vim.notify("Failed to fetch models", vim.log.levels.ERROR)
        end
    end)
end

-- Create floating window for chat/prompts
function M.create_window()
    -- Calculate window size
    local width = math.floor(vim.o.columns * M.config.window.width)
    local height = math.floor(vim.o.lines * M.config.window.height)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create buffer if it doesn't exist
    if not M.buf or not api.nvim_buf_is_valid(M.buf) then
        M.buf = api.nvim_create_buf(false, true)
        api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
        api.nvim_buf_set_option(M.buf, 'bufhidden', 'hide')
    end

    -- Window options
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = M.config.window.border,
        title = " Ollama Chat ",
        title_pos = "center",
    }

    -- Create window
    if not M.win or not api.nvim_win_is_valid(M.win) then
        M.win = api.nvim_open_win(M.buf, true, opts)
        api.nvim_win_set_option(M.win, 'wrap', true)
        api.nvim_win_set_option(M.win, 'linebreak', true)
    else
        api.nvim_win_set_config(M.win, opts)
    end

    -- Return to window if it exists
    api.nvim_set_current_win(M.win)

    -- Set some keymaps for the chat buffer
    local buffer_maps = {
        ["<Esc>"] = ":lua require('ollama').close_window()<CR>",
        ["q"] = ":lua require('ollama').close_window()<CR>",
        ["<C-c>"] = ":lua require('ollama').close_window()<CR>",
        ["<C-k>"] = ":lua require('ollama').scroll_up()<CR>",
        ["<C-j>"] = ":lua require('ollama').scroll_down()<CR>",
    }

    for k, v in pairs(buffer_maps) do
        api.nvim_buf_set_keymap(M.buf, 'n', k, v, { noremap = true, silent = true })
    end

    return M.buf, M.win
end

-- Close the floating window
function M.close_window()
    if M.win and api.nvim_win_is_valid(M.win) then
        api.nvim_win_close(M.win, true)
        M.win = nil
    end
end

-- Scroll functions for chat window
function M.scroll_up()
    local cursor = api.nvim_win_get_cursor(M.win)
    if cursor[1] > 1 then
        api.nvim_win_set_cursor(M.win, { cursor[1] - 1, cursor[2] })
    end
end

function M.scroll_down()
    local cursor = api.nvim_win_get_cursor(M.win)
    local line_count = api.nvim_buf_line_count(M.buf)
    if cursor[1] < line_count then
        api.nvim_win_set_cursor(M.win, { cursor[1] + 1, cursor[2] })
    end
end

-- Open a prompt input for quick queries
function M.open_prompt()
    local model = M.model or M.config.default_model
    local prompt = vim.fn.input({
        prompt = "Ollama (" .. model .. "): ",
        completion = "customlist,v:lua.require'ollama'.complete_prompt",
        cancelreturn = "",
    })

    if prompt and prompt ~= "" then
        table.insert(M.prompt_history, prompt)
        M.history_index = #M.prompt_history + 1

        M.create_window()
        api.nvim_buf_set_lines(M.buf, 0, -1, false, {
            "# Query",
            prompt,
            "",
            "# Response",
            "Thinking..."
        })

        M.generate_completion(prompt, nil, function(response)
            if response and response.response then
                api.nvim_buf_set_lines(M.buf, 4, 5, false, vim.split(response.response, "\n"))
            else
                api.nvim_buf_set_lines(M.buf, 4, 5, false, { "Error: Failed to get response" })
            end
        end)
    end
end

-- Generate inline completion at cursor position
function M.inline_completion()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_get_current_line()
    local prefix = string.sub(line, 1, col)

    if prefix:match("^%s*$") then
        vim.notify("Please provide some context for inline completion", vim.log.levels.WARN)
        return
    end

    -- Get the few lines before cursor for context
    local start_row = math.max(1, row - 10)
    local context_lines = api.nvim_buf_get_lines(0, start_row - 1, row, false)
    local context = table.concat(context_lines, "\n")

    local prompt = "Continue the following code or text. Only provide the continuation:\n\n" .. context

    -- Create a temporary notification
    vim.notify("Generating completion...", vim.log.levels.INFO)

    M.generate_completion(prompt, nil, function(response)
        if response and response.response then
            -- Get completion text and remove leading whitespace
            local completion_text = response.response:gsub("^%s+", "")

            -- Insert the completion at cursor position
            local new_line = prefix .. completion_text
            api.nvim_set_current_line(new_line)
            api.nvim_win_set_cursor(0, { row, #new_line })
        else
            vim.notify("Failed to get completion", vim.log.levels.ERROR)
        end
    end)
end

-- Process selected text with Ollama
function M.process_selection()
    -- Get visual selection
    local start_pos = fn.getpos("'<")
    local end_pos = fn.getpos("'>")
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    -- Get selected text
    local lines
    if start_row == end_row then
        local line = api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
        lines = { line:sub(start_col, end_col) }
    else
        lines = api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
        if #lines > 0 then
            lines[1] = lines[1]:sub(start_col)
            lines[#lines] = lines[#lines]:sub(1, end_col)
        end
    end

    local selected_text = table.concat(lines, "\n")

    -- Get the action to perform
    local actions = {
        "Explain this code",
        "Improve this code",
        "Optimize this code",
        "Document this code",
        "Find bugs in this code",
        "Complete this code",
        "Summarize this text",
        "Other (custom prompt)",
    }

    vim.ui.select(actions, {
        prompt = "What do you want to do with the selection?",
    }, function(choice)
        if not choice then return end

        local prompt
        if choice == "Other (custom prompt)" then
            prompt = vim.fn.input({
                prompt = "Custom prompt: ",
                cancelreturn = "",
            })
            if prompt == "" then return end
            prompt = prompt .. ":\n\n" .. selected_text
        else
            prompt = choice .. ":\n\n" .. selected_text
        end

        -- Create window for response
        M.create_window()
        api.nvim_buf_set_lines(M.buf, 0, -1, false, {
            "# Selection",
            selected_text,
            "",
            "# " .. choice,
            "Thinking..."
        })

        M.generate_completion(prompt, nil, function(response)
            if response and response.response then
                api.nvim_buf_set_lines(M.buf, 4, 5, false, vim.split(response.response, "\n"))
            else
                api.nvim_buf_set_lines(M.buf, 4, 5, false, { "Error: Failed to get response" })
            end
        end)
    end)
end

-- Open chat interface with persistent history
function M.open_chat()
    M.create_window()

    -- If we don't have a model selected, prompt for one
    if not M.model then
        M.select_model(function()
            M.display_chat_history()
        end)
    else
        M.display_chat_history()
    end
end

-- Display the chat history in the buffer
function M.display_chat_history()
    local lines = { "# Ollama Chat (" .. (M.model or M.config.default_model) .. ")", "" }

    -- Add chat history
    for _, msg in ipairs(M.chat_history) do
        table.insert(lines, "## " .. msg.role)
        table.insert(lines, "")
        for _, line in ipairs(vim.split(msg.content, "\n")) do
            table.insert(lines, line)
        end
        table.insert(lines, "")
    end

    -- Add prompt for user input
    table.insert(lines, "## You")
    table.insert(lines, "")
    table.insert(lines, "_Type your message here and press <C-Enter> to send_")

    -- Set the buffer content
    api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)

    -- Move cursor to the last line
    api.nvim_win_set_cursor(M.win, { #lines, 0 })

    -- Enter insert mode
    vim.cmd("startinsert!")

    -- Set keymap for sending the message
    api.nvim_buf_set_keymap(M.buf, 'i', '<C-CR>',
        "<Esc>:lua require('ollama').send_chat_message()<CR>",
        { noremap = true, silent = true }
    )
end

-- Send a message from the chat interface
function M.send_chat_message()
    -- Get current buffer content
    local lines = api.nvim_buf_get_lines(M.buf, 0, -1, false)

    -- Find the start of the user's latest message
    local start_idx = 0
    for i = #lines, 1, -1 do
        if lines[i] == "## You" then
            start_idx = i + 2 -- +2 to skip the "## You" line and the empty line
            break
        end
    end

    if start_idx == 0 then return end

    -- Extract the message
    local message_lines = {}
    for i = start_idx, #lines do
        local line = lines[i]
        if line ~= "_Type your message here and press <C-Enter> to send_" then
            table.insert(message_lines, line)
        end
    end

    local message = table.concat(message_lines, "\n")
    message = message:gsub("^%s+", ""):gsub("%s+$", "")

    if message == "" then
        vim.notify("Please enter a message", vim.log.levels.WARN)
        return
    end

    -- Add the message to chat history
    table.insert(M.chat_history, {
        role = "You",
        content = message
    })

    -- Update the display with a "thinking" message
    table.insert(M.chat_history, {
        role = "Ollama",
        content = "Thinking..."
    })

    M.display_chat_history()

    -- Generate response
    local messages = {}
    for _, msg in ipairs(M.chat_history) do
        table.insert(messages, {
            role = msg.role == "You" and "user" or "assistant",
            content = msg.content
        })
    end

    -- Remove the "thinking" message
    table.remove(M.chat_history)

    ollama_request("chat", {
        model = M.model or M.config.default_model,
        messages = messages,
        stream = M.config.stream
    }, function(response)
        if response and response.message and response.message.content then
            -- Add the response to chat history
            table.insert(M.chat_history, {
                role = "Ollama",
                content = response.message.content
            })

            -- Update the display
            M.display_chat_history()
        else
            vim.notify("Failed to get chat response", vim.log.levels.ERROR)
            -- Remove the thinking message
            table.remove(M.chat_history)
            M.display_chat_history()
        end
    end)
end

-- Generate completion with Ollama
function M.generate_completion(prompt, model, callback)
    ollama_request("generate", {
        model = model or M.model or M.config.default_model,
        prompt = prompt,
        stream = false
    }, callback)
end

-- Select a model from available models
function M.select_model(callback)
    M.get_models(function(models)
        local model_names = {}
        for _, model in ipairs(models) do
            table.insert(model_names, model.name)
        end

        vim.ui.select(model_names, {
            prompt = "Select Ollama model:",
        }, function(choice)
            if choice then
                M.model = choice
                vim.notify("Using model: " .. choice, vim.log.levels.INFO)
                if callback then callback() end
            end
        end)
    end)
end

-- Command completion for prompts
function M.complete_prompt(arg_lead, cmd_line, cursor_pos)
    local results = {}
    if #M.prompt_history == 0 then
        return results
    end

    arg_lead = arg_lead:lower()
    for i = #M.prompt_history, 1, -1 do
        local item = M.prompt_history[i]
        if arg_lead == "" or item:lower():find(arg_lead, 1, true) then
            table.insert(results, item)
        end
    end

    return results
end

-- Setup function
function M.setup(user_config)
    -- Merge user config with defaults
    if user_config then
        for k, v in pairs(user_config) do
            if type(v) == "table" and type(M.config[k]) == "table" then
                for k2, v2 in pairs(v) do
                    M.config[k][k2] = v2
                end
            else
                M.config[k] = v
            end
        end
    end

    -- Set keymaps
    vim.keymap.set('n', M.config.keymaps.prompt, function() M.open_prompt() end, { desc = "Ollama: Open prompt" })
    vim.keymap.set('n', M.config.keymaps.inline, function() M.inline_completion() end,
        { desc = "Ollama: Inline completion" })
    vim.keymap.set('v', M.config.keymaps.selection, function() M.process_selection() end,
        { desc = "Ollama: Process selection" })
    vim.keymap.set('n', M.config.keymaps.chat, function() M.open_chat() end, { desc = "Ollama: Open chat" })

    -- Create user commands
    vim.api.nvim_create_user_command("OllamaPrompt", function() M.open_prompt() end, {})
    vim.api.nvim_create_user_command("OllamaInline", function() M.inline_completion() end, {})
    vim.api.nvim_create_user_command("OllamaChat", function() M.open_chat() end, {})
    vim.api.nvim_create_user_command("OllamaSelectModel", function() M.select_model() end, {})
end

return M
```

### File: lua/mlamkadm/core/ollama-mk2.lua
```
-- ollama.nvim: A Neovim plugin for interacting with Ollama local LLMs
-- Author: Claude
-- License: MIT

local M = {}
local api = vim.api
local fn = vim.fn

-- Default configuration
M.config = {
    host = "http://localhost",
    port = 11434,
    default_model = "mistral:7b",
    models = {
        "llama2",
        "codellama",
        "mistral",
        "phi2",
        "gemma"
    },
    keymaps = {
        prompt = "<leader>op", -- Open prompt
        inline = "<leader>oi", -- Generate inline completion
        selection = "<leader>os", -- Process selection
        chat = "<leader>oc",  -- Open chat window
    },
    window = {
        width = 0.8, -- Percentage of screen width
        height = 0.7, -- Percentage of screen height
        border = "rounded",
    },
    timeout = 30000, -- Request timeout in ms
    stream = true, -- Stream responses
}

-- Buffers and history
M.buf = nil
M.win = nil
M.prompt_history = {}
M.history_index = 0
M.chat_history = {}
M.model = nil

-----------------------------------------------------------
-- Utility: Execute an API request to the Ollama server.
-----------------------------------------------------------
local function ollama_request(endpoint, data, callback)
    local curl_cmd = string.format(
        "curl -s -X POST %s:%d/api/%s -H 'Content-Type: application/json' -d '%s'",
        M.config.host,
        M.config.port,
        endpoint,
        vim.json.encode(data)
    )

    local handle = io.popen(curl_cmd)
    if not handle then
        vim.notify("Failed to execute curl command", vim.log.levels.ERROR)
        return
    end

    local result = handle:read("*a")
    handle:close()

    local ok, parsed = pcall(vim.json.decode, result)
    if not ok then
        vim.notify("Failed to parse JSON response: " .. result, vim.log.levels.ERROR)
        return
    end

    if callback then
        callback(parsed)
    end

    return parsed
end

-----------------------------------------------------------
-- Get available models from Ollama.
-----------------------------------------------------------
function M.get_models(callback)
    ollama_request("tags", {}, function(response)
        if response and response.models then
            callback(response.models)
        else
            vim.notify("Failed to fetch models", vim.log.levels.ERROR)
        end
    end)
end

-----------------------------------------------------------
-- Create a floating window for chat/prompts.
-----------------------------------------------------------
function M.create_window()
    local width = math.floor(vim.o.columns * M.config.window.width)
    local height = math.floor(vim.o.lines * M.config.window.height)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create buffer if needed
    if not M.buf or not api.nvim_buf_is_valid(M.buf) then
        M.buf = api.nvim_create_buf(false, true)
        api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
        api.nvim_buf_set_option(M.buf, 'bufhidden', 'hide')
    end

    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = M.config.window.border,
        title = " Ollama Chat ",
        title_pos = "center",
    }

    if not M.win or not api.nvim_win_is_valid(M.win) then
        M.win = api.nvim_open_win(M.buf, true, opts)
        api.nvim_win_set_option(M.win, 'wrap', true)
        api.nvim_win_set_option(M.win, 'linebreak', true)
    else
        api.nvim_win_set_config(M.win, opts)
    end

    api.nvim_set_current_win(M.win)

    -- Set buffer keymaps for the chat window
    local buffer_maps = {
        ["<Esc>"] = ":lua require('ollama').close_window()<CR>",
        ["q"] = ":lua require('ollama').close_window()<CR>",
        ["<C-c>"] = ":lua require('ollama').close_window()<CR>",
        ["<C-k>"] = ":lua require('ollama').scroll_up()<CR>",
        ["<C-j>"] = ":lua require('ollama').scroll_down()<CR>",
    }

    for k, v in pairs(buffer_maps) do
        api.nvim_buf_set_keymap(M.buf, 'n', k, v, { noremap = true, silent = true })
    end

    return M.buf, M.win
end

-----------------------------------------------------------
-- Close the floating window.
-----------------------------------------------------------
function M.close_window()
    if M.win and api.nvim_win_is_valid(M.win) then
        api.nvim_win_close(M.win, true)
        M.win = nil
    end
end

-----------------------------------------------------------
-- Scroll functions for the chat window.
-----------------------------------------------------------
function M.scroll_up()
    local cursor = api.nvim_win_get_cursor(M.win)
    if cursor[1] > 1 then
        api.nvim_win_set_cursor(M.win, { cursor[1] - 1, cursor[2] })
    end
end

function M.scroll_down()
    local cursor = api.nvim_win_get_cursor(M.win)
    local line_count = api.nvim_buf_line_count(M.buf)
    if cursor[1] < line_count then
        api.nvim_win_set_cursor(M.win, { cursor[1] + 1, cursor[2] })
    end
end

-----------------------------------------------------------
-- Open a prompt for quick queries.
-----------------------------------------------------------
function M.open_prompt()
    local model = M.model or M.config.default_model
    local prompt = vim.fn.input({
        prompt = "Ollama (" .. model .. "): ",
        completion = "customlist,v:lua.require'ollama'.complete_prompt",
        cancelreturn = "",
    })

    if prompt and prompt ~= "" then
        table.insert(M.prompt_history, prompt)
        M.history_index = #M.prompt_history + 1

        M.create_window()
        api.nvim_buf_set_lines(M.buf, 0, -1, false, {
            "# Query",
            prompt,
            "",
            "# Response",
            "Thinking..."
        })

        M.generate_completion(prompt, nil, function(response)
            if response and response.response then
                api.nvim_buf_set_lines(M.buf, 4, 5, false, vim.split(response.response, "\n"))
            else
                api.nvim_buf_set_lines(M.buf, 4, 5, false, { "Error: Failed to get response" })
            end
        end)
    end
end

-----------------------------------------------------------
-- Generate inline completion at the cursor position.
-----------------------------------------------------------
function M.inline_completion()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_get_current_line()
    local prefix = string.sub(line, 1, col)

    if prefix:match("^%s*$") then
        vim.notify("Please provide some context for inline completion", vim.log.levels.WARN)
        return
    end

    -- Get context from previous lines
    local start_row = math.max(1, row - 10)
    local context_lines = api.nvim_buf_get_lines(0, start_row - 1, row, false)
    local context = table.concat(context_lines, "\n")
    local prompt = "Continue the following code or text. Only provide the continuation:\n\n" .. context

    vim.notify("Generating completion...", vim.log.levels.INFO)

    M.generate_completion(prompt, nil, function(response)
        if response and response.response then
            local completion_text = response.response:gsub("^%s+", "")
            local new_line = prefix .. completion_text
            api.nvim_set_current_line(new_line)
            api.nvim_win_set_cursor(0, { row, #new_line })
        else
            vim.notify("Failed to get completion", vim.log.levels.ERROR)
        end
    end)
end

-----------------------------------------------------------
-- Process selected text with Ollama.
-----------------------------------------------------------
function M.process_selection()
    -- Get visual selection positions
    local start_pos = fn.getpos("'<")
    local end_pos = fn.getpos("'>")
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    local lines
    if start_row == end_row then
        local line = api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
        lines = { line:sub(start_col, end_col) }
    else
        lines = api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
        if #lines > 0 then
            lines[1] = lines[1]:sub(start_col)
            lines[#lines] = lines[#lines]:sub(1, end_col)
        end
    end

    local selected_text = table.concat(lines, "\n")
    local actions = {
        "Explain this code",
        "Improve this code",
        "Optimize this code",
        "Document this code",
        "Find bugs in this code",
        "Complete this code",
        "Summarize this text",
        "Other (custom prompt)",
    }

    vim.ui.select(actions, {
        prompt = "What do you want to do with the selection?",
    }, function(choice)
        if not choice then
            return
        end

        local prompt
        if choice == "Other (custom prompt)" then
            prompt = vim.fn.input({ prompt = "Custom prompt: ", cancelreturn = "" })
            if prompt == "" then
                return
            end
            prompt = prompt .. ":\n\n" .. selected_text
        else
            prompt = choice .. ":\n\n" .. selected_text
        end

        M.create_window()
        api.nvim_buf_set_lines(M.buf, 0, -1, false, {
            "# Selection",
            selected_text,
            "",
            "# " .. choice,
            "Thinking..."
        })

        M.generate_completion(prompt, nil, function(response)
            if response and response.response then
                api.nvim_buf_set_lines(M.buf, 4, 5, false, vim.split(response.response, "\n"))
            else
                api.nvim_buf_set_lines(M.buf, 4, 5, false, { "Error: Failed to get response" })
            end
        end)
    end)
end

-----------------------------------------------------------
-- Open chat interface with persistent history.
-----------------------------------------------------------
function M.open_chat()
    M.create_window()

    if not M.model then
        M.select_model(function()
            M.display_chat_history()
        end)
    else
        M.display_chat_history()
    end
end

-----------------------------------------------------------
-- Display the chat history in the floating buffer.
-----------------------------------------------------------
function M.display_chat_history()
    local lines = { "# Ollama Chat (" .. (M.model or M.config.default_model) .. ")", "" }

    for _, msg in ipairs(M.chat_history) do
        table.insert(lines, "## " .. msg.role)
        table.insert(lines, "")
        for _, line in ipairs(vim.split(msg.content, "\n")) do
            table.insert(lines, line)
        end
        table.insert(lines, "")
    end

    table.insert(lines, "## You")
    table.insert(lines, "")
    table.insert(lines, "_Type your message here and press <C-Enter> to send_")

    api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
    api.nvim_win_set_cursor(M.win, { #lines, 0 })

    vim.cmd("startinsert!")

    api.nvim_buf_set_keymap(M.buf, 'i', '<C-CR>',
        "<Esc>:lua require('ollama').send_chat_message()<CR>",
        { noremap = true, silent = true }
    )
end

-----------------------------------------------------------
-- Send a chat message from the chat interface.
-----------------------------------------------------------
function M.send_chat_message()
    local lines = api.nvim_buf_get_lines(M.buf, 0, -1, false)
    local start_idx = 0

    for i = #lines, 1, -1 do
        if lines[i] == "## You" then
            start_idx = i + 2 -- Skip "## You" and the following empty line
            break
        end
    end

    if start_idx == 0 then
        return
    end

    local message_lines = {}
    for i = start_idx, #lines do
        local line = lines[i]
        if line ~= "_Type your message here and press <C-Enter> to send_" then
            table.insert(message_lines, line)
        end
    end

    local message = table.concat(message_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    if message == "" then
        vim.notify("Please enter a message", vim.log.levels.WARN)
        return
    end

    table.insert(M.chat_history, { role = "You", content = message })
    table.insert(M.chat_history, { role = "Ollama", content = "Thinking..." })

    M.display_chat_history()

    local messages = {}
    for _, msg in ipairs(M.chat_history) do
        table.insert(messages, {
            role = msg.role == "You" and "user" or "assistant",
            content = msg.content
        })
    end

    -- Remove the "Thinking..." placeholder before requesting
    table.remove(M.chat_history)

    ollama_request("chat", {
        model = M.model or M.config.default_model,
        messages = messages,
        stream = M.config.stream
    }, function(response)
        if response and response.message and response.message.content then
            table.insert(M.chat_history, { role = "Ollama", content = response.message.content })
            M.display_chat_history()
        else
            vim.notify("Failed to get chat response", vim.log.levels.ERROR)
            table.remove(M.chat_history)
            M.display_chat_history()
        end
    end)
end

-----------------------------------------------------------
-- Generate a completion using the Ollama server.
-----------------------------------------------------------
function M.generate_completion(prompt, model, callback)
    ollama_request("generate", {
        model = model or M.model or M.config.default_model,
        prompt = prompt,
        stream = false
    }, callback)
end

-----------------------------------------------------------
-- Select a model from the available models.
-----------------------------------------------------------
function M.select_model(callback)
    M.get_models(function(models)
        local model_names = {}
        for _, model in ipairs(models) do
            table.insert(model_names, model.name)
        end

        vim.ui.select(model_names, {
            prompt = "Select Ollama model:",
        }, function(choice)
            if choice then
                M.model = choice
                vim.notify("Using model: " .. choice, vim.log.levels.INFO)
                if callback then callback() end
            end
        end)
    end)
end

-----------------------------------------------------------
-- Command-line completion for prompts.
-----------------------------------------------------------
function M.complete_prompt(arg_lead, cmd_line, cursor_pos)
    local results = {}
    if #M.prompt_history == 0 then
        return results
    end

    arg_lead = arg_lead:lower()
    for i = #M.prompt_history, 1, -1 do
        local item = M.prompt_history[i]
        if arg_lead == "" or item:lower():find(arg_lead, 1, true) then
            table.insert(results, item)
        end
    end

    return results
end

-----------------------------------------------------------
-- Setup the plugin with optional user configuration.
-----------------------------------------------------------
function M.setup(user_config)
    if user_config then
        -- Deep merge defaults with user configuration.
        M.config = vim.tbl_deep_extend("force", M.config, user_config)
    end

    vim.keymap.set('n', M.config.keymaps.prompt, function() M.open_prompt() end, { desc = "Ollama: Open prompt" })
    vim.keymap.set('n', M.config.keymaps.inline, function() M.inline_completion() end,
        { desc = "Ollama: Inline completion" })
    vim.keymap.set('v', M.config.keymaps.selection, function() M.process_selection() end,
        { desc = "Ollama: Process selection" })
    vim.keymap.set('n', M.config.keymaps.chat, function() M.open_chat() end, { desc = "Ollama: Open chat" })

    vim.api.nvim_create_user_command("OllamaPrompt", function() M.open_prompt() end, {})
    vim.api.nvim_create_user_command("OllamaInline", function() M.inline_completion() end, {})
    vim.api.nvim_create_user_command("OllamaChat", function() M.open_chat() end, {})
    vim.api.nvim_create_user_command("OllamaSelectModel", function() M.select_model() end, {})
end

return M
```

### File: lua/mlamkadm/core/ollama-vi.lua
```
-- ollama.nvim: A minimal Neovim plugin for processing visual selections with Ollama
-- Author: Claude
-- License: MIT

local M = {}
local api = vim.api
local fn = vim.fn

-- Minimal configuration
M.config = {
  host = "http://localhost",
  port = 11434,
  default_model = "mistral:7b",
  keymaps = {
    selection = "<leader>os", -- Process selection (visual mode)
  },
  window = {
    width = 0.8,   -- Percentage of screen width
    height = 0.7,  -- Percentage of screen height
    border = "rounded",
  },
  timeout = 30000, -- Request timeout in ms
  stream = false,  -- Disable streaming responses for simplicity
}

-- Buffer for the floating window
M.buf = nil
M.win = nil

-----------------------------------------------------------
-- Utility: Make an API request to the Ollama server.
-----------------------------------------------------------
local function ollama_request(endpoint, data, callback)
  local curl_cmd = string.format(
    "curl -s -X POST %s:%d/api/%s -H 'Content-Type: application/json' -d '%s'",
    M.config.host,
    M.config.port,
    endpoint,
    vim.json.encode(data)
  )

  local handle = io.popen(curl_cmd)
  if not handle then
    vim.notify("Failed to execute curl command", vim.log.levels.ERROR)
    return
  end

  local result = handle:read("*a")
  handle:close()

  local ok, parsed = pcall(vim.json.decode, result)
  if not ok then
    vim.notify("Failed to parse JSON response: " .. result, vim.log.levels.ERROR)
    return
  end

  if callback then
    callback(parsed)
  end

  return parsed
end

-----------------------------------------------------------
-- Create a floating window for displaying responses.
-----------------------------------------------------------
function M.create_window()
  local width = math.floor(vim.o.columns * M.config.window.width)
  local height = math.floor(vim.o.lines * M.config.window.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  if not M.buf or not api.nvim_buf_is_valid(M.buf) then
    M.buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
    api.nvim_buf_set_option(M.buf, 'bufhidden', 'hide')
  end

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = M.config.window.border,
    title = " Ollama Response ",
    title_pos = "center",
  }

  if not M.win or not api.nvim_win_is_valid(M.win) then
    M.win = api.nvim_open_win(M.buf, true, opts)
    api.nvim_win_set_option(M.win, 'wrap', true)
    api.nvim_win_set_option(M.win, 'linebreak', true)
  else
    api.nvim_win_set_config(M.win, opts)
  end

  api.nvim_set_current_win(M.win)
  return M.buf, M.win
end

-----------------------------------------------------------
-- Process the currently selected text in visual mode.
-----------------------------------------------------------
function M.process_selection()
  -- Get visual selection positions
  local start_pos = fn.getpos("'<")
  local end_pos = fn.getpos("'>")
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]

  local lines
  if start_row == end_row then
    local line = api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
    lines = { line:sub(start_col, end_col) }
  else
    lines = api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    if #lines > 0 then
      lines[1] = lines[1]:sub(start_col)
      lines[#lines] = lines[#lines]:sub(1, end_col)
    end
  end

  local selected_text = table.concat(lines, "\n")
  local action_choices = {
    "Explain this code",
    "Improve this code",
    "Optimize this code",
    "Document this code",
    "Find bugs in this code",
    "Complete this code",
    "Summarize this text",
    "Other (custom prompt)",
  }

  vim.ui.select(action_choices, {
    prompt = "What do you want to do with the selection?",
  }, function(choice)
    if not choice then
      return
    end

    local prompt_text
    if choice == "Other (custom prompt)" then
      prompt_text = vim.fn.input({ prompt = "Custom prompt: ", cancelreturn = "" })
      if prompt_text == "" then
        return
      end
      prompt_text = prompt_text .. ":\n\n" .. selected_text
    else
      prompt_text = choice .. ":\n\n" .. selected_text
    end

    -- Split the selected_text into lines to avoid embedded newlines in a single item.
    local selection_lines = vim.split(selected_text, "\n", { plain = true })

    -- Build the header lines for the floating window.
    local header_lines = {}
    table.insert(header_lines, "# Selection")
    for _, l in ipairs(selection_lines) do
      table.insert(header_lines, l)
    end
    table.insert(header_lines, "")
    table.insert(header_lines, "# " .. choice)
    table.insert(header_lines, "Thinking...")

    M.create_window()
    api.nvim_buf_set_lines(M.buf, 0, -1, false, header_lines)

    M.generate_completion(prompt_text, nil, function(response)
      if response and response.response then
        local response_lines = vim.split(response.response, "\n", { plain = true })
        api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, response_lines)
      else
        api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, { "Error: Failed to get response" })
      end
    end)
  end)
end

-----------------------------------------------------------
-- Generate a completion using the Ollama server.
-----------------------------------------------------------
function M.generate_completion(prompt, model, callback)
  ollama_request("generate", {
    model = model or M.config.default_model,
    prompt = prompt,
    stream = false
  }, callback)
end

-----------------------------------------------------------
-- Setup the plugin and map the visual mode selection key.
-----------------------------------------------------------
function M.setup(user_config)
  if user_config then
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
  end

  vim.keymap.set('v', M.config.keymaps.selection, function() M.process_selection() end,
    { desc = "Ollama: Process visual selection" }
  )

  vim.api.nvim_create_user_command("OllamaSelection", function() M.process_selection() end, {})
end

return M
```

### File: lua/mlamkadm/core/ollama-vi-mk2.lua
```
-- -- ollama.nvim: A minimal Neovim plugin for processing visual selections with streamed responses from Ollama
-- -- Author: Claude
-- -- License: MIT
--
-- local M = {}
-- local api = vim.api
-- local fn = vim.fn
--
-- -- Minimal configuration
-- M.config = {
--   host = "http://localhost",
--   port = 11434,
--   default_model = "mistral:7b",
--   keymaps = {
--     selection = "<leader>os", -- Process selection (visual mode)
--   },
--   window = {
--     width = 0.8,   -- Percentage of screen width
--     height = 0.7,  -- Percentage of screen height
--     border = "rounded",
--   },
--   timeout = 30000, -- Request timeout in ms
--   stream = true,   -- Enable streaming responses
-- }
--
-- -- Buffer for the floating window
-- M.buf = nil
-- M.win = nil
--
-- -----------------------------------------------------------
-- -- Utility: Make a non-streaming API request.
-- -----------------------------------------------------------
-- local function ollama_request(endpoint, data, callback)
--   local curl_cmd = string.format(
--     "curl -s -X POST %s:%d/api/%s -H 'Content-Type: application/json' -d '%s'",
--     M.config.host,
--     M.config.port,
--     endpoint,
--     vim.json.encode(data)
--   )
--
--   local handle = io.popen(curl_cmd)
--   if not handle then
--     vim.notify("Failed to execute curl command", vim.log.levels.ERROR)
--     return
--   end
--
--   local result = handle:read("*a")
--   handle:close()
--
--   local ok, parsed = pcall(vim.json.decode, result)
--   if not ok then
--     vim.notify("Failed to parse JSON response: " .. result, vim.log.levels.ERROR)
--     return
--   end
--
--   if callback then
--     callback(parsed)
--   end
--
--   return parsed
-- end
--
-- -----------------------------------------------------------
-- -- Create a floating window for displaying responses.
-- -----------------------------------------------------------
-- function M.create_window()
--   local width = math.floor(vim.o.columns * M.config.window.width)
--   local height = math.floor(vim.o.lines * M.config.window.height)
--   local row = math.floor((vim.o.lines - height) / 2)
--   local col = math.floor((vim.o.columns - width) / 2)
--
--   if not M.buf or not api.nvim_buf_is_valid(M.buf) then
--     M.buf = api.nvim_create_buf(false, true)
--     api.nvim_buf_set_option(M.buf, 'filetype', 'markdown')
--     api.nvim_buf_set_option(M.buf, 'bufhidden', 'hide')
--   end
--
--   local opts = {
--     relative = 'editor',
--     width = width,
--     height = height,
--     row = row,
--     col = col,
--     style = 'minimal',
--     border = M.config.window.border,
--     title = " Ollama Response ",
--     title_pos = "center",
--   }
--
--   if not M.win or not api.nvim_win_is_valid(M.win) then
--     M.win = api.nvim_open_win(M.buf, true, opts)
--     api.nvim_win_set_option(M.win, 'wrap', true)
--     api.nvim_win_set_option(M.win, 'linebreak', true)
--   else
--     api.nvim_win_set_config(M.win, opts)
--   end
--
--   api.nvim_set_current_win(M.win)
--   return M.buf, M.win
-- end
--
-- -----------------------------------------------------------
-- -- Generate a completion using the Ollama server.
-- -- If streaming is enabled, update the response window live.
-- -----------------------------------------------------------
-- function M.generate_completion(prompt, model, callback)
--   if M.config.stream then
--     local args = {
--       "-s",             -- silent
--       "-N",             -- disable buffering
--       "-X", "POST",
--       string.format("%s:%d/api/generate", M.config.host, M.config.port),
--       "-H", "Content-Type: application/json",
--       "-d", vim.json.encode({
--           model = model or M.config.default_model,
--           prompt = prompt,
--           stream = true
--       })
--     }
--     local stdout = vim.loop.new_pipe(false)
--     local response_lines = {}
--     local buf, _ = M.create_window()
--     local function on_read(err, chunk)
--       if err then
--         vim.schedule(function()
--           vim.notify("Error reading stream: " .. err, vim.log.levels.ERROR)
--         end)
--         return
--       end
--       if chunk then
--         for line in string.gmatch(chunk, "[^\r\n]+") do
--           local ok, data = pcall(vim.json.decode, line)
--           if ok and data and data.response then
--             table.insert(response_lines, data.response)
--             vim.schedule(function()
--               local current = table.concat(response_lines, "")
--               -- Split the current response into individual lines
--               local new_lines = vim.split(current, "\n", { plain = true })
--               local total = api.nvim_buf_line_count(buf)
--               -- Replace the last line with the new_lines table
--               api.nvim_buf_set_lines(buf, total - 1, total, false, new_lines)
--             end)
--           end
--         end
--       end
--     end
--
--     local handle
--     handle = vim.loop.spawn("curl", {
--       args = args,
--       stdio = { nil, stdout, nil }
--     }, function(code, signal)
--       stdout:close()
--       handle:close()
--       if callback then
--         callback({ response = table.concat(response_lines, "") })
--       end
--     end)
--     stdout:read_start(on_read)
--   else
--     ollama_request("generate", {
--       model = model or M.config.default_model,
--       prompt = prompt,
--       stream = false
--     }, callback)
--   end
-- end
--
-- -----------------------------------------------------------
-- -- Process the currently selected text in visual mode.
-- -----------------------------------------------------------
-- function M.process_selection()
--   local start_pos = fn.getpos("'<")
--   local end_pos = fn.getpos("'>")
--   local start_row, start_col = start_pos[2], start_pos[3]
--   local end_row, end_col = end_pos[2], end_pos[3]
--
--   local lines
--   if start_row == end_row then
--     local line = api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
--     lines = { line:sub(start_col, end_col) }
--   else
--     lines = api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
--     if #lines > 0 then
--       lines[1] = lines[1]:sub(start_col)
--       lines[#lines] = lines[#lines]:sub(1, end_col)
--     end
--   end
--
--   local selected_text = table.concat(lines, "\n")
--   local action_choices = {
--     "Explain this code",
--     "Improve this code",
--     "Optimize this code",
--     "Document this code",
--     "Find bugs in this code",
--     "Complete this code",
--     "Summarize this text",
--     "Other (custom prompt)",
--   }
--
--   vim.ui.select(action_choices, {
--     prompt = "What do you want to do with the selection?",
--   }, function(choice)
--     if not choice then return end
--
--     local prompt_text
--     if choice == "Other (custom prompt)" then
--       prompt_text = vim.fn.input({ prompt = "Custom prompt: ", cancelreturn = "" })
--       if prompt_text == "" then return end
--       prompt_text = prompt_text .. ":\n\n" .. selected_text
--     else
--       prompt_text = choice .. ":\n\n" .. selected_text
--     end
--
--     local selection_lines = vim.split(selected_text, "\n", { plain = true })
--     local header_lines = {}
--     table.insert(header_lines, "# Selection")
--     for _, l in ipairs(selection_lines) do
--       table.insert(header_lines, l)
--     end
--     table.insert(header_lines, "")
--     table.insert(header_lines, "# " .. choice)
--     table.insert(header_lines, "Thinking...")
--
--     M.create_window()
--     api.nvim_buf_set_lines(M.buf, 0, -1, false, header_lines)
--
--     M.generate_completion(prompt_text, nil, function(response)
--       if not M.config.stream then
--         if response and response.response then
--           local response_lines = vim.split(response.response, "\n", { plain = true })
--           api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, response_lines)
--         else
--           api.nvim_buf_set_lines(M.buf, #header_lines - 1, #header_lines, false, { "Error: Failed to get response" })
--         end
--       end
--     end)
--   end)
-- end
--
-- -----------------------------------------------------------
-- -- Setup the plugin and map the visual mode selection key.
-- -----------------------------------------------------------
-- function M.setup(user_config)
--   if user_config then
--     M.config = vim.tbl_deep_extend("force", M.config, user_config)
--   end
--
--   vim.keymap.set('v', M.config.keymaps.selection, function() M.process_selection() end,
--     { desc = "Ollama: Process visual selection" }
--   )
--
--   vim.api.nvim_create_user_command("OllamaSelection", function() M.process_selection() end, {})
-- end
--
-- return M
--
-- function M.generate_completion(prompt, model, callback)
--   local model_name = model or M.config.default_model
--   local buf, win = M.create_window()
--
--   -- Add initial content to buffer
--   local header = string.format("# Processing with %s\n\n", model_name)
--   M.update_buffer_content(buf, header)
--
--   if M.config.stream then
--     local args = {
--       "-s",             -- silent
--       "-N",             -- disable buffering
--       "-X", "POST",
--       string.format("%s:%d/api/generate", M.config.host, M.config.port),
--       "-H", "Content-Type: application/json",
--       "-d", vim.json.encode({
--           model = model_name,
--           prompt = prompt,
--           stream = true
--       })
--     }
--
--     local stdout = vim.loop.new_pipe(false)
--     local response_text = ""
--     local is_first_update = true
--
--     local function on_read(err, chunk)
--       if err then
--         vim.schedule(function()
--           vim.notify("Error reading stream: " .. err, vim.log.levels.ERROR)
--           M.update_buffer_content(buf, header .. "Error: " .. err)
--         end)
--         return
--       end
--
--       if chunk then
--         vim.schedule(function()
--           if not api.nvim_buf_is_valid(buf) then
--             return
--           end
--
--           -- Process the JSON lines in the chunk
--           for line in string.gmatch(chunk, "[^\r\n]+") do
--             local ok, data = pcall(vim.json.decode, line)
--             if ok and data and data.response then
--               response_text = response_text .. data.response
--
--               -- Only update the buffer if window is still valid
--               if api.nvim_win_is_valid(win) then
--                 local display_text = header .. response_text
--
--                 -- For the first update, replace the entire buffer
--                 -- For subsequent updates, append to existing content
--                 if is_first_update then
--                   api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(display_text, "\n", { plain = true }))
--                   is_first_update = false
--                 else
--                   local lines = vim.split(display_text, "\n", { plain = true })
--                   api.nvim_buf_set_lines(buf, 0, -1, false, lines)
--                 end
--
--                 -- Auto-scroll to bottom if cursor was at the bottom
--                 local cursor_pos = api.nvim_win_get_cursor(win)
--                 local line_count = api.nvim_buf_line_count(buf)
--                 if cursor_pos[1] >= line_count - 2 then
--                   api.nvim_win_set_cursor(win, {line_count, 0})
--                 end
--               end
--             end
--
--             -- Check if we're done
--             if ok and data and data.done then
--               -- Finished generating
--             end
--           end
--         end)
--       end
--     end
--
--     -- Handle process lifecycle
--     local stderr = vim.loop.new_pipe(false)
--     local handle
--     handle = vim.loop.spawn("curl", {
--       args = args,
--       stdio = { nil, stdout, stderr }
--     }, function(code, signal)
--       stdout:close()
--       stderr:close()
--       handle:close()
--
--       vim.schedule(function()
--         if code ~= 0 then
--           vim.notify("Ollama request failed with code: " .. code, vim.log.levels.ERROR)
--         end
--
--         if callback then
--           callback({ response = response_text, code = code })
--         end
--       end)
--     end)
--
--     -- Start reading from stdout and stderr
--     stdout:read_start(on_read)
--     stderr:read_start(function(err, chunk)
--       if chunk then
--         vim.schedule(function()
--           vim.notify("Ollama error: " .. chunk, vim.log.levels.ERROR)
--         end)
--       end
--     end)
--   else
--     -- Non-streaming implementation
--     M.update_buffer_content(buf, header .. "Processing request...")
--
--     ollama_request("generate", {
--       model = model_name,
--       prompt = prompt,
--       stream = false
--     }, function(response)
--       vim.schedule(function()
--         if response and response.response then
--           M.update_buffer_content(buf, header .. response.response)
--         else
--           M.update_buffer_content(buf, header .. "Error: Failed to get response")
--         end
--
--         if callback then
--           callback(response)
--         end
--       end)
--     end)
--   end
-- end

function M.generate_completion(prompt, model, callback)
    local model_name = model or M.config.default_model
    local buf, win = M.create_window()

    -- Add initial content to buffer
    local header = string.format("# Processing with %s\n\n", model_name)
    M.update_buffer_content(buf, header)

    if M.config.stream then
        local args = {
            "-s", -- silent
            "-N", -- disable buffering
            "-X", "POST",
            string.format("%s:%d/api/generate", M.config.host, M.config.port),
            "-H", "Content-Type: application/json",
            "-d", vim.json.encode({
            model = model_name,
            prompt = prompt,
            stream = true
        })
        }

        local stdout = vim.loop.new_pipe(false)
        local response_text = ""
        local is_first_update = true

        local function on_read(err, chunk)
            if err then
                vim.schedule(function()
                    vim.notify("Error reading stream: " .. err, vim.log.levels.ERROR)
                    M.update_buffer_content(buf, header .. "Error: " .. err)
                end)
                return
            end

            if chunk then
                vim.schedule(function()
                    if not api.nvim_buf_is_valid(buf) then
                        return
                    end

                    -- Process the JSON lines in the chunk
                    for line in string.gmatch(chunk, "[^\r\n]+") do
                        local ok, data = pcall(vim.json.decode, line)
                        if ok and data and data.response then
                            response_text = response_text .. data.response

                            -- Only update the buffer if window is still valid
                            if api.nvim_win_is_valid(win) then
                                local display_text = header .. response_text

                                -- For the first update, replace the entire buffer
                                -- For subsequent updates, append to existing content
                                if is_first_update then
                                    api.nvim_buf_set_lines(buf, 0, -1, false,
                                        vim.split(display_text, "\n", { plain = true }))
                                    is_first_update = false
                                else
                                    local lines = vim.split(display_text, "\n", { plain = true })
                                    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                                end

                                -- Auto-scroll to bottom if cursor was at the bottom
                                local cursor_pos = api.nvim_win_get_cursor(win)
                                local line_count = api.nvim_buf_line_count(buf)
                                if cursor_pos[1] >= line_count - 2 then
                                    api.nvim_win_set_cursor(win, { line_count, 0 })
                                end
                            end
                        end

                        -- Check if we're done
                        if ok and data and data.done then
                            -- Finished generating
                        end
                    end
                end)
            end
        end

        -- Handle process lifecycle
        local stderr = vim.loop.new_pipe(false)
        local handle
        handle = vim.loop.spawn("curl", {
            args = args,
            stdio = { nil, stdout, stderr }
        }, function(code, signal)
            stdout:close()
            stderr:close()
            handle:close()

            vim.schedule(function()
                if code ~= 0 then
                    vim.notify("Ollama request failed with code: " .. code, vim.log.levels.ERROR)
                end

                if callback then
                    callback({ response = response_text, code = code })
                end
            end)
        end)

        -- Start reading from stdout and stderr
        stdout:read_start(on_read)
        stderr:read_start(function(err, chunk)
            if chunk then
                vim.schedule(function()
                    vim.notify("Ollama error: " .. chunk, vim.log.levels.ERROR)
                end)
            end
        end)
    else
        -- Non-streaming implementation
        M.update_buffer_content(buf, header .. "Processing request...")

        ollama_request("generate", {
            model = model_name,
            prompt = prompt,
            stream = false
        }, function(response)
            vim.schedule(function()
                if response and response.response then
                    M.update_buffer_content(buf, header .. response.response)
                else
                    M.update_buffer_content(buf, header .. "Error: Failed to get response")
                end

                if callback then
                    callback(response)
                end
            end)
        end)
    end
end
```

### File: lua/mlamkadm/core/options.lua
```

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.number = true
vim.opt.relativenumber = true
--vim.opt.undo_history = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.cursorline = true

vim.opt.termguicolors = true
--vim.opt.background = "dark"
vim.opt.signcolumn = "yes"

vim.opt.backspace = "indent,eol,start"

-- Example using a list of specs with the default options
vim.g.mapleader = " "       -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = "\\" -- Same for `maplocalleader`

-- wl-clipboard
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank to clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from clipboard" })

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1


```

### File: lua/mlamkadm/core/sessions.lua
```
require('auto-session').setup {
    {
        enabled = true,                             -- Enables/disables auto creating, saving and restoring
        root_dir = vim.fn.stdpath "data" .. "/sessions/", -- Root dir where sessions will be stored
        auto_save = true,                           -- Enables/disables auto saving session on exit
        auto_restore = true,                        -- Enables/disables auto restoring session on start
        auto_create = true,                         -- Enables/disables auto creating new session files. Can take a function that should return true/false if a new session file should be created or not
        suppressed_dirs = nil,                      -- Suppress session restore/create in certain directories
        allowed_dirs = nil,                         -- Allow session restore/create in certain directories
        auto_restore_last_session = false,          -- On startup, loads the last saved session if session for cwd does not exist
        use_git_branch = false,                     -- Include git branch name in session name
        lazy_support = true,                        -- Automatically detect if Lazy.nvim is being used and wait until Lazy is done to make sure session is restored correctly. Does nothing if Lazy isn't being used. Can be disabled if a problem is suspected or for debugging
        bypass_save_filetypes = nil,                -- List of filetypes to bypass auto save when the only buffer open is one of the file types listed, useful to ignore dashboards
        close_unsupported_windows = true,           -- Close windows that aren't backed by normal file before autosaving a session
        args_allow_single_directory = true,         -- Follow normal sesion save/load logic if launched with a single directory as the only argument
        args_allow_files_auto_save = false,         -- Allow saving a session even when launched with a file argument (or multiple files/dirs). It does not load any existing session first. While you can just set this to true, you probably want to set it to a function that decides when to save a session when launched with file args. See documentation for more detail
        continue_restore_on_error = true,           -- Keep loading the session even if there's an error
        show_auto_restore_notif = false,            -- Whether to show a notification when auto-restoring
        cwd_change_handling = false,                -- Follow cwd changes, saving a session before change and restoring after
        lsp_stop_on_restore = false,                -- Should language servers be stopped when restoring a session. Can also be a function that will be called if set. Not called on autorestore from startup
        log_level = "error",                        -- Sets the log level of the plugin (debug, info, warn, error).

        session_lens = {
            load_on_setup = true, -- Initialize on startup (requires Telescope)
            theme_conf = { -- Pass through for Telescope theme options
                -- layout_config = { -- As one example, can change width/height of picker
                --   width = 0.8,    -- percent of window
                --   height = 0.5,
                -- },
            },
            previewer = false, -- File preview for session picker

            mappings = {
                -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
                delete_session = { "i", "<C-D>" },
                alternate_session = { "i", "<C-S>" },
                copy_session = { "i", "<C-Y>" },
            },

            session_control = {
                control_dir = vim.fn.stdpath "data" .. "/auto_session/", -- Auto session control dir, for control files, like alternating between two sessions with session-lens
                control_filename = "session_control.json",     -- File name of the session control file
            },
        },
    }
}
```

### File: lua/mlamkadm/core/terminal.lua
```
require("toggleterm").setup {
    -- size can be a number or function which is passed the current terminal
    size = 50, --function(term)
    -- if term.direction == "horizontal" then
    --     return 15
    -- elseif term.direction == "vertical" then
    --     return vim.o.columns * 0.4
    -- end
    -- end,
    direction = 'float',
    open_mapping = [[<c-\>]], -- or { [[<c-\>]], [[<c-¥>]] } if you also use a Japanese keyboard.
    -- on_create = fun(t: Terminal), -- function to run when the terminal is first created
    -- on_open = fun(t: Terminal), -- function to run when the terminal opens
    -- on_close = fun(t: Terminal), -- function to run when the terminal closes
    -- on_stdout = fun(t: Terminal, job: number, data: string[], name: string) -- callback for processing output on stdout
    -- on_stderr = fun(t: Terminal, job: number, data: string[], name: string) -- callback for processing output on stderr
    -- on_exit = fun(t: Terminal, job: number, exit_code: number, name: string) -- function to run when terminal process exits
    hide_numbers = true, -- hide the number column in toggleterm buffers
    shade_filetypes = {},
    autochdir = true,    -- when neovim changes it current directory the terminal will change it's own when next it's opened
    -- highlights = {
    --     -- highlights which map to a highlight group name and a table of it's values
    --     -- NOTE: this is only a subset of values, any group placed here will be set for the terminal window split
    --     Normal = {
    --         guibg = "<VALUE-HERE>",
    --     },
    --     NormalFloat = {
    --         link = 'Normal'
    --     },
    --     FloatBorder = {
    --         guifg = "<VALUE-HERE>",
    --         guibg = "<VALUE-HERE>",
    --     },
    -- },
    shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    -- shading_factor = '<number>', -- the percentage by which to lighten dark terminal background, default: -30
    -- shading_ratio = '<number>', -- the ratio of shading factor for light/dark terminal background, default: -3
    start_in_insert = true,
    -- insert_mappings = true, -- whether or not the open mapping applies in insert mode
    terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
    -- persist_size = true,
    -- persist_mode = true, -- if set to true (default) the previous terminal mode will be remembered
    -- direction = 'vertical' | 'horizontal' | 'tab' | 'float',
    close_on_exit = true, -- close the terminal window when the process exits
    -- clear_env = false, -- use only environmental variables from `env`, passed to jobstart()
    --  -- Change the default shell. Can be a string or a function returning a string
    -- shell = vim.o.shell,
    -- auto_scroll = true, -- automatically scroll to the bottom on terminal output
    -- -- This field is only relevant if direction is set to 'float'
    -- float_opts = {
    --   -- The border key is *almost* the same as 'nvim_open_win'
    --   -- see :h nvim_open_win for details on borders however
    --   -- the 'curved' border is a custom border type
    --   -- not natively supported but implemented in this plugin.
    border = 'curved' --| 'double' | 'shadow' | 'curved' | ... other options supported by win open
    --   -- like `size`, width, height, row, and col can be a number or function which is passed the current terminal
    --   width = <value>,
    --   height = <value>,
    --   row = <value>,
    --   col = <value>,
    --   winblend = 3,
    --   zindex = <value>,
    --   title_pos = 'left' | 'center' | 'right', position of the title of the floating window
    -- },
    -- winbar = {
    --   enabled = false,
    --   name_formatter = function(term) --  term: Terminal
    --     return term.name
    --   end
    -- },
    -- responsiveness = {
    --   -- breakpoint in terms of `vim.o.columns` at which terminals will start to stack on top of each other
    --   -- instead of next to each other
    --   -- default = 0 which means the feature is turned off
    --   horizontal_breakpoint = 135,
    -- }
}

local Terminal = require('toggleterm.terminal').Terminal

-- local options = {
--     dir = "git_dir", -- Optional: opens in git repo root
--     direction = "float",
--     float_opts = {
--         border = "curved",
--         winblend = 13,      -- Transparency (0-100)
--     },
--     shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
-- }

local openGlowCurrentFile = function()
    local openGlow = Terminal:new({
        cmd = "glow " .. vim.fn.expand("%"),
        dir = "git_dir", -- Optional: opens in git repo root
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,      -- Transparency (0-100)
        },
        shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    })
    return openGlow
end

local function renderMdFile() 
    local open_glow = Terminal:new({
        cmd = "md-tui " .. vim.fn.expand("%"),
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,      -- Transparency (0-100)
        },
        shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    })
    return open_glow
end

function GetFileNames()
    local file = vim.fn.expand("%")
    local file_name = vim.fn.fnamemodify(file, ":t")
    local file_extension = vim.fn.fnamemodify(file, ":e")
    return file_name, file_extension
end

local function get_term(cmd)
    return Terminal:new({
        cmd = cmd,
        dir = "git_dir", -- Optional: opens in git repo root
        direction = "float",
        float_opts = {
            border = "curved",
            winblend = 13,      -- Transparency (0-100)
        },
        shade_terminals = true, -- NOTE: this option takes priority over highlights specified so if you specify Normal highlights you should set this to false
    })
end

function Poptui(cmd)
    get_term(cmd):toggle()
end



vim.keymap.set("n", "<leader>jh", function()
    Poptui(
    "python3 /home/mlamkadm/repos/IRC-TUI-python/irc_tui.py --password Alilepro135! --user testuser --port 16000 --nick testnick --real testreal")
end)

-- vim.keymap.set("n", "<leader>jh", function ()
-- poptui("irssi")

-- end)

vim.api.nvim_set_keymap("n", "<leader>jj", "<cmd>lua Poptui('lazygit')<CR>", { noremap = true, silent = true })
-- Keymap to toggle btop terminal
vim.keymap.set("n", "<leader>jt", "<cmd> lua Poptui('btop')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jd", "<cmd> lua Poptui('lazydocker')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jy", "<cmd> lua Poptui('yazi')<CR>", { noremap = true, silent = true })


vim.keymap.set("n", "<leader>ja", "<cmd> lua Poptui('ai')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jg", "<cmd> lua Poptui('glow')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jo", "<cmd> lua renderMdFile:toggle()<CR>", { noremap = true, silent = true })

-- Makefile

vim.keymap.set("n", "<leader>jr", "<cmd> lua Poptui('make run')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>jm", "<cmd> lua Poptui('make')<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>ja", "<cmd> lua Poptui('agent')<CR>", { noremap = true, silent = true })

```

### File: lua/mlamkadm/core/winshift.lua
```
-- Lua
require("winshift").setup({
  highlight_moving_win = true,  -- Highlight the window being moved
  focused_hl_group = "Visual",  -- The highlight group used for the moving window
  moving_win_options = {
    -- These are local options applied to the moving window while it's
    -- being moved. They are unset when you leave Win-Move mode.
    wrap = false,
    cursorline = false,
    cursorcolumn = false,
    colorcolumn = "",
  },
  keymaps = {
    disable_defaults = true, -- Disable the default keymaps
    win_move_mode = {
      ["h"] = "left",
      ["j"] = "down",
      ["k"] = "up",
      ["l"] = "right",
      ["H"] = "far_left",
      ["J"] = "far_down",
      ["K"] = "far_up",
      ["L"] = "far_right",
      ["<left>"] = "left",
      ["<down>"] = "down",
      ["<up>"] = "up",
      ["<right>"] = "right",
      ["<S-left>"] = "far_left",
      ["<S-down>"] = "far_down",
      ["<S-up>"] = "far_up",
      ["<S-right>"] = "far_right",
    },
  },
  ---A function that should prompt the user to select a window.
  ---
  ---The window picker is used to select a window while swapping windows with
  ---`:WinShift swap`.
  ---@return integer? winid # Either the selected window ID, or `nil` to
  ---   indicate that the user cancelled / gave an invalid selection.
  window_picker = function()
    return require("winshift.lib").pick_window({
      -- A string of chars used as identifiers by the window picker.
      picker_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
      filter_rules = {
        -- This table allows you to indicate to the window picker that a window
        -- should be ignored if its buffer matches any of the following criteria.
        cur_win = true, -- Filter out the current window
        floats = true,  -- Filter out floating windows
        filetype = {},  -- List of ignored file types
        buftype = {},   -- List of ignored buftypes
        bufname = {},   -- List of vim regex patterns matching ignored buffer names
      },
      ---A function used to filter the list of selectable windows.
      ---@param winids integer[] # The list of selectable window IDs.
      ---@return integer[] filtered # The filtered list of window IDs.
      filter_func = nil,
    })
  end,
})
```

### File: lua/mlamkadm/lazy.lua
```

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup("mlamkadm.plugs",
    {
        change_detection = {
            -- automatically check for config file changes and reload the ui
            enabled = false,
            notify = false, -- get a notification when changes are found
        },
    }
)
```

### File: lua/mlamkadm/plugs/42-formatter.lua
```
return {
  "Diogo-ss/42-C-Formatter.nvim",
  cmd = "CFormat42",
  config = function()
    local formatter = require "42-formatter"
    formatter.setup({
      formatter = 'c_formatter_42',
      filetypes = { c = true, h = true, cpp = true, hpp = true },
    })
  end
}
```

### File: lua/mlamkadm/plugs/42-header.lua
```
return
{
    "Diogo-ss/42-header.nvim",
    cmd = { "Stdheader" },
    keys = { "<F1>" },
    opts = {
        default_map = true,  -- Default mapping <F1> in normal mode.
        auto_update = false,  -- Update header when saving.
        user = "mlamkadm",   -- Your user.
        mail = "mlamkadm@student.42.fr", -- Your mail.
        -- add other options.
    },
    config = function(_, opts)
        require("42header").setup(opts)
    end,
}
```

### File: lua/mlamkadm/plugs/auto-pairs.lua
```
return {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = true
    -- use opts = {} for passing setup options
    -- this is equalent to setup({}) function
}
```

### File: lua/mlamkadm/plugs/auto-save.lua
```
return {
    "Pocco81/auto-save.nvim",
    enabled = true,
    execution_message = {
        message = function() -- message to print on save
            return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
        end,
        dim = 0.18,                                    -- dim the color of `message`
        cleaning_interval = 1250,                      -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
    },
    trigger_events = { "InsertLeave", "TextChanged" }, -- vim events that trigger auto-save. See :h events
    -- function that determines whether to save the current buffer or not
    -- return true: if buffer is ok to be saved
    -- return false: if it's not ok to be saved
    condition = function(buf)
        local fn = vim.fn
        local utils = require("auto-save.utils.data")

        if
            fn.getbufvar(buf, "&modifiable") == 1 and
            utils.not_in(fn.getbufvar(buf, "&filetype"), {}) then
            return true              -- met condition(s), can save
        end
        return false                 -- can't save
    end,
    write_all_buffers = false,       -- write all buffers when the current one meets `condition`
    debounce_delay = 135,            -- saves the file at most every `debounce_delay` milliseconds
    callbacks = {                    -- functions to be executed at different intervals
        enabling = nil,              -- ran when enabling auto-save
        disabling = nil,             -- ran when disabling auto-save
        before_asserting_save = nil, -- ran before checking `condition`
        before_saving = nil,         -- ran before doing the actual save
        after_saving = nil           -- ran after doing the actual save
    }
}
```

### File: lua/mlamkadm/plugs/auto-sesssion.lua
```
return {
    'rmagatti/auto-session',
}

```

### File: lua/mlamkadm/plugs/comments.lua
```
return {
    'numToStr/Comment.nvim',
    keys = {
    },
    opts = {
        {
            ---Add a space b/w comment and the line
            padding = true,
            ---Whether the cursor should stay at its position
            sticky = true,
            ---Lines to be ignored while (un)comment
            ignore = nil,
            ---LHS of toggle mappings in NORMAL mode
            toggler = {
                ---Line-comment toggle keymap
                line = '<leader>hh',
                ---Block-comment toggle keymap
                block = 'gbc',
            },
            ---LHS of operator-pending mappings in NORMAL and VISUAL mode
            opleader = {
                ---Line-comment keymap
                line = 'gc',
                ---Block-comment keymap
                block = 'gb',
            },
            ---LHS of extra mappings
            extra = {
                ---Add comment on the line above
                above = 'gcO',
                ---Add comment on the line below
                below = 'gco',
                ---Add comment at the end of line
                eol = 'gcA',
            },
            ---Enable keybindings
            ---NOTE: If given `false` then the plugin won't create any mappings
            mappings = {
                ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
                basic = true,
                ---Extra mapping; `gco`, `gcO`, `gcA`
                extra = nil,
            },
            ---Function to call before (un)comment
            pre_hook = nil,
            ---Function to call after (un)comment
            post_hook = nil,
        }
        -- add any options here
    },
    lazy = false,
}
```

### File: lua/mlamkadm/plugs/copilot.lua
```

return
{
  "zbirenbaum/copilot-cmp",
  event = "InsertEnter",

  config = function () require("copilot_cmp").setup() end,
  dependencies = {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = true},
        panel = { enabled = true},
        experimental = { enabled = true },
        snippet = { enabled = true },
      })
    end,
  },
}

```

### File: lua/mlamkadm/plugs/explorer.lua
```
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
        -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    keys = {
        { "<leader><tab>", "<cmd>Neotree float<cr>" },
    },
    config = function()
        -- If you want icons for diagnostic errors, you'll need to define them somewhere:
        vim.fn.sign_define("DiagnosticSignError",
            { text = " ", texthl = "DiagnosticSignError" })
        vim.fn.sign_define("DiagnosticSignWarn",
            { text = " ", texthl = "DiagnosticSignWarn" })
        vim.fn.sign_define("DiagnosticSignInfo",
            { text = " ", texthl = "DiagnosticSignInfo" })
        vim.fn.sign_define("DiagnosticSignHint",
            { text = "󰌵", texthl = "DiagnosticSignHint" })

        require("neo-tree").setup({
            close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
            popup_border_style = "rounded",
            enable_git_status = true,
            enable_diagnostics = true,
            enable_normal_mode_for_inputs = false,                             -- Enable normal mode for input dialogs.
            open_files_do_not_replace_types = { "terminal", "trouble", "qf" }, -- when opening files, do not use windows containing these filetypes or buftypes
            sort_case_insensitive = false,                                     -- used when sorting files and directories in the tree
            sort_function = nil,                                               -- use a custom function for sorting files and directories in the tree
            -- sort_function = function (a,b)
            --       if a.type == b.type then
            --           return a.path > b.path
            --       else
            --           return a.type > b.type
            --       end
            --   end , -- this sorts files and directories descendantly
            default_component_configs = {
                container = {
                    enable_character_fade = true
                },
                indent = {
                    indent_size = 2,
                    padding = 2, -- extra padding on left hand side
                    -- indent guides
                    with_markers = true,
                    indent_marker = "│",
                    last_indent_marker = "└",
                    highlight = "NeoTreeIndentMarker",
                    -- expander config, needed for nesting files
                    with_expanders = nil, -- if nil and file nesting is enabled, will enable expanders
                    expander_collapsed = "",
                    expander_expanded = "",
                    expander_highlight = "NeoTreeExpander",
                },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "󰜌",
                    -- The next two settings are only a fallback, if you use nvim-web-devicons and configure default icons there
                    -- then these will never be used.
                    default = "*",
                    highlight = "NeoTreeFileIcon"
                },
                modified = {
                    symbol = "[+]", highlight = "NeoTreeModified", },
                name = {
                    trailing_slash = false,
                    use_git_status_colors = true,
                    highlight = "NeoTreeFileName",
                },
                git_status = {
                    symbols = {
                        -- Change type
                        added     = "", -- or "✚", but this is redundant info if you use git_status_colors on the name
                        modified  = "", -- or "", but this is redundant info if you use git_status_colors on the name
                        deleted   = "✖", -- this can only be used in the git_status source
                        renamed   = "󰁕", -- this can only be used in the git_status source
                        -- Status type
                        untracked = "",
                        ignored   = "",
                        unstaged  = "󰄱",
                        staged    = "",
                        conflict  = "",
                    }
                },
                -- If you don't want to use these columns, you can set `enabled = false` for each of them individually
                file_size = {
                    enabled = true,
                    required_width = 64, -- min width of window required to show this column
                },
                type = {
                    enabled = true,
                    required_width = 122, -- min width of window required to show this column
                },
                last_modified = {
                    enabled = true,
                    required_width = 88, -- min width of window required to show this column
                },
                created = {
                    enabled = true,
                    required_width = 110, -- min width of window required to show this column
                },
                symlink_target = {
                    enabled = false,
                },
            },
            -- A list of functions, each representing a global custom command
            -- that will be available in all sources (if not overridden in `opts[source_name].commands`)
            -- see `:h neo-tree-custom-commands-global`
            commands = {},
            window = {
                position = "left",
                width = 40,
                mapping_options = {
                    noremap = false,
                    nowait = true,
                },
                mappings = {
                    ["<leader>"] = {
                        "toggle_node",
                        nowait = true, -- disable `nowait` if you have existing combos starting with this char that you want to use
                    },
                    --[""] = "open",
                    ["<cr>"] = "open",
                    ["<esc>"] = "cancel", -- close preview or floating neo-tree window
                    ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
                    -- Read `# Preview Mode` for more information
                    ["l"] = "focus_preview",
                    ["-"] = "open_split",
                    ["="] = "open_vsplit",
                    -- ["S"] = "split_with_window_picker",
                    -- ["s"] = "vsplit_with_window_picker",
                    ["t"] = "open_tabnew",
                    -- ["<cr>"] = "open_drop",
                    -- ["t"] = "open_tab_drop",
                    ["w"] = "open_with_window_picker",
                    --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
                    ["C"] = "close_node",
                    -- ['C'] = 'close_all_subnodes',
                    ["z"] = "close_all_nodes",
                    --["Z"] = "expand_all_nodes",
                    ["a"] = {
                        "add",
                        -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
                        -- some commands may take optional config options, see `:h neo-tree-mappings` for details
                        config = {
                            show_path = "none" -- "none", "relative", "absolute"
                        }
                    },
                    ["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
                    ["d"] = "delete",
                    ["r"] = "rename",
                    ["y"] = "copy_to_clipboard",
                    ["x"] = "cut_to_clipboard",
                    ["p"] = "paste_from_clipboard",
                    ["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
                    -- ["c"] = {
                    --  "copy",
                    --  config = {
                    --    show_path = "none" -- "none", "relative", "absolute"
                    --  }
                    --}
                    ["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
                    ["q"] = "close_window",
                    ["R"] = "refresh",
                    ["?"] = "show_help",
                    ["<"] = "prev_source",
                    [">"] = "next_source",
                    ["i"] = "show_file_details",
                }
            },
            nesting_rules = {},
            filesystem = {
                filtered_items = {
                    visible = false, -- when true, they will just be displayed differently than normal items
                    hide_dotfiles = true,
                    hide_gitignored = true,
                    hide_hidden = nil, -- only works on Windows for hidden files/directories
                    hide_by_name = {
                        --"node_modules"
                    },
                    hide_by_pattern = { -- uses glob style patterns
                        --"*.meta",
                        --"*/src/*/tsconfig.json",
                    },
                    always_show = { -- remains visible even if other settings would normally hide it
                        --".gitignored",
                    },
                    never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
                        --".DS_Store",
                        --"thumbs.db"
                    },
                    never_show_by_pattern = { -- uses glob style patterns
                        --".null-ls_*",
                    },
                },
                follow_current_file = {
                    enabled = false,                    -- This will find and focus the file in the active buffer every time
                    --               -- the current file is changed while the tree is open.
                    leave_dirs_open = false,            -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
                },
                group_empty_dirs = false,               -- when true, empty folders will be grouped together
                hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
                -- in whatever position is specified in window.position
                -- "open_current",  -- netrw disabled, opening a directory opens within the
                -- window like netrw would, regardless of window.position
                -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
                use_libuv_file_watcher = false, -- This will use the OS level file watchers to detect changes
                -- instead of relying on nvim autocmd events.
                window = {
                    mappings = {
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["H"] = "toggle_hidden",
                        ["/"] = "fuzzy_finder",
                        ["D"] = "fuzzy_finder_directory",
                        ["#"] = "fuzzy_sorter", -- fuzzy sorting using the fzy algorithm
                        -- ["D"] = "fuzzy_sorter_directory",
                        ["f"] = "filter_on_submit",
                        ["<c-x>"] = "clear_filter",
                        ["[g"] = "prev_git_modified",
                        ["]g"] = "next_git_modified",
                        ["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["og"] = { "order_by_git_status", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                        -- ['<key>'] = function(state) ... end,
                    },
                    fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
                        ["<down>"] = "move_cursor_down",
                        ["<C-n>"] = "move_cursor_down",
                        ["<up>"] = "move_cursor_up",
                        ["<C-p>"] = "move_cursor_up",
                        -- ['<key>'] = function(state, scroll_padding) ... end,
                    },
                },

                commands = {} -- Add a custom command or override a global one using the same function name
            },
            buffers = {
                follow_current_file = {
                    enabled = true,          -- This will find and focus the file in the active buffer every time
                    --              -- the current file is changed while the tree is open.
                    leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
                },
                group_empty_dirs = true,     -- when true, empty folders will be grouped together
                show_unloaded = true,
                window = {
                    mappings = {
                        ["bd"] = "buffer_delete",
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                    }
                },
            },
            git_status = {
                window = {
                    position = "float",
                    mappings = {
                        ["A"]  = "git_add_all",
                        ["gu"] = "git_unstage_file",
                        ["ga"] = "git_add_file",
                        ["gr"] = "git_revert_file",
                        ["gc"] = "git_commit",
                        ["gp"] = "git_push",
                        ["gg"] = "git_commit_and_push",
                        ["o"]  = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                    }
                }
            }
        })

        vim.cmd([[nnoremap \ :Neotree reveal<cr>]])
    end,
}
```

### File: lua/mlamkadm/plugs/fzf.lua
```
return
{
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons",
        "echasnovski/mini.icons" },
    opts = {}
}
```

### File: lua/mlamkadm/plugs/glow.lua
```
return {
    {
        "ellisonleao/glow.nvim",
        config = true,
        cmd = "Glow",
    },
}
```

### File: lua/mlamkadm/plugs/icons.lua
```
return {
    'nvim-tree/nvim-web-devicons',
}
```

### File: lua/mlamkadm/plugs/line.lua
```
return {
    "sontungexpt/sttusline",
    event = "VeryLazy",
    dependencies = {
        "nvim-tree/nvim-web-devicons", -- Optional but recommended for icons
    },
    opts = {
        -- Statusline general configuration
        statusline_color = "StatusLine",
        laststatus = 3, -- Global statusline

        -- Disable statusline for specific filetypes/buftypes
        disabled = {
            filetypes = {
                -- Add filetypes where you don't want the statusline
                "NvimTree",
                "TelescopePrompt",
                "alpha",
                "dashboard",
            },
            buftypes = {
                -- Add buftypes where you don't want the statusline
                "terminal",
                "prompt",
                "nofile",
            },
        },

        -- Statusline components configuration
        components = {
            "mode",                -- Vim mode (Normal, Insert, Visual, etc.)
            "filename",            -- Current file name
            "git-branch",          -- Git branch name
            "git-diff",            -- Git changes (added, modified, removed)
            "%=",                  -- Align the rest to the right
            "diagnostics",         -- LSP diagnostics
            "lsps-formatters",     -- Active LSP clients and formatters
            "copilot",             -- GitHub Copilot status
            "indent",              -- Indentation settings
            "encoding",            -- File encoding
            "pos-cursor",          -- Cursor position (line:column)
            "pos-cursor-progress", -- File progress percentage
        },

        -- Customize component settings
        -- mode = {
        --     colors = {
        --         NORMAL = "#8aadf4",
        --         INSERT = "#a6da95",
        --         VISUAL = "#ed8796",
        --         V_LINE = "#ed8796",
        --         V_BLOCK = "#ed8796",
        --         REPLACE = "#f5a97f",
        --         COMMAND = "#c6a0f6",
        --         TERMINAL = "#a6da95",
        --         SELECT = "#ed8796",
        --     },
        -- },

        -- Filename component configuration
        filename = {
            full_path = false,    -- Show full path
            path_sep = "/",       -- Path separator
            shorting_target = 40, -- Maximum filename length
            exclude_prefix = {    -- Excluded path prefixes
                "~",
                vim.fn.getcwd(),
            },
        },

        -- Git components configuration
        -- git = {
        --     branch = {
        --         format = "%s", -- Branch format
        --     },
        --     diff = {
        --         added = {
        --             hl = "DiffAdd",
        --         },
        --         modified = {
        --             hl = "DiffChange",
        --         },
        --         removed = {
        --             hl = "DiffDelete",
        --         },
        --     },
        -- },

        -- LSP configuration
        lsp = {
            diagnostics = {
                errors = { icon = " ", hl = "DiagnosticError" },
                warnings = { icon = " ", hl = "DiagnosticWarn" },
                info = { icon = " ", hl = "DiagnosticInfo" },
                hints = { icon = "󰌵 ", hl = "DiagnosticHint" },
            },
            formatter = {
                icon = "󰉼 ", -- Formatter icon
                format = "%s", -- Format string
            },
        },


        indent = {
            icon = "󰌒 ", -- Indent icon
            format = "%s spaces", -- Format string
        },

        encoding = {
            icon = "󰘦 ", -- Encoding icon
            exclude = { -- Excluded encodings
                "utf-8",
            },
        },

        position = {
            icon = "󰆥 ", -- Position icon
            format = "%l:%c", -- Position format
            progress_icon = "󰜎 ", -- Progress icon
        },
    },
    config = function(_, opts)
        -- Setup statusline
        require("sttusline").setup(opts)


        -- Add autocommands for dynamic updates
        vim.api.nvim_create_autocmd("User", {
            pattern = "GitSignsUpdate",
            callback = function()
                vim.cmd("redrawstatus")
            end,
        })

        -- Custom command to toggle statusline
        vim.api.nvim_create_user_command("ToggleStatusline", function()
            if vim.o.laststatus == 3 then
                vim.o.laststatus = 0
            else
                vim.o.laststatus = 3
            end
        end, {})

        -- Example keymaps for statusline control
        vim.keymap.set("n", "<leader>ts", ":ToggleStatusline<CR>", { silent = true, desc = "Toggle Statusline" })
    end,
}
```

### File: lua/mlamkadm/plugs/markdown.lua
```
return
{
    'jakewvincent/mkdnflow.nvim',
    config = function()
        require('mkdnflow').setup({
            -- Config goes here; leave blank for defaults
        })
    end
}
```

### File: lua/mlamkadm/plugs/mason.lua
```
return {
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v2.x",
        dependencies = {
            -- Core LSP plugins
            { "neovim/nvim-lspconfig" },
            {
                "williamboman/mason.nvim",
                build = ":MasonUpdate", -- Automatically update Mason registry
            },
            { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion plugins
            { "hrsh7th/nvim-cmp" },
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lua" },

            -- Snippet engine and snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },
        },
        config = function()
            local lsp = require("lsp-zero").preset({})

            -- Ensure these LSP servers are installed
            lsp.ensure_installed({
                "clangd",  -- C/C++
                "pyright", -- Python
                "gopls",   -- Go
                "lua_ls",  -- Lua
                "bashls",  -- Shell scripting
            })

            -- LSP-specific configurations
            require("lspconfig").clangd.setup({
                cmd = { "clangd", "--background-index", "--cross-file-rename" },
            })
            require("lspconfig").pyright.setup({})
            require("lspconfig").gopls.setup({})
            require("lspconfig").lua_ls.setup({
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                        telemetry = { enable = false },
                    },
                },
            })
            require("lspconfig").bashls.setup({})

            -- Attach key mappings
            lsp.on_attach(function(_, bufnr)
                local opts = { buffer = bufnr, noremap = true, silent = true }
                vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
                vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
                vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
                vim.keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
                vim.keymap.set("n", "<leader>ds", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", opts)
                vim.keymap.set("n", "<leader>ws", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>", opts)
                vim.keymap.set("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
                vim.keymap.set("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
                vim.keymap.set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
                vim.keymap.set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
            end)

            lsp.setup()
        end,
    },
    {
        "ray-x/go.nvim", -- Go tools
        dependencies = { "ray-x/guihua.lua" },
        config = function()
            require("go").setup()
            local opts = { noremap = true, silent = true }
            vim.keymap.set("n", "<leader>gt", "<cmd>GoTest<CR>", opts)
            vim.keymap.set("n", "<leader>gb", "<cmd>GoBuild<CR>", opts)
            vim.keymap.set("n", "<leader>gr", "<cmd>GoRun<CR>", opts)
        end,
    },
}
```

### File: lua/mlamkadm/plugs/material.lua
```
return {
    -- If you are using Packer
    'marko-cerovac/material.nvim',
    priority = 1000,
    config = function()
        vim.cmd("colorscheme material-deep-ocean")
    end
}
```

### File: lua/mlamkadm/plugs/notify.lua
```
-- return {
--     "rcarriga/nvim-notify",
--     event = "VeryLazy",
--     keys = {
--         { "<leader>fn", "<cmd>Telescope notify<cr>", desc = "List Notifications" },
--     },
--     opts = {
--         -- Configure animations
--         stages = "fade", -- fade|slide|fade_in_slide_out|static
--
--         -- Set timeout for notifications (in ms)
--         timeout = 1000,
--
--         -- Maximum width of notifications
--         max_width = function()
--             return math.floor(vim.o.columns * 0.75)
--         end,
--
--         -- Maximum height of notifications
--         max_height = function()
--             return math.floor(vim.o.lines * 0.75)
--         end,
--
--         -- Minimal width for notifications
--         minimum_width = 50,
--
--         -- Icons for different levels (using nerdfont)
--         icons = {
--             -- ERROR = "",
--             -- WARN = "",
--             -- INFO = "",
--             -- DEBUG = "",
--             TRACE = "✎",
--         },
--
--         -- Background color by notification level
--         background_colour = function()
--             return "#000000"
--         end,
--
--         -- Set default level for vim.notify()
--         level = 3,
--
--         -- Render style
--         render = "default", -- default|minimal|simple
--
--         -- Animation FPS
--         fps = 60,
--
--         -- Top position for notifications
--         top_down = true,
--
--         -- Time format
--         time_formats = {
--             notification_history = "%FT%T",
--             notification = "%T",
--         },
--
--         -- Max notification history
--         max_history = 100,
--     },
--     config = function(_, opts)
--         local notify = require("notify")
--
--         -- Setup notify
--         notify.setup(opts)
--
--         -- Override vim.notify
--         vim.notify = notify
--
--         -- Create highlight groups
--         vim.api.nvim_set_hl(0, "NotifyERRORBorder", { fg = "#8A1F1F" })
--         vim.api.nvim_set_hl(0, "NotifyWARNBorder", { fg = "#79491D" })
--         vim.api.nvim_set_hl(0, "NotifyINFOBorder", { fg = "#4F6752" })
--         vim.api.nvim_set_hl(0, "NotifyDEBUGBorder", { fg = "#8B8B8B" })
--         vim.api.nvim_set_hl(0, "NotifyTRACEBorder", { fg = "#4F3552" })
--
--         -- Sample Usage Commands
--         vim.api.nvim_create_user_command("NotifyDismiss", function()
--             notify.dismiss()
--         end, {})
--
--         -- Example usage of notification history in Telescope
--         require("telescope").load_extension("notify")
--
--         -- Helper function for common notifications
--         _G.notify_custom = function(msg, level, opts)
--             opts = opts or {}
--             level = level or "INFO"
--
--             local default_opts = {
--                 title = string.format("[%s] Notification", os.date("%H:%M:%S")),
--                 timeout = 3000,
--                 on_open = function(win)
--                     local buf = vim.api.nvim_win_get_buf(win)
--                     vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
--                 end,
--             }
--
--             opts = vim.tbl_deep_extend("force", default_opts, opts)
--             vim.notify(msg, level, opts)
--         end
--
--         -- Create some example keymaps for common actions
--         local function map(mode, lhs, rhs, desc)
--             vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
--         end
--
--         -- Dismiss all notifications
--         map("n", "<leader>nd", function()
--             notify.dismiss()
--         end, "Dismiss all notifications")
--
--         -- Example notification levels
--         map("n", "<leader>ni", function()
--             notify_custom("This is an info message", "INFO")
--         end, "Info notification")
--
--         map("n", "<leader>nw", function()
--             notify_custom("This is a warning message", "WARN")
--         end, "Warning notification")
--
--         map("n", "<leader>ne", function()
--             notify_custom("This is an error message", "ERROR")
--         end, "Error notification")
--
--         -- Example usage in your configuration:
--         -- vim.notify("Configuration loaded!", "INFO", {
--         --     title = "Neovim",
--         --     timeout = 2000,
--         -- })
--
--         -- Add autocommands for automatic notifications
--         vim.api.nvim_create_autocmd("User", {
--             pattern = "LazyLoad",
--             callback = function(event)
--                 notify_custom(string.format("Plugin loaded: %s", event.data), "INFO", {
--                     title = "Plugin Manager",
--                     timeout = 2000,
--                 })
--             end,
--         })
--
--         -- Notification for long running operations
--         vim.api.nvim_create_autocmd("LspProgress", {
--             callback = function(event)
--                 if event.data and event.data.message then
--                     notify_custom(event.data.message, "INFO", {
--                         title = "LSP Progress",
--                         timeout = false,
--                         hide_from_history = true,
--                     })
--                 end
--             end,
--         })
--     end,
-- }

return {}
```

### File: lua/mlamkadm/plugs/nvimcmp.lua
```
return {
    "hrsh7th/cmp-nvim-lsp",
    {
        'L3MON4D3/LuaSnip',
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = {
            'hrsh7th/nvim-cmp',
            'tzachar/fuzzy.nvim',
            'saadparwaiz1/cmp_luasnip',
            "rafamadriz/friendly-snippets",
            'tamago324/cmp-zsh',
            'Shougo/deol.nvim',
        },
    },
    'tzachar/cmp-fuzzy-path',
    dependencies = { 'hrsh7th/nvim-cmp', 'tzachar/fuzzy.nvim' },
    {
        "hrsh7th/nvim-cmp",
        config = function()
            local cmp = require("cmp")
            require("luasnip.loaders.from_vscode").lazy_load()
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                    end,
                },

                mapping = {
                    ['<tab>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
                    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
                    ['<C-a>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
                    ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
                    ['<C-e>'] = cmp.mapping({
                        i = cmp.mapping.abort(),
                        c = cmp.mapping.close(),
                    }),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                },
                sources = cmp.config.sources({
                    { name = 'luasnip' }, -- For luasnip users.
                }, {
                    { name = 'nvim_lsp' },
                }, {
                    { name = 'buffer' },
                    -- }, {
                    --     { name = 'fuzzy_path', option = { fd_timeout_msec = 1500 } },
                })
            })
        end,
    }
}
```

### File: lua/mlamkadm/plugs/nvim-devicons.lua
```
return {
}
```

### File: lua/mlamkadm/plugs/outline.lua
```
return {
    'simrat39/symbols-outline.nvim'
}
```

### File: lua/mlamkadm/plugs/persistence.lua
```
return
{
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {
        {
            dir = vim.fn.stdpath("state") .. "/sessions/",  -- directory where session files are saved
            options = { "buffers", "curdir", "tabpages", "winsize" }, -- sessionoptions used for saving
            pre_save = nil,                                 -- a function to call before saving the session
            post_save = nil,                                -- a function to call after saving the session
            save_empty = false,                             -- don't save if there are no open file buffers
            pre_load = nil,                                 -- a function to call before loading the session
            post_load = nil,                                -- a function to call after loading the session
        }
    }
}
```

### File: lua/mlamkadm/plugs/refactoring.lua
```
return {
    -- "ThePrimeagen/refactoring.nvim",
    -- event = { "BufReadPre", "BufNewFile" },
    -- dependencies = {
    --     "nvim-lua/plenary.nvim",
    --     "nvim-treesitter/nvim-treesitter",
    -- },
    -- keys = {
    --     { "<leader>r", "", desc = "+refactor", mode = { "n", "v" } },
    --     {
    --         "<leader>rs",
    --         function()
    --             require("telescope").extensions.refactoring.refactors()
    --         end,
    --         mode = "v",
    --         desc = "Select Refactor",
    --     },
    --     {
    --         "<leader>ri",
    --         function()
    --             require("refactoring").refactor("Inline Variable")
    --         end,
    --         mode = { "n", "v" },
    --         desc = "Inline Variable",
    --     },
    --     {
    --         "<leader>rb",
    --         function()
    --             require("refactoring").refactor("Extract Block")
    --         end,
    --         desc = "Extract Block",
    --     },
    --     {
    --         "<leader>rf",
    --         function()
    --             require("refactoring").refactor("Extract Block To File")
    --         end,
    --         desc = "Extract Block to File",
    --     },
    -- },
    -- opts = {
    --     prompt_func_return_type = {
    --         go = false,
    --         java = false,
    --         cpp = false,
    --         c = false,
    --         h = false,
    --         hpp = false,
    --         cxx = false,
    --     },
    --     prompt_func_param_type = {
    --         go = false,
    --         java = false,
    --         cpp = false,
    --         c = false,
    --         h = false,
    --         hpp = false,
    --         cxx = false,
    --     },
    --     printf_statements = {},
    --     print_var_statements = {},
    --     show_success_message = true,
    -- },
    -- config = function(_, opts)
    --     require("refactoring").setup(opts)
    --     require("telescope").load_extension("refactoring")
    -- end,
}
```

### File: lua/mlamkadm/plugs/startup.lua
```
return {
  "startup-nvim/startup.nvim",
  requires = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"},
  config = function()
    require"startup".setup({theme = "dashboard"})
  end
}
```

### File: lua/mlamkadm/plugs/tabline.lua
```
return {
--     {
--         'tomiis4/BufferTabs.nvim',
--         dependencies = {
--             'nvim-tree/nvim-web-devicons', -- optional
--         },
--         lazy = false,
--         config = function()
--             require('buffertabs').setup({
--                 ---@type 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|table
--                 border = 'rounded',
--                 ---@type integer
--                 padding = 1,
--                 ---@type boolean
--                 icons = true,
--                 ---@type string
--                 modified = " ",
--                 ---@type string use hl Group or hex color
--                 hl_group = 'Keyword',
--                 ---@type string use hl Group or hex color
--                 hl_group_inactive = 'Comment',
--                 ---@type boolean
--                 show_all = false,
--                 ---@type 'row'|'column'
--                 display = 'row',
--                 ---@type 'left'|'right'|'center'
--                 horizontal = 'center',
--                 ---@type 'top'|'bottom'|'center'
--                 vertical = 'top',
--                 ---@type number in ms (recommend 2000)
--                 timeout = 0
--             })
--             require('buffertabs').toggle()
--         end
--     },
}
```

### File: lua/mlamkadm/plugs/telescope.lua
```

return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    event = "VeryLazy", -- Lazy load for better startup time
    dependencies = {
        'nvim-lua/plenary.nvim',
        'jonarrien/telescope-cmdline.nvim',
        'gbrlsnchs/telescope-lsp-handlers.nvim',
        -- Highly recommended performance extension
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            build =
            'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
        },
        -- Additional powerful extensions
        'nvim-telescope/telescope-frecency.nvim',       -- Frecent file sorting
        'nvim-telescope/telescope-live-grep-args.nvim', -- Better grep with args
        { 'nvim-telescope/telescope-ui-select.nvim', version = '^1.0.0' },
        'debugloop/telescope-undo.nvim',                -- Visual undo tree
    },
    keys = {
        -- Essential operations
        { ':',                '<cmd>Telescope cmdline<cr>',                          desc = 'Command Line' },
        { '<leader><leader>', '<cmd>Telescope find_files hidden=true<cr>',           desc = 'Find Files' },
        { '<leader>b',        '<cmd>Telescope buffers sort_mru=true<cr>',            desc = 'Buffers' },
        { '<leader>i',        '<cmd>Telescope git_files<cr>',                        desc = 'Git Files' },

        -- Advanced search
        { '<leader>/',        '<cmd>Telescope live_grep_args<cr>',                   desc = 'Live Grep with Args' },
        { '<leader>fw',       '<cmd>Telescope grep_string<cr>',                      desc = 'Find Word Under Cursor' },
        { '<leader>fr',       '<cmd>Telescope frecency<cr>',                         desc = 'Recent Files' },
        { '<leader>fu',       '<cmd>Telescope undo<cr>',                             desc = 'Undo Tree' },

        -- LSP operations
        { 'gd',               '<cmd>Telescope lsp_definitions jump_type=vsplit<cr>', desc = 'Go to Definition' },
        { 'gr',               '<cmd>Telescope lsp_references<cr>',                   desc = 'Find References' },
        { 'gl',               '<cmd>Telescope lsp_implementations<cr>',              desc = 'Find Implementations' },
        { 'gs',               '<cmd>Telescope lsp_document_symbols<cr>',             desc = 'Document Symbols' },
        { '<leader>ws',       '<cmd>Telescope lsp_workspace_symbols<cr>',            desc = 'Workspace Symbols' },

        -- Git operations
        { '<leader>gc',       '<cmd>Telescope git_commits<cr>',                      desc = 'Git Commits' },
        { '<leader>gb',       '<cmd>Telescope git_branches<cr>',                     desc = 'Git Branches' },
        { '<leader>gs',       '<cmd>Telescope git_status<cr>',                       desc = 'Git Status' },
    },
    opts = {
        defaults = {
            -- Performance optimizations
            file_ignore_patterns = {
                "%.git/", "node_modules/", "%.cache/", "%.DS_Store",
                "%.class", "%.pdf", "%.mkv", "%.mp4", "%.zip"
            },
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--hidden",
            },

            -- Better UI
            layout_strategy = 'flex',
            layout_config = {
                horizontal = {
                    preview_width = 0.6,
                    prompt_position = "top",
                },
                vertical = {
                    mirror = false,
                    preview_height = 0.7,
                },
                flex = {
                    flip_columns = 140,
                },
            },

            -- Improved UX
            path_display = { "truncate" },
            winblend = 0,
            border = true,
            sorting_strategy = "ascending",
            scroll_strategy = "cycle",
            color_devicons = true,

            -- Better mappings in preview
            mappings = {
                i = {
                    ["<C-j>"] = "move_selection_next",
                    ["<C-k>"] = "move_selection_previous",
                    ["<C-u>"] = "preview_scrolling_up",
                    ["<C-d>"] = "preview_scrolling_down",
                },
            },
        },

        pickers = {
            find_files = {
                hidden = true,
                no_ignore = false,
                follow = true,
            },
            live_grep = {
                additional_args = function()
                    return { "--hidden" }
                end,
            },
            buffers = {
                sort_lastused = true,
                sort_mru = true,
                show_all_buffers = true,
                ignore_current_buffer = true,
                mappings = {
                    i = {
                        ["<c-d>"] = "delete_buffer",
                    },
                },
            },
        },

        extensions = {
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
            },
            cmdline = {
                history = true,
                previewer = true,
                history_style = 'dropdown',
                mappings = {
                    i = {
                        -- Optionally, you might want to add these for consistent navigation
                        ["<Down>"] = false, -- Optionally disable arrows
                        ["<Up>"] = false,   -- Optionally disable arrows
                    },
                },
            },
            ["ui-select"] = {
                require("telescope.themes").get_dropdown(),
            },
            undo = {
                use_delta = true,
                side_by_side = true,
                layout_strategy = "vertical",
                layout_config = {
                    preview_height = 0.8,
                },
            },
            frecency = {
                show_scores = true,
                show_unindexed = true,
                ignore_patterns = { "*.git/*", "*/tmp/*" },
                workspaces = {
                    ["conf"] = "/home/mlamkadm/.config",
                    ["project"] = "/home/mlamkadm/repos",
                    ["services"] = "/home/mlamkadm/services",
                },
            },
        }
    },
    config = function(_, opts)
        local telescope = require("telescope")

        -- Setup telescope
        telescope.setup(opts)

        -- Load extensions
        local extensions = {
            'cmdline',
            'lsp_handlers',
            'fzf',
            'ui-select',
            'frecency',
            'undo',
            'live_grep_args',
        }

        -- Safely load extensions
        for _, extension in ipairs(extensions) do
            pcall(function()
                telescope.load_extension(extension)
            end)
        end

        -- Custom action to open files in splits
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        telescope.setup({
            defaults = {
                mappings = {
                    i = {
                        ["<C-s>"] = function()
                            local selection = action_state.get_selected_entry()
                            if selection then
                                actions.close(vim.api.nvim_get_current_buf())
                                vim.cmd("split " .. selection.path)
                            end
                        end,
                        ["<C-v>"] = function()
                            local selection = action_state.get_selected_entry()
                            if selection then
                                actions.close(vim.api.nvim_get_current_buf())
                                vim.cmd("vsplit " .. selection.path)
                            end
                        end,
                    },
                },
            },
        })
    end,
}
```

### File: lua/mlamkadm/plugs/term.lua
```
return {
        'akinsho/toggleterm.nvim', version = "*", opts = { --[[ things you want to change go here]] }
}
```

### File: lua/mlamkadm/plugs/tokyonight.lua
```

return {
    -- "folke/tokyonight.nvim",
    -- gruvbox
    -- "ellisonleao/gruvbox.nvim",
}
```

### File: lua/mlamkadm/plugs/treesitter.lua
```
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            ensure_installed = { "c", "cpp", "markdown", "lua", "vim", "vimdoc", "query", "javascript", "html" },
            sync_install = true,
            highlight = { enable = true },
            indent = { enable = false },
            refactor = {
                highlight_definitions = { enable = true },
                highlight_current_scope = { enable = false },
                smart_rename = {
                    enable = true,
                    keymaps = {
                        smart_rename = "grr",  -- Trigger rename with 'grr'
                    },
                },
                navigation = {
                    enable = true,
                    keymaps = {
                        goto_definition = "gnd",
                        list_definitions = "gnD",
                        list_definitions_toc = "gO",
                        goto_next_usage = "<a-*>",
                        goto_previous_usage = "<a-#>",
                    },
                },
            },
        })
    end,
    dependencies = {
        "nvim-treesitter/nvim-treesitter-refactor",
        "nvim-lua/plenary.nvim",  -- Required for rename across files
    },
}
```

### File: lua/mlamkadm/plugs/whichkey.lua
```
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 300
    end,
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    }
}
```

### File: lua/mlamkadm/plugs/winshift.lua
```

return {
    "sindrets/winshift.nvim"
}
```

### File: main.lua
```

-- ************************************************************************** --
--                                                                            --
--                                                        :::      ::::::::   --
--   gemini.lua                                         :+:      :+:    :+:   --
--                                                    +:+ +:+         +:+     --
--   By: mlamkadm <mlamkadm@student.42.fr>          +#+  +:+       +#+        --
--                                                +#+#+#+#+#+   +#+           --
--   Created: 2025/04/01 11:26:49 by mlamkadm          #+#    #+#             --
--   Updated: 2025/04/01 11:26:49 by mlamkadm         ###   ########.fr       --
--                                                                            --
-- ************************************************************************** --

local gemini = {}

-- Configuration
local config = {
    api_key = "AIzaSyDRKg7kYPJPSCxYhsSWC73xK1iCoaDA3Z4",
    model = "gemini-1.5-pro-latest",
    base_url = "https://generativelanguage.googleapis.com/v1beta/models",
    temperature = 0.3,
    max_tokens = 2048
}

-- Dependencies (these would need to be available in your Lua environment)
local json
local http

json = require('lunajson')
-- -- Try to load required libraries
-- if pcall(require, 'lunajson') then
--     json = require('lunajson')
-- elseif pcall(require, 'cjson') then
--     json = require('cjson')
-- elseif pcall(require, 'json') then
--     json = require('json')
-- else
--     error("JSON library required (dkjson, cjson, or similar)")
-- end

if pcall(require, 'socket.http') then
    http = require('socket.http')
elseif pcall(require, 'resty.http') then
    http = require('resty.http')
else
    error("HTTP library required (socket.http, resty.http, or similar)")
end

-- Helper function for HTTP requests
local function make_request(url, payload)
    local body = json.encode(payload)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #body
    }

    local res, status, response_headers
    if http.request then -- LuaSocket style
        local request_body = {}
        res, status, response_headers = http.request {
            url = url,
            method = "POST",
            headers = headers,
            source = ltn12.source.string(body),
            sink = ltn12.sink.table(request_body)
        }
        res = table.concat(request_body)
    else -- OpenResty style
        local client = http.new()
        res, err = client:request_uri(url, {
            method = "POST",
            body = body,
            headers = headers
        })
        if not res then
            return nil, err
        end
        status = res.status
        res = res.body
    end

    if status ~= 200 then
        return nil, "HTTP error: " .. tostring(status)
    end

    local data, err = json.decode(res)
    if not data then
        return nil, "JSON decode error: " .. tostring(err)
    end

    return data
end

-- Main generation function
function gemini.generate(prompt, options)
    options = options or {}
    local url = string.format("%s/%s:generateContent?key=%s",
        config.base_url,
        options.model or config.model,
        options.api_key or config.api_key)

    local payload = {
        contents = {
            {
                parts = {
                    {
                        text = prompt
                    }
                }
            }
        },
        generationConfig = {
            temperature = options.temperature or config.temperature,
            maxOutputTokens = options.max_tokens or config.max_tokens
        }
    }

    local data, err = make_request(url, payload)
    if not data then
        return nil, err
    end

    -- Extract response text
    if data.candidates and data.candidates[1] and data.candidates[1].content and data.candidates[1].content.parts then
        return data.candidates[1].content.parts[1].text
    else
        local error_msg = data.error and data.error.message or "Unknown error"
        return nil, "API Error: " .. error_msg
    end
end

-- Simple chat interface
function gemini.chat(options)
    options = options or {}
    local history = options.history or {}

    return function(prompt)
        table.insert(history, { role = "user", parts = { { text = prompt } } })

        local url = string.format("%s/%s:generateContent?key=%s",
            config.base_url,
            options.model or config.model,
            options.api_key or config.api_key)

        local payload = {
            contents = history,
            generationConfig = {
                temperature = options.temperature or config.temperature,
                maxOutputTokens = options.max_tokens or config.max_tokens
            }
        }

        local data, err = make_request(url, payload)
        if not data then
            return nil, err
        end

        -- Extract response
        if data.candidates and data.candidates[1] and data.candidates[1].content then
            local response = data.candidates[1].content
            table.insert(history, response)

            if response.parts and response.parts[1] then
                return response.parts[1].text
            end
        end

        local error_msg = data.error and data.error.message or "Unknown error"
        return nil, "API Error: " .. error_msg
    end
end

-- Tool calling support (basic implementation)
function gemini.tool_prompt(system_prompt, tools, history, user_input)
    local prompt = system_prompt .. "\n\n"

    if tools and next(tools) ~= nil then
        prompt = prompt .. "Available tools:\n"
        for name, tool in pairs(tools) do
            prompt = prompt .. string.format("- %s: %s\n", name, tool.description)
            prompt = prompt .. string.format("  Parameters: %s\n", json.encode(tool.params_schema))
        end
        prompt = prompt .. "\n"
    end

    if history and next(history) ~= nil then
        prompt = prompt .. "Conversation history:\n"
        for _, msg in ipairs(history) do
            prompt = prompt .. string.format("%s: %s\n", msg.role, msg.content)
        end
        prompt = prompt .. "\n"
    end

    prompt = prompt .. string.format("User: %s\n\nAssistant: ", user_input)

    return prompt
end

-- ************************************************************************** --
-- Simple test cases
-- -- Uncomment the following lines to run simple test cases

local function test()
    local prompt = "What is the capital of France?"
    local options = {
        }
    local response, err = gemini.generate(prompt, options)
    print("Response:", response)
    print("Error:", err)
end


test()

        
```

### File: test.lua
```
-- main.lua
local SimpleGemini = require('gemini')

-- Create a client instance (uses environment variable for API key by default)
-- You can override defaults:
-- local gemini = SimpleGemini:new({ api_key = "YOUR_KEY", model = "gemini-1.5-pro-latest", temperature = 0.8 })
local gemini = SimpleGemini:new()

-- --- Simple Generation ---
print("--- Simple Generate ---")
local prompt1 = "What is the capital of Canada?"
local response1, err1 = gemini:generate(prompt1)

if err1 then
    print("Error:", err1)
else
    print("User:", prompt1)
    print("Assistant:", response1)
end

-- --- Chat ---
print("\n--- Chat ---")
-- You need to manage the history list yourself
local chat_history = {}

local function add_to_history(role, text)
    table.insert(chat_history, { role = role, parts = { { text = text } } })
end

local prompt2 = "What are the main features of the Lua language?"
print("User:", prompt2)
local response2, err2 = gemini:chat(chat_history, prompt2)

if err2 then
    print("Error:", err2)
else
    print("Assistant:", response2)
    -- Add both user prompt and assistant response to history for next turn
    add_to_history("user", prompt2)
    add_to_history("model", response2) -- The API uses "model" for the assistant role
end

print("\n--- Chat (Continue) ---")
local prompt3 = "Can you list one specific feature you mentioned in more detail?"
print("User:", prompt3)
local response3, err3 = gemini:chat(chat_history, prompt3)

if err3 then
    print("Error:", err3)
else
    print("Assistant:", response3)
    -- Add to history again if continuing the chat
    add_to_history("user", prompt3)
    add_to_history("model", response3)
end

-- print("\nFinal History:")
-- print(require('lunajson').encode(chat_history)) -- If you want to see the history structure
```

### File: tests/test.lua
```

local gemini = require("lua.mlamkadm.core.gemini")

local response, err = gemini.generate("What is the capital of France?")
if err then
    print("Error:", err)
else
    print(response)
end
```
