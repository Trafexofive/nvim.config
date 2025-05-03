
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

        
