-- This files test the desambiguition function,
-- cause it's a bit too complex to have no unit tests here.
-- Unit tests of the poor however. Just run "luafile %" in neovim to "run the tests"

local config = require('tabline.config')

package.loaded['tabline.desambiguition'] = nil
local desambiguate = require('tabline.desambiguition').desambiguate2

local function check_desambiguition(test_str, input, expected)
    local input_len = #input
    local output = desambiguate(input)
    local failures = {}
    if input_len ~= #output then
        table.insert(failures, string.format('lost elems, #input=%d while #output=%d', #input, #output))
    end
    for i = 1, #input do
        if output[i] ~= expected[i] then
            table.insert(failures, string.format('@%d : %s -> %s != %s', i, input[i], output[i], expected[i]))
        end
    end
    assert(#failures == 0, test_str .. ': wrong transforms : ' .. vim.inspect(failures))
end

check_desambiguition('ambiguity @root and subfolder', {
    '/home/user/code/project/readme.md',
    '/home/user/code/project/readme.md',
    '/readme.md',
}, {
    'project/readme.md',
    'project/readme.md',
    '/readme.md',
})

check_desambiguition('random long stuff', {
    '/home/user/code/project/readme.md',
    '/home/user/code/project/readme.md',
    '/home/user/code/project/support/readme.md',
    '/home/user/code2/project/readme.md',
    '/home/user/.local/config',
    '/etc/service/config',
    '/home/user/code/proj/src/generated/tigris1v1/ext.py',
    '/home/user/code/proj/src/generated/tigris1v2/ext.py',
    '/home/user/code/proj/src/generated/tigris1v3/ext.py',
    '/home/user/code1/proj/src/my_ext.py',
    '/home/user/code2/proj/src/my_ext.py',
    '/home/user/code3/proj/src/my_ext.py',
    '/one_file.txt',
    '/and_another.txt',
    '/the/same/path.lua',
    '/the/same/path.lua',
    '/some/long/unique/path',
}, {
    'code/project/readme.md',
    'code/project/readme.md',
    'support/readme.md',
    'code2/project/readme.md',
    '.local/config',
    'service/config',
    'tigris1v1/ext.py',
    'tigris1v2/ext.py',
    'tigris1v3/ext.py',
    'code1/proj/src/my_ext.py',
    'code2/proj/src/my_ext.py',
    'code3/proj/src/my_ext.py',
    'one_file.txt',
    'and_another.txt',
    'path.lua',
    'path.lua',
    'path',
})

check_desambiguition('same file with dif ext works', {
    '/etc/stuff/foo',
    '/etc/stuff/bar',
    '/home/user/.local/bar',
    '/home/bar.txt',
}, {
    'foo',
    'stuff/bar',
    '.local/bar',
    'bar.txt',
})

check_desambiguition('same file many levels', {
    '/some/sub/sub/level/file.txt',
    '/some/sub/level/file.txt',
    '/some/file.txt',
}, {
    'sub/sub/level/file.txt',
    'some/sub/level/file.txt',
    'some/file.txt',
})

check_desambiguition('with empty files', {
    '',
    '/file.txt',
    '',
}, {
    config.get('no_name'),
    'file.txt',
    config.get('no_name'),
})

print('passed all checks')
