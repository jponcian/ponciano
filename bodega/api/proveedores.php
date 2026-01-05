<?php
require_once __DIR__ . '/cors.php';
// Devuelve la lista de proveedores únicos de la tabla productos
header('Content-Type: application/json');
require_once __DIR__ . '/../db.php';
try {
    global $db;
    $stmt = $db->query("SELECT DISTINCT proveedor FROM productos WHERE proveedor IS NOT NULL AND proveedor != '' ORDER BY proveedor ASC");
    $proveedores = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo json_encode(['ok' => true, 'proveedores' => $proveedores]);
} catch (Exception $e) {
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
