-- /lua/mlamkadm/utils/vim_motions.lua
-- Vim motions registry for learning and executing motions

local M = {}

-- Default motions registry with common Vim motions
M.motions = {
  { motion = "h", description = "Move cursor left", rank = 1, category = "movement" },
  { motion = "j", description = "Move cursor down", rank = 2, category = "movement" },
  { motion = "k", description = "Move cursor up", rank = 3, category = "movement" },
  { motion = "l", description = "Move cursor right", rank = 4, category = "movement" },
  { motion = "w", description = "Move to next word", rank = 5, category = "movement" },
  { motion = "b", description = "Move to previous word", rank = 6, category = "movement" },
  { motion = "e", description = "Move to end of word", rank = 7, category = "movement" },
  { motion = "0", description = "Move to beginning of line", rank = 8, category = "movement" },
  { motion = "$", description = "Move to end of line", rank = 9, category = "movement" },
  { motion = "^", description = "Move to first non-blank character", rank = 10, category = "movement" },
  { motion = "gg", description = "Go to first line", rank = 11, category = "movement" },
  { motion = "G", description = "Go to last line", rank = 12, category = "movement" },
  { motion = "H", description = "Move to top of screen", rank = 13, category = "movement" },
  { motion = "M", description = "Move to middle of screen", rank = 14, category = "movement" },
  { motion = "L", description = "Move to bottom of screen", rank = 15, category = "movement" },
  
  { motion = "i", description = "Enter insert mode", rank = 16, category = "editing" },
  { motion = "a", description = "Append after cursor", rank = 17, category = "editing" },
  { motion = "o", description = "Open new line below", rank = 18, category = "editing" },
  { motion = "O", description = "Open new line above", rank = 19, category = "editing" },
  { motion = "x", description = "Delete character under cursor", rank = 20, category = "editing" },
  { motion = "dd", description = "Delete current line", rank = 21, category = "editing" },
  { motion = "yy", description = "Yank current line", rank = 22, category = "editing" },
  { motion = "p", description = "Paste after cursor", rank = 23, category = "editing" },
  { motion = "P", description = "Paste before cursor", rank = 24, category = "editing" },
  { motion = "u", description = "Undo last change", rank = 25, category = "editing" },
  { motion = "<C-r>", description = "Redo last undo", rank = 26, category = "editing" },
  
  { motion = "f<char>", description = "Find character in current line", rank = 27, category = "search" },
  { motion = "t<char>", description = "Move before character in current line", rank = 28, category = "search" },
  { motion = ";", description = "Repeat last f, t, F, or T motion", rank = 29, category = "search" },
  { motion = ",", description = "Repeat last f, t, F, or T motion in opposite direction", rank = 30, category = "search" },
}

-- Function to register a new motion
function M.register_motion(motion, description, category)
  category = category or "general"
  
  -- Find next available rank
  local next_rank = 1
  for _, m in ipairs(M.motions) do
    if m.rank >= next_rank then
      next_rank = m.rank + 1
    end
  end
  
  table.insert(M.motions, {
    motion = motion,
    description = description,
    rank = next_rank,
    category = category
  })
  
  -- Sort by rank after adding new motion
  M.sort_motions_by_rank()
end

-- Function to sort motions by rank
function M.sort_motions_by_rank()
  table.sort(M.motions, function(a, b)
    return a.rank < b.rank
  end)
end

-- Function to get motions (optionally filtered by category)
function M.get_motions(category)
  if not category then
    return M.motions
  end
  
  local filtered = {}
  for _, motion in ipairs(M.motions) do
    if motion.category == category then
      table.insert(filtered, motion)
    end
  end
  return filtered
end

-- Function to update a motion's rank
function M.update_motion_rank(motion, new_rank)
  for i, m in ipairs(M.motions) do
    if m.motion == motion then
      m.rank = new_rank
      break
    end
  end
  M.sort_motions_by_rank()
end

-- Function to move a motion up in rank (decrease rank number)
function M.move_motion_up(motion)
  for i, m in ipairs(M.motions) do
    if m.motion == motion then
      if i > 1 then  -- Not the first item
        local current_rank = m.rank
        local prev_motion = M.motions[i-1]
        m.rank = prev_motion.rank
        prev_motion.rank = current_rank
        M.sort_motions_by_rank()
        return true
      end
      break
    end
  end
  return false
end

-- Function to move a motion down in rank (increase rank number)
function M.move_motion_down(motion)
  local len = #M.motions
  for i, m in ipairs(M.motions) do
    if m.motion == motion then
      if i < len then  -- Not the last item
        local current_rank = m.rank
        local next_motion = M.motions[i+1]
        m.rank = next_motion.rank
        next_motion.rank = current_rank
        M.sort_motions_by_rank()
        return true
      end
      break
    end
  end
  return false
end

-- Function to remove a motion
function M.remove_motion(motion)
  for i, m in ipairs(M.motions) do
    if m.motion == motion then
      table.remove(M.motions, i)
      break
    end
  end
  -- Renumber ranks after removal
  for i, m in ipairs(M.motions) do
    m.rank = i
  end
end

return M