<?php
$roles = lookup_options('roles');
$usuarios = db_rows('LEHZ_PS_LISTAR_USUARIOS');
?>
<div class="card mb-4">
    <div class="card-header">
        <h3 class="card-title mb-0">Crear usuario</h3>
        <div class="text-body-secondary small mt-1">La politica de contrasena, el correo y el rol se validan en Oracle.</div>
    </div>
    <div class="card-body">
        <form method="post" class="row g-3">
            <input type="hidden" name="action" value="user_create">
            <div class="col-md-6">
                <label class="form-label" for="userName">Nombre completo</label>
                <input class="form-control" id="userName" name="nombre_completo" required value="<?= h(old_value('nombre_completo')) ?>">
            </div>
            <div class="col-md-6">
                <label class="form-label" for="userLogin">Nombre de usuario</label>
                <input class="form-control" id="userLogin" name="username" required autocomplete="off" value="<?= h(old_value('username')) ?>">
            </div>
            <div class="col-md-6">
                <label class="form-label" for="userEmail">Correo electronico</label>
                <input class="form-control" id="userEmail" type="email" name="email" required value="<?= h(old_value('email')) ?>">
            </div>
            <div class="col-md-6">
                <label class="form-label" for="userRole">Rol</label>
                <select class="form-select" id="userRole" name="rol" required>
                    <option value="">Seleccione un rol...</option>
                    <?php foreach ($roles as $r): ?>
                        <option value="<?= h($r['value']) ?>" <?= (string)old_value('rol') === (string)$r['value'] ? 'selected' : '' ?>><?= h($r['label']) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="userPassword">Contrasena</label>
                <div class="input-group">
                    <input class="form-control" id="userPassword" type="password" name="password" required autocomplete="new-password" data-password>
                    <button class="btn btn-outline-secondary" type="button" data-toggle-password>Mostrar</button>
                </div>
            </div>
            <div class="col-md-6">
                <label class="form-label" for="userPasswordConfirm">Repetir contrasena</label>
                <div class="input-group">
                    <input class="form-control" id="userPasswordConfirm" type="password" name="password_confirm" required autocomplete="new-password" data-password>
                    <button class="btn btn-outline-secondary" type="button" data-toggle-password>Mostrar</button>
                </div>
            </div>
            <div class="col-12 d-flex justify-content-end">
                <button class="btn btn-primary" type="submit"><i class="bi bi-person-plus me-1"></i>Crear usuario</button>
            </div>
        </form>
    </div>
</div>

<div class="card mb-4">
    <div class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2">
        <h3 class="card-title mb-0">Usuarios del sistema</h3>
        <input class="form-control filter-input" type="search" data-filter="usuariosBody" placeholder="Filtrar usuarios..." aria-label="Filtrar usuarios" style="max-width: 18rem;">
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-striped table-hover align-middle mb-0">
                <thead>
                    <tr><th>ID</th><th>Usuario</th><th>Nombre</th><th>Correo</th><th>Rol</th><th>Estado</th><th>Creado</th><th class="text-end">Acciones</th></tr>
                </thead>
                <tbody id="usuariosBody">
                <?php foreach ($usuarios as $u): ?>
                    <tr>
                        <td><?= h($u['ID_USUARIO']) ?></td>
                        <td><?= h($u['USERNAME']) ?></td>
                        <td><?= h($u['NOMBRE_COMPLETO']) ?></td>
                        <td><?= h($u['EMAIL']) ?></td>
                        <td><?= h($u['NOMBRE_ROL']) ?></td>
                        <td>
                            <span class="badge <?= $u['ESTADO'] === 'ACTIVO' ? 'text-bg-success' : 'text-bg-secondary' ?>"><?= h($u['ESTADO']) ?></span>
                        </td>
                        <td><?= h($u['FECHA_CREACION']) ?></td>
                        <td class="text-end text-nowrap">
                            <form method="post" class="d-inline" onsubmit="return confirm('¿Cambiar el estado de esta cuenta?');">
                                <input type="hidden" name="action" value="user_state">
                                <input type="hidden" name="id_usuario" value="<?= h($u['ID_USUARIO']) ?>">
                                <input type="hidden" name="estado" value="<?= $u['ESTADO'] === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO' ?>">
                                <button class="btn btn-sm <?= $u['ESTADO'] === 'ACTIVO' ? 'btn-outline-danger' : 'btn-outline-success' ?>" type="submit" title="Cambiar estado">
                                    <i class="bi <?= $u['ESTADO'] === 'ACTIVO' ? 'bi-toggle-on' : 'bi-toggle-off' ?>"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>
