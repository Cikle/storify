<?php
// GET /items → list all items, POST /items → create new

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../helpers/response.php';

setCorsHeaders();
validateApiKey();

$method = $_SERVER['REQUEST_METHOD'];

try {
    $pdo = getDbConnection();

    if ($method === 'GET') {
        // ── GET /items ──────────────────────────────────────────────────
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

        // Only name, quantity, location_id are required; description and category are optional
        $required = ['name', 'quantity', 'location_id'];
        foreach ($required as $field) {
            if (empty($body[$field]) && $body[$field] !== 0) {
                sendError("Required field missing: $field", 400);
            }
        }

        $stmt = $pdo->prepare(
            'INSERT INTO items
               (name, description, category, barcode, quantity, location_id,
                expiry_date, unit, critical_threshold, warning_days, pack_size)
             VALUES
               (:name, :description, :category, :barcode, :quantity, :location_id,
                :expiry_date, :unit, :critical_threshold, :warning_days, :pack_size)'
        );
        $stmt->execute([
            ':name'               => trim($body['name']),
            ':description'        => isset($body['description']) && $body['description'] !== '' ? trim($body['description']) : null,
            ':category'           => isset($body['category'])    && $body['category']    !== '' ? trim($body['category'])    : null,
            ':barcode'            => isset($body['barcode'])     && $body['barcode']     !== '' ? trim($body['barcode'])     : null,
            ':quantity'           => (int) $body['quantity'],
            ':location_id'        => (int) $body['location_id'],
            ':expiry_date'        => isset($body['expiry_date']) && $body['expiry_date'] !== '' ? $body['expiry_date']       : null,
            ':unit'               => isset($body['unit'])               && $body['unit']               !== '' ? trim($body['unit'])               : null,
            ':critical_threshold' => isset($body['critical_threshold']) && $body['critical_threshold'] !== '' ? (int) $body['critical_threshold'] : null,
            ':warning_days'       => isset($body['warning_days'])       && $body['warning_days']       !== '' ? (int) $body['warning_days']       : null,
            ':pack_size'          => isset($body['pack_size'])          && $body['pack_size']          !== '' ? (int) $body['pack_size']          : null,
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
    sendError('A database error occurred.', 500);
}
