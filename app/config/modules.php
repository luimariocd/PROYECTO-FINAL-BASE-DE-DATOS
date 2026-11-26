<?php
// Esta parte del código se encarga de describir formularios; Oracle valida y autoriza.

$maintainers = [
    'regiones' => [
        'title' => 'Regiones',
        'proc'  => 'LEHZ_PS_IUD_REGION',
        'list'  => 'LEHZ_PS_LISTAR_REGIONES',
        'id'    => [['name' => 'ID_REGION', 'param' => 'p_id_region', 'auto' => true]],
        'fields' => [
            ['name' => 'NOMBRE_REGION', 'param' => 'p_nombre_region', 'label' => 'Region de Chile', 'type' => 'select', 'source' => 'regiones_chile'],
        ],
    ],
    'comunas' => [
        'title' => 'Comunas',
        'proc'  => 'LEHZ_PS_IUD_COMUNA',
        'list'  => 'LEHZ_PS_LISTAR_COMUNAS',
        'id'    => [['name' => 'ID_COMUNA', 'param' => 'p_id_comuna', 'auto' => true]],
        'fields' => [
            ['name' => 'NOMBRE_COMUNA', 'param' => 'p_nombre_comuna', 'label' => 'Comuna de Chile', 'type' => 'select', 'source' => 'comunas_chile'],
        ],
    ],
    'terminales' => [
        'title' => 'Terminales',
        'proc'  => 'LEHZ_PS_IUD_TERMINAL',
        'list'  => 'LEHZ_PS_LISTAR_TERMINALES',
        'id'    => [['name' => 'ID_TERMINAL', 'param' => 'p_id_terminal', 'auto' => true]],
        'fields' => [
            ['name' => 'NOMBRE', 'param' => 'p_nombre', 'label' => 'Nombre del terminal', 'type' => 'text'],
            ['name' => 'CALLE', 'param' => 'p_calle', 'label' => 'Calle', 'type' => 'text'],
            ['name' => 'NUMERO', 'param' => 'p_numero', 'label' => 'Numero', 'type' => 'number'],
            ['name' => 'ID_COMUNA', 'param' => 'p_id_comuna', 'label' => 'Comuna', 'type' => 'select', 'source' => 'comunas'],
        ],
    ],
    'empresas' => [
        'title' => 'Empresas',
        'proc'  => 'LEHZ_PS_IUD_EMPRESA',
        'list'  => 'LEHZ_PS_LISTAR_EMPRESAS',
        'id'    => [['name' => 'RUT_EMPRESA', 'param' => 'p_rut_empresa', 'label' => 'RUT de la empresa', 'placeholder' => '7 u 8 digitos, con o sin DV']],
        'fields' => [
            ['name' => 'RAZON_SOCIAL', 'param' => 'p_razon_social', 'label' => 'Nombre de la empresa', 'type' => 'text'],
            ['name' => 'TELEFONO_EMPRESA', 'param' => 'p_telefono', 'label' => 'Numero de contacto', 'type' => 'tel', 'placeholder' => '+56 2 2345 6789, 600 123 456, 809 123 456'],
            ['name' => 'CORREO_ELECTRONICO_EMPRESA', 'param' => 'p_correo', 'label' => 'Correo electronico', 'type' => 'email'],
        ],
    ],
    'buses' => [
        'title' => 'Buses',
        'proc'  => 'LEHZ_PS_IUD_BUS',
        'list'  => 'LEHZ_PS_LISTAR_BUSES',
        'id'    => [['name' => 'PATENTE_BUS', 'param' => 'p_patente', 'label' => 'Patente del bus', 'placeholder' => 'Ej. BCDF12']],
        'fields' => [
            ['name' => 'MARCA', 'param' => 'p_marca', 'label' => 'Marca', 'type' => 'text'],
            ['name' => 'MODELO', 'param' => 'p_modelo', 'label' => 'Modelo', 'type' => 'text'],
            ['name' => 'ANIO_FABRICACION', 'param' => 'p_anio', 'label' => 'Anio de fabricacion', 'type' => 'number'],
            ['name' => 'CAPACIDAD', 'param' => 'p_capacidad', 'label' => 'Capacidad de pasajeros', 'type' => 'number'],
            ['name' => 'TIPO_SERVICIO', 'param' => 'p_tipo_servicio', 'label' => 'Tipo de servicio', 'type' => 'domain', 'domain' => 'TIPO_SERVICIO'],
            ['name' => 'CANTIDAD_PISOS', 'param' => 'p_cantidad_pisos', 'label' => 'Cantidad de pisos', 'type' => 'domain', 'domain' => 'CANTIDAD_PISOS'],
            ['name' => 'TARIFA_BASE', 'param' => 'p_tarifa_base', 'label' => 'Tarifa base', 'type' => 'number'],
            ['name' => 'RUT_EMPRESA', 'param' => 'p_rut_empresa', 'label' => 'Empresa', 'type' => 'select', 'source' => 'empresas'],
        ],
    ],
    'asientos' => [
        'title' => 'Asientos',
        'proc'  => 'LEHZ_PS_IUD_ASIENTO',
        'list'  => 'LEHZ_PS_LISTAR_ASIENTOS',
        'id'    => [
            ['name' => 'NUMERO_ASIENTO', 'param' => 'p_nro_asiento', 'label' => 'Numero de asiento', 'type' => 'number'],
            ['name' => 'PATENTE_BUS', 'param' => 'p_patente', 'label' => 'Bus', 'source' => 'buses'],
        ],
        'fields' => [
            ['name' => 'PISO', 'param' => 'p_piso', 'label' => 'Piso', 'type' => 'number'],
            ['name' => 'UBICACION', 'param' => 'p_ubicacion', 'label' => 'Ubicacion', 'type' => 'domain', 'domain' => 'UBICACION_ASIENTO'],
        ],
    ],
    'conductores' => [
        'title' => 'Conductores',
        'proc'  => 'LEHZ_PS_IUD_CONDUCTOR',
        'list'  => 'LEHZ_PS_LISTAR_CONDUCTORES',
        'id'    => [['name' => 'RUT_CONDUCTOR', 'param' => 'p_rut', 'label' => 'RUT del conductor', 'placeholder' => '7 u 8 digitos, con o sin DV']],
        'fields' => [
            ['name' => 'NOMBRE_CONDUCTOR', 'param' => 'p_nombre', 'label' => 'Nombre', 'type' => 'text'],
            ['name' => 'APELLIDO1_CONDUCTOR', 'param' => 'p_apellido1', 'label' => 'Primer apellido', 'type' => 'text'],
            ['name' => 'APELLIDO2_CONDUCTOR', 'param' => 'p_apellido2', 'label' => 'Segundo apellido', 'type' => 'text'],
            ['name' => 'TELEFONO', 'param' => 'p_telefono', 'label' => 'Telefono movil', 'type' => 'tel', 'placeholder' => '+56 9 1234 5678'],
            ['name' => 'TIPO_LICENCIA', 'param' => 'p_tipo_licencia', 'label' => 'Tipo de licencia', 'type' => 'domain', 'domain' => 'TIPO_LICENCIA'],
            ['name' => 'VENCIMIENTO_LICENCIA', 'param' => 'p_vencimiento', 'label' => 'Vencimiento de licencia', 'type' => 'date'],
            ['name' => 'RUT_EMPRESA', 'param' => 'p_rut_empresa', 'label' => 'Empresa', 'type' => 'select', 'source' => 'empresas'],
        ],
    ],
    'mecanicos' => [
        'title' => 'Mecanicos',
        'proc'  => 'LEHZ_PS_IUD_MECANICO',
        'list'  => 'LEHZ_PS_LISTAR_MECANICOS',
        'id'    => [['name' => 'RUT_MECANICO', 'param' => 'p_rut', 'label' => 'RUT del mecanico', 'placeholder' => '7 u 8 digitos, con o sin DV']],
        'fields' => [
            ['name' => 'NOMBRE_MECANICO', 'param' => 'p_nombre', 'label' => 'Nombre', 'type' => 'text'],
            ['name' => 'APELLIDO1_MECANICO', 'param' => 'p_apellido1', 'label' => 'Primer apellido', 'type' => 'text'],
            ['name' => 'APELLIDO2_MECANICO', 'param' => 'p_apellido2', 'label' => 'Segundo apellido', 'type' => 'text'],
            ['name' => 'TELEFONO', 'param' => 'p_telefono', 'label' => 'Telefono movil', 'type' => 'tel', 'placeholder' => '+56 9 1234 5678'],
            ['name' => 'ESPECIALIDAD', 'param' => 'p_especialidad', 'label' => 'Especialidad', 'type' => 'text'],
            ['name' => 'RUT_EMPRESA', 'param' => 'p_rut_empresa', 'label' => 'Empresa', 'type' => 'select', 'source' => 'empresas'],
        ],
    ],
    'rutas' => [
        'title' => 'Rutas',
        'proc'  => 'LEHZ_PS_IUD_RUTA',
        'list'  => 'LEHZ_PS_LISTAR_RUTAS',
        'id'    => [['name' => 'ID_RUTA', 'param' => 'p_id_ruta', 'auto' => true]],
        'fields' => [
            ['name' => 'NOMBRE_RUTA', 'param' => 'p_nombre_ruta', 'label' => 'Nombre de la ruta', 'type' => 'text'],
            ['name' => 'ID_TERMINAL_ORIGEN', 'param' => 'p_id_terminal_origen', 'label' => 'Terminal de origen', 'type' => 'select', 'source' => 'terminales'],
            ['name' => 'ID_TERMINAL_DESTINO', 'param' => 'p_id_terminal_destino', 'label' => 'Terminal de destino', 'type' => 'select', 'source' => 'terminales'],
            ['name' => 'HORARIO', 'param' => 'p_horario', 'label' => 'Fecha y hora de referencia', 'type' => 'datetime-local'],
            ['name' => 'DISTANCIA', 'param' => 'p_distancia', 'label' => 'Distancia (km)', 'type' => 'number'],
            ['name' => 'HORAS_ESTIMADAS', 'param' => 'p_horas_est', 'label' => 'Horas estimadas', 'type' => 'number'],
            ['name' => 'MINUTOS_ESTIMADOS', 'param' => 'p_minutos_est', 'label' => 'Minutos estimados', 'type' => 'number'],
        ],
    ],
    'paradas' => [
        'title' => 'Paradas por ruta',
        'proc'  => 'LEHZ_PS_IUD_RUTA_PARADA',
        'list'  => 'LEHZ_PS_LISTAR_RUTA_PARADAS',
        'id'    => [['name' => 'ID_RUTA_PARADA', 'param' => 'p_id_ruta_parada', 'auto' => true]],
        'fields' => [
            ['name' => 'ID_RUTA', 'param' => 'p_id_ruta', 'label' => 'Ruta', 'type' => 'select', 'source' => 'rutas'],
            ['name' => 'ID_TERMINAL', 'param' => 'p_id_terminal', 'label' => 'Terminal', 'type' => 'select', 'source' => 'terminales'],
            ['name' => 'ORDEN_PARADA', 'param' => 'p_orden', 'label' => 'Orden de la parada', 'type' => 'number'],
            ['name' => 'MINUTOS_DESDE_ORIG', 'param' => 'p_minutos', 'label' => 'Minutos desde el origen', 'type' => 'number'],
            ['name' => 'PERMITE_BAJADA', 'param' => 'p_permite_bajada', 'label' => 'Permite bajada', 'type' => 'domain', 'domain' => 'PERMITE_BAJADA'],
        ],
    ],
    'horarios' => [
        'title' => 'Horarios',
        'proc'  => 'LEHZ_PS_IUD_HORARIO',
        'list'  => 'LEHZ_PS_LISTAR_HORARIOS',
        'id'    => [['name' => 'ID_HORARIO', 'param' => 'p_id_horario', 'auto' => true]],
        'fields' => [
            ['name' => 'HORARIO', 'param' => 'p_horario_val', 'label' => 'Codigo de horario', 'type' => 'number'],
            ['name' => 'FECHA_HORARIO', 'param' => 'p_fecha_horario', 'label' => 'Fecha del horario', 'type' => 'date'],
            ['name' => 'HORA_SALIDA', 'param' => 'p_hora_salida', 'label' => 'Hora de salida', 'type' => 'datetime-local'],
            ['name' => 'HORA_LLEGADA', 'param' => 'p_hora_llegada', 'label' => 'Hora de llegada', 'type' => 'datetime-local'],
        ],
    ],
    'pasajeros' => [
        'title' => 'Pasajeros',
        'proc'  => 'LEHZ_PS_IUD_PASAJERO',
        'list'  => 'LEHZ_PS_LISTAR_PASAJEROS',
        'id'    => [['name' => 'RUT_PASAJERO', 'param' => 'p_rut', 'label' => 'RUT del pasajero', 'placeholder' => '7 u 8 digitos, con o sin DV']],
        'fields' => [
            ['name' => 'NOMBRE_PASAJERO', 'param' => 'p_nombre', 'label' => 'Nombre', 'type' => 'text'],
            ['name' => 'APELLIDO1_PASAJERO', 'param' => 'p_apellido1', 'label' => 'Primer apellido', 'type' => 'text'],
            ['name' => 'APELLIDO2_PASAJERO', 'param' => 'p_apellido2', 'label' => 'Segundo apellido', 'type' => 'text'],
            ['name' => 'TELEFONO', 'param' => 'p_telefono', 'label' => 'Telefono movil', 'type' => 'tel', 'placeholder' => '+56 9 1234 5678'],
            ['name' => 'CORREO_ELECTRONICO_PASAJERO', 'param' => 'p_correo', 'label' => 'Correo electronico', 'type' => 'email'],
        ],
    ],
];

$lookups = [
    'regiones'         => ['proc' => 'LEHZ_PS_LISTAR_REGIONES', 'value' => 'ID_REGION', 'label' => ['NOMBRE_REGION']],
    'regiones_chile'   => ['proc' => 'LEHZ_PS_LISTAR_REGIONES_CHILE', 'value' => 'VALOR', 'label' => ['ETIQUETA']],
    'comunas_chile'    => ['proc' => 'LEHZ_PS_LISTAR_COMUNAS_CHILE', 'value' => 'VALOR', 'label' => ['ETIQUETA']],
    'comunas'     => ['proc' => 'LEHZ_PS_LISTAR_COMUNAS', 'value' => 'ID_COMUNA', 'label' => ['NOMBRE_COMUNA', 'NOMBRE_REGION']],
    'terminales'  => ['proc' => 'LEHZ_PS_LISTAR_TERMINALES', 'value' => 'ID_TERMINAL', 'label' => ['NOMBRE', 'NOMBRE_COMUNA']],
    'empresas'    => ['proc' => 'LEHZ_PS_LISTAR_EMPRESAS', 'value' => 'RUT_EMPRESA', 'label' => ['RAZON_SOCIAL']],
    'buses'       => ['proc' => 'LEHZ_PS_LISTAR_BUSES', 'value' => 'PATENTE_BUS', 'label' => ['PATENTE_BUS', 'MARCA', 'MODELO']],
    'rutas'       => ['proc' => 'LEHZ_PS_LISTAR_RUTAS', 'value' => 'ID_RUTA', 'label' => ['ID_RUTA', 'NOMBRE_RUTA']],
    'conductores' => ['proc' => 'LEHZ_PS_LISTAR_CONDUCTORES', 'value' => 'RUT_CONDUCTOR', 'label' => ['RUT_CONDUCTOR', 'NOMBRE_CONDUCTOR', 'APELLIDO1_CONDUCTOR']],
    'mecanicos'   => ['proc' => 'LEHZ_PS_LISTAR_MECANICOS', 'value' => 'RUT_MECANICO', 'label' => ['RUT_MECANICO', 'NOMBRE_MECANICO', 'APELLIDO1_MECANICO']],
    'pasajeros'   => ['proc' => 'LEHZ_PS_LISTAR_PASAJEROS', 'value' => 'RUT_PASAJERO', 'label' => ['RUT_PASAJERO', 'NOMBRE_COMPLETO']],
    'viajes'      => ['proc' => 'LEHZ_PS_LISTAR_VIAJES', 'value' => 'ID_VIAJE', 'label' => ['ID_VIAJE', 'FECHA_VIAJE', 'NOMBRE_RUTA', 'HORA_SALIDA', 'TERMINAL_ORIGEN', 'TERMINAL_DESTINO']],
    'horarios'    => ['proc' => 'LEHZ_PS_LISTAR_HORARIOS', 'value' => 'ID_HORARIO', 'label' => ['ID_HORARIO', 'RANGO']],
    'roles'       => ['proc' => 'LEHZ_PS_LISTAR_ROLES', 'value' => 'NOMBRE_ROL', 'label' => ['NOMBRE_ROL']],
];

$reports = [
    'recaudacion'   => ['title' => 'Recaudacion por viaje', 'proc' => 'LEHZ_PS_REP_RECAUDACION_VIAJES'],
    'rep_mantencion'=> ['title' => 'Costos de mantenimiento', 'proc' => 'LEHZ_PS_REP_COSTOS_MANTENCION'],
    'ocupacion'     => ['title' => 'Ocupacion de asientos', 'proc' => 'LEHZ_PS_REP_OCUPACION_ASIENTOS'],
    'itinerario'    => ['title' => 'Itinerario y paradas', 'proc' => 'LEHZ_PS_REP_ITINERARIO_PARADAS'],
];

return [
    'maintainers' => $maintainers,
    'lookups'     => $lookups,
    'reports'     => $reports,
];
