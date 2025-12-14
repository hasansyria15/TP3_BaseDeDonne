-- Procédure : AJOUTER_PROJET
create or replace procedure ajouter_projet (
 p_id_projet projet.id_projet%type,
 p_titre projet.titre%type,
 p_domaine projet.domaine%type,
 p_budget projet.budget%type,
 p_date_debut projet.date_debut%type,
 p_date_fin projet.date_fin%type,
 p_id_chercheur_resp projet.id_chercheur_resp%type
) is
 v_exists number;
begin
 if p_budget <= 0 then
  raise_application_error(-20001,'Le budget doit être supérieur à zéro.');
 end if;

 if p_date_fin < p_date_debut then
  raise_application_error(-20002,'La date de fin doit être postérieure à la date de début.');
 end if;

 select count(*)
  into v_exists
  from chercheur
 where id_chercheur = p_id_chercheur_resp;

 if v_exists = 0 then
  raise_application_error(-20003,'Le chercheur responsable spécifié n''existe pas.');
 end if;

 insert into projet (
  id_projet,
  titre,
  domaine,
  budget,
  date_debut,
  date_fin,
  id_chercheur_resp
 ) values (
  p_id_projet,
  p_titre,
  p_domaine,
  p_budget,
  p_date_debut,
  p_date_fin,
  p_id_chercheur_resp
 );

 commit;
exception
 when others then
  rollback;
  raise;
end ajouter_projet;
/

-- Procédure : AFFECTER_EQUIPEMENT
create or replace procedure affecter_equipement (
 p_id_projet affectation_equip.id_projet%type,
 p_id_equipement affectation_equip.id_equipement%type,
 p_date_affectation affectation_equip.date_affectation%type,
 p_duree_jours affectation_equip.duree_jours%type
) is
 v_dispo number;
begin
 if p_duree_jours <= 0 then
  raise_application_error(-20011,'La durée doit être supérieure à zéro.');
 end if;

 select count(*)
  into v_dispo
  from equipement
 where id_equipement = p_id_equipement
   and etat = 'Disponible';

 if v_dispo = 0 then
  raise_application_error(-20012,'L''équipement spécifié n''est pas disponible.');
 end if;

 insert into affectation_equip (
  id_projet,
  id_equipement,
  date_affectation,
  duree_jours
 ) values (
  p_id_projet,
  p_id_equipement,
  p_date_affectation,
  p_duree_jours
 );

 commit;
exception
 when others then
  rollback;
  raise;
end affecter_equipement;
/

-- Procédure : PLANIFIER_EXPERIENCE
create or replace procedure planifier_experience (
 p_id_projet experience.id_projet%type,
 p_titre_exp experience.titre_exp%type,
 p_date_realisation experience.date_realisation%type,
 p_statut experience.statut%type,
 p_resultat experience.resultat%type,
 p_id_equipement equipement.id_equipement%type,
 p_duree_jours affectation_equip.duree_jours%type
) is
 v_exists number;
 v_id_exp experience.id_exp%type;
begin
 select count(*)
  into v_exists
  from projet
 where id_projet = p_id_projet;

 if v_exists = 0 then
  raise_application_error(-20020,'Projet inexistant.');
 end if;

 if p_statut not in ('En cours','Terminée','Annulée') then
  raise_application_error(-20021,'Statut invalide.');
 end if;

 if p_statut = 'Terminée'
  and (p_resultat is null or trim(p_resultat) is null)
 then
  raise_application_error(-20022,'Le résultat est obligatoire pour une expérience terminée.');
 end if;

 savepoint sp_planif;

 insert into experience (
  id_exp,
  id_projet,
  titre_exp,
  date_realisation,
  resultat,
  statut
 ) values (
  experience_seq.nextval,
  p_id_projet,
  p_titre_exp,
  p_date_realisation,
  p_resultat,
  p_statut
 ) returning id_exp into v_id_exp;

 savepoint sp_avant_affect;
 begin
  affecter_equipement(
   p_id_projet => p_id_projet,
   p_id_equipement => p_id_equipement,
   p_date_affectation => p_date_realisation,
   p_duree_jours => p_duree_jours
  );
 exception
  when others then
   rollback to sp_avant_affect;
   raise;
 end;

 journaliser_action(
  p_table => 'EXPERIENCE',
  p_operation => 'INSERT',
  p_description => 'Planification experience ID='
                   || v_id_exp
                   || ', projet='
                   || p_id_projet
                   || ', equip='
                   || p_id_equipement
 );

 commit;
exception
 when others then
  rollback to sp_planif;
  raise;
end planifier_experience;
/

-- Procédure : SUPPRIMER_PROJET
create or replace procedure supprimer_projet (
 p_id_projet in projet.id_projet%type
) as
 cursor c_projet is
  select id_projet
   from projet
  where id_projet = p_id_projet
  for update;

 v_id_projet projet.id_projet%type;
begin
 open c_projet;
 fetch c_projet into v_id_projet;
 if c_projet%notfound then
  close c_projet;
  raise no_data_found;
 end if;
 close c_projet;

 delete from echantillon
  where id_exp in (
   select id_exp
    from experience
   where id_projet = p_id_projet
  );

 delete from experience
  where id_projet = p_id_projet;

 delete from affectation_equip
  where id_projet = p_id_projet;

 delete from projet
  where id_projet = p_id_projet;

 journaliser_action(
  p_table => 'PROJET',
  p_operation => 'DELETE',
  p_description => 'Suppression du projet ' || p_id_projet
 );

 commit;
exception
 when no_data_found then
  rollback;
  raise_application_error(-20001,'Projet ' || p_id_projet || ' introuvable.');
 when others then
  rollback;
  raise_application_error(-20002,'Erreur suppression projet ' || p_id_projet || ' : ' || sqlerrm);
end;
/

-- Procédure : JOURNALISER_ACTION
create or replace procedure journaliser_action (
 p_table log_operation.table_concernee%type,
 p_operation log_operation.operation%type,
 p_description log_operation.description%type
) is
 v_op log_operation.operation%type;
begin
 v_op := upper(trim(p_operation));
 if v_op not in ('INSERT','UPDATE','DELETE') then
  raise_application_error(-20030,'Operation invalide (INSERT/UPDATE/DELETE).');
 end if;

 insert into log_operation (
  id_log,
  table_concernee,
  operation,
  utilisateur,
  date_op,
  description
 ) values (
  log_operation_seq.nextval,
  p_table,
  v_op,
  user,
  sysdate,
  p_description
 );

 commit;
exception
 when others then
  rollback;
  raise;
end journaliser_action;
/
