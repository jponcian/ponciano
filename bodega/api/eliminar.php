<?php
require_once __DIR__ . '/cors.php';
require __DIR__ . '/../db.php';
header('Content-Type: application/json; charset=utf-8');

$body = $_POST;
if (!isset($body['id']) || !is_numeric($body['id'])) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'Falta id']);
    exit;
}

$id = intval($body['id']);
try {
    $ok = eliminarProducto($id);
    echo json_encode(['ok' => (bool)$ok]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'Error al eliminar producto']);
}
