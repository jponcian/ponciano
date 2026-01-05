<?php
require_once __DIR__ . '/cors.php';
require __DIR__ . '/../db.php';
header('Content-Type: application/json; charset=utf-8');

$q = isset($_GET['q']) ? trim($_GET['q']) : null;
$id = isset($_GET['id']) ? intval($_GET['id']) : null;

try {
    if ($id) {
        $p = getProducto($id);
        if (!$p) {
            http_response_code(404);
            echo json_encode(['ok' => false, 'error' => 'No encontrado']);
            exit;
        }
        echo json_encode($p);
        exit;
    }
    $productos = obtenerProductos($q);
    echo json_encode($productos);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'Error al obtener productos']);
}
