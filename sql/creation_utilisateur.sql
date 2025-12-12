--- ========================
-- Creation des utilisateurs
-- ========================

--Adminsitrateur
create user admin_lab identified by adminpwd#2025
   default tablespace users
   temporary tablespace temp
   quota unlimited on users;

--Gestionnaire de laboratoire
create user gest_lab identified by gestpwd#2025
   default tablespace users
   temporary tablespace temp
   quota 100M on users;

--lecteur
create user lect_lab identified by labpwd#2025
   default tablespace users
   temporary tablespace temp
   quota 50M on users;


-- Droits de connexion
grant create session to admin_lab;
grant create session to gest_lab;
grant create session to lect_lab;

-- Droits d'administration pour admin_lab
-- DBA donne tous les droits, à utiliser avec précaution
grant dba to admin_lab;

-- Droits pour le gestionnaire de laboratoire
grant execute any procedure to gest_lab;
grant insert on admin_lab.chercheur to gest_lab;
grant insert on admin_lab.projet to gest_lab;
grant insert on admin_lab.experience to gest_lab;
grant insert on admin_lab.echantillon to gest_lab;




-- Droits en lecture pour lect_lab
grant select on admin_lab.v_rapport_chercheurs to lect_lab;
grant select on admin_lab.v_rapport_projets to lect_lab;
grant select on admin_lab.v_statistiques to lect_lab;




-- Création de rôles personalisés++
create role role_lab_research;

--Droits pour le rôle role_lab_research
grant select,insert,update on admin_lab.chercheur to role_lab_research;
grant select on admin_lab.projet to role_lab_research;
grant select on admin_lab.equipement to role_lab_research;