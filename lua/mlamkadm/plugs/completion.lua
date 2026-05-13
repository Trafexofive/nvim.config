-- lua/mlamkadm/plugs/gemini.lua (using Ollama for code completion since Gemini API isn't suitable)
-- Local Ollama model provides AI completion as an nvim-cmp source
return {
    'milanglacier/minuet-ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        require('minuet').setup {
            provider = 'openai_fim_compatible',  -- Fill-in-the-middle completion (good for code)
            n_completions = 1,
            context_window = 512,
            provider_options = {
                openai_fim_compatible = {
                    -- For Ollama, we use a placeholder API key (Ollama doesn't need a real key)
                    api_key = 'DUMMY',  -- Placeholder - Ollama doesn't need an API key
                    name = 'Ollama',
                    -- Ollama server endpoint for FIM (Fill in the Middle) compatible completion
                    end_point = 'http://localhost:11434/v1/completions',
                    model = 'codellama:7b',  -- Code-specific model, or you could use 'deepseek-coder:6.7b' or similar
                    optional = {
                        max_tokens = 56,
                        top_p = 0.9,
                        temperature = 0.2,
                    },
                },
            },
        }
    end,
    event = 'VeryLazy',
}