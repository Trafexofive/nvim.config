
local gemini = require("lua.mlamkadm.core.gemini")

local response, err = gemini.generate("What is the capital of France?")
if err then
    print("Error:", err)
else
    print(response)
end
