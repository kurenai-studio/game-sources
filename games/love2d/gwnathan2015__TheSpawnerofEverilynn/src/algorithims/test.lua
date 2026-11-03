i = 20
c = string.char(i + 0)

print('numbers coming')
print(i * i, c)

if false then
    for i = 1, 20 do
        if i % 3 == 0 then
            c = string.char(i + 0)
            print(i + 50, c)
        end
    end
end

for i = 1, 255 do
    c = string.char(i + 0)
    print(i, c)
end


print('numbers ending')
print(i * i, c)

print(4 + 3, c)


-- start-process 'C:\Program Files (x86)\LOVE\love.exe' . -wait