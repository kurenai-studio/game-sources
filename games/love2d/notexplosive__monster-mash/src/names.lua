firstNames = {
  'Steve',
  'Mike',
  'Ryder',
  'Alex',
  'Cody',
  'Kaylee',
  'Mary',
  'Lee',
  'Anabelle',
  'Michael',
  'David',
  'Aran'
}

lastNames = {
  'Dirtworker',
  'Miner',
  'Smith',
  'Jackson',
  'Bush',
  'Coder',
  'Claus',
  'Johnson',
  "Horseman"
}

function generateName()
  return getRandFromArray(firstNames) .. ' ' .. getRandFromArray(lastNames)
end

function getRandFromArray(arr)
  return arr[math.floor(love.math.random()*#arr)+1]
end
