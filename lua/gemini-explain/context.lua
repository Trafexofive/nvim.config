local M = {}

-- Function to get the git root directory
local function get_git_root()
  local cwd = vim.fn.getcwd()
  local current_dir = cwd

  -- Traverse up the directory tree to find .git
  while current_dir ~= "/" do
    if vim.fn.isdirectory(current_dir .. "/.git") == 1 then
      return current_dir
    end
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end

  -- If we reach here, we didn't find a .git directory
  return cwd
end

-- Function to get the relative file path from git root
local function get_relative_path()
  local current_file = vim.fn.expand("%:p")
  local git_root = get_git_root()
  
  if string.find(current_file, git_root, 1, true) == 1 then
    return string.sub(current_file, #git_root + 2)
  else
    return current_file
  end
end

-- Function to get the git tree structure
local function get_git_tree(max_files)
  local git_root = get_git_root()
  local files_output = vim.fn.systemlist("cd " .. git_root .. " && git ls-files")
  
  -- Limit the number of files if needed
  if #files_output > max_files then
    local limited_files = {}
    for i = 1, max_files do
      limited_files[i] = files_output[i]
    end
    table.insert(limited_files, "... (truncated)")
    return limited_files
  end
  
  return files_output
end

-- Function to get surrounding lines around the selection
local function get_surrounding_lines(start_line, end_line, context_lines)
  local total_lines = vim.fn.line("$")
  local start_context = math.max(1, start_line - context_lines)
  local end_context = math.min(total_lines, end_line + context_lines)
  
  local lines = vim.fn.getline(start_context, end_context)
  
  -- Add line numbers to the context
  local numbered_lines = {}
  for i, line in ipairs(lines) do
    local actual_line_num = start_context + i - 1
    table.insert(numbered_lines, string.format("%4d: %s", actual_line_num, line))
  end
  
  return table.concat(numbered_lines, "\n")
end

-- Function to detect the file type/language
local function get_file_type()
  return vim.bo.filetype
end

-- Main function to build context
function M.build_context(start_line, end_line)
  local config = require("gemini-explain").active_config
  
  local relative_path = get_relative_path()
  local git_tree = get_git_tree(config.max_tree_files)
  local surrounding_lines = get_surrounding_lines(start_line, end_line, config.context_lines)
  local file_type = get_file_type()
  
  local context_parts = {
    "Current file: " .. relative_path,
    "File type: " .. file_type,
    "",
    "Surrounding code context:",
    surrounding_lines,
    "",
    "Repository file structure:",
    table.concat(git_tree, "\n")
  }
  
  return table.concat(context_parts, "\n")
end

-- Function to read a specific file by path
function M.read_file(file_path)
  -- Resolve relative to git root
  local git_root = get_git_root()
  local full_path = git_root .. "/" .. file_path
  
  if vim.fn.filereadable(full_path) == 1 then
    local lines = vim.fn.readfile(full_path)
    return table.concat(lines, "\n")
  else
    return nil
  end
end

return M