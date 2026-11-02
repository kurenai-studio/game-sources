<?php

declare(strict_types=1);

require __DIR__ . '/lib.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        http_response_code(405);
        echo json_encode(['ok' => false, 'error' => 'method_not_allowed']);
        exit;
    }

    $config = engagedsnake_config();
    $pdo = engagedsnake_pdo($config);
    $table = engagedsnake_table($config, 'scores');
    $limit = engagedsnake_int_range($_GET['limit'] ?? ($config['score_limit'] ?? 100), 1, 500);
    $stmt = $pdo->query(
        "SELECT player_name, score, level_ended, victory, created_at
         FROM {$table}
         ORDER BY score DESC, created_at ASC
         LIMIT {$limit}"
    );

    $scores = array_map(
        static function (array $score): array {
            return [
                'player_name' => (string) $score['player_name'],
                'score' => (int) $score['score'],
                'level_ended' => (int) $score['level_ended'],
                'victory' => ((int) $score['victory']) === 1,
                'created_at' => (string) $score['created_at'],
            ];
        },
        $stmt->fetchAll()
    );

    echo json_encode(['ok' => true, 'scores' => $scores]);
} catch (Throwable $error) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'server_error']);
}
