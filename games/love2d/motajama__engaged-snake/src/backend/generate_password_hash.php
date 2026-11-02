<?php

declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    echo "Run this script from the command line.\n";
    exit(1);
}

$password = $argv[1] ?? null;
if ($password === null || $password === '') {
    fwrite(STDERR, "Usage: php backend/generate_password_hash.php 'upload-password'\n");
    exit(1);
}

echo password_hash($password, PASSWORD_DEFAULT) . PHP_EOL;
