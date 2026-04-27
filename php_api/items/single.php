<?php
// GET/PUT/DELETE /items/{id} – ID passed as ?id=5

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../helpers/response.php';

setCorsHeaders();
validateApiKey();

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

        // Only name, quantity, location_id are required; description and category are optional
        $required = ['name', 'quantity', 'location_id'];
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

        // photo_url is intentionally NOT updated here — use the dedicated /photo endpoint
        $stmt = $pdo->prepare(
            'UPDATE items
                SET name               = :name,
                    description        = :description,
                    category           = :category,
                    barcode            = :barcode,
                    quantity           = :quantity,
                    location_id        = :location_id,
                    expiry_date        = :expiry_date,
                    unit               = :unit,
                    critical_threshold = :critical_threshold,
                    warning_days       = :warning_days,
                    pack_size          = :pack_size
              WHERE id = :id'
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
            ':id'                 => $id,
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
        // Get photo_url before deleting so we can clean up the file
        $check = $pdo->prepare('SELECT id, photo_url FROM items WHERE id = :id');
        $check->execute([':id' => $id]);
        $existing = $check->fetch();
        if (!$existing) {
            sendError('Item not found.', 404);
        }

        // Delete photo file if exists
        if (!empty($existing['photo_url'])) {
            $path = __DIR__ . '/../../' . $existing['photo_url'];
            if (file_exists($path)) {
                unlink($path);
            }
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
