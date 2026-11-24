<?php
$roles = lookup_options('roles');
$usuarios = db_rows('LEHZ_PS_LISTAR_USUARIOS');
?>
<section class="panel form-panel">
    <div class="panel-head">
        <div><span class="eyebrow">SEGURIDAD</span><h3>Crear usuario</h3><p>La politica de contrasena, el correo y el rol se validan en Oracle.</p></div>
    </div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="user_create">
        <label>Nombre completo
            <input name="nombre_completo" required value="<?= h(old_value('nombre_completo')) ?>">
        </label>
        <label>Nombre de usuario
            <input name="username" required autocomplete="off" value="<?= h(old_value('username')) ?>">
        </label>
        <label>Correo electronico
            <input type="email" name="email" required value="<?= h(old_value('email')) ?>">
        </label>
        <label>Rol
            <select name="rol" required>
                <option value="">Seleccione un rol...</option>
                <?php foreach ($roles as $r): ?>
                    <option value="<?= h($r['value']) ?>" <?= (string)old_value('rol') === (string)$r['value'] ? 'selected' : '' ?>><?= h($r['label']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>Contrasena
            <span class="password-field">
                <input type="password" name="password" required autocomplete="new-password" data-password>
                <button type="button" class="toggle-pass" data-toggle-password>Mostrar</button>
            </span>
        </label>
        <label>Repetir contrasena
            <span class="password-field">
                <input type="password" name="password_confirm" required autocomplete="new-password" data-password>
                <button type="button" class="toggle-pass" data-toggle-password>Mostrar</button>
            </span>
        </label>
        <div class="form-actions"><button class="btn primary" type="submit">Crear usuario</button></div>
    </form>
</section>

<section class="panel">
    <div class="panel-head"><div><span class="eyebrow">CUENTAS</span><h3>Usuarios del sistema</h3></div></div>
    <div class="table-wrap">
        <table>
            <thead><tr><th>ID</th><th>Usuario</th><th>Nombre</th><th>Correo</th><th>Rol</th><th>Estado</th><th>Creado</th><th>Acciones</th></tr></thead>
            <tbody>
            <?php foreach ($usuarios as $u): ?>
                <tr>
                    <td><?= h($u['ID_USUARIO']) ?></td>
                    <td><?= h($u['USERNAME']) ?></td>
                    <td><?= h($u['NOMBRE_COMPLETO']) ?></td>
                    <td><?= h($u['EMAIL']) ?></td>
                    <td><?= h($u['NOMBRE_ROL']) ?></td>
                    <td><span class="badge"><?= h($u['ESTADO']) ?></span></td>
                    <td><?= h($u['FECHA_CREACION']) ?></td>
                    <td class="actions">
                        <form method="post" class="inline" onsubmit="return confirm('¿Cambiar el estado de esta cuenta?');">
                            <input type="hidden" name="action" value="user_state">
                            <input type="hidden" name="id_usuario" value="<?= h($u['ID_USUARIO']) ?>">
                            <input type="hidden" name="estado" value="<?= $u['ESTADO'] === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO' ?>">
                            <button class="icon-btn" type="submit" title="Cambiar estado"><?= $u['ESTADO'] === 'ACTIVO' ? '⊘' : '✓' ?></button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</section>
