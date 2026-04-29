<?php
// GET /locations → list all locations, POST /locations → create new

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../helpers/response.php';

setCorsHeaders();
validateApiKey(); // Validate API key

$method = $_SERVER['REQUEST_METHOD'];

try {
    $pdo = getDbConnection();

    if ($method === 'GET') {
        // ── GET /locations ───────────────────────────────────────────────
        $stmt = $pdo->prepare('SELECT * FROM locations ORDER BY name ASC');
        $stmt->execute();
        sendJson($stmt->fetchAll());

    } elseif ($method === 'POST') {
        // ── POST /locations ──────────────────────────────────────────────
        $body = getRequestBody();

        if (empty($body['name'])) {
            sendError('Required field missing: name', 400);
        }

        $stmt = $pdo->prepare(
            'INSERT INTO locations (name, description)
             VALUES (:name, :description)'
        );
        $stmt->execute([
            ':name'        => trim($body['name']),
            ':description' => isset($body['description']) ? trim($body['description']) : null,
        ]);

        $newId = (int) $pdo->lastInsertId();

        $stmt = $pdo->prepare('SELECT * FROM locations WHERE id = :id');
        $stmt->execute([':id' => $newId]);
        sendJson($stmt->fetch(), 201);

    } else {
        sendError('Method not allowed.', 405);
    }

} catch (RuntimeException $e) {
    sendError($e->getMessage(), $e->getCode() ?: 500);
} catch (PDOException $e) {
    sendError('A database error occurred.', 500);
}
