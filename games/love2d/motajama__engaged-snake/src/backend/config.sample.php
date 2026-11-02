<?php

return [
    'db' => [
        'dsn' => 'mysql:host=127.0.0.1;dbname=engagedsnake;charset=utf8mb4',
        'user' => 'engagedsnake_user',
        'password' => 'replace-with-database-password',
    ],
    'table_prefix' => 'engagedsnake-',
    'upload_password_hash' => '$2y$10$replaceThisHashWithOutputFromGeneratePasswordHash',
    'score_limit' => 100,
];
