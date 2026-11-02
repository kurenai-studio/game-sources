<?php

declare(strict_types=1);

require __DIR__ . '/lib.php';

$scores = [];
$loadError = null;

try {
    $config = engagedsnake_config();
    $pdo = engagedsnake_pdo($config);
    $table = engagedsnake_table($config, 'scores');
    $limit = engagedsnake_int_range($config['score_limit'] ?? 100, 1, 500);
    $stmt = $pdo->query(
        "SELECT player_name, score, level_ended, victory, created_at
         FROM {$table}
         ORDER BY score DESC, created_at ASC
         LIMIT {$limit}"
    );
    $scores = $stmt->fetchAll();
} catch (Throwable $error) {
    $loadError = 'Scores are not available.';
}

function e(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Divadelni utopie Scores</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <main class="scoreboard">
        <header class="scoreboard__header">
            <h1>Divadelni utopie Scores</h1>
        </header>

        <?php if ($loadError !== null): ?>
            <p class="notice"><?= e($loadError) ?></p>
        <?php elseif ($scores === []): ?>
            <p class="notice">No scores yet.</p>
        <?php else: ?>
            <table class="scores">
                <thead>
                    <tr>
                        <th class="scores__rank" scope="col">#</th>
                        <th class="scores__player" scope="col">Player</th>
                        <th class="scores__score" scope="col">Score</th>
                        <th class="scores__level" scope="col">Level</th>
                        <th class="scores__victory" scope="col">Win</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($scores as $index => $score): ?>
                        <tr>
                            <td class="scores__rank"><?= $index + 1 ?></td>
                            <td class="scores__player"><?= e((string) $score['player_name']) ?></td>
                            <td class="scores__score"><?= number_format((int) $score['score']) ?></td>
                            <td class="scores__level"><?= (int) $score['level_ended'] ?></td>
                            <td class="scores__victory victory"><?= ((int) $score['victory']) === 1 ? '*' : '' ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        <?php endif; ?>
    </main>
</body>
</html>
