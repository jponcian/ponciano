<?php
require_once __DIR__ . '/cors.php';
require __DIR__ . '/../db.php';
header('Content-Type: application/json; charset=utf-8');

try {
    // Buscar tasa del día actual o fecha especificada
    $hoy = isset($_GET['fecha']) ? $_GET['fecha'] : date('Y-m-d');
    $stmt = $db->prepare("SELECT fecha, valor FROM tasas_cambio WHERE fecha = ? LIMIT 1");
    $stmt->execute([$hoy]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        echo json_encode([
            'ok' => true,
            'fecha' => $row['fecha'],
            'valor' => (float)$row['valor']
        ]);
    } else {
        // Si no hay tasa para hoy, usar la tasa más reciente disponible (anterior o igual a hoy).
        $stmt2 = $db->prepare("SELECT fecha, valor FROM tasas_cambio ORDER BY fecha DESC LIMIT 1");
        $stmt2->execute();
        $row2 = $stmt2->fetch(PDO::FETCH_ASSOC);
        if ($row2) {
            echo json_encode([
                'ok' => true,
                'fecha' => $row2['fecha'],
                'valor' => (float)$row2['valor']
            ]);
        } else {
            echo json_encode(['ok' => false, 'error' => 'No hay tasa registrada']);
        }
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'Error al consultar tasa']);
}
