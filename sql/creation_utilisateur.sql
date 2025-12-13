-- Creation des utilisateurs
--Adminsitrateur
create user admin_lab identified by adminlab#2025
   default tablespace users
   temporary tablespace temp
   quota unlimited on users;

--Gestionnaire de laboratoire
create user gest_lab identified by gestlab#2025
   default tablespace users
   temporary tablespace temp
   quota 100M on users;

--lecteur
create user lect_lab identified by lectlab#2025
   default tablespace users
   temporary tablespace temp
   quota 50M on users;

--Creation des roles
create role role_lab_admin;
create role role_lab_gest;
create role role_lab_lect;
create role role_lab_research;


-- Droits de connexion
grant create session to role_lab_research;

--Droits Admin
grant create table,
   create view,
   create sequence,
   create procedure,
   create trigger
to role_lab_admin;


--Assignation des roles
grant role_lab_admin,role_lab_research to admin_lab;
grant role_lab_gest,role_lab_research to gest_lab;
grant role_lab_lect,role_lab_research to lect_lab;