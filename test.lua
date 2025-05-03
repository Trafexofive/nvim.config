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
