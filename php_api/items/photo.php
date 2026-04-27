<?php
// POST /items/{id}/photo  – upload or replace photo for an item
// DELETE /items/{id}/photo – remove photo from an item

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

    // Verify item exists
    $check = $pdo->prepare('SELECT id, photo_url FROM items WHERE id = :id');
    $check->execute([':id' => $id]);
    $existing = $check->fetch();
    if (!$existing) {
        sendError('Item not found.', 404);
    }

    if ($method === 'POST') {
        // ── POST /items/{id}/photo ──────────────────────────────────────
        if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
            $errCode = $_FILES['photo']['error'] ?? -1;
            sendError("No valid file uploaded (error code: $errCode).", 400);
        }

        $file    = $_FILES['photo'];
        $maxBytes = 5 * 1024 * 1024; // 5 MB
        if ($file['size'] > $maxBytes) {
            sendError('File too large. Maximum size is 5 MB.', 413);
        }

        // Validate MIME type by reading actual file bytes (not trusting extension)
        $finfo    = new finfo(FILEINFO_MIME_TYPE);
        $mimeType = $finfo->file($file['tmp_name']);
        $allowed  = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
        if (!array_key_exists($mimeType, $allowed)) {
            sendError('Only JPEG, PNG, and WebP images are allowed.', 415);
        }

        // Resolve uploads directory (one level above php_api/)
        $uploadsDir = realpath(__DIR__ . '/../../') . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR;
        if (!is_dir($uploadsDir)) {
            if (!mkdir($uploadsDir, 0755, true)) {
                sendError('Could not create uploads directory.', 500);
            }
        }

        // Delete old photo if any
        if (!empty($existing['photo_url'])) {
            $oldPath = realpath(__DIR__ . '/../../') . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $existing['photo_url']);
            if (file_exists($oldPath)) {
                unlink($oldPath);
            }
        }

        $ext      = $allowed[$mimeType];
        $filename = 'item_' . $id . '_' . time() . '.' . $ext;
        $destPath = $uploadsDir . $filename;

        if (!move_uploaded_file($file['tmp_name'], $destPath)) {
            sendError('Failed to save uploaded file.', 500);
        }

        $relPath = 'uploads/' . $filename;

        $stmt = $pdo->prepare('UPDATE items SET photo_url = :url WHERE id = :id');
        $stmt->execute([':url' => $relPath, ':id' => $id]);

        sendJson(['photo_url' => $relPath], 200);

    } elseif ($method === 'DELETE') {
        // ── DELETE /items/{id}/photo ────────────────────────────────────
        if (!empty($existing['photo_url'])) {
            $path = realpath(__DIR__ . '/../../') . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $existing['photo_url']);
            if (file_exists($path)) {
                unlink($path);
            }
        }

        $stmt = $pdo->prepare('UPDATE items SET photo_url = NULL WHERE id = :id');
        $stmt->execute([':id' => $id]);

        sendJson(['message' => 'Photo removed.']);

    } else {
        sendError('Method not allowed.', 405);
    }

} catch (RuntimeException $e) {
    sendError($e->getMessage(), $e->getCode() ?: 500);
} catch (PDOException $e) {
    sendError('A database error occurred.', 500);
}
