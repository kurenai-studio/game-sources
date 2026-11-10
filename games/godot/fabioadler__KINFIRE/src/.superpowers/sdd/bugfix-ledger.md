# SDD ledger — plan: KINFIRE 7 medium bugs fix

## Tarefas

### Task 1: CONSUMABLES — Adicionar `Item.use()` (CRÍTICO: crash ao usar consumível)
- Status: complete — Adicionado `func use(user: Player = null) -> bool` em item.gd

### Task 2: CONSUMABLES — Decrementar contagem do item após uso (MÉDIO)
- Status: complete — Adicionada remoção de 1 item do inventário após use() bem-sucedido

### Task 3: SKILLS — Adicionar `Player._use_skill()` (CRÍTICO: crash ao clicar slot de skill no HUD)
- Status: complete — Adicionado `func _use_skill(slot: int)` em player.gd que chama `_request_cast`

### Task 4: SKILLS — Árvore: nós dependentes não atualizados após compra (MÉDIO)
- Status: complete — Substituído `_update_node_ui(node.id)` por `refresh()` em skill_tree_panel.gd

### Task 5: DIALOGUE — `_select_choice` fecha mesmo quando next_id está definido (MÉDIO)
- Status: complete — Reescrito `_show_page`/`_advance_or_close`/`_select_choice` para usar `_current_node` e avançar para próximo nó via next_id

### Task 6: STRINGS — `%d` usado para valores float (armor, max_hp) (MÉDIO)
- Status: complete — Alterado `%d` para `%.1f` em valores float em inventory_panel.gd e character_panel.gd

### Task 7: INVENTORY — `_sell_junk` usa `erase()` direto em vez de `remove()` (MÉDIO)
- Status: complete — Alterado `hero.inventory.items.erase(it)` para `hero.inventory.remove(it)` em inventory_panel.gd

### Task 8: CONDITIONS — `stage_of()` crash se `q.stages` vazio (MÉDIO)
- Status: complete — Adicionado check `is_empty()` em `stage_of()` e `progress_of()` em quest_log.gd

### Task 9: Atualizar test_audit_simulator.py — marcar bugs como corrigidos
- Status: complete — Todos os 8 bugs médios listados como CORRIGIDO com detalhes

### Task 10: Executar simulação completa e verificar regressões
- Status: complete — 0 erros, 0 avisos, 0 críticos, 50/50 níveis, 9/9 equipamentos