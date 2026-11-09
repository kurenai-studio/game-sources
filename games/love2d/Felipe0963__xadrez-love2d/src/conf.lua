function love.conf(t)
    t.identity = "xadrez-love2d"
    t.window.title = "Xadrez"
    t.window.width = 1000
    t.window.height = 700
    t.window.msaa = 4
    -- modo de testes: sem janela
    for _, a in ipairs(arg or {}) do
        if a == "--testes" then t.window = false end
    end
end
