-- Esta parte del código se encarga de ajustar tipos conservando los datos de LEHZ.
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE

-- Esta parte del código se encarga de quitar restricciones heredadas; los datos quedan en LEHZ_BAK_*.
BEGIN
  FOR r IN (SELECT table_name, constraint_name
              FROM user_constraints
             WHERE constraint_type IN ('R','P','U','C')
               AND constraint_name NOT LIKE 'BIN$%'
             ORDER BY CASE constraint_type WHEN 'R' THEN 1 ELSE 2 END, table_name) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || r.table_name || ' DROP CONSTRAINT ' || r.constraint_name;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

-- Esta parte del código se encarga de crear una funcion temporal para calcular el digito del RUT.
CREATE OR REPLACE FUNCTION LEHZ_FN_DV_TMP(p_rut IN VARCHAR2) RETURN VARCHAR2 IS
  v_sum NUMBER := 0;
  v_mul NUMBER := 2;
  v_dv  NUMBER;
BEGIN
  FOR i IN REVERSE 1 .. LENGTH(p_rut) LOOP
    v_sum := v_sum + TO_NUMBER(SUBSTR(p_rut, i, 1)) * v_mul;
    v_mul := v_mul + 1;
    IF v_mul > 7 THEN
      v_mul := 2;
    END IF;
  END LOOP;
  v_dv := 11 - MOD(v_sum, 11);
  IF v_dv = 11 THEN
    RETURN '0';
  ELSIF v_dv = 10 THEN
    RETURN 'K';
  ELSE
    RETURN TO_CHAR(v_dv);
  END IF;
END;
/

CREATE TABLE LEHZ_TMP_RUT_EMPRESA (OLD_RUT NUMBER, NEW_RUT VARCHAR2(12));

-- Esta parte del código se encarga de convertir el RUT y el telefono de empresa al formato requerido.
ALTER TABLE LEHZ_EMPRESA ADD (RUT_EMPRESA_NEW VARCHAR2(12), TELEFONO_EMPRESA_NEW VARCHAR2(15));

UPDATE LEHZ_EMPRESA
   SET RUT_EMPRESA_NEW = CASE WHEN LENGTH(TO_CHAR(RUT_EMPRESA)) = 8
                              THEN TO_CHAR(RUT_EMPRESA)
                              ELSE '9' || LPAD(TO_CHAR(RUT_EMPRESA), 7, '0')
                         END || '-' || LEHZ_FN_DV_TMP(
                              CASE WHEN LENGTH(TO_CHAR(RUT_EMPRESA)) = 8
                                   THEN TO_CHAR(RUT_EMPRESA)
                                   ELSE '9' || LPAD(TO_CHAR(RUT_EMPRESA), 7, '0')
                              END),
       TELEFONO_EMPRESA_NEW = CASE WHEN TELEFONO_EMPRESA IS NULL THEN NULL
                                   ELSE '+56' || TO_CHAR(TELEFONO_EMPRESA)
                              END;

INSERT INTO LEHZ_TMP_RUT_EMPRESA (OLD_RUT, NEW_RUT)
SELECT RUT_EMPRESA, RUT_EMPRESA_NEW FROM LEHZ_EMPRESA;

ALTER TABLE LEHZ_EMPRESA DROP COLUMN RUT_EMPRESA;
ALTER TABLE LEHZ_EMPRESA DROP COLUMN TELEFONO_EMPRESA;
ALTER TABLE LEHZ_EMPRESA RENAME COLUMN RUT_EMPRESA_NEW TO RUT_EMPRESA;
ALTER TABLE LEHZ_EMPRESA RENAME COLUMN TELEFONO_EMPRESA_NEW TO TELEFONO_EMPRESA;

-- Esta parte del código se encarga de ajustar el RUT de empresa, marca y modelo de buses.
ALTER TABLE LEHZ_BUS ADD (RUT_EMPRESA_NEW VARCHAR2(12), MARCA_NEW VARCHAR2(30), MODELO_NEW VARCHAR2(30));

UPDATE LEHZ_BUS b
   SET RUT_EMPRESA_NEW = (SELECT m.NEW_RUT FROM LEHZ_TMP_RUT_EMPRESA m WHERE m.OLD_RUT = b.RUT_EMPRESA),
       MARCA_NEW = MARCA,
       MODELO_NEW = MODELO;

ALTER TABLE LEHZ_BUS DROP COLUMN RUT_EMPRESA;
ALTER TABLE LEHZ_BUS DROP COLUMN MARCA;
ALTER TABLE LEHZ_BUS DROP COLUMN MODELO;
ALTER TABLE LEHZ_BUS RENAME COLUMN RUT_EMPRESA_NEW TO RUT_EMPRESA;
ALTER TABLE LEHZ_BUS RENAME COLUMN MARCA_NEW TO MARCA;
ALTER TABLE LEHZ_BUS RENAME COLUMN MODELO_NEW TO MODELO;

-- Esta parte del código se encarga de ajustar los datos de conductores.
ALTER TABLE LEHZ_CONDUCTOR ADD (RUT_CONDUCTOR_NEW VARCHAR2(12), RUT_EMPRESA_NEW VARCHAR2(12));

UPDATE LEHZ_CONDUCTOR c
   SET RUT_CONDUCTOR_NEW = TO_CHAR(RUT_CONDUCTOR) || '-' || LEHZ_FN_DV_TMP(TO_CHAR(RUT_CONDUCTOR)),
       RUT_EMPRESA_NEW = (SELECT m.NEW_RUT FROM LEHZ_TMP_RUT_EMPRESA m WHERE m.OLD_RUT = c.RUT_EMPRESA);

ALTER TABLE LEHZ_CONDUCTOR DROP COLUMN RUT_CONDUCTOR;
ALTER TABLE LEHZ_CONDUCTOR DROP COLUMN RUT_EMPRESA;
ALTER TABLE LEHZ_CONDUCTOR RENAME COLUMN RUT_CONDUCTOR_NEW TO RUT_CONDUCTOR;
ALTER TABLE LEHZ_CONDUCTOR RENAME COLUMN RUT_EMPRESA_NEW TO RUT_EMPRESA;

-- Esta parte del código se encarga de ajustar los datos de mecanicos.
ALTER TABLE LEHZ_MECANICO ADD (RUT_MECANICO_NEW VARCHAR2(12), RUT_EMPRESA_NEW VARCHAR2(12), ESPECIALIDAD_NEW VARCHAR2(40));

UPDATE LEHZ_MECANICO m
   SET RUT_MECANICO_NEW = TO_CHAR(RUT_MECANICO) || '-' || LEHZ_FN_DV_TMP(TO_CHAR(RUT_MECANICO)),
       RUT_EMPRESA_NEW = (SELECT x.NEW_RUT FROM LEHZ_TMP_RUT_EMPRESA x WHERE x.OLD_RUT = m.RUT_EMPRESA),
       ESPECIALIDAD_NEW = ESPECIALIDAD;

ALTER TABLE LEHZ_MECANICO DROP COLUMN RUT_MECANICO;
ALTER TABLE LEHZ_MECANICO DROP COLUMN RUT_EMPRESA;
ALTER TABLE LEHZ_MECANICO DROP COLUMN ESPECIALIDAD;
ALTER TABLE LEHZ_MECANICO RENAME COLUMN RUT_MECANICO_NEW TO RUT_MECANICO;
ALTER TABLE LEHZ_MECANICO RENAME COLUMN RUT_EMPRESA_NEW TO RUT_EMPRESA;
ALTER TABLE LEHZ_MECANICO RENAME COLUMN ESPECIALIDAD_NEW TO ESPECIALIDAD;

-- Esta parte del código se encarga de ajustar los datos de pasajeros.
ALTER TABLE LEHZ_PASAJERO ADD (RUT_PASAJERO_NEW VARCHAR2(12), CORREO_NEW VARCHAR2(80));

UPDATE LEHZ_PASAJERO
   SET RUT_PASAJERO_NEW = TO_CHAR(RUT_PASAJERO) || '-' || LEHZ_FN_DV_TMP(TO_CHAR(RUT_PASAJERO)),
       CORREO_NEW = CORREO_ELECTRONICO_PASAJERO;

ALTER TABLE LEHZ_PASAJERO DROP COLUMN RUT_PASAJERO;
ALTER TABLE LEHZ_PASAJERO DROP COLUMN CORREO_ELECTRONICO_PASAJERO;
ALTER TABLE LEHZ_PASAJERO RENAME COLUMN RUT_PASAJERO_NEW TO RUT_PASAJERO;
ALTER TABLE LEHZ_PASAJERO RENAME COLUMN CORREO_NEW TO CORREO_ELECTRONICO_PASAJERO;

DROP TABLE LEHZ_TMP_RUT_EMPRESA PURGE;
DROP FUNCTION LEHZ_FN_DV_TMP;

-- Esta parte del código se encarga de recrear las restricciones de LEHZTEST dentro de LEHZ.
BEGIN
  FOR r IN (SELECT constraint_name, table_name, constraint_type
              FROM all_constraints
             WHERE owner = 'LEHZTEST'
               AND generated = 'USER NAME'
               AND constraint_type IN ('P','U','C')
             ORDER BY CASE constraint_type WHEN 'P' THEN 1 WHEN 'U' THEN 2 ELSE 3 END, table_name) LOOP
    BEGIN
      EXECUTE IMMEDIATE REPLACE(REPLACE(
        DBMS_METADATA.GET_DDL('CONSTRAINT', r.constraint_name, 'LEHZTEST'),
        '"LEHZTEST".', ''), 'LEHZTEST.', '');
      DBMS_OUTPUT.PUT_LINE('CONSTRAINT OK: ' || r.constraint_name);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('CONSTRAINT ERROR: ' || r.constraint_name || ': ' || SQLERRM);
    END;
  END LOOP;

  FOR r IN (SELECT constraint_name
              FROM all_constraints
             WHERE owner = 'LEHZTEST'
               AND generated = 'USER NAME'
               AND constraint_type = 'R'
             ORDER BY constraint_name) LOOP
    BEGIN
      EXECUTE IMMEDIATE REPLACE(REPLACE(
        DBMS_METADATA.GET_DDL('REF_CONSTRAINT', r.constraint_name, 'LEHZTEST'),
        '"LEHZTEST".', ''), 'LEHZTEST.', '');
      DBMS_OUTPUT.PUT_LINE('FK OK: ' || r.constraint_name);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('FK ERROR: ' || r.constraint_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

-- Esta parte del código se encarga de crear los indices que no dependen de restricciones.
BEGIN
  FOR r IN (SELECT index_name FROM all_indexes
             WHERE owner='LEHZTEST' AND generated='N'
               AND index_name NOT IN (SELECT index_name FROM all_constraints WHERE owner='LEHZTEST' AND index_name IS NOT NULL)
             ORDER BY index_name) LOOP
    BEGIN
      EXECUTE IMMEDIATE REPLACE(REPLACE(
        DBMS_METADATA.GET_DDL('INDEX', r.index_name, 'LEHZTEST'),
        '"LEHZTEST".', ''), 'LEHZTEST.', '');
      DBMS_OUTPUT.PUT_LINE('INDEX OK: ' || r.index_name);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('INDEX ERROR: ' || r.index_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

-- Esta parte del código se encarga de recompilar los objetos que quedaron invalidos.
BEGIN
  FOR r IN (SELECT object_name, object_type FROM user_objects
             WHERE status='INVALID'
               AND object_type IN ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','TRIGGER','VIEW')) LOOP
    BEGIN
      IF r.object_type = 'PACKAGE BODY' THEN
        EXECUTE IMMEDIATE 'ALTER PACKAGE ' || r.object_name || ' COMPILE BODY';
      ELSE
        EXECUTE IMMEDIATE 'ALTER ' || r.object_type || ' ' || r.object_name || ' COMPILE';
      END IF;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
END;
/

COMMIT;
EXIT;
