/*
Matias Valenzuela Gonzalez
Modelamiento de Datos S2
Profesor: Carlos Castro
Fecha: 26/06/2025
RUT: 21683053-9
*/

--------------------------------------------------
-- BORRADO DE TABLAS
--------------------------------------------------

DROP TABLE MFVG_CONSULTA;
DROP TABLE MFVG_MASCOTA;
DROP TABLE MFVG_DIAGNOSTICO;
DROP TABLE MFVG_VETERINARIO;
DROP TABLE MFVG_RAZA;
DROP TABLE MFVG_DUENO;
DROP TABLE MFVG_ESPECIALIDAD;
DROP TABLE MFVG_NUM_CASA_DUENO;
DROP TABLE MFVG_ESPECIE;
DROP TABLE MFVG_CALLE;
DROP TABLE MFVG_CIUDAD;

--------------------------------------------------
-- CREACION DE TABLAS
--------------------------------------------------

CREATE TABLE MFVG_ESPECIALIDAD(
    cod_especialidad NUMBER,
    nombre_especialidad VARCHAR2(200),
    CONSTRAINT PK_MFVG_ESPECIALIDAD
        PRIMARY KEY(cod_especialidad)
);

CREATE TABLE MFVG_ESPECIE(
    cod_especie NUMBER,
    nombre_especie VARCHAR2(200),
    CONSTRAINT PK_MFVG_ESPECIE
        PRIMARY KEY(cod_especie)
);

CREATE TABLE MFVG_CIUDAD(
    cod_ciudad NUMBER,
    nombre_ciudad VARCHAR2(200),
    CONSTRAINT PK_MFVG_CIUDAD
        PRIMARY KEY(cod_ciudad)
);

CREATE TABLE MFVG_DIAGNOSTICO(
    cod_diagnostico NUMBER,
    nombre_diagnostico VARCHAR2(200),
    CONSTRAINT PK_MFVG_DIAGNOSTICO
        PRIMARY KEY(cod_diagnostico)
);

CREATE TABLE MFVG_VETERINARIO(
    cod_veterinario NUMBER,
    nombre_vet VARCHAR2(200),
    apellido1_vet VARCHAR2(200),
    apellido2_vet VARCHAR2(200),
    telefono_vet NUMBER,
    cod_especialidad NUMBER,

    CONSTRAINT PK_MFVG_VETERINARIO
        PRIMARY KEY(cod_veterinario),

    CONSTRAINT FK_MFVG_VETERINARIO_ESPECIALIDAD
        FOREIGN KEY(cod_especialidad)
        REFERENCES MFVG_ESPECIALIDAD(cod_especialidad)
);

CREATE TABLE MFVG_RAZA(
    cod_raza NUMBER,
    nombre_raza VARCHAR2(200),
    cod_especie NUMBER,

    CONSTRAINT PK_MFVG_RAZA
        PRIMARY KEY(cod_raza),

    CONSTRAINT FK_MFVG_RAZA_ESPECIE
        FOREIGN KEY(cod_especie)
        REFERENCES MFVG_ESPECIE(cod_especie)
);

CREATE TABLE MFVG_CALLE(
    cod_calle NUMBER,
    nombre_calle VARCHAR2(200),
    cod_ciudad NUMBER,

    CONSTRAINT PK_MFVG_CALLE
        PRIMARY KEY(cod_calle),

    CONSTRAINT FK_MFVG_CALLE_CIUDAD
        FOREIGN KEY(cod_ciudad)
        REFERENCES MFVG_CIUDAD(cod_ciudad)
);

CREATE TABLE MFVG_NUM_CASA_DUENO(
    cod_num_casa NUMBER,
    num_casa NUMBER,
    cod_calle NUMBER,

    CONSTRAINT PK_MFVG_NUM_CASA_DUENO
        PRIMARY KEY(cod_num_casa),

    CONSTRAINT FK_MFVG_NUM_CASA_DUENO_CALLE
        FOREIGN KEY(cod_calle)
        REFERENCES MFVG_CALLE(cod_calle)
);

CREATE TABLE MFVG_DUENO(
    cod_dueno NUMBER,
    nombre_due VARCHAR2(200),
    apellido1_due VARCHAR2(200),
    apellido2_due VARCHAR2(200),
    telefono_due NUMBER,
    num_casa_dueno NUMBER,

    CONSTRAINT PK_MFVG_DUENO
        PRIMARY KEY(cod_dueno),

    CONSTRAINT FK_MFVG_DUENO_NUM_CASA
        FOREIGN KEY(num_casa_dueno)
        REFERENCES MFVG_NUM_CASA_DUENO(cod_num_casa)
);

CREATE TABLE MFVG_MASCOTA(
    cod_mascota NUMBER,
    nombre_mas VARCHAR2(200),
    fecha_nacimiento DATE,
    cod_raza NUMBER,
    cod_dueno NUMBER,

    CONSTRAINT PK_MFVG_MASCOTA
        PRIMARY KEY(cod_mascota),

    CONSTRAINT FK_MFVG_MASCOTA_RAZA
        FOREIGN KEY(cod_raza)
        REFERENCES MFVG_RAZA(cod_raza),

    CONSTRAINT FK_MFVG_MASCOTA_DUENO
        FOREIGN KEY(cod_dueno)
        REFERENCES MFVG_DUENO(cod_dueno)
);

CREATE TABLE MFVG_CONSULTA(
    cod_veterinario NUMBER,
    cod_mascota NUMBER,
    fecha_consulta DATE,
    tratamiento VARCHAR2(200),
    cod_diagnostico NUMBER,

    CONSTRAINT PK_MFVG_CONSULTA
        PRIMARY KEY(cod_veterinario,cod_mascota),

    CONSTRAINT FK_MFVG_CONSULTA_VETERINARIO
        FOREIGN KEY(cod_veterinario)
        REFERENCES MFVG_VETERINARIO(cod_veterinario),

    CONSTRAINT FK_MFVG_CONSULTA_MASCOTA
        FOREIGN KEY(cod_mascota)
        REFERENCES MFVG_MASCOTA(cod_mascota),

    CONSTRAINT FK_MFVG_CONSULTA_DIAGNOSTICO
        FOREIGN KEY(cod_diagnostico)
        REFERENCES MFVG_DIAGNOSTICO(cod_diagnostico)
);

--------------------------------------------------
-- INSERTS
--------------------------------------------------

-- ESPECIALIDAD

INSERT INTO MFVG_ESPECIALIDAD
VALUES(1,'Medicina General');

INSERT INTO MFVG_ESPECIALIDAD
VALUES(2,'Cirugia');

-- VETERINARIO

INSERT INTO MFVG_VETERINARIO
VALUES(1,'Carolina','Perez','Soto',987654321,1);

INSERT INTO MFVG_VETERINARIO
VALUES(2,'Diego','Munoz','Rojas',912345678,2);

-- ESPECIE

INSERT INTO MFVG_ESPECIE
VALUES(1,'Perro');

INSERT INTO MFVG_ESPECIE
VALUES(2,'Gato');

-- RAZA

INSERT INTO MFVG_RAZA
VALUES(1,'Labrador',1);

INSERT INTO MFVG_RAZA
VALUES(2,'Siames',2);

-- CIUDAD

INSERT INTO MFVG_CIUDAD
VALUES(1,'Santiago');

INSERT INTO MFVG_CIUDAD
VALUES(2,'Valparaiso');

-- CALLE

INSERT INTO MFVG_CALLE
VALUES(1,'Avenida Libertador',1);

INSERT INTO MFVG_CALLE
VALUES(2,'Calle Prat',2);

-- NUMERO CASA

INSERT INTO MFVG_NUM_CASA_DUENO
VALUES(1,1250,1);

INSERT INTO MFVG_NUM_CASA_DUENO
VALUES(2,450,2);

--------------------------------------------------
-- DUEÑOS
--------------------------------------------------

INSERT INTO MFVG_DUENO
VALUES(1,'Matias','Valenzuela','Gonzalez',986507986,1);

INSERT INTO MFVG_DUENO
VALUES(
2,'Maria','Gonzalez','Diaz',987123456,2);

--------------------------------------------------
-- MASCOTAS
--------------------------------------------------

INSERT INTO MFVG_MASCOTA
VALUES(1,'Rocky',TO_DATE('15/03/2020','DD/MM/YYYY'),1,1);

INSERT INTO MFVG_MASCOTA
VALUES(2,'Mishi',TO_DATE('22/08/2022','DD/MM/YYYY'),2,2);

--------------------------------------------------
-- DIAGNOSTICOS
--------------------------------------------------

INSERT INTO MFVG_DIAGNOSTICO
VALUES(1,'Otitis');

INSERT INTO MFVG_DIAGNOSTICO
VALUES(2,'Dermatitis');

--------------------------------------------------
-- CONSULTAS
--------------------------------------------------

INSERT INTO MFVG_CONSULTA
VALUES(1,1,TO_DATE('26/06/2025','DD/MM/YYYY'),'Limpieza de oido y antibioticos',1);

INSERT INTO MFVG_CONSULTA
VALUES(2,2,TO_DATE('26/06/2025','DD/MM/YYYY'),'Crema dermatologica',2);

--------------------------------------------------
-- ACTUALIZACIONES
--------------------------------------------------

-- Cambio telefono Carolina Perez

UPDATE MFVG_VETERINARIO
SET telefono_vet = 998887766
WHERE cod_veterinario = 1;

--------------------------------------------------

-- Diego cambia de especialidad

UPDATE MFVG_VETERINARIO
SET cod_especialidad = 1
WHERE cod_veterinario = 2;

--------------------------------------------------

-- Labrador cambia de nombre

UPDATE MFVG_RAZA
SET nombre_raza = 'Labrador Retriever'
WHERE cod_raza = 1;

--------------------------------------------------

-- Diagnostico cambia de nombre

UPDATE MFVG_DIAGNOSTICO
SET nombre_diagnostico = 'Dermatitis Alergica'
WHERE cod_diagnostico = 2;

--------------------------------------------------

-- Actualizar tratamiento primera consulta

UPDATE MFVG_CONSULTA
SET tratamiento =
'Limpieza de oido y antibioticos, control en 10 dias'
WHERE cod_veterinario = 1
AND cod_mascota = 1;

--------------------------------------------------
-- REGISTROS EXTRA
-- (Necesarios para poder realizar los DELETE pedidos)
--------------------------------------------------

INSERT INTO MFVG_ESPECIALIDAD
VALUES(3,'Traumatologia');

INSERT INTO MFVG_RAZA
VALUES(3,'Pastor Aleman',1);

INSERT INTO MFVG_DIAGNOSTICO
VALUES(3,'Resfriado');

INSERT INTO MFVG_DUENO
VALUES(3,'Pedro','Lopez','Perez',998887111,1);

--------------------------------------------------
-- BORRADOS
--------------------------------------------------

-- Eliminar especialidad sin uso
DELETE FROM MFVG_ESPECIALIDAD
WHERE cod_especialidad = 3;

--------------------------------------------------

-- Eliminar raza sin mascotas
DELETE FROM MFVG_RAZA
WHERE cod_raza = 3;

--------------------------------------------------

-- Eliminar ultima consulta
DELETE FROM MFVG_CONSULTA
WHERE cod_veterinario = 2
AND cod_mascota = 2;

--------------------------------------------------

-- Eliminar diagnostico sin consultas
DELETE FROM MFVG_DIAGNOSTICO
WHERE cod_diagnostico = 3;

--------------------------------------------------

-- Eliminar dueño sin mascotas
DELETE FROM MFVG_DUENO
WHERE cod_dueno = 3;

--------------------------------------------------
-- CONSULTAS
--------------------------------------------------

-- Ver todos los veterinarios
SELECT *
FROM MFVG_VETERINARIO;

--------------------------------------------------

-- Nombre y apellido de los dueños
SELECT nombre_due, apellido1_due
FROM MFVG_DUENO;

--------------------------------------------------

-- Nombre de las mascotas
SELECT nombre_mas
FROM MFVG_MASCOTA;

--------------------------------------------------

-- Nombre de las especies
SELECT nombre_especie
FROM MFVG_ESPECIE;

--------------------------------------------------

-- Mostrar todos los diagnósticos
SELECT *
FROM MFVG_DIAGNOSTICO;

--------------------------------------------------

-- Mostrar nombre y fecha de las consultas
SELECT fecha_consulta, tratamiento
FROM MFVG_CONSULTA;