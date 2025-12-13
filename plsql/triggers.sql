-- TRG_PROJET_BEFORE_INSERT
CREATE OR REPLACE TRIGGER trg_projet_before_insert
BEFORE INSERT ON projet
FOR EACH ROW
BEGIN
    IF :NEW.budget <= 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Budget invalide');
    END IF;

    IF :NEW.date_fin < :NEW.date_debut THEN
        RAISE_APPLICATION_ERROR(-20020, 'Dates invalides');
    END IF;
END;
/

-- TRG_AFFECTATION_BEFORE_INSERT
CREATE OR REPLACE TRIGGER trg_affectation_before_insert
BEFORE INSERT ON affectation_equip
FOR EACH ROW
DECLARE
    v_etat_equip equipement.etat%TYPE;
BEGIN
    SELECT etat INTO v_etat_equip
    FROM equipement
    WHERE id_equipement = :NEW.id_equipement;

    IF v_etat_equip <> 'Disponible' THEN
        RAISE_APPLICATION_ERROR(-20030, 'Equipement non disponible');
    END IF;
END;
/


-- TRG_AFFECTATION_AFTER_INSERT
CREATE OR REPLACE TRIGGER trg_affectation_after_insert
AFTER INSERT ON affectation_equip
FOR EACH ROW
BEGIN
    UPDATE equipement
    SET etat = 'Occupe'
    WHERE id_equipement = :NEW.id_equipement;
END;
/

-- TRG_AFFECTATION_AFTER_DELETE
CREATE OR REPLACE TRIGGER trg_affectation_after_delete
AFTER DELETE ON affectation_equip
FOR EACH ROW
BEGIN
    UPDATE equipement
    SET etat = 'Disponible'
    WHERE id_equipement = :OLD.id_equipement;
END;
/

-- TRG_EXPERIENCE_AFTER_INSERT
CREATE OR REPLACE TRIGGER trg_experience_after_insert
AFTER INSERT ON experience
FOR EACH ROW
BEGIN
    INSERT INTO log_operation
    VALUES (seq_log.NEXTVAL, 'EXPERIENCE', 'INSERT', USER, SYSDATE, NULL);
END;
/

-- TRG_LOG_BEFORE_INSERT
CREATE OR REPLACE TRIGGER trg_log_before_insert
BEFORE INSERT ON log_operation
FOR EACH ROW
BEGIN
    :NEW.operation := UPPER(:NEW.operation);
    :NEW.date_op := NVL(:NEW.date_op, SYSDATE);
END;
/
