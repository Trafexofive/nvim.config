local M = {}

local Job = require("plenary.job")

-- Function to check if mvn is available
function M.has_maven()
    local result = vim.fn.system("command -v mvn")
    return vim.v.shell_error == 0
end

-- Function to run a maven task
function M.run_maven_task(task, opts)
    opts = opts or {}
    local silent = opts.silent or false
    local callback = opts.callback or nil

    if not M.has_maven() then
        vim.notify("Maven (mvn) not found in the system", vim.log.levels.ERROR)
        return
    end

    -- Create a floating window to display the output
    if not silent then
        -- Reuse the same build output functions from Gradle module
        local gradle_module = require("mc-modder.gradle")
        gradle_module.show_build_output()
    end

    -- Run the maven task using plenary.job
    Job:new({
        command = "mvn",
        args = vim.split(task, " "), -- Allow multiple arguments like "clean install"
        cwd = vim.fn.getcwd(),
        on_stdout = function(_, data)
            if data and not silent then
                local gradle_module = require("mc-modder.gradle")
                gradle_module.append_to_build_output(data)
            end
        end,
        on_stderr = function(_, data)
            if data and not silent then
                local gradle_module = require("mc-modder.gradle")
                gradle_module.append_to_build_output("ERROR: " .. data, "error")
            end
        end,
        on_exit = function(job)
            local exit_code = job.code
            if callback then
                callback(exit_code == 0, job:result())
            else
                if exit_code == 0 then
                    vim.notify("Maven task '" .. task .. "' completed successfully", vim.log.levels.INFO)
                else
                    vim.notify("Maven task '" .. task .. "' failed with exit code: " .. exit_code, vim.log.levels.ERROR)
                end
            end
        end,
    }):start()
end

-- Common Maven tasks for Minecraft modding
M.common_tasks = {
    build = "compile",
    clean = "clean",
    install = "install",
    test = "test",
    package = "package",
    verify = "verify",
    deploy = "deploy",
    site = "site",
}

-- Function to run common Maven tasks with presets
function M.run_common_task(task_name, opts)
    local task = M.common_tasks[task_name]
    if not task then
        vim.notify("Unknown Maven task: " .. task_name, vim.log.levels.ERROR)
        return
    end

    M.run_maven_task(task, opts)
end

-- Function to get available Maven lifecycle phases
function M.get_available_phases()
    return {
        "validate",
        "initialize",
        "generate-sources",
        "process-sources",
        "generate-resources",
        "process-resources",
        "compile",
        "process-classes",
        "generate-test-sources",
        "process-test-sources",
        "generate-test-resources",
        "process-test-resources",
        "test-compile",
        "process-test-classes",
        "test",
        "prepare-package",
        "package",
        "pre-integration-test",
        "integration-test",
        "post-integration-test",
        "verify",
        "install",
        "deploy",
        "pre-clean",
        "clean",
        "post-clean",
        "pre-site",
        "site",
        "post-site",
        "site-deploy",
    }
end

-- Function to get plugins and goals from the project
function M.get_available_goals(callback)
    if not M.has_maven() then
        callback(nil, "Maven not found in the system")
        return
    end

    Job:new({
        command = "mvn",
        args = { "help:describe", "-Ddetail=true", "--batch-mode" },
        cwd = vim.fn.getcwd(),
        on_exit = function(job)
            if job.code == 0 then
                local goals = {}
                local result = job:result()

                for _, line in ipairs(result) do
                    -- Look for lines that contain plugin goals
                    local goal_match = line:match("^%s*([%w%-:]+)%s*$")
                    if goal_match and goal_match:match(":") then -- Contains plugin:goal format
                        table.insert(goals, goal_match)
                    end
                end

                callback(goals)
            else
                -- If help:describe fails, return common lifecycle phases
                callback(M.get_available_phases(), "Could not get project-specific goals, using default phases")
            end
        end,
    }):start()
end

return M
