# Task 9 Brief: Integration Test & Full Playthrough Verification

## Task Description
Run the complete full playthrough audit test to verify all fixes work together correctly. This is the final validation that all bugs are fixed.

## Test to Run
```bash
flatpak run org.godotengine.Godot --headless --path /media/f/HD/KINFIRE scenes/test_full_playthrough_audit.tscn
```

## Expected Results
All 6 phases should pass:
- FASE 1: Validação de Inicialização ✓
- FASE 2: Tutorial e Prólogo ✓
- FASE 3: Criação de Personagem ✓
- FASE 4: Gameplay Progressivo (50 níveis) ✓
- FASE 5: Testes de Sistemas ✓
- FASE 6: Análise Final ✓

Final report should show:
- 50/50 levels completed
- 9/9 equipment tests passed
- 0 errors, 0 critical issues, 0 bugs
- 5 expected warnings (class restrictions - Bruxo can't use Espada)
- Status: ✅ PASSOU

## Files to Check
- `user://audit_report.txt` - human readable report
- `user://audit_report.json` - structured report

## Global Constraints
- Godot 4.7.2 (Flatpak) headless execution for testing
- No breaking changes to save format or public APIs
- Preserve existing signal connections and cleanup patterns

## Report File
Write report to: `/media/f/HD/KINFIRE/.superpowers/sdd/2026-10-30-kinfire-bug-fixes/task-9-report.md`