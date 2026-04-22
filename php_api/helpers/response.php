<?php
// Helper functions for JSON responses and API key validation

// CORS-Header + Preflight (NFA-09)
function setCorsHeaders(): void
{
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Accept, X-Api-Key');

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

// Validate X-Api-Key, return 401 if missing or wrong
function validateApiKey(): void
{
    $header = $_SERVER['HTTP_X_API_KEY'] ?? '';
    if (empty($header) || $header !== API_KEY) {
        sendJson(['message' => 'Invalid or missing API key.'], 401);
    }
}

// JSON ausgeben und Skript beenden
function sendJson(mixed $data, int $status = 200): void
{
    header('Content-Type: application/json; charset=utf-8');
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

// Return error without exposing internal details (NFA-08)
function sendError(string $message, int $status = 400): void
{
    sendJson(['message' => $message], $status);
}

// Request-Body als Array lesen
function getRequestBody(): array
{
    $raw = file_get_contents('php://input');
    if (empty($raw)) {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}
