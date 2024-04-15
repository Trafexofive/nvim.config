Here is a comprehensive guide to the Neovim and installed plugins shortcuts mentioned in the code snippet:

1. Local function `map()`: This function allows you to map a key or a command to a new key or command. The function takes four arguments: `mode`, `lhs`, `rhs`, and `opts`. In this guide, we will focus on the shortcuts defined in the `map()` function.
2. Disabling arrow keys: To disable arrow keys, you can use the following mapping: `map('', '<up>', '<nop>')`. This will map the up arrow key to nothing (`<nop>`). Similarly, you can map the down arrow key by using the following mapping: `map('', '<down>', '<nop>')`.
3. Clear search highlighting with `<leader> and c`: You can clear the search highlighting by pressing `<leader>` (which is typically `space`) followed by `c`. To map this command to a key, you can use the following mapping: `map('n', '<leader>c', ':nohl<CR>')`.
4. Toggle auto-indenting for code paste: You can toggle auto-indenting for code paste by using the following mapping: `map('n', '<F2>', ':set invpaste paste?<CR>')`. This will map the F2 key to toggle auto-indentation for code pastes.
5. Change split orientation: You can change the orientation of splits by using the following mappings: `map('n', '<leader>tk', '<C-w>t<C-w>K')`, which will change vertical splits to horizontal, and `map('n', '<leader>th', '<C-w>t<C-w>H')`, which will change horizontal splits to vertical.

