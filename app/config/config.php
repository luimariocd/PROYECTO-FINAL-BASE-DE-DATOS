<?php
// Esta parte del código se encarga de leer la configuracion de Oracle desde variables de entorno.
return [
    'host' => getenv('DB_HOST') ?: '127.0.0.1',
    'port' => getenv('DB_PORT') ?: '1521',
    'service' => getenv('DB_SERVICE') ?: 'FREEPDB1',
    'user' => getenv('DB_USER') ?: 'LEHZ',
    'password' => getenv('DB_PASSWORD') ?: 'Lehz1234',
    'charset' => 'AL32UTF8'
];