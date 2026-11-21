document.addEventListener('keydown',e=>{if(e.key==='Escape'){const m=document.getElementById('recordModal');if(m)m.classList.remove('show')}});document.addEventListener('click',e=>{const m=document.getElementById('recordModal');if(m&&e.target===m)m.classList.remove('show')});

/* Filtro de tablas: solo oculta filas en el navegador, no toca Oracle. */
function normalizeText(value) {
    return (value === null || value === undefined ? '' : String(value))
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '');
}

function filterTable(input, tableId) {
    var query = normalizeText(input.value);
    var table = document.getElementById(tableId);
    if (!table) return;
    table.querySelectorAll('tbody tr').forEach(function (row) {
        if (row.classList.contains('empty')) return;
        row.style.display = normalizeText(row.textContent).indexOf(query) >= 0 ? '' : 'none';
    });
}

/* Al elegir un viaje, selecciona automaticamente el bus asignado. */
function syncBusVenta() {
    var viaje = document.getElementById('ventaViaje');
    var bus = document.getElementById('ventaBus');
    if (!viaje || !bus) return;
    var option = viaje.options[viaje.selectedIndex];
    var patente = option ? option.getAttribute('data-bus') : '';
    if (patente) {
        for (var i = 0; i < bus.options.length; i++) {
            if (bus.options[i].value === patente) {
                bus.selectedIndex = i;
                break;
            }
        }
    }
}
