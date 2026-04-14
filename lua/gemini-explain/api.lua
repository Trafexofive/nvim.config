local M = {}

local gemini_context = require("gemini-explain.context")
local gemini_ui = require("gemini-explain.ui")

-- Function to send code to Gemini API with true streaming
function M.send_to_gemini(code_snippet, context, callback)
  local config = require("gemini-explain").active_config

  -- Prepare the prompt with context
  local prompt = "Please explain the following code:\n\n" .. code_snippet .. "\n\nContext:\n" .. context

  -- Construct the API request body for streaming
  local body = {
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
      temperature = 0.2,
      maxOutputTokens = 2048,
    },
    safetySettings = {
      {
        category = "HARM_CATEGORY_DANGEROUS_CONTENT",
        threshold = "BLOCK_NONE"
      }
    }
  }

  -- Convert body to JSON
  local json_body = vim.fn.json_encode(body)

  -- Make the streaming API request
  local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. config.model .. ":streamGenerateContent?key=" .. config.api_key

  -- Initialize the UI to show a loading message
  gemini_ui.initialize_streaming_display()

  -- Use plenary's async functionality for streaming
  local Job = require("plenary.job")

  -- Accumulated response text
  local accumulated_response = ""
  local all_chunks = {}

  -- Make the streaming request using curl command directly
  Job:new({
    command = "curl",
    args = {
      "-X", "POST",
      "-H", "Content-Type: application/json",
      "-d", json_body,
      url
    },
    on_stdout = function(job, data)
      if data then
        -- Accumulate the data
        accumulated_response = accumulated_response .. data

        -- Handle Server-Sent Events format (data: prefix)
        local lines = {}
        for s in accumulated_response:gmatch("[^\n]+") do
          table.insert(lines, s)
        end

        -- Process each complete line
        for i = 1, #lines - 1 do  -- Skip the last item which might be incomplete
          local line = lines[i]
          if line and line ~= "" then
            -- Remove "data:" prefix if present (common in server-sent events)
            local clean_line = line:gsub("^data:%s*", "")
            clean_line = clean_line:gsub("^%s+", ""):gsub("%s+$", "")  -- trim

            if clean_line ~= "" and clean_line ~= "[DONE]" then
              -- Attempt to decode the JSON
              local success, result = pcall(vim.fn.json_decode, clean_line)
              if success and result then
                table.insert(all_chunks, result)

                -- Extract the text content from this chunk
                if result.candidates and #result.candidates > 0 then
                  local candidate = result.candidates[1]
                  if candidate.content and candidate.content.parts then
                    for _, part in ipairs(candidate.content.parts) do
                      if part.text then
                        -- Update the UI with the incremental response
                        gemini_ui.update_streaming_display(part.text)
                      end
                    end
                  end
                end
              end
            end
          end
        end

        -- Keep the last potentially incomplete line for next iteration
        if #lines > 0 then
          accumulated_response = lines[#lines] or ""
        else
          accumulated_response = ""
        end
      end
    end,
    on_exit = function(job)
      -- Process any remaining data
      if accumulated_response and accumulated_response ~= "" then
        -- Remove "data:" prefix if present
        local clean_remaining = accumulated_response:gsub("^data:%s*", "")
        clean_remaining = clean_remaining:gsub("^%s+", ""):gsub("%s+$", "")  -- trim

        if clean_remaining ~= "" and clean_remaining ~= "[DONE]" then
          local success, result = pcall(vim.fn.json_decode, clean_remaining)
          if success and result then
            table.insert(all_chunks, result)
          end
        end
      end

      -- Combine all text parts from all chunks
      local full_explanation = ""
      for _, chunk in ipairs(all_chunks) do
        if chunk.candidates and #chunk.candidates > 0 then
          local candidate = chunk.candidates[1]
          if candidate.content and candidate.content.parts then
            for _, part in ipairs(candidate.content.parts) do
              if part.text then
                full_explanation = full_explanation .. part.text
              end
            end
          end
        end
      end

      -- Schedule the callback to run in the main thread to avoid fast event context issues
      vim.schedule(function()
        -- Check if the agent requested to read a file
        if string.find(full_explanation, "READ_FILE:") then
          M.handle_agent_request(full_explanation, callback)
        else
          callback(full_explanation)
        end
      end)
    end
  }):start()
end

-- Function to handle agent requests for additional files
function M.handle_agent_request(response, original_callback)
  local config = require("gemini-explain").active_config

  -- Find all READ_FILE directives
  local has_processed_request = false
  for file_path in string.gmatch(response, "READ_FILE:%s*([^\n]+)") do
    file_path = vim.trim(file_path)
    has_processed_request = true

    -- Read the requested file
    local file_content = gemini_context.read_file(file_path)

    if file_content then
      -- Prepare a follow-up request with the file content
      local follow_up_prompt = "Here's the content of " .. file_path .. ":\n\n" .. file_content .. "\n\nPlease continue with the explanation."

      local body = {
        contents = {
          {
            parts = {
              {
                text = follow_up_prompt
              }
            }
          }
        },
        generationConfig = {
          temperature = 0.2,
          maxOutputTokens = 2048,
        },
        safetySettings = {
          {
            category = "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold = "BLOCK_NONE"
          }
        }
      }

      local json_body = vim.fn.json_encode(body)

      -- Make the follow-up API request (non-streaming)
      local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. config.model .. ":generateContent?key=" .. config.api_key

      -- Use plenary's async functionality
      local Job = require("plenary.job")

      -- Make the follow-up API request using streaming
      local follow_url = "https://generativelanguage.googleapis.com/v1beta/models/" .. config.model .. ":streamGenerateContent?key=" .. config.api_key

      -- Initialize the accumulated response for follow-up
      local accumulated_followup_response = ""
      local all_followup_chunks = {}

      -- Make the streaming request using curl command directly
      Job:new({
        command = "curl",
        args = {
          "-X", "POST",
          "-H", "Content-Type: application/json",
          "-d", json_body,
          follow_url
        },
        on_stdout = function(job, data)
          if data then
            -- Accumulate the data
            accumulated_followup_response = accumulated_followup_response .. data

            -- Handle Server-Sent Events format (data: prefix)
            local lines = {}
            for s in accumulated_followup_response:gmatch("[^\n]+") do
              table.insert(lines, s)
            end

            -- Process each complete line
            for i = 1, #lines - 1 do  -- Skip the last item which might be incomplete
              local line = lines[i]
              if line and line ~= "" then
                -- Remove "data:" prefix if present (common in server-sent events)
                local clean_line = line:gsub("^data:%s*", "")
                clean_line = clean_line:gsub("^%s+", ""):gsub("%s+$", "")  -- trim

                if clean_line ~= "" and clean_line ~= "[DONE]" then
                  -- Attempt to decode the JSON
                  local success, result = pcall(vim.fn.json_decode, clean_line)
                  if success and result then
                    table.insert(all_followup_chunks, result)

                    -- Extract the text content from this chunk
                    if result.candidates and #result.candidates > 0 then
                      local candidate = result.candidates[1]
                      if candidate.content and candidate.content.parts then
                        for _, part in ipairs(candidate.content.parts) do
                          if part.text then
                            -- Update the UI with the incremental response
                            gemini_ui.update_streaming_display(part.text)
                          end
                        end
                      end
                    end
                  end
                end
              end
            end

            -- Keep the last potentially incomplete line for next iteration
            if #lines > 0 then
              accumulated_followup_response = lines[#lines] or ""
            else
              accumulated_followup_response = ""
            end
          end
        end,
        on_exit = function(job)
          -- Process any remaining data
          if accumulated_followup_response and accumulated_followup_response ~= "" then
            -- Remove "data:" prefix if present
            local clean_remaining = accumulated_followup_response:gsub("^data:%s*", "")
            clean_remaining = clean_remaining:gsub("^%s+", ""):gsub("%s+$", "")  -- trim

            if clean_remaining ~= "" and clean_remaining ~= "[DONE]" then
              local success, result = pcall(vim.fn.json_decode, clean_remaining)
              if success and result then
                table.insert(all_followup_chunks, result)
              end
            end
          end

          -- Combine all text parts from all follow-up chunks
          local follow_up_explanation = ""
          for _, chunk in ipairs(all_followup_chunks) do
            if chunk.candidates and #chunk.candidates > 0 then
              local candidate = chunk.candidates[1]
              if candidate.content and candidate.content.parts then
                for _, part in ipairs(candidate.content.parts) do
                  if part.text then
                    follow_up_explanation = follow_up_explanation .. part.text
                  end
                end
              end
            end
          end

          -- Schedule the callback to run in the main thread to avoid fast event context issues
          vim.schedule(function()
            -- Check if there are more file requests
            if string.find(follow_up_explanation, "READ_FILE:") then
              M.handle_agent_request(follow_up_explanation, original_callback)
            else
              original_callback(response .. "\n\n" .. follow_up_explanation)
            end
          end)
        end
      }):start()

      return  -- Exit after processing the first file request for simplicity
    else
      -- If file couldn't be read, continue processing other requests
      vim.notify("Could not read file: " .. file_path, vim.log.levels.WARN)
    end
  end

  -- If no READ_FILE directives were processed, call the original callback
  if not has_processed_request then
    original_callback(response)
  end
end

return M