return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "williamboman/mason.nvim",
            "jay-babu/mason-nvim-dap.nvim",
            "leoluz/nvim-dap-go",
            "mfussenegger/nvim-dap-python",
        },
        keys = {
            {
                "<F5>",
                function()
                    require("dap").continue()
                end,
                desc = "Debug: Continue",
            },
            {
                "<F10>",
                function()
                    require("dap").step_over()
                end,
                desc = "Debug: Step Over",
            },
            {
                "<F11>",
                function()
                    require("dap").step_into()
                end,
                desc = "Debug: Step Into",
            },
            {
                "<F12>",
                function()
                    require("dap").step_out()
                end,
                desc = "Debug: Step Out",
            },
            {
                "<leader>b",
                function()
                    require("dap").toggle_breakpoint()
                end,
                desc = "Debug: Toggle Breakpoint",
            },
            {
                "<leader>B",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end,
                desc = "Debug: Conditional Breakpoint",
            },
            {
                "<leader>du",
                function()
                    require("dapui").toggle()
                end,
                desc = "Debug: Toggle UI",
            },
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            require("mason-nvim-dap").setup({
                -- Makes a best effort to setup the various debuggers with
                -- reasonable debug configurations
                automatic_setup = true,

                -- You can provide additional configuration to the handlers,
                -- see mason-nvim-dap README for more information
                handlers = {},

                -- You'll need to check that you have the required things installed
                -- online, please don't ask me how to install them :)
                ensure_installed = {
                    -- Update this to ensure that you have the debuggers for the languages you want
                    "delve",
                    "codelldb",
                    "debugpy",
                    "javadbg",
                    "javatest",
                },
            })

            -- Dap UI setup
            -- For more information, see |:help nvim-dap-ui|
            dapui.setup({
                -- Set icons to characters that are more likely to work in all terminal fonts.
                -- Feel free to remove those if your font supports them.
                icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
                controls = {
                    icons = {
                        pause = "⏸",
                        play = "▶",
                        step_into = "⏎",
                        step_over = "⏭",
                        step_out = "⏮",
                        step_back = "b",
                        run_last = "▶▶",
                        terminate = "⏹",
                        disconnect = "⏏",
                    },
                },
            })

            -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
            vim.keymap.set("n", "<F7>", dapui.toggle, { desc = "Debug: See last session result." })

            dap.listeners.after.event_initialized["dapui_config"] = dapui.open
            dap.listeners.before.event_terminated["dapui_config"] = dapui.close
            dap.listeners.before.event_exited["dapui_config"] = dapui.close

            -- Install golang specific config
            require("dap-go").setup()

            -- Install python specific config
            -- Uses the debugpy installed by mason
            local debugpy_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
            require("dap-python").setup(debugpy_path)

            -- C/C++/Rust via codelldb
            -- mason-nvim-dap handles the setup usually, but custom configs can be added here
        end,
    },
}
