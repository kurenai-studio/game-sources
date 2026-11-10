# Plano de Execução: Correção de Erros de Inventário + Redesenho do Layout

**Data:** 2026-10-30
**Escopo:** Corrigir 3 erros críticos ao equipar itens + expandir layout do "paper doll" com slots adicionais

## Especificação de Referência

### Problema Atual
- `it.display_name()` não existe (Item tem `name`, não `display_name`)
- `panel.show_message()` não existe (deveria ser `panel.hud.show_message()`)
- Layout do inventário está incompleto (faltam slots de luvas e acessórios)

### Layout Desejado (Paper Doll)
```
Helm (capacete)          Amulet (amuleto)
Weapon (arma)  Chest (peitoral)  Offhand (mão sec.)
Ring (anel)    Boots (botas)
+ Gloves (luvas) - novo
+ Accessory slots - novos
```

## Global Constraints
- Todos os erros devem ser corrigidos
- Testes devem passar após cada tarefa
- Nenhuma regressão em funcionalidade existente
- Layout deve manter compatibilidade visual

---

# Tarefa 1: Corrigir `item.display_name()` → `item.name`

**Escopo:** Corrigir 3 ocorrências onde `Item` usa `.display_name()` indevidamente

**Arquivos afetados:**
- `scripts/ui/inventory_panel.gd` (linha 180)
- `scripts/ui/inventory_panel.gd` (linha 233)
- `scripts/ui/consumable_slot.gd` (linha 50)

**Steps:**
1. Ler arquivo `inventory_panel.gd` linhas 175-185
2. Substituir `it.display_name()` por `it.name` na linha 180
3. Ler arquivo `inventory_panel.gd` linhas 228-237
4. Substituir `it.display_name()` por `it.name` na linha 233
5. Ler arquivo `consumable_slot.gd` linhas 45-55
6. Substituir `item.display_name` por `item.name` na linha 50
7. Rodar testes: verificar parsing sem erros

**Expected:** Nenhum erro de método não encontrado ao equipar/vender itens

**Interfaces produzidas:**
- Métodos corrigidos em `inventory_panel.gd` e `consumable_slot.gd`

---

# Tarefa 2: Corrigir `panel.show_message()` → `panel.hud.show_message()`

**Escopo:** Corrigir 1 ocorrência na linha 233 de `inventory_panel.gd`

**Steps:**
1. Ler arquivo `inventory_panel.gd` linhas 228-237
2. Substituir `panel.show_message(...)` por `panel.hud.show_message(...)`
3. Rodar testes: verificar funcionalidade ao vender item com Shift+Click

**Expected:** Mensagem de venda aparece corretamente

**Interfaces consumidas:**
- `InventoryPanel.hud` existe e tem método `show_message()`

---

# Tarefa 3: Expandir Layout do Paper Doll com Slots Adicionais

**Escopo:** Adicionar slots de luvas (gloves) e expandir slots de acessórios no layout

**Novos slots:**
- `gloves`: Luvas (entre weapon e offhand)
- `accessory_1`, `accessory_2`, `accessory_3`: Acessórios adicionais (além do ring existente)

**Steps:**
1. Ler `scripts/autoload/db.gd` para entender DB.EQUIP_SLOTS e DB.SLOT_NAMES
2. Adicionar novos slots a DB.EQUIP_SLOTS e DB.SLOT_NAMES
3. Ler `scripts/core/hero.gd` linhas 73-76 (inicialização equipment)
4. Verificar se precisa adicionar inicialização para novos slots
5. Atualizar layout dictionary em `inventory_panel.gd` com posições para gloves e accessories
6. Rodar testes: verificar parsing e rendering

**Expected:** 
- DB.EQUIP_SLOTS contém todos os slots
- Layout renderiza corretamente
- Nenhum erro ao equipar em novos slots

**Interfaces produzidas:**
- Novos slots em DB.EQUIP_SLOTS
- Layout atualizado em inventory_panel.gd

---

# Tarefa 4: Teste de Integração - Equipagem de Itens

**Escopo:** Verificar que equipagem funciona sem erros

**Steps:**
1. Criar teste simples em GDScript que:
   - Cria um hero
   - Tenta equipar um item em cada slot (inclusive novos)
   - Verifica que não há erros
2. Rodar teste
3. Verificar que todas as mensagens aparecem corretamente

**Expected:** Equipagem funciona sem erros em todos os slots

**Interfaces consumidas:**
- Todos os slots funcionam
- Mensagens aparecem
- Sem crashes

---

# Commits Previstos

1. `fix: correct item.display_name() to item.name in 3 files`
2. `fix: correct panel.show_message() to panel.hud.show_message()`
3. `feat: add gloves and accessory slots to equipment system`
4. `test: verify equipment system integration`

