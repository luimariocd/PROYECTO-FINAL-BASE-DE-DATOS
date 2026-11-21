<?php

function require_login(): void {
    if (empty($_SESSION['user'])) {
        header('Location: ?page=login');
        exit;
    }
}

function current_role(): string {
    return strtoupper((string)($_SESSION['user']['role'] ?? ''));
}

function is_admin(): bool {
    return current_role() === 'ADMINISTRADOR';
}

function can_manage(): bool {
    return in_array(current_role(), ['ADMINISTRADOR', 'OPERACIONES'], true);
}

function require_role(array $roles): void {
    require_login();
    if (!in_array(current_role(), array_map('strtoupper', $roles), true)) {
        http_response_code(403);
        exit('No tienes permisos para acceder a este módulo.');
    }
}

/**
 * Define qué módulos puede ver cada perfil. La base de datos sigue siendo
 * la que valida los datos; esto solo controla la navegación y el acceso.
 */
function page_allowed(string $page): bool {
    $role = current_role();
    if ($page === 'dashboard') return true;
    if ($page === 'seg_usuarios') return $role === 'ADMINISTRADOR';

    if (str_starts_with($page, 'm_')) {
        return in_array($role, ['ADMINISTRADOR', 'OPERACIONES'], true);
    }
    if ($page === 'g_venta') {
        return in_array($role, ['ADMINISTRADOR', 'VENDEDOR'], true);
    }
    if (in_array($page, ['g_viaje', 'g_conduce', 'g_mantencion', 'g_terminal'], true)) {
        return in_array($role, ['ADMINISTRADOR', 'OPERACIONES'], true);
    }
    if ($page === 'r_recaudacion') {
        return in_array($role, ['ADMINISTRADOR', 'OPERACIONES', 'VENDEDOR'], true);
    }
    if (str_starts_with($page, 'r_')) {
        return in_array($role, ['ADMINISTRADOR', 'OPERACIONES'], true);
    }
    return false;
}

function require_page(string $page): void {
    require_login();
    if (!page_allowed($page)) {
        http_response_code(403);
        exit('No tienes permisos para acceder a este módulo.');
    }
}
