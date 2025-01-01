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
