-- Creation des utilisateurs
--Adminsitrateur
create user admin_lab identified by AdminLab#2025
   default tablespace users
   temporary tablespace temp
   quota unlimited on users;

--Gestionnaire de laboratoire
create user gest_lab identified by GestLab#2025
   default tablespace users
   temporary tablespace temp
   quota unlimited on users;

--lecteur
create user lect_lab identified by LectLab#2025
   default tablespace users
   temporary tablespace temp
   quota unlimited on users;

--Creation des roles
CREATE ROLE role_lab_admin;
CREATE ROLE role_lab_gest;
CREATE ROLE role_lab_lect;
CREATE ROLE role_lab_research;


-- Droits de connexion
GRANT CREATE SESSION TO role_lab_research;

--Droits Admin
GRANT CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
CREATE PROCEDURE, CREATE TRIGGER
TO role_lab_admin;


--Assignation des roles
GRANT role_lab_admin, role_lab_research TO admin_lab;
GRANT role_lab_gest, role_lab_research TO gest_lab;
GRANT role_lab_lect, role_lab_research TO lect_lab;


