local M = {}

local Job = require("plenary.job")

-- Function to check if gradle is available
function M.has_gradle()
    local result = vim.fn.system("command -v gradle")
    return vim.v.shell_error == 0
end

-- Function to check if gradlew is available in the current project
function M.has_gradlew()
    return vim.fn.executable("./gradlew") == 1
end

-- Function to run a gradle task
function M.run_gradle_task(task, opts)
    opts = opts or {}
    local use_wrapper = opts.use_wrapper ~= false -- default to true
    local silent = opts.silent or false
    local callback = opts.callback or nil

    local gradle_cmd
    if use_wrapper and M.has_gradlew() then
        gradle_cmd = "./gradlew"
    elseif M.has_gradle() then
        gradle_cmd = "gradle"
    else
        vim.notify("Neither gradle nor gradlew found in the project", vim.log.levels.ERROR)
        return
    end

    -- Create a floating window to display the output
    if not silent then
        M.show_build_output()
    end

    -- Run the gradle task using plenary.job
    Job:new({
        command = gradle_cmd,
        args = { task, "--console=plain" },
        cwd = vim.fn.getcwd(),
        on_stdout = function(_, data)
            if data and not silent then
                M.append_to_build_output(data)
            end
        end,
        on_stderr = function(_, data)
            if data and not silent then
                M.append_to_build_output("ERROR: " .. data, "error")
            end
        end,
        on_exit = function(job)
            local exit_code = job.code
            if callback then
                callback(exit_code == 0, job:result())
            else
                if exit_code == 0 then
                    vim.notify("Gradle task '" .. task .. "' completed successfully", vim.log.levels.INFO)
                else
                    vim.notify(
                        "Gradle task '" .. task .. "' failed with exit code: " .. exit_code,
                        vim.log.levels.ERROR
                    )
                end
            end
        end,
    }):start()
end

-- Build output window variables
local build_output_buf = nil
local build_output_win = nil

-- Function to show the build output window
function M.show_build_output()
    -- Create buffer if it doesn't exist
    if not build_output_buf or not vim.api.nvim_buf_is_valid(build_output_buf) then
        build_output_buf = vim.api.nvim_create_buf(false, true) -- not listed, scratch
        vim.api.nvim_buf_set_option(build_output_buf, "bufhidden", "hide")
        vim.api.nvim_buf_set_option(build_output_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(build_output_buf, "filetype", "gradle-output")
        vim.api.nvim_buf_set_option(build_output_buf, "modifiable", true)
    end

    -- Create window if it doesn't exist or recreate if closed
    if not build_output_win or not vim.api.nvim_win_is_valid(build_output_win) then
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.3)

        local row = vim.o.lines - height - 2
        local col = math.floor((vim.o.columns - width) / 2)

        build_output_win = vim.api.nvim_open_win(build_output_buf, false, {
            relative = "editor",
            width = width,
            height = height,
            row = row,
            col = col,
            style = "minimal",
            border = "rounded",
            title = "Gradle Build Output",
            title_pos = "center",
        })

        -- Set window options
        vim.api.nvim_win_set_option(build_output_win, "winhighlight", "Normal:Normal,FloatBorder:FloatBorder")

        -- Set buffer options
        vim.api.nvim_buf_set_option(build_output_buf, "buflisted", false)
        vim.api.nvim_buf_set_option(build_output_buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(build_output_buf, "filetype", "gradle-output")
    else
        -- Bring window to front if it already exists
        vim.api.nvim_set_current_win(build_output_win)
    end

    -- Set up key mapping to close the window
    vim.api.nvim_buf_set_keymap(build_output_buf, "n", "q", "<cmd>hide<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(build_output_buf, "n", "<Esc>", "<cmd>hide<CR>", { noremap = true, silent = true })
end

-- Function to append text to the build output window
function M.append_to_build_output(text, severity)
    if not build_output_buf or not vim.api.nvim_buf_is_valid(build_output_buf) then
        return
    end

    -- Make the buffer modifiable
    vim.api.nvim_buf_set_option(build_output_buf, "modifiable", true)

    -- Get current line count
    local line_count = vim.api.nvim_buf_line_count(build_output_buf)

    -- Prepare the text to append
    local lines = {}
    if type(text) == "string" then
        for line in text:gmatch("[^\n]*") do
            if line ~= "" then
                table.insert(lines, line)
            end
        end
    elseif type(text) == "table" then
        lines = text
    end

    -- Append the lines
    if #lines > 0 then
        vim.api.nvim_buf_set_lines(build_output_buf, -1, -1, false, lines)
    end

    -- Restore non-modifiable state
    vim.api.nvim_buf_set_option(build_output_buf, "modifiable", false)

    -- Scroll to the bottom
    if build_output_win and vim.api.nvim_win_is_valid(build_output_win) then
        vim.api.nvim_win_set_cursor(build_output_win, { vim.api.nvim_buf_line_count(build_output_buf), 0 })
    end
end

-- Function to close the build output window
function M.close_build_output()
    if build_output_win and vim.api.nvim_win_is_valid(build_output_win) then
        vim.api.nvim_win_close(build_output_win, true)
    end
end

-- Common Gradle tasks for Minecraft modding
M.common_tasks = {
    build = "build",
    clean = "clean",
    run_client = "runClient",
    run_server = "runServer",
    idea = "idea",
    eclipse = "eclipse",
    gen_sources = "genSources",
    download_assets = "downloadAssets",
    extract_natives = "extractNatives",
    jar = "jar",
}

-- Function to run common Gradle tasks with presets
function M.run_common_task(task_name, opts)
    local task = M.common_tasks[task_name]
    if not task then
        vim.notify("Unknown Gradle task: " .. task_name, vim.log.levels.ERROR)
        return
    end

    M.run_gradle_task(task, opts)
end

-- Function to get available Gradle tasks in the project
function M.get_available_tasks(callback)
    local gradle_cmd
    if M.has_gradlew() then
        gradle_cmd = "./gradlew"
    elseif M.has_gradlew() then
        gradle_cmd = "gradle"
    else
        callback(nil, "Neither gradle nor gradlew found in the project")
        return
    end

    Job:new({
        command = gradle_cmd,
        args = { "tasks", "--console=plain" },
        cwd = vim.fn.getcwd(),
        on_exit = function(job)
            if job.code == 0 then
                local tasks = {}
                local result = job:result()
                local in_task_section = false

                for _, line in ipairs(result) do
                    -- Look for the start of the task list
                    if line:match(".*-.*Tasks.*-.*") then
                        in_task_section = true
                    elseif in_task_section then
                        -- Match lines like "taskName - Description"
                        local task_match = line:match("^([%w:]+)%s+-")
                        if task_match then
                            table.insert(tasks, task_match)
                        end
                        -- Stop when we reach the next section
                        if line:match(".*-.*Rules.*-.*") then
                            break
                        end
                    end
                end

                callback(tasks)
            else
                callback(nil, "Failed to get tasks: " .. table.concat(job:result(), "\n"))
            end
        end,
    }):start()
end

return M
