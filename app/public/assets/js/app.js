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

    function filterSelect(input) {
        var target = document.getElementById(input.getAttribute('data-filter'));
        if (!target) return;
        if (!target._originalHTML) target._originalHTML = target.innerHTML;
        var q = input.value.trim().toLowerCase();
        if (q === '') {
            target.innerHTML = target._originalHTML;
            return;
        }
        var current = target.value;
        var parser = new DOMParser();
        var doc = parser.parseFromString('<select>' + target._originalHTML + '</select>', 'text/html');
        var orig = doc.querySelector('select');
        var html = '<option value="">Seleccione...</option>';
        Array.prototype.forEach.call(orig.querySelectorAll('optgroup'), function (group) {
            var opts = '';
            Array.prototype.forEach.call(group.querySelectorAll('option'), function (opt) {
                if (opt.textContent.toLowerCase().indexOf(q) !== -1) {
                    var o = opt.outerHTML;
                    if (opt.value === current) o = o.replace('<option', '<option selected');
                    opts += o;
                }
            });
            if (opts) {
                html += '<optgroup label="' + group.getAttribute('label') + '">' + opts + '</optgroup>';
            }
        });
        Array.prototype.forEach.call(orig.querySelectorAll(':scope > option'), function (opt) {
            if (!opt.value) return;
            if (opt.textContent.toLowerCase().indexOf(q) !== -1) {
                var o = opt.outerHTML;
                if (opt.value === current) o = o.replace('<option', '<option selected');
                html += o;
            }
        });
        target.innerHTML = html;
    }

    document.addEventListener('input', function (event) {
        if (event.target.classList && event.target.classList.contains('filter-input')) {
            filterSelect(event.target);
        }
    });

    (function acInit() {
        function setupAC(fieldName) {
            var hidden = document.getElementById('field_' + fieldName);
            var input = document.getElementById('ac_' + fieldName);
            var dd = document.getElementById('acdd_' + fieldName);
            if (!hidden || !input || !dd) return;
            var opts = (window.LEHZ_AC && window.LEHZ_AC[fieldName]) || [];
            function render(q) {
                q = (q || '').trim().toLowerCase();
                var groups = {};
                var order = [];
                opts.forEach(function (o) {
                    if (q === '' || (o.label || o.value).toLowerCase().indexOf(q) !== -1) {
                        var g = o.group || '';
                        if (!groups[g]) { groups[g] = []; order.push(g); }
                        groups[g].push(o);
                    }
                });
                var html = '';
                order.forEach(function (g) {
                    if (g) html += '<div class="ac-group">' + g + '</div>';
                    groups[g].forEach(function (o) {
                        html += '<div class="ac-option" data-value="' + String(o.value).replace(/"/g, '&quot;') + '">' + o.label + '</div>';
                    });
                });
                if (!html) html = '<div class="ac-empty">Sin resultados</div>';
                dd.innerHTML = html;
                dd.style.display = 'block';
            }
            input.addEventListener('focus', function () { render(input.value); });
            input.addEventListener('click', function () { render(input.value); });
            input.addEventListener('input', function () { render(input.value); });
            dd.addEventListener('mousedown', function (e) {
                var opt = e.target.closest('.ac-option');
                if (!opt) return;
                e.preventDefault();
                hidden.value = opt.getAttribute('data-value');
                input.value = opt.textContent;
                dd.style.display = 'none';
            });
            document.addEventListener('click', function (e) {
                if (e.target !== input && !dd.contains(e.target)) dd.style.display = 'none';
            });
        }
        document.addEventListener('DOMContentLoaded', function () {
            if (window.LEHZ_AC) {
                Object.keys(window.LEHZ_AC).forEach(setupAC);
            }
        });
    })();

    function syncPhone(fieldName) {
        var hidden = document.getElementById('field_' + fieldName);
        var numInput = document.getElementById('num_' + fieldName);
        var prefixSel = document.querySelector('.phone-prefix[data-target="field_' + fieldName + '"]');
        if (!hidden || !numInput || !prefixSel) return;
        var num = numInput.value.trim().replace(/^\+?56\s*9?\s*/, '').replace(/^600\s*/, '').replace(/^809\s*/, '').trim();
        hidden.value = num ? (prefixSel.value + ' ' + num) : '';
    }

    document.addEventListener('input', function (event) {
        if (event.target.id && event.target.id.indexOf('num_') === 0) {
            syncPhone(event.target.id.replace('num_', ''));
        }
    });

    document.addEventListener('change', function (event) {
        if (event.target.classList && event.target.classList.contains('phone-prefix')) {
            syncPhone(event.target.getAttribute('data-target').replace('field_', ''));
        }
    });

    document.addEventListener('DOMContentLoaded', function () {
        document.querySelectorAll('.phone-prefix').forEach(function (sel) {
            syncPhone(sel.getAttribute('data-target').replace('field_', ''));
        });
    });

    (function sidebarScroll() {
        var sb = document.querySelector('.sidebar');
        if (!sb) return;
        var key = 'sidebarScroll';
        var saved = sessionStorage.getItem(key);
        if (saved !== null) sb.scrollTop = parseInt(saved, 10) || 0;
        sb.addEventListener('scroll', function () {
            sessionStorage.setItem(key, String(sb.scrollTop));
        });
    })();
