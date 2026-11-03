texts2 = {
    "well, there cant be anymore splits of profit, so you will just be earning wage",
    "stop nuking ukraine!",
    "where is russias 2nd civil war?"
}

i = ("hello")
print(i)

--[[
16 / 3 = 5 R 1
17 / 7 = 14 r 3

.... / 3
0 = 0 r 0
1 = 0 R 1
2 = 0 R 2
3 = 1 R 0
4 = 1 R 1
5 = 1 R 2
6 = 2 R 0

.... / 21
R 0
R 1 
R 3
R 10
.....
R 20
R 0

-------------------------------------------------------
1      1,66
2      678
3      456745
4
5
6      123,45,34534
7      1232134,8678
8      333,8
9      87
10     57896758,231,23
11
12
-----------------------------------------------------

Is 231 in `data`?

231 / 13 = 17 R 10

30 / 13 = 2 R 4
ss
]]


data = {1, 63, 333, 9, 123, 57896753, 231, 456745, 1232135, 49, 87, 231, 673, 23, 8671, 34535, 566456799}

numamount = #(data)
divider = 27

hashtable = {}

for i = 1, numamount do
    bucket_number = data[i] % divider
    if hashtable[bucket_number] == nil then 
        hashtable[bucket_number] = data[i]
    else
        bucket_number = bucket_number + 1
        if hashtable[bucket_number] == nil then 
            hashtable[bucket_number] = data[i]
        else   
            print('Can\'t insert ', data[i])
        end
    end
end

for i = 0, divider-1 do
    print('bucket', i, hashtable[i])
end

-- 9 is part of data but collision in hash bucket 9
target = 123
search_bucket_number = target % divider
if hashtable[search_bucket_number] == target then
    print('Found it in bucket ', search_bucket_number)
elseif hashtable[search_bucket_number+1] == target then
    print('Found it in bucket ', search_bucket_number+1)
else
    print('nah... out of luck')
end






-- dividing to lower the numbers you have to check to find it, and, then using another algorithim to find withc one of those numbes left id our target
