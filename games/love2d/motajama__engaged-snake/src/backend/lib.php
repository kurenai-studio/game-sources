<?php

declare(strict_types=1);

function engagedsnake_config(): array
{
    $configFile = __DIR__ . '/config.php';
    if (!is_file($configFile)) {
        http_response_code(500);
        throw new RuntimeException('Missing backend/config.php. Copy config.sample.php and edit it.');
    }

    $config = require $configFile;
    if (!is_array($config)) {
        throw new RuntimeException('Invalid config.php.');
    }
    return $config;
}

function engagedsnake_pdo(array $config): PDO
{
    $pdo = new PDO(
        $config['db']['dsn'],
        $config['db']['user'],
        $config['db']['password'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
    return $pdo;
}

function engagedsnake_table(array $config, string $suffix): string
{
    $name = ($config['table_prefix'] ?? 'engagedsnake-') . $suffix;
    if (!preg_match('/^[A-Za-z0-9_-]+$/', $name)) {
        throw new RuntimeException('Invalid table name.');
    }
    return '`' . str_replace('`', '``', $name) . '`';
}

function engagedsnake_clean_player_name(string $name): string
{
    $name = trim(preg_replace('/[^\pL\pN _-]+/u', '', $name) ?? '');
    $name = preg_replace('/\s+/', ' ', $name) ?? '';
    if ($name === '') {
        return 'PLY';
    }
    if (function_exists('mb_substr')) {
        return mb_substr($name, 0, 32, 'UTF-8');
    }
    return substr($name, 0, 32);
}

function engagedsnake_int_range(mixed $value, int $min, int $max): int
{
    $int = filter_var($value, FILTER_VALIDATE_INT);
    if ($int === false) {
        return $min;
    }
    return max($min, min($max, (int) $int));
}
