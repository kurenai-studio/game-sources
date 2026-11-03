local utils = {}

function utils.sign(value)
    if value > 0 then return 1 end
    if value < 0 then return -1 end
    return 0
end

function utils.setup_random()
    seed = os.time()
    for i = 1, 1 + seed % 27 do
        math.random()
    end
end

function utils.print_table(tab)
    print('{')
    for key, value in pairs(tab) do
        print(string.format('  %s="%s"', key, tostring(value)))
    end
    print('}')
end

return utils