
-- DROP table CHERCHEUR
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CHERCHEUR CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- CREATE table CHERCHEUR
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE CHERCHEUR (
            id_chercheur NUMBER,
            nom VARCHAR2(100) NOT NULL,
            prenom VARCHAR2(100) NOT NULL,
            specialite VARCHAR2(50) NOT NULL CHECK (specialite IN (''Biotech'',''IA'',''Physique'',''Chimie'',''Mathématiques'',''Autre'')),
            date_embauche DATE NOT NULL CHECK (date_embauche <= SYSDATE),
            CONSTRAINT pk_chercheur PRIMARY KEY (id_chercheur)
        )';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Erreur creation CHERCHEUR : ' || SQLERRM);
END;
/
    

--DROP table PROJET

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PROJET CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--Create table PROJET
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE PROJET (
            id_projet NUMBER,
            titre VARCHAR2(200) NOT NULL,
            domaine VARCHAR2(100) NOT NULL,
            budget NUMBER NOT NULL CHECK (budget > 0),
            date_debut DATE NOT NULL,
            date_fin DATE NOT NULL CHECK (date_fin >= date_debut),
            id_chercheur_resp NUMBER NOT NULL,
            CONSTRAINT pk_projet PRIMARY KEY (id_projet),
            CONSTRAINT fk_projet_chercheur FOREIGN KEY (id_chercheur_resp)
                REFERENCES CHERCHEUR(id_chercheur)
        )';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Erreur creation PROJET : ' || SQLERRM);
END;
/
    

--DROP table EQUIPEMENT
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE EQUIPEMENT CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--CREATE table EQUIPEMENT
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE EQUIPEMENT (
            id_equipement NUMBER,
            nom VARCHAR2(100) NOT NULL,
            categorie VARCHAR2(100) NOT NULL,
            date_acquisition DATE NOT NULL CHECK (date_acquisition <= SYSDATE),
            etat VARCHAR2(20) NOT NULL CHECK (etat IN (''Disponible'',''En maintenance'',''Hors service'')),
            CONSTRAINT pk_equipement PRIMARY KEY (id_equipement)
        )';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Erreur creation EQUIPEMENT : ' || SQLERRM);
END;
/
    


--DROP table AFFECTATION_EQUIP
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE AFFECTATION_EQUIP CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--CREATE table AFFECTATION_EQUIP
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE AFFECTATION_EQUIP (
            id_affect NUMBER,
            id_projet NUMBER NOT NULL,
            id_equipement NUMBER NOT NULL,
            date_affectation DATE NOT NULL,
            duree_jours NUMBER NOT NULL CHECK (duree_jours > 0),
            CONSTRAINT pk_affect PRIMARY KEY (id_affect),
            CONSTRAINT fk_affect_projet FOREIGN KEY (id_projet)
                REFERENCES PROJET(id_projet),
            CONSTRAINT fk_affect_equipement FOREIGN KEY (id_equipement)
                REFERENCES EQUIPEMENT(id_equipement)
        )';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Erreur creation AFFECTATION_EQUIP : ' || SQLERRM);
END;
/
    

--DROP table EXPERIENCE
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE EXPERIENCE CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--CREATE table EXPERIENCE
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE EXPERIENCE (
            id_exp NUMBER,
            id_projet NUMBER NOT NULL,
            titre_exp VARCHAR2(200) NOT NULL,
            date_realisation DATE NOT NULL,
            resultat VARCHAR2(2000),
            statut VARCHAR2(20) NOT NULL CHECK (statut IN (''En cours'',''Terminée'',''Annulée'')),
            CONSTRAINT pk_experience PRIMARY KEY (id_exp),
            CONSTRAINT fk_exp_projet FOREIGN KEY (id_projet)
                REFERENCES PROJET(id_projet)
        )';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Erreur creation EXPERIENCE : ' || SQLERRM);
END;
/
    
--DROP table ECHANTILLON
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ECHANTILLON CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--CREATE table ECHANTILLON
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE ECHANTILLON (
            id_echantillon NUMBER,
            id_exp NUMBER NOT NULL,
            type_echantillon VARCHAR2(100) NOT NULL,
            date_prelevement DATE NOT NULL,
            mesure NUMBER CHECK (mesure >= 0),
            CONSTRAINT pk_echantillon PRIMARY KEY (id_echantillon),
            CONSTRAINT fk_echantillon_exp FOREIGN KEY (id_exp)
                REFERENCES EXPERIENCE(id_exp)
        )';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Erreur creation ECHANTILLON : ' || SQLERRM);
END;
/
    

--DROP table LOG_OPERATION
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE LOG_OPERATION CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

--CREATE table LOG_OPERATION
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE LOG_OPERATION (
            id_log NUMBER,
            table_concernee VARCHAR2(100) NOT NULL,
            operation VARCHAR2(20) NOT NULL CHECK (operation IN (''INSERT'',''UPDATE'',''DELETE'')),
            utilisateur VARCHAR2(100) NOT NULL,
            date_op DATE DEFAULT SYSDATE,
            description VARCHAR2(1000),
            CONSTRAINT pk_log PRIMARY KEY (id_log)
        )';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Erreur creation LOG_OPERATION : ' || SQLERRM);
END;
/
