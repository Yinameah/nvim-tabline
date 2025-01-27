local M = {}

local config = require('tabline.config')

local split_path = function(name)
    local elems = vim.split(name, '/', { trimempty = false })
    local path_elems = {}
    for i = 1, #elems - 1 do
        path_elems[i] = elems[i]
    end
    return path_elems, elems[#elems]
end

local join_path = function(prev, new)
    if prev == nil then
        return new
    end
    if new == nil then
        return prev
    end
    return prev .. '/' .. new
end

local has_only_empty_sublists = function(list)
    local only_empty = true
    for _, sublist in ipairs(list) do
        if #sublist ~= 0 then
            only_empty = false
            break
        end
    end
    return only_empty
end

M.desambiguate = function(paths)
    local paths_infos, result = {}, {}

    -- Treat full duplicates only once,
    -- keep reference of them to copy the result at the end
    local duplicates = {}
    for orig_idx, p in ipairs(paths) do
        if duplicates[p] == nil then
            duplicates[p] = { orig_idx }
        else
            table.insert(duplicates[p], orig_idx)
        end
    end
    local copy_table = {}
    for _, p_counts in pairs(duplicates) do
        for i, orig_idx in ipairs(p_counts) do
            if i > 1 then
                paths[orig_idx] = nil
                if copy_table[p_counts[1]] == nil then
                    copy_table[p_counts[1]] = { orig_idx }
                else
                    table.insert(copy_table[p_counts[1]], orig_idx)
                end
            end
        end
    end
    -- copy_table now contains something like :
    -- {orig_id_ref = { orig_id_cpy1, orig_id_cpy2 ... } , ... }
    -- paths is now cripple of duplicates, not a list anymore

    -- Split paths and index by tail to check what need disambiguation
    for orig_idx, path in pairs(paths) do
        -- Empty paths are already resolved
        if path == '' then
            result[orig_idx] = config.get('no_name')
        else
            local head, tail = split_path(path)
            if paths_infos[tail] == nil then
                paths_infos[tail] = { orig_idx = { orig_idx }, elems_heads = { head } }
            else
                table.insert(paths_infos[tail].orig_idx, orig_idx)
                table.insert(paths_infos[tail].elems_heads, head)
            end
        end
    end

    -- Resolve unambiguous ones, directly push in result, remove from paths_infos
    for tail, infos in pairs(paths_infos) do
        if #infos.orig_idx == 1 then
            result[infos.orig_idx[1]] = vim.fn.fnamemodify(paths[infos.orig_idx[1]], ':t')
            paths_infos[tail] = nil
        end
    end

    -- Iterate ambiguous ones until they are not anymore
    for tail, infos in pairs(paths_infos) do
        while not has_only_empty_sublists(infos.elems_heads) do
            local head_comp = {}
            -- Index by last head elem, keeping track of original index
            for i, orig_idx in ipairs(infos.orig_idx) do
                local last_head_elem = table.remove(infos.elems_heads[i], #infos.elems_heads[i])
                if last_head_elem ~= nil then
                    if head_comp[last_head_elem] == nil then
                        head_comp[last_head_elem] = { i }
                    else
                        table.insert(head_comp[last_head_elem], i)
                    end
                end
            end
            -- If last head elem is unique, we have no ambiguity left
            -- Otherwise, we store the last head in the result for the next loop
            for last_head, indexes in pairs(head_comp) do
                if #indexes == 1 then
                    local orig_i = infos.orig_idx[indexes[1]]
                    local head_so_far = join_path(last_head, result[orig_i])
                    result[orig_i] = join_path(head_so_far, tail)
                    -- Empty elems_heads that are desambiguated
                    infos.elems_heads[indexes[1]] = {}
                else
                    for _, i in ipairs(indexes) do
                        local orig_i = infos.orig_idx[i]
                        local head_so_far = join_path(last_head, result[orig_i])
                        result[orig_i] = head_so_far
                    end
                end
            end
        end
    end

    -- At last, restore full path duplicates
    for orig_idx_ref, copies_idx in pairs(copy_table) do
        for _, idx in ipairs(copies_idx) do
            result[idx] = result[orig_idx_ref]
        end
    end
    return result
end

return M
