<?php
// GET/PUT/DELETE /items/{id} – ID passed as ?id=5

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
        // ── GET /items/{id} ─────────────────────────────────────────────
        $stmt = $pdo->prepare(
            'SELECT i.*, s.name AS location_name
               FROM items i
               JOIN locations s ON i.location_id = s.id
              WHERE i.id = :id'
        );
        $stmt->execute([':id' => $id]);
        $item = $stmt->fetch();

        if (!$item) {
            sendError('Item not found.', 404);
        }
        sendJson($item);

    } elseif ($method === 'PUT') {
        // ── PUT /items/{id} ──────────────────────────────────────────────
        $body = getRequestBody();

        $required = ['name', 'description', 'category', 'quantity', 'location_id'];
        foreach ($required as $field) {
            if (empty($body[$field]) && $body[$field] !== 0) {
                sendError("Required field missing: $field", 400);
            }
        }

        // Check if item exists
        $check = $pdo->prepare('SELECT id FROM items WHERE id = :id');
        $check->execute([':id' => $id]);
        if (!$check->fetch()) {
            sendError('Item not found.', 404);
        }

        $stmt = $pdo->prepare(
            'UPDATE items
                SET name        = :name,
                    description = :description,
                    category    = :category,
                    barcode     = :barcode,
                    quantity    = :quantity,
                    location_id = :location_id,
                    expiry_date = :expiry_date
              WHERE id = :id'
        );
        $stmt->execute([
            ':name'        => trim($body['name']),
            ':description' => trim($body['description']),
            ':category'    => trim($body['category']),
            ':barcode'     => isset($body['barcode']) ? trim($body['barcode']) : null,
            ':quantity'    => (int) $body['quantity'],
            ':location_id' => (int) $body['location_id'],
            ':expiry_date' => isset($body['expiry_date']) && $body['expiry_date'] !== '' ? $body['expiry_date'] : null,
            ':id'          => $id,
        ]);

        // Return the updated item
        $stmt = $pdo->prepare(
            'SELECT i.*, s.name AS location_name
               FROM items i
               JOIN locations s ON i.location_id = s.id
              WHERE i.id = :id'
        );
        $stmt->execute([':id' => $id]);
        sendJson($stmt->fetch());

    } elseif ($method === 'DELETE') {
        // ── DELETE /items/{id} ───────────────────────────────────────────
        $check = $pdo->prepare('SELECT id FROM items WHERE id = :id');
        $check->execute([':id' => $id]);
        if (!$check->fetch()) {
            sendError('Item not found.', 404);
        }

        $stmt = $pdo->prepare('DELETE FROM items WHERE id = :id');
        $stmt->execute([':id' => $id]);
        sendJson(['message' => 'Item deleted successfully.']);

    } else {
        sendError('Method not allowed.', 405);
    }

} catch (RuntimeException $e) {
    sendError($e->getMessage(), $e->getCode() ?: 500);
} catch (PDOException $e) {
    sendError('A database error occurred.', 500);
}
