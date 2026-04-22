<?php
// GET/PUT/DELETE /locations/{id} – ID passed as ?id=2

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../helpers/response.php';

setCorsHeaders();
validateApiKey(); // Validate API key

$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int) $_GET['id'] : 0;

if ($id <= 0) {
    sendError('Invalid ID.', 400);
}

try {
    $pdo = getDbConnection();

    if ($method === 'GET') {
        // ── GET /locations/{id} ──────────────────────────────────────────
        $stmt = $pdo->prepare('SELECT * FROM locations WHERE id = :id');
        $stmt->execute([':id' => $id]);
        $location = $stmt->fetch();

        if (!$location) {
            sendError('Location not found.', 404);
        }
        sendJson($location);

    } elseif ($method === 'PUT') {
        // ── PUT /locations/{id} ──────────────────────────────────────────
        $body = getRequestBody();

        if (empty($body['name'])) {
            sendError('Required field missing: name', 400);
        }

        $check = $pdo->prepare('SELECT id FROM locations WHERE id = :id');
        $check->execute([':id' => $id]);
        if (!$check->fetch()) {
            sendError('Location not found.', 404);
        }

        $stmt = $pdo->prepare(
            'UPDATE locations
                SET name        = :name,
                    description = :description
              WHERE id = :id'
        );
        $stmt->execute([
            ':name'        => trim($body['name']),
            ':description' => isset($body['description']) ? trim($body['description']) : null,
            ':id'          => $id,
        ]);

        $stmt = $pdo->prepare('SELECT * FROM locations WHERE id = :id');
        $stmt->execute([':id' => $id]);
        sendJson($stmt->fetch());

    } elseif ($method === 'DELETE') {
        // ── DELETE /locations/{id} ───────────────────────────────────────
        // Check if items are still assigned to this location (FK RESTRICT)
        $checkItems = $pdo->prepare(
            'SELECT COUNT(*) as cnt FROM items WHERE location_id = :id'
        );
        $checkItems->execute([':id' => $id]);
        $row = $checkItems->fetch();
        if ((int) $row['cnt'] > 0) {
            sendError(
                'Location cannot be deleted – items are still assigned to it.',
                409
            );
        }

        $check = $pdo->prepare('SELECT id FROM locations WHERE id = :id');
        $check->execute([':id' => $id]);
        if (!$check->fetch()) {
            sendError('Location not found.', 404);
        }

        $stmt = $pdo->prepare('DELETE FROM locations WHERE id = :id');
        $stmt->execute([':id' => $id]);
        sendJson(['message' => 'Location deleted successfully.']);

    } else {
        sendError('Method not allowed.', 405);
    }

} catch (RuntimeException $e) {
    sendError($e->getMessage(), $e->getCode() ?: 500);
} catch (PDOException $e) {
    sendError('A database error occurred.', 500);
}
