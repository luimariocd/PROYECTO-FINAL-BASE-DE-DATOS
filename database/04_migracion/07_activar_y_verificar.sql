SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE

BEGIN
  FOR r IN (SELECT trigger_name FROM user_triggers WHERE status='DISABLED') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TRIGGER ' || r.trigger_name || ' ENABLE';
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('TRIGGER ERROR: ' || r.trigger_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

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
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('COMPILE ERROR: ' || r.object_type || ' ' || r.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

COMMIT;
EXIT;
