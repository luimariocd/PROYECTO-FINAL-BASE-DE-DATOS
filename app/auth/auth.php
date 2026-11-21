<?php
function require_login(): void { if(empty($_SESSION['user'])) { header('Location: ?page=login'); exit; } }
function can_manage(): bool { return in_array($_SESSION['user']['role'] ?? '', ['ADMINISTRADOR','OPERACIONES'], true); }
function is_admin(): bool { return ($_SESSION['user']['role'] ?? '') === 'ADMINISTRADOR'; }
function require_role(array $roles): void { require_login(); if(!in_array($_SESSION['user']['role'] ?? '',$roles,true)){ http_response_code(403); exit('No tienes permisos para acceder a este módulo.'); } }
