--[[

A B C D .... L M N ...P Q R S T U V ....z
             ^        ^   ^   ^
             ¦        ¦   ¦   ¦
             300      ¦   ¦   ¦
                      ¦   ¦  450
                      375 ¦
                          383

Searching for "S" (at page 407)

0th step: >= 1   AND <= 600  (initialization)
    m= 300, letter = "L"
1st step: >= 300 AND <= 600
    m= 450, letter = "T"
2nd step: >= 300 AND <= 450
    m= 375, letter = "P"
3rd step: >= 375 AND <= 450
    m= 383, letter = "R"
4th step: >= 383 AND <= 450
              ^          ^
              ¦          ¦
 lower bound (lb)        ¦
             upper bound (ub)

m = (lb + ub) / 2

Check if the letter at m is larger or smaller than our target.

If it's larger:
* Update upper bound to M

If it's smaller:
* Update lower bound to M

If it's equal:
* return m
* end

When ub == lb:
* print("not available in this book")
* return -1
* end

]]


function binary_search(data, target)
    lb = 1
    ub = #(data)
    while lb < ub do
        print("lb = ", lb, "ub = ", ub)
        m = math.floor((lb + ub) / 2)
        middle = data[m]
        if middle > target then
            ub = m
        elseif middle < target then
            lb = m
        else -- implicitly: middle == target
            print("found it at ", m)
            return m
        end
    end
    -- Automatically lb == ub
    print("not available in this book")
    return -1
end

--     1  2  3    4  5    6   7   8  9
arr = { 1, 2, 6, 23, 7, 432, 21, 87, 3 }
texts = {
    "Hello",                                                   -- 1
    "Good bye",                                                --2
    "Don't disturb me",                                        --3
    "What do you want?",                                       --4
    "hello world",                                             --5
    "xxxx",                                                    --6
    "A nuke can really mess up your day",                      --7
    "what do you want",                                        --8
    "Get off my lawn!",                                        -- 9
    "why is your money here?",                                 -- 10
    "why did you leave the door open!",                        --11
    "why is your safe unlocked?",                              -- 12
    "dont litter on my private property!!",                    -- 13
    "get away from the chemical reactor or you will get hurt", -- 14
    "told you so",
    --15
}

function get_random_textornumber_v2()
    setup_random()

    -- NOT WORKING.
    local target = table.pack(table.unpack(arr), table.unpack(texts))
    i = math.random(#(target))
    print(target[i])
end

function get_random_textornumber()
    setup_random()

    local target
    local r = math.random()
    if r < 0.8 then
        -- Pick a numbers
        target = arr
    elseif r > 0.8 then
        target = texts
        --pick a text
    end
    i = math.random(#(target))
    print(target[i])
end

function linear_search()
    search_item = "A nuke can really mess up your day"

    local e = 0
    for i = 1, #(texts) do
        item = texts[i]
        -- print(item)
        if item == search_item then
            e = i
            break
        end
    end
    print(e)
end

function setup_random()
    seed = os.time()
    for i = 1, 1 + seed % 27 do
        math.random()
    end
end

function get_random_item()
    setup_random()

    i = math.random(#(target))
    print(target[i])
end

function multiple_runs()
    for i = 1, 59, 1 do
        get_random_textornumber()
    end
end

unsorted_stuff = {
    "box",   -- 1
    "apple", --2
    "zebra", --- i = 3
    "screen",
    "laptop",
    "animation", -- 6
    "history",
    "thirty",
    "geology"
}

function is_sorted(unsorted_stuff)
    for i = 2, #(unsorted_stuff) do
        current_word = unsorted_stuff[i]:lower()
        previous_word = unsorted_stuff[i - 1]:lower()
        if previous_word > current_word then
            return false
        end
    end
    return true
end

function sortit()
    while true do
        if is_sorted(unsorted_stuff) then
            break
        end
        d1 = math.random(#(unsorted_stuff))
        d2 = math.random(#(unsorted_stuff))
        -- compare d1 and d2 and exchange if needed, so d1 always is smaller.
        if d1 > d2 then
            ---- d1: 10, d2:3
            dtemp = d1
            ---- d1: 10, d2:3, dtemp:10
            d1 = d2
            ---- d1: 3, d2:3, dtemp:10
            d2 = dtemp
            ---- d1: 3, d2:10, dtemp:10
        end
        -- here: d1 always <= d2

        if d1 ~= d2 then
            w1 = unsorted_stuff[d1]
            w2 = unsorted_stuff[d2]
            if w1:lower() > w2:lower() then
                unsorted_stuff[d1] = w2
                unsorted_stuff[d2] = w1
            end
            -- print(table.concat(unsorted_stuff, ", "))
        end
    end
end

setup_random()
sortit()
item_index = binary_search(unsorted_stuff, "laptop")
print("result ", item_index)