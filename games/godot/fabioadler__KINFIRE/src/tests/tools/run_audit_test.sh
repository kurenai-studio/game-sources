#!/bin/bash
# run_audit_test.sh - Executa o teste de auditoria completo do KINFIRE

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_PATH="${GODOT_PATH:-godot}"
TEST_SCENE="res://tests/test_full_playthrough_audit.gd"
OUTPUT_DIR="$PROJECT_DIR/user"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  KINFIRE - TESTE DE AUDITORIA COMPLETO                    ║"
echo "║  Full Playthrough + Bug Hunt                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verificar se Godot está disponível
if ! command -v "$GODOT_PATH" &> /dev/null; then
    echo "❌ Godot não encontrado em: $GODOT_PATH"
    echo "   Configure com: export GODOT_PATH=/caminho/para/godot"
    exit 1
fi

echo "ℹ️  Projeto: $PROJECT_DIR"
echo "ℹ️  Godot: $GODOT_PATH"
echo "ℹ️  Saída: $OUTPUT_DIR"
echo ""

# Criar diretório de saída
mkdir -p "$OUTPUT_DIR"

echo "🚀 Iniciando teste..."
echo ""

# Executar o teste (headless)
cd "$PROJECT_DIR"
"$GODOT_PATH" --headless --path . scenes/test_full_playthrough_audit.tscn 2>&1 | tee "$OUTPUT_DIR/audit_test.log"

RESULT=$?

echo ""
echo "════════════════════════════════════════════════════════════"

if [ $RESULT -eq 0 ]; then
    echo "✅ Teste finalizado"
else
    echo "⚠️  Teste finalizado com código: $RESULT"
fi

echo ""
echo "📄 Relatórios gerados:"
echo "   • Completo (JSON): $OUTPUT_DIR/audit_report.json"
echo "   • Legível (TXT): $OUTPUT_DIR/audit_report.txt"
echo "   • Log de teste: $OUTPUT_DIR/audit_test.log"
echo ""

# Mostrar resumo
if [ -f "$OUTPUT_DIR/audit_report.txt" ]; then
    echo "📊 RESUMO DO RELATÓRIO:"
    echo "════════════════════════════════════════════════════════════"
    tail -30 "$OUTPUT_DIR/audit_report.txt"
fi
