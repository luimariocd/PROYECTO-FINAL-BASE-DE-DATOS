<?php
require_once __DIR__ . '/../config/database.php';

function auth_user(): ?array {
    return $_SESSION['user'] ?? null;
}

function auth_role(): string {
    return (string)($_SESSION['user']['role'] ?? '');
}

function auth_can(array $roles): bool {
    return in_array(auth_role(), $roles, true);
}

function auth_login(string $username, string $password): array {
    $rows = db_rows('LHAOMRJZ_PS_LOGIN', [
        'p_username' => trim($username),
        'p_password' => $password,
    ]);
    if (!$rows) {
        throw new RuntimeException('Usuario o contrasena incorrectos, o la cuenta esta inactiva.');
    }
    $u = $rows[0];
    session_regenerate_id(true);
    $_SESSION['user'] = [
        'id'       => $u['ID_USUARIO'],
        'username' => $u['USERNAME'],
        'name'     => $u['NOMBRE_COMPLETO'],
        'email'    => $u['EMAIL'],
        'role'     => $u['NOMBRE_ROL'],
    ];
    return $_SESSION['user'];
}

function auth_logout(): void {
    $_SESSION = [];
    if (ini_get('session.use_cookies')) {
        $p = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
    }
    session_destroy();
}

function require_login(): void {
    if (!auth_user()) {
        header('Location: ?page=login');
        exit;
    }
}

function require_role(array $roles): void {
    require_login();
    if (!auth_can($roles)) {
        auth_flash('error', 'Tu rol no tiene permisos para este modulo.');
        header('Location: ?page=dashboard');
        exit;
    }
}

function auth_flash(string $type, string $message): void {
    $_SESSION['flash'][] = ['type' => $type, 'message' => $message];
}

function auth_take_flash(): array {
    $items = $_SESSION['flash'] ?? [];
    unset($_SESSION['flash']);
    return $items;
}
