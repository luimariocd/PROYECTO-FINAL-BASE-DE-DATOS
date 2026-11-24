(function () {
    'use strict';

    function byId(id) {
        return document.getElementById(id);
    }

    function showModal(id) {
        var modal = byId(id);
        if (modal) modal.classList.add('show');
    }

    function hideModal(id) {
        var modal = byId(id);
        if (modal) modal.classList.remove('show');
    }

    window.openCreate = function () {
        var form = byId('recordForm');
        var cfg = window.LEHZ_MAINTAINER;
        if (!form || !cfg) return;
        form.reset();
        byId('formOp').value = 'I';
        byId('modalTitle').textContent = 'Nuevo registro';
        cfg.id.forEach(function (id) {
            var original = byId('orig_' + id.name);
            var field = byId('field_' + id.name);
            if (original) original.value = '';
            if (field) {
                field.disabled = false;
                field.value = '';
            }
        });
        cfg.fields.forEach(function (field) {
            var el = byId('field_' + field.name);
            if (el) el.value = '';
        });
        showModal('recordModal');
    };

    window.editMaintainer = function (row) {
        var form = byId('recordForm');
        var cfg = window.LEHZ_MAINTAINER;
        if (!form || !cfg) return;
        form.reset();
        byId('formOp').value = 'U';
        byId('modalTitle').textContent = 'Editar registro';
        cfg.id.forEach(function (id) {
            var original = byId('orig_' + id.name);
            var field = byId('field_' + id.name);
            if (original) original.value = row[id.name] !== undefined && row[id.name] !== null ? row[id.name] : '';
            if (field) {
                field.value = row[id.name] !== undefined && row[id.name] !== null ? row[id.name] : '';
                if (!id.auto) field.disabled = true;
            }
        });
        cfg.fields.forEach(function (field) {
            var el = byId('field_' + field.name);
            if (el) {
                el.value = row[field.name] !== undefined && row[field.name] !== null ? row[field.name] : '';
            }
        });
        showModal('recordModal');
    };

    window.closeModal = function () {
        hideModal('recordModal');
    };

    window.openAnnul = function (id) {
        var input = byId('annulId');
        if (input) input.value = id;
        var motivo = byId('annulMotivo');
        if (motivo) {
            motivo.value = '';
            motivo.focus();
        }
        showModal('annulModal');
    };

    window.closeAnnul = function () {
        hideModal('annulModal');
    };

    function digits(value) {
        return String(value || '').replace(/\D+/g, '');
    }

    function formatPhone(value) {
        var d = digits(value);
        if (d.indexOf('600') === 0) {
            d = d.substring(0, 9);
            return '600' + (d.length > 3 ? ' ' + d.substring(3, 6) : '') + (d.length > 6 ? ' ' + d.substring(6, 9) : '');
        }
        if (d.indexOf('809') === 0) {
            d = d.substring(0, 9);
            return '809' + (d.length > 3 ? ' ' + d.substring(3, 6) : '') + (d.length > 6 ? ' ' + d.substring(6, 9) : '');
        }
        if (d.indexOf('56') === 0) {
            d = d.substring(2, 11);
        }
        if (d.length > 9) {
            d = d.substring(0, 9);
        }
        if (d.length === 0) return '';
        if (d.length < 9) return d;
        return '+56 ' + d.charAt(0) + ' ' + d.substring(1, 5) + ' ' + d.substring(5, 9);
    }

    function formatRut(value) {
        var raw = String(value || '').toUpperCase().replace(/[^0-9K]/g, '');
        if (raw.length === 0) return '';
        var body = raw;
        var dv = '';
        if (raw.length >= 9 || String(value).indexOf('-') !== -1) {
            dv = raw.slice(-1);
            body = raw.slice(0, -1);
        }
        if (body.length > 8) {
            body = body.substring(0, 8);
        }
        var formatted = body.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
        return dv ? formatted + '-' + dv : formatted;
    }

    document.addEventListener('input', function (event) {
        if (event.target.matches('[data-phone]')) {
            event.target.value = formatPhone(event.target.value);
        }
    });

    document.addEventListener('blur', function (event) {
        if (event.target.matches('[data-phone]')) {
            event.target.value = formatPhone(event.target.value);
        }
        if (event.target.matches('[data-rut]')) {
            event.target.value = formatRut(event.target.value);
        }
    }, true);

    document.addEventListener('click', function (event) {
        if (event.target.matches('[data-toggle-password]')) {
            var wrap = event.target.closest('.password-field');
            var input = wrap ? wrap.querySelector('input') : null;
            if (!input) return;
            var show = input.type === 'password';
            input.type = show ? 'text' : 'password';
            event.target.textContent = show ? 'Ocultar' : 'Mostrar';
        }
        if (event.target.id === 'recordModal' || event.target.id === 'annulModal') {
            event.target.classList.remove('show');
        }
    });

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') {
            hideModal('recordModal');
            hideModal('annulModal');
        }
    });

    function filterParadas() {
        var viaje = byId('saleViaje');
        var bajada = byId('saleBajada');
        if (!viaje || !bajada) return;
        var selected = viaje.value;
        var selectedStillVisible = false;
        Array.prototype.forEach.call(bajada.options, function (option) {
            if (!option.value) return;
            var visible = !selected || option.getAttribute('data-viaje') === selected;
            option.hidden = !visible;
            option.disabled = !visible;
            if (visible && option.selected) selectedStillVisible = true;
        });
        if (!selectedStillVisible && bajada.selectedIndex > 0) {
            bajada.selectedIndex = 0;
        }
        updateTarifa();
    }

    function updateTarifa() {
        var bajada = byId('saleBajada');
        var preview = byId('tarifaPreview');
        if (!bajada || !preview) return;
        var option = bajada.options[bajada.selectedIndex];
        var tarifa = option ? option.getAttribute('data-tarifa') : null;
        if (tarifa) {
            preview.textContent = 'Tarifa estimada para esta bajada: $' + Number(tarifa).toLocaleString('es-CL') + '. Oracle confirma el valor al vender.';
        } else {
            preview.textContent = 'La tarifa final la calcula Oracle al confirmar la venta.';
        }
    }

    document.addEventListener('change', function (event) {
        if (event.target.id === 'saleViaje') filterParadas();
        if (event.target.id === 'saleBajada') updateTarifa();
    });

    document.addEventListener('DOMContentLoaded', function () {
        filterParadas();
    });
})();
