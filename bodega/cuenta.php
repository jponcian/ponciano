<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Bodega - móvil</title>
    <meta name="description" content="Gestión de inventario optimizada para móvil" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
    <link rel="stylesheet" href="style.css">
    <style>
        .producto-card {
            background: #f8f9fa;
            border-radius: 12px;
            padding: 16px 12px;
            margin-bottom: 18px;
            box-shadow: 0 2px 8px #0001;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .producto-card .fw-bold {
            font-size: 1em !important;
        }

        /* Modal elegante y compacto para móviles */
        #detalleCuentaModal .modal-dialog {
            max-width: 98vw;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        #detalleCuentaModal .modal-content {
            border-radius: 18px;
            background: #f4f6fb;
            box-shadow: 0 4px 24px #0002;
            padding: 0;
        }

        #detalleCuentaModal .modal-header {
            border-bottom: none;
            background: #e3f2fd;
            border-radius: 18px 18px 0 0;
            padding: 16px 18px 8px 18px;
        }

        #detalleCuentaModal .modal-title {
            font-size: 1.15em;
            font-weight: bold;
            color: #1565c0;
        }

        #detalleCuentaModal .modal-body {
            padding: 12px 16px 18px 16px;
        }

        #detalleCuentaModal .list-group-item {
            border: none;
            background: #fff;
            margin-bottom: 8px;
            border-radius: 10px;
            font-size: 0.98em;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 1px 4px #0001;
        }

        #detalleCuentaModal .badge {
            font-size: 0.95em;
            padding: 6px 12px;
            background: #1976d2;
        }

        #detalleCuentaModal .btn-close {
            background: none;
            font-size: 1.2em;
            color: #1976d2;
            opacity: 0.7;
        }

        @media (max-width: 600px) {
            #detalleCuentaModal .modal-dialog {
                max-width: 100vw;
            }

            #detalleCuentaModal .modal-content {
                border-radius: 12px;
                padding: 0;
            }

            #detalleCuentaModal .modal-header {
                padding: 12px 12px 6px 12px;
            }

            #detalleCuentaModal .modal-body {
                padding: 10px 8px 14px 8px;
            }
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
</head>

<body>
    <div class="app">

        <header class="app-header d-flex align-items-center justify-content-between" style="gap:12px;">
            <div style="display:flex;flex-direction:column;align-items:flex-start;min-width:170px;max-width:260px;">
                <span id="tasa-info" class="badge bg-primary" style="overflow:ellipsis;">
                    <i class="fa-solid fa-dollar-sign"></i> <span id="tasa-valor" class="small fw-bold" style="font-size: 1.1em;"></span>
                </span>
                <span class="small text-muted mt-1" style="font-size: 0.8em;">
                    Fecha: <span id="tasa-fecha" class="fw-bold"></span>
                </span>
            </div>
            <div class="header-actions">
                <a href="index.php" class="btn btn-outline-secondary btn-sm" style="vertical-align:middle;">
                    <i class="fa-solid fa-arrow-left"></i> Volver
                </a>
                <div>
        </header>

        <main class="app-main">
            <div onclick="mostrarDetalleCuenta()" id="total-cuenta" style="background:#e3f2fd;border-radius:8px;padding:16px 24px;margin-bottom:18px;font-size:2em;font-weight:bold;color:#1565c0;text-align:center;box-shadow:0 2px 8px #0001;cursor:pointer;">Total: 0</div>
            <!-- ...existing code... -->
            <div class="search-bar">
                <input id="search" type="search" placeholder="Buscar por nombre, proveedor o precio" />
            </div>
            <div id="list" class="list"></div>
        </main>
        <!-- Modal para mostrar el detalle de la cuenta (fuera de <main>) -->
        <div class="modal fade" id="detalleCuentaModal" tabindex="-1" aria-labelledby="detalleCuentaLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="detalleCuentaLabel">Detalle de la cuenta</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
                    </div>
                    <div class="modal-body" id="detalleCuentaBody">
                    </div>
                </div>
            </div>
        </div>

        <!-- Eliminada barra de edición de tasa, solo informativa arriba -->

        <script>
            // Mostrar el modal con los productos usados en la cuenta
            function mostrarDetalleCuenta() {
                // Obtener la lista actualizada de productos y cantidades
                let lista = window.ultimaLista || [];
                let cantidades = window.cantidades || {};
                
                // Si la lista está vacía, intentar obtenerla del DOM (fallback)
                if (!Array.isArray(lista) || lista.length === 0) {
                     // El fallback del DOM sigue siendo útil si por alguna razón falla el state
                    lista = Array.from(document.querySelectorAll('.item.producto-card')).map(el => {
                        let precio = el.getAttribute('data-precio');
                        let moneda = el.getAttribute('data-moneda');
                        if (precio === null || precio === undefined) {
                            const precioText = el.querySelector('.text-primary')?.textContent || '';
                            precio = parseFloat(precioText.split(' ')[0]) || 0;
                        } else {
                            precio = parseFloat(precio);
                        }
                        return {
                            id: el.dataset.id,
                            display_name: el.querySelector('.fw-bold')?.textContent || '',
                            display_price: precio,
                            moneda_compra: (!moneda && el.querySelector('.text-primary')?.textContent.includes('Bs') ? 'BS' : 'USD')
                        };
                    });
                }
                
                // Filtrar productos con cantidad > 0 (acepta decimales)
                const productosUsados = lista.filter(p => (cantidades[p.id] && parseFloat(cantidades[p.id]) > 0));
                const modalBody = document.getElementById('detalleCuentaBody');

                if (productosUsados.length === 0) {
                    modalBody.innerHTML = '<div class="text-center text-muted">No hay productos en la cuenta.</div>';
                } else {
                    let totalUSD = 0,
                        totalBS = 0;
                    modalBody.innerHTML = '<ul class="list-group">' + productosUsados.map(p => {
                        const cantidad = parseFloat(cantidades[p.id]) || 0;
                        const precio = p.display_price !== undefined ? p.display_price : ((p.precio_venta_unidad !== undefined && p.precio_venta_unidad !== null && p.precio_venta_unidad !== '') ? Number(p.precio_venta_unidad) : 0);
                        
                        // Determinar etiqueta para detalle (si el nombre ya trae 'Paquete' no agregarlo)
                        let nombreMostrar = p.display_name || p.nombre || '';
                        if (p.id.endsWith && p.id.endsWith('_pkg') && !nombreMostrar.includes('Paquete')) {
                             nombreMostrar += ' (Paquete)';
                        }
                        
                        const moneda = (p.moneda_compra && p.moneda_compra.toUpperCase() === 'BS') ? 'BS' : 'USD';
                        let precioUSD, precioBS, totalUSDItem, totalBSItem;
                        if (moneda === 'USD') {
                            precioUSD = precio;
                            precioBS = precio * exchangeRate;
                            totalUSDItem = precioUSD * cantidad;
                            totalBSItem = precioBS * cantidad;
                        } else {
                            precioBS = precio;
                            precioUSD = exchangeRate > 0 ? precio / exchangeRate : 0;
                            totalBSItem = precioBS * cantidad;
                            totalUSDItem = precioUSD * cantidad;
                        }
                        totalUSD += totalUSDItem;
                        totalBS += totalBSItem;
                        return `<li class="list-group-item d-flex flex-column align-items-start">
                            <div class="w-100 d-flex justify-content-between align-items-center">
                                <span><b>${escapeHtml(nombreMostrar)}</b> <span class="badge bg-secondary ms-2">x${cantidad}</span></span>
                                <span class="text-primary">${precioUSD.toFixed(2)} $ / ${precioBS.toFixed(2)} Bs</span>
                            </div>
                            <div class="w-100 text-end small text-muted">Subtotal: <b>${totalUSDItem.toFixed(2)} $ / ${totalBSItem.toFixed(2)} Bs</b></div>
                        </li>`;
                    }).join('') + '</ul>';
                    // Sección de total
                    modalBody.innerHTML += `<div class='mt-3 text-center fw-bold'>Total:<br>${totalUSD.toFixed(2)} $ / ${totalBS.toFixed(2)} Bs</div>`;
                }
                const modalEl = document.getElementById('detalleCuentaModal');
                const modal = new bootstrap.Modal(modalEl);
                modal.show();
            }
            // Declarar solo una vez las variables globales
            let timeout = null;
            let exchangeRate = 0;
            let exchangeDate = '';
            const btnPrint = document.getElementById('btn-print');
            let actionsVisible = true;

            const API_VER = 'api/ver.php';
            const API_CREAR = 'api/crear.php';
            const API_EDITAR = 'api/editar.php';
            const API_ELIMINAR = 'api/eliminar.php';

            function el(selector, parent = document) {
                return parent.querySelector(selector);
            }

            function show(elm) {
                elm.classList.remove('hidden');
            }

            function hide(elm) {
                elm.classList.add('hidden');
            }

            const listEl = el('#list');
            const searchEl = el('#search');

            async function fetchList(q) {
                const url = API_VER + (q ? '?q=' + encodeURIComponent(q) : '');
                const res = await fetch(url);
                const data = await res.json();
                renderList(data);
            }

            function renderList(rawItems) {
                if (!Array.isArray(rawItems) || rawItems.length === 0) {
                    listEl.innerHTML = '<div class="empty">Sin productos</div>';
                    return;
                }

                // Procesar la lista para crear filas independientes para paquetes
                const displayItems = [];
                rawItems.forEach(item => {
                    // 1. Versión Unidad (Siempre agregada)
                    const precioUnitario = (item.precio_venta_unidad !== undefined && item.precio_venta_unidad !== null && item.precio_venta_unidad !== '') ? Number(item.precio_venta_unidad) : (Number(item.precio_venta) || 0);
                    
                    // Clonar y ajustar para unidad
                    displayItems.push({
                        ...item,
                        id: item.id.toString(), // ID original como string
                        display_name: item.nombre,
                        display_price: precioUnitario,
                        is_package: false
                    });

                    // 2. Versión Paquete (Si existe)
                    if (item.unidad_medida === 'paquete' && item.precio_venta_paquete && Number(item.precio_venta_paquete) > 0) {
                        displayItems.push({
                            ...item,
                            id: item.id.toString() + '_pkg', // ID compuesto
                            display_name: item.nombre + ' (Paquete)',
                            display_price: Number(item.precio_venta_paquete),
                            is_package: true
                        });
                    }
                });

                window.ultimaLista = displayItems; // Guardar lista expandida para otras funciones
                if (!window.cantidades) window.cantidades = {};

                listEl.innerHTML = displayItems.map(i => {
                    if (!(i.id in window.cantidades)) window.cantidades[i.id] = 0;
                    
                    const precio = i.display_price;
                    const moneda = (i.moneda_compra && i.moneda_compra.toUpperCase() === 'BS') ? 'Bs' : '$';
                    
                    let precioMostrar = '';
                    if (moneda === '$') {
                        let precioBs = (typeof exchangeRate !== 'undefined' && exchangeRate > 0) ? (precio * exchangeRate) : 0;
                        precioMostrar = `${precio.toFixed(2)} $ (${precioBs.toFixed(2)} Bs)`;
                    } else {
                        precioMostrar = `${precio.toFixed(2)} Bs`;
                    }
                    
                    // Agrega los datos en atributos para reconstrucción confiable
                    return `<div class="item producto-card" data-id="${i.id}" data-precio="${precio}" data-moneda="${i.moneda_compra}">
                        <div class="flex-grow-1">
                            <span class="fw-bold">${escapeHtml(i.display_name)}</span>
                        </div>
                        <div style="min-width:120px;text-align:right;">
                            <span class="fw-bold text-primary display-precio">${precioMostrar}</span>
                        </div>
                        <div style="min-width:120px;display:flex;align-items:center;gap:4px;">
                            <button class="btn btn-sm btn-danger restar" title="Restar"><i class="fa-solid fa-minus"></i></button>
                            <input type="number" step="0.01" class="form-control form-control-sm cantidad-input" min="0" value="${window.cantidades[i.id]}" style="width:70px;text-align:center;">
                            <button class="btn btn-sm btn-success sumar" title="Sumar"><i class="fa-solid fa-plus"></i></button>
                        </div>
                    </div>`;
                }).join('');

                // Eventos para sumar/restar y actualizar total
                listEl.querySelectorAll('.item').forEach(itemEl => {
                    const id = itemEl.dataset.id;
                    const input = itemEl.querySelector('.cantidad-input');
                    const btnMas = itemEl.querySelector('.sumar');
                    const btnMenos = itemEl.querySelector('.restar');
                    
                    if (btnMas) {
                        btnMas.addEventListener('click', () => {
                            window.cantidades[id] = (window.cantidades[id] || 0) + 1;
                            input.value = window.cantidades[id];
                            actualizarTotalCobrar(displayItems);
                        });
                    }
                    if (btnMenos) {
                        btnMenos.addEventListener('click', () => {
                            window.cantidades[id] = Math.max(0, (window.cantidades[id] || 0) - 1);
                            input.value = window.cantidades[id];
                            actualizarTotalCobrar(displayItems);
                        });
                    }
                    if (input) {
                        input.addEventListener('input', () => {
                            const rawValue = input.value.trim();
                            if (rawValue === '') {
                                window.cantidades[id] = 0;
                                actualizarTotalCobrar(displayItems);
                                return;
                            }
                            const parsed = parseFloat(rawValue.replace(',', '.'));
                            if (!isNaN(parsed)) {
                                window.cantidades[id] = Math.max(0, parsed);
                                actualizarTotalCobrar(displayItems);
                            }
                        });
                        input.addEventListener('blur', () => {
                            const current = window.cantidades[id] || 0;
                            input.value = current ? current : '';
                        });
                    }
                });
                actualizarTotalCobrar(displayItems);
            }

            function actualizarTotalCobrar(items) {
                let totalBs = 0;
                items.forEach(i => {
                    // Usar display_price que ya viene calculado en renderList o calcular si es item raw (no debería pasar aqui si usamos displayItems)
                    let precio = i.display_price !== undefined ? i.display_price : ((i.precio_venta_unidad !== undefined && i.precio_venta_unidad !== null && i.precio_venta_unidad !== '') ? Number(i.precio_venta_unidad) : (Number(i.precio_venta) || 0));

                    const moneda = (i.moneda_compra && i.moneda_compra.toUpperCase() === 'BS') ? 'Bs' : '$';
                    let precioBs = precio;
                    if (moneda === '$' && typeof exchangeRate !== 'undefined' && exchangeRate > 0) {
                        precioBs = precio * exchangeRate;
                    }
                    totalBs += precioBs * (window.cantidades[i.id] || 0);
                });
                const totalCuentaEl = document.getElementById('total-cuenta');
                if (totalCuentaEl) {
                    let texto = `Total: ${totalBs.toFixed(2)} Bs`;
                    totalCuentaEl.textContent = texto;
                }
            }

            function escapeHtml(s) {
                if (!s && s !== 0) return '';
                return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
            }


            // let exchangeRate = 0;
            // let exchangeDate = '';
            async function fetchExchangeRate() {
                try {
                    const res = await fetch('api/tasa.php');
                    const data = await res.json();
                    if (data.ok && data.valor) {
                        exchangeRate = parseFloat(data.valor);
                        exchangeDate = data.fecha || '';
                        // Set the hidden input field with the exchange rate
                        const tasaOcultaInput = document.getElementById('tasa_actual_oculta');
                        if (tasaOcultaInput) {
                            tasaOcultaInput.value = exchangeRate;
                        }

                        const valorEl = document.getElementById('tasa-valor');
                        if (valorEl) valorEl.textContent = `${exchangeRate.toFixed(2)} Bs`;
                        const fechaEl = document.getElementById('tasa-fecha');
                        let fechaFormateada = '';
                        if (exchangeDate && /^\d{4}-\d{2}-\d{2}$/.test(exchangeDate)) {
                            const [y, m, d] = exchangeDate.split('-');
                            fechaFormateada = `${d}-${m}-${y}`;
                        }
                        fechaEl.textContent = fechaFormateada ? fechaFormateada : '';
                        fetchList(searchEl.value);
                    } else { // Added else block for debugging

                    }
                } catch (e) {

                }
            }

            window.addEventListener('DOMContentLoaded', () => {
                fetchExchangeRate();
            });

            fetchList();

            const btnPrintTable = document.getElementById('btn-print-table');
            if (btnPrintTable) {
                btnPrintTable.addEventListener('click', function(e) {
                    e.preventDefault();
                    const checks = document.querySelectorAll('.select-product:checked');
                    if (checks.length === 0) {
                        alert('Selecciona al menos un producto para imprimir la tabla.');
                        return;
                    }
                    const ids = Array.from(checks).map(ch => ch.value).join(',');
                    window.open('generar_pdf_tabla.php?ids=' + encodeURIComponent(ids), '_blank');
                });
            }

            // Asegurar que el input de búsqueda funcione correctamente
            if (searchEl) {
                // input -> búsqueda con debounce
                searchEl.addEventListener('input', () => {
                    clearTimeout(timeout);
                    timeout = setTimeout(() => fetchList(searchEl.value), 300);
                });

                // focus -> seleccionar todo el texto (solo una vez)
                if (!searchEl.dataset.selectOnFocusAdded) {
                    searchEl.addEventListener('focus', function() {
                        // select() funciona en inputs tipo search/text
                        this.select();
                        // En algunos navegadores el mouseup quita la selección, impedirlo
                        const onMouseUp = function(e) {
                            e.preventDefault();
                            // remover este listener después del primer uso
                            searchEl.removeEventListener('mouseup', onMouseUp);
                        };
                        searchEl.addEventListener('mouseup', onMouseUp);
                    });
                    searchEl.dataset.selectOnFocusAdded = '1';
                }
            }
        </script>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>
<?php
include_once __DIR__ . '/actualizar_tasa_bcv.php';
?>