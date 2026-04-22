<?php
// GET /items → list all items, POST /items → create new

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../helpers/response.php';

setCorsHeaders();
validateApiKey(); // Validate API key

$method = $_SERVER['REQUEST_METHOD'];

try {
    $pdo = getDbConnection();

    if ($method === 'GET') {
        // ── GET /items ──────────────────────────────────────────────────
        // JOIN with locations to include location name in response
        $stmt = $pdo->prepare(
            'SELECT i.*, s.name AS location_name
               FROM items i
               JOIN locations s ON i.location_id = s.id
              ORDER BY i.name ASC'
        );
        $stmt->execute();
        $items = $stmt->fetchAll();
        sendJson($items);

    } elseif ($method === 'POST') {
        // ── POST /items ─────────────────────────────────────────────────
        $body = getRequestBody();

        // Validate required fields
        $required = ['name', 'description', 'category', 'quantity', 'location_id'];
        foreach ($required as $field) {
            if (empty($body[$field]) && $body[$field] !== 0) {
                sendError("Required field missing: $field", 400);
            }
        }

        $stmt = $pdo->prepare(
            'INSERT INTO items (name, description, category, barcode, quantity, location_id, expiry_date)
             VALUES (:name, :description, :category, :barcode, :quantity, :location_id, :expiry_date)'
        );
        $stmt->execute([
            ':name'        => trim($body['name']),
            ':description' => trim($body['description']),
            ':category'    => trim($body['category']),
            ':barcode'     => isset($body['barcode']) ? trim($body['barcode']) : null,
            ':quantity'    => (int) $body['quantity'],
            ':location_id' => (int) $body['location_id'],
            ':expiry_date' => isset($body['expiry_date']) && $body['expiry_date'] !== '' ? $body['expiry_date'] : null,
        ]);

        $newId = (int) $pdo->lastInsertId();

        // Return the newly created item
        $stmt = $pdo->prepare(
            'SELECT i.*, s.name AS location_name
               FROM items i
               JOIN locations s ON i.location_id = s.id
              WHERE i.id = :id'
        );
        $stmt->execute([':id' => $newId]);
        $item = $stmt->fetch();
        sendJson($item, 201);

    } else {
        sendError('Method not allowed.', 405);
    }

} catch (RuntimeException $e) {
    sendError($e->getMessage(), $e->getCode() ?: 500);
} catch (PDOException $e) {
    // Do not expose internal PDO errors (NFA-08)
    sendError('A database error occurred.', 500);
}
