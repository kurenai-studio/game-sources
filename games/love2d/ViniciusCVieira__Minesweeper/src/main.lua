--[[
tipo: 0 = numero; 1 = bomba

crio um atributo reveladoAgora que fica true so no frame onde ele é revelado. Aplica iteracao dupla para quadrado e vizinhos e se for 0 e o do lado revelado agr revela tambem

se só tem bombas do lado nao pode ser outra bomba

minimizar os casos de chute
]]--
math.randomseed(os.time())
tamanhoDoTabuleiro = 16 -- 9 16 22
numeroDeBombas = 40 -- 10 40 99
bandeirinhasColocadas = 0
apertando1 = false
wasDown1 = false
apertando2 = false
wasDown2 = false
comecou = false
acabou = false
gameOver = false
tempoPassado = 0
revelados = 0
function updateZero(zero, n, w, h)
  if (zero.j ~= n-1) then
    zero.j = zero.j + 1
    zero.x = zero.x + w
  elseif (zero.j == n-1) then
    zero.j = 0
    zero.x = zero.x - (n-1)*w
    zero.i = zero.i + 1
    zero.y = zero.y+ h
  end
  zero.centrox = zero.x + w/2
  zero.centroy = zero.y + h/2
  return zero
end
function geraMatrizN(n, marginUpDown, marginSides)
  marginSides = marginSides or 0
  marginUpDown = marginUpDown or 0
  local quadrado = true
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  w = w - marginSides*2
  h = h - marginUpDown*2
  w = w/n
  h = h/n
  local zero = {x = marginSides, y = marginUpDown, i = 0, j = 0, centrox = marginSides+(w/2), centroy = marginUpDown+(h/2)}
  if quadrado then
    if w > h then
      w = h
      zero.x = (love.graphics.getWidth() - (n*w)) / 2
    elseif h > w then
      w = h
      zero.x = (love.graphics.getWidth() - (n*w)) / 2
    end
    zero.centrox = zero.x + (w/2)
  end
  local controle = 0
  local tiles = {}
  local linha = {}
  local ultimaLinha = 0
  while controle < n*n do
    local _ = {x = zero.x, y = zero.y, width = w, height = h, i=zero.i, j=zero.j, centrox = zero.centrox, centroy = zero.centroy, tipo = 0, num=0, revelado = false, reveladoAgora = false, bandeirinha = false}
    linha[_.j] = _
    zero = updateZero(zero, n, w, h)
    controle = controle + 1
    if zero.i ~= ultimaLinha then
      ultimaLinha = ultimaLinha + 1
      tiles[_.i] = linha
      linha = {}
    end
  end
  return tiles
end
function alocaBombas(n, coordenadas)
  -- coordenadas: {{i0, j0}, {i1, j1} ... {in, jn}}
  n = n-1
  local bombas=0
  for a, obj in pairs(coordenadas) do
    tab[obj.i][obj.j].tipo = 1
  end
  for i1=0, n, 1 do
    for j1=0, n, 1 do
      bombas = 0
      for i2=0, n, 1 do
        for j2=0, n, 1 do
          if (i1 ~= i2 or j1 ~= j2) then
            if ((math.abs(i1-i2) <= 1 and math.abs(j1-j2) <= 1) and tab[i2][j2].tipo == 1) then
              bombas = bombas + 1
            end
          end
        end
        tab[i1][j1].num = bombas
      end
    end
  end
end


function dentro(matriz, i, j)
  for a, obj in pairs(matriz) do
    if obj.i == i and obj.j == j then
      return true
    end
  end
  return false
end
function geraBombas(iInicio, jInicio)
  local bombas = {}
  local coordenadas, i, j
  local alocadas=0
  while alocadas ~= 1 do
    coordenadas = {}
    i = math.random(0, tamanhoDoTabuleiro-1)
    j = math.random(0, tamanhoDoTabuleiro-1)
    if (math.abs(jInicio-j) + math.abs(iInicio-i)) >= 1 then
      coordenadas.i = i
      coordenadas.j = j
      table.insert(bombas, coordenadas)
      alocadas = alocadas + 1
    end
  end
  while alocadas ~= numeroDeBombas do
    coordenadas = {}
    i = math.random(0, tamanhoDoTabuleiro-1)
    j = math.random(0, tamanhoDoTabuleiro-1)
    if (not dentro(bombas, i, j)) and math.abs(jInicio-j)>1 and math.abs(iInicio-i)>1 then
      coordenadas.i = i
      coordenadas.j = j
      table.insert(bombas, coordenadas)
      alocadas = alocadas + 1
    end
  end
  return bombas
end
function revelaZeros()
  for a=0, tamanhoDoTabuleiro-1, 1 do
    for b=0, tamanhoDoTabuleiro-1, 1 do
      if tab[a][b].reveladoAgora and tab[a][b].num == 0 and tab[a][b].tipo == 0 then
        for c=0, tamanhoDoTabuleiro-1, 1 do
          for d=0, tamanhoDoTabuleiro-1, 1 do
            if math.abs(a-c) <= 1 and math.abs(b-d) <= 1 and (not tab[c][d].revelado) then
              if tab[c][d].tipo == 0 then
                revelados = revelados + 1
                tab[c][d].revelado = true
                tab[c][d].reveladoAgora = true
              end
            end
          end
        end
      end
      tab[a][b].reveladoAgora = false
    end
  end
end
function love.load()
  tab = geraMatrizN(tamanhoDoTabuleiro, 20, 20)
end

function coletaInput1()
  if love.mouse.isDown(1) then
    if not wasDown1 then
      apertando1 = true
      wasDown1 = true
    else
      apertando1 = false
    end
  else
    apertando1 = false
    wasDown1 = false
  end
  local X, Y = love.mouse.getPosition()
  return X, Y
end

function coletaInput2()
  if love.mouse.isDown(2) then
    if not wasDown2 then
      apertando2 = true
      wasDown2 = true
    else
      apertando2 = false
    end
  else
    apertando2 = false
    wasDown2 = false
  end
  local X, Y = love.mouse.getPosition()
  return X, Y
end
function encontraCasa(X, Y)
  for a, obj1 in pairs(tab) do
    for b, obj in pairs(obj1) do
      if (X >= obj.x) and (X <= obj.x+obj.width) and (Y >= obj.y) and (Y <= obj.y + obj.height) then
        return obj.i, obj.j
      end
    end
  end
  return -1, -1
end
function love.update(dt)
  revelaZeros()
  local bombas
  local X, Y = coletaInput1()
  local x, y = coletaInput2()
  local i, j
  if not acabou then
    if comecou then
      tempoPassado = tempoPassado + dt
    end
    if apertando1 then
      i, j = encontraCasa(X, Y)
      if i~=-1 and j~=-1 and (not tab[i][j].bandeirinha) and (not tab[i][j].revelado) then
        tab[i][j].revelado = true
        tab[i][j].reveladoAgora = true
        tab[i][j].bandeirinha = false
        if tab[i][j].tipo == 1 then
          acabou = true
          gameOver = true
        else
          revelados = revelados + 1
        end
      end
      if not comecou then
        bombas = geraBombas(i, j)
        alocaBombas(tamanhoDoTabuleiro, bombas)
        comecou = true
      end
    end
    if apertando2 and comecou then
      i, j = encontraCasa(x, y)
      if i~=-1 and j~=-1 then
        if not tab[i][j].revelado then
          if tab[i][j].bandeirinha then
            tab[i][j].bandeirinha = false
            bandeirinhasColocadas = bandeirinhasColocadas - 1
          else
            tab[i][j].bandeirinha = true
            bandeirinhasColocadas = bandeirinhasColocadas + 1
          end
        end
      end
    end
  end
  if revelados == ((tamanhoDoTabuleiro * tamanhoDoTabuleiro) - numeroDeBombas) then
    acabou = true
  end
  if love.keyboard.isDown('m') then
    for a, obj in pairs(tab) do
      for b, c in pairs(obj) do
        c.revelado = true
      end
    end
  end
end

function love.draw()
  for i, obj in pairs(tab) do
    for i, obj2 in pairs(obj) do
      if obj2.bandeirinha then
        love.graphics.setColor(255, 0, 0)
      else
        love.graphics.setColor(255, 255, 255)
      end
      love.graphics.rectangle("fill", obj2.x, obj2.y, obj2.width, obj2.height)
      love.graphics.setColor(0, 0, 255)
      love.graphics.rectangle("line", obj2.x, obj2.y, obj2.width, obj2.height)
      love.graphics.setColor(0, 0, 0)
      if obj2.revelado then
        if (obj2.tipo == 1) then
          love.graphics.print("*", obj2.centrox, obj2.centroy)
        else
          love.graphics.print(obj2.num, obj2.centrox, obj2.centroy)
        end
      end
      if obj2.bandeirinha then
        love.graphics.print("|>", obj2.centrox, obj2.centroy)
      end
      if gameOver then
        love.graphics.print("GAME OVER", love.graphics.getWidth()/2, love.graphics.getHeight()/2)
      end
      if acabou and not gameOver then
        love.graphics.print("VITORIA!!!", love.graphics.getWidth()/2, love.graphics.getHeight()/2)
      end
    end
  end
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("|>" .. tostring(numeroDeBombas - bandeirinhasColocadas), 20, 100)
  love.graphics.print(string.format("%.1f", tempoPassado), 20, 150)
end