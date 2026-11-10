# AUDITORIA KINFIRE - Teste de Playthrough Completo

## Como Executar o Teste

### Opção 1: Script Bash (Linux/Mac)
```bash
chmod +x run_audit_test.sh
./run_audit_test.sh
```

### Opção 2: Comando Godot Direto
```bash
# Linux/Mac
godot --headless --path . scenes/test_full_playthrough_audit.tscn

# Windows (PowerShell)
& 'C:\Program Files\Godot\godot.exe' --headless --path . scenes/test_full_playthrough_audit.tscn
```

### Opção 3: Dentro da Engine Godot
1. Abrir projeto em Godot Editor
2. Navegar para `res://tests/test_full_playthrough_audit.gd`
3. Clicar em "Run"
4. Aguardar conclusão (normalmente 2-5 minutos)

## Saída do Teste

O teste gera 3 arquivos no diretório `user://`:

### 1. `audit_report.json`
Relatório estruturado em JSON com:
- Métricas completas
- Lista de erros e avisos
- Relatório de bugs encontrados
- Logs detalhados com timestamps
- Duração por fase

### 2. `audit_report.txt`
Versão legível em texto com:
- Resumo executivo
- Problemas encontrados
- Lista de bugs por severidade
- Status final

### 3. `audit_test.log`
Log bruto da execução com timestamps ANSI coloridos

## O que o Teste Valida

### FASE 1: Inicialização (2-5s)
- ✓ Singletons (Game, DB) inicializados
- ✓ Recursos carregados (raças, classes)
- ✓ EQUIP_SLOTS configurados (11 slots)
- ✓ Banco de dados de itens

### FASE 2: Tutorial/Prólogo (1-2s)
- ✓ Herói aldeão criado corretamente
- ✓ Inventário inicializado (10x6)
- ✓ Equipamento com 11 slots
- ✓ Consumíveis com 9 slots

### FASE 3: Criação de Personagem (1-2s)
- ✓ Criação com raça e classe aleatória
- ✓ Cálculo de vida (max_hp)
- ✓ Cálculo de armadura
- ✓ Cálculo de DPS
- ✓ Equipamento inicial

### FASE 4: Gameplay - 50 Níveis (10-30s)
- ✓ Progression de XP/Level
- ✓ Escalagem de stats
- ✓ Sistema de equipagem a cada 10 níveis
- ✓ Validação de stats a cada 5 níveis

### FASE 5: Testes de Sistemas (5-10s)
- ✓ **Inventário**: Adicionar/remover itens
- ✓ **Equipamento**: Testar todos os slots principais
- ✓ **Stats**: Validar cálculos de vida, armadura, DPS

## Bugs e Problemas Esperados

Baseado na auditoria preliminar de código, os seguintes problemas podem ser encontrados:

### 🔴 CRÍTICO

1. **Equipagem de Itens (InventoryPanel.gd, linha 300-310)**
   - Problema: Ao equipar item via clique direito na grade, há falha de validação
   - Sintoma: Mensagens de erro ao tentar equipar
   - Impacto: Sistema de equipagem quebrado
   - Solução: Validar `hero.can_use_category()` antes de equipar

2. **Referência Dictionary Null (inventory_panel.gd, linha 125)**
   - Problema: `hero.equipment.get(it.slot)` pode retornar None
   - Sintoma: Crash ao comparar com `it`
   - Impacto: Tooltip não funciona
   - Solução: Adicionar null check

### 🟠 ALTO

3. **Layout de Slots de Equipamento (inventory_panel.gd, linha 43-48)**
   - Problema: Slots "gloves", "ring", "amulet", "accessory_*" posicionados em pixel-art
   - Sintoma: Slots aparecem fora de posição na UI
   - Impacto: UX ruim, mas funcional

4. **Validação de Categoria de Arma (hero.gd, linha 560-565)**
   - Problema: `can_use_category()` assume que `cls.allowed_weapons` está populado
   - Sintoma: Classes podem não conseguir equipar nenhuma arma
   - Impacto: Gameplay impossível

### 🟡 MÉDIO

5. **Consumíveis não Testados (player.gd, consumable_slots)**
   - Problema: Sistema de consumíveis inicializado mas não testado no gameplay
   - Sintoma: Consumíveis podem falhar em combate
   - Impacto: Mechânica perdida

6. **Grid de Inventário Cheio (inventory_grid.gd, linha 52-58)**
   - Problema: Sem tratamento para inventário cheio
   - Sintoma: Itens dropados ao cair do boss poderão ser perdidos
   - Impacto: Frustração do jogador

## Interpretando os Resultados

### Se o teste PASSAR ✅
```
ERROS: 0
AVISOS: 0
CRÍTICOS: 0
BUGS ENCONTRADOS: 0
```
→ Sistema está estável para este playthrough básico

### Se o teste FALHAR ⚠️
```
ERROS: 5+
AVISOS: 10+
CRÍTICOS: 2+
BUGS ENCONTRADOS: 8+
```
→ Há problemas que precisam ser corrigidos

Verificar `audit_report.txt` para detalhes específicos.

## Próximos Passos

1. **Executar o teste** e coletar relatório
2. **Analisar bugs** encontrados por severidade
3. **Priorizar correções** (CRÍTICO → ALTO → MÉDIO)
4. **Implementar testes unitários** para cada bug
5. **Re-executar auditoria** após cada correção

## Métricas de Sucesso

| Métrica | Alvo | Atual |
|---------|------|-------|
| Níveis Completados | 50 | ? |
| Equipamento Tests | 100% | ? |
| Erros Críticos | 0 | ? |
| Tempo Total | < 5min | ? |
| Taxa de Pass | 100% | ? |

## Notas Técnicas

- **Teste headless**: Executa sem UI gráfica, apenas validação lógica
- **Monkey-patching**: Captura de push_error/push_warning via logging
- **Modo determinístico**: Usa seeds para reprodução consistente
- **Performance**: Testa até 50 níveis = ~50k XP processado

## Suporte

Para issues ao executar:

1. Verificar se Godot 4.7+ está instalado
2. Validar paths do projeto
3. Verificar permissões de arquivo em `user://`
4. Consultar `audit_test.log` para detalhes do erro
