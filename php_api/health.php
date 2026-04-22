<?php
// GET /health – connection test for the setup screen

require_once __DIR__ . '/config/db.php';
require_once __DIR__ . '/helpers/response.php';

setCorsHeaders();
validateApiKey(); // 401 if key is missing or wrong

// Test DB connection
try {
    getDbConnection();
    sendJson(['status' => 'ok', 'message' => 'Connection successful.']);
} catch (RuntimeException $e) {
    sendError('Database connection failed.', 500);
}
