local M = {}
local config = require('tabline.config')
local desambiguate = require('tabline.desambiguition').desambiguate

M.get_hl = function(group, item, index, modified)
    if item == '' then
        return ''
    end

    local active = index == vim.fn.tabpagenr()
    if modified then
        group = group .. 'Modified'
    end
    if active then
        group = group .. 'Sel'
    end

    return '%#' .. group .. '#' .. item .. '%*'
end

local tabnames = {}

M.update_tabnames = function()
    for i, winid in ipairs(vim.api.nvim_list_wins()) do
        local bufnr = vim.api.nvim_win_get_buf(winid)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        tabnames[i] = vim.fs.normalize(bufname)
    end
    tabnames = desambiguate(tabnames)
end

M.get_tabname = function(index)
    local title = vim.fn.gettabvar(index, 'TablineTitle')
    if title ~= vim.NIL and title ~= '' then
        return title
    end
    return tabnames[index]
end

local is_focusable = function(win_id)
    return vim.api.nvim_win_get_config(win_id).focusable
end

M.eval_len = function(str)
    return vim.api.nvim_eval_statusline(str, { maxwidth = 1600, use_winbar = true }).width
end

M.get_win_count = function(index)
    local win_list = vim.api.nvim_tabpage_list_wins(index)

    local buf_list = {}
    local opts = config.get('show_window_count')

    for _, win_id in pairs(win_list) do
        if is_focusable(win_id) then
            local bufnr = vim.api.nvim_win_get_buf(win_id)
            local bt = vim.bo[bufnr].buftype

            if not vim.list_contains(opts.buftype_blacklist, bt) then
                table.insert(buf_list, bufnr)
            end
        end
    end

    local counted = 0
    if opts.count_unique_buf then
        local counted_unique = {}
        for _, bufnr in pairs(buf_list) do
            counted_unique[bufnr] = bufnr
        end
        for _, _ in pairs(counted_unique) do
            counted = counted + 1
        end
    else
        counted = #buf_list
    end
    if counted == 1 and not opts.show_if_alone then
        return ''
    else
        if opts.count_others then
            -- if blacklisted buftype is currently focused, the [+x] doesn't make sense, so
            -- we kind of count it anyway
            local focused_bufnr = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(index))
            local focused_bt = vim.bo[focused_bufnr].buftype
            if vim.list_contains(opts.buftype_blacklist, focused_bt) then
                return string.format(' [+%s]', counted)
            else
                return string.format(' [+%s]', counted - 1)
            end
        else
            return string.format(' [%s]', counted)
        end
    end
end

return M
