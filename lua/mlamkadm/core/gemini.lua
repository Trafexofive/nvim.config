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