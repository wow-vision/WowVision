local utils = {}

function utils.splitString(str, delim)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delim, from, true)
    while delim_from do
        tinsert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim, from, true)
    end
    tinsert(result, string.sub(str, from))
    return result
end

WowVision.utils = utils
