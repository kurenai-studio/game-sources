<?php

declare(strict_types=1);

require __DIR__ . '/lib.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        http_response_code(405);
        echo json_encode(['ok' => false, 'error' => 'method_not_allowed']);
        exit;
    }

    $config = engagedsnake_config();
    $password = (string) ($_POST['password'] ?? '');
    $expectedHash = (string) ($config['upload_password_hash'] ?? '');
    if ($expectedHash === '' || !password_verify($password, $expectedHash)) {
        http_response_code(403);
        echo json_encode(['ok' => false, 'error' => 'invalid_password']);
        exit;
    }

    $playerName = engagedsnake_clean_player_name((string) ($_POST['player_name'] ?? ''));
    $score = engagedsnake_int_range($_POST['score'] ?? 0, 0, 2147483647);
    $levelEnded = engagedsnake_int_range($_POST['level_ended'] ?? 1, 1, 9999);
    $victory = engagedsnake_int_range($_POST['victory'] ?? 0, 0, 1);

    $pdo = engagedsnake_pdo($config);
    $table = engagedsnake_table($config, 'scores');
    $stmt = $pdo->prepare(
        "INSERT INTO {$table} (player_name, score, level_ended, victory, ip_address, user_agent)
         VALUES (:player_name, :score, :level_ended, :victory, :ip_address, :user_agent)"
    );
    $stmt->execute([
        ':player_name' => $playerName,
        ':score' => $score,
        ':level_ended' => $levelEnded,
        ':victory' => $victory,
        ':ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
        ':user_agent' => substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255),
    ]);

    echo json_encode(['ok' => true]);
} catch (Throwable $error) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'server_error']);
}
