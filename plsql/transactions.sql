CREATE OR REPLACE PROCEDURE planifier_experience (
    p_id_projet     NUMBER,
    p_titre_exp     VARCHAR2,
    p_date_real     DATE,
    p_id_equipement NUMBER
) IS
    v_id_exp EXPERIENCE.id_exp%TYPE;
BEGIN
    INSERT INTO EXPERIENCE (
        id_exp,
        id_projet,
        titre_exp,
        date_realisation,
        statut
    )
    VALUES (
        seq_experience.NEXTVAL,
        p_id_projet,
        p_titre_exp,
        p_date_real,
        'En cours'
    )
    RETURNING id_exp INTO v_id_exp;

    SAVEPOINT avant_affectation_equipement;

    INSERT INTO AFFECTATION_EQUIP (
        id_affect,
        id_projet,
        id_equipement,
        date_affectation
    )
    VALUES (
        seq_affect.NEXTVAL,
        p_id_projet,
        p_id_equipement,
        SYSDATE
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO avant_affectation_equipement;
        COMMIT;
END;
/
