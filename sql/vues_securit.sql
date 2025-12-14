-- ========================================
-- SÉCURITÉ DES DONNÉES
-- ========================================
-- À exécuter avec : admin_lab@XEPDB1

-- ========================================
-- 1. VUES DE SÉCURITÉ
-- ========================================

/*
  Vue : V_PROJETS_PUBLICS

  Objectif :
    Vue de consultation réservée au rôle LECT_LAB.
    Affiche uniquement les projets terminés (date_fin < SYSDATE).
*/
create or replace view v_projets_publics as
   select id_projet,
          titre,
          domaine,
          budget,
          date_debut,
          date_fin,
          id_chercheur_resp
     from projet
    where date_fin < sysdate;
/

/*
  Vue : V_RESULTATS_EXPERIENCE

  Objectif :
    Vue enrichie combinant expériences, projets, chercheurs et échantillons.
    Réservée au rôle LECT_LAB.
*/
create or replace view v_resultats_experience as
   select e.id_exp,
          e.titre_exp,
          e.date_realisation,
          e.statut,
          p.titre as titre_projet,
          p.domaine as domaine_projet,
          c.nom as nom_chercheur,
          c.prenom as prenom_chercheur,
          count(ech.id_echantillon) as nb_echantillons,
          avg(ech.valeur_mesuree) as moyenne_mesure,
          e.resultat as resultat_exp,
          ( p.date_fin - p.date_debut ) as duree_projet
     from experience e
    inner join projet p
   on e.id_projet = p.id_projet
    inner join chercheur c
   on p.id_chercheur_resp = c.id_chercheur
     left join echantillon ech
   on e.id_exp = ech.id_exp
    group by e.id_exp,
             e.titre_exp,
             e.date_realisation,
             e.statut,
             p.titre,
             p.domaine,
             c.nom,
             c.prenom,
             e.resultat,
             p.date_fin,
             p.date_debut
    order by e.date_realisation desc;
/


-- ========================================
-- 2. CHIFFREMENT DES DONNÉES SENSIBLES
-- ========================================

/*
  Colonnes à chiffrer :
    - ECHANTILLON.valeur_mesuree
    - CHERCHEUR.nom

  Fonction de hachage SHA256 (unidirectionnel)
*/
create or replace function hash_nom (
   p_nom varchar2
) return varchar2 as
begin
   return standard_hash(
      p_nom,
      'SHA256'
   );
end;
/

-- Note : Pour chiffrement bidirectionnel, utiliser DBMS_CRYPTO
-- (nécessite modification des tables avec colonnes RAW/BLOB)


-- ========================================
-- 3. CHIFFREMENT DES DONNÉES SENSIBLES



-- ========================================
-- 4. GESTION DES PRIVILÈGES
-- ========================================

/*
  PRIVILÈGES POUR GEST_LAB
  Peut exécuter TOUTES les procédures SAUF supprimer_projet
*/

-- Procédures opérationnelles
grant execute on ajouter_projet to gest_lab;
grant execute on affecter_equipement to gest_lab;
grant execute on planifier_experience to gest_lab;
grant execute on journaliser_action to gest_lab;

-- Fonctions utilitaires
grant execute on calculer_duree_projet to gest_lab;
grant execute on verifier_disponibilite_equipement to gest_lab;
grant execute on moyenne_mesures_experience to gest_lab;

-- PAS DE GRANT sur supprimer_projet (restriction)


/*
  PRIVILÈGES POUR LECT_LAB
  Accès lecture seule via vues et fonctions de reporting
*/

-- Vues de sécurité
grant select on v_projets_publics to lect_lab;
grant select on v_resultats_experience to lect_lab;

-- Fonctions de reporting
grant execute on statistiques_equipements to lect_lab;
grant execute on budget_moyen_par_domaine to lect_lab;
grant execute on rapport_projets_par_chercheur to lect_lab;
grant execute on rapport_activite_projets to lect_lab;

-- Interdire l'accès direct aux tables
revoke all on projet from lect_lab;
revoke all on chercheur from lect_lab;
revoke all on experience from lect_lab;
revoke all on equipement from lect_lab;
revoke all on echantillon from lect_lab;
revoke all on affectation_equip from lect_lab;
revoke all on log_operation from lect_lab;



-- ========================================
-- 5. JOURNALISATION AUTOMATIQUE
-- ========================================

/*
  TRIGGERS DE JOURNALISATION
  Enregistrent automatiquement les INSERT et DELETE dans LOG_OPERATION
*/

-- Trigger sur PROJET
create or replace trigger trg_projet_audit after
   insert or delete on projet
   for each row
begin
   if inserting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'PROJET',
                 'INSERT',
                 'Nouveau projet ID='
                 || :new.id_projet
                 || ', Titre: '
                 || :new.titre );
   elsif deleting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'PROJET',
                 'DELETE',
                 'Suppression projet ID='
                 || :old.id_projet
                 || ', Titre: '
                 || :old.titre );
   end if;
end;
/

-- Trigger sur EXPERIENCE
create or replace trigger trg_experience_audit after
   insert or delete on experience
   for each row
begin
   if inserting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'EXPERIENCE',
                 'INSERT',
                 'Nouvelle expérience ID='
                 || :new.id_exp
                 || ', Titre: '
                 || :new.titre_exp );
   elsif deleting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'EXPERIENCE',
                 'DELETE',
                 'Suppression expérience ID='
                 || :old.id_exp
                 || ', Titre: '
                 || :old.titre_exp );
   end if;
end;
/

-- Trigger sur EQUIPEMENT
create or replace trigger trg_equipement_audit after
   insert or delete on equipement
   for each row
begin
   if inserting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'EQUIPEMENT',
                 'INSERT',
                 'Nouvel équipement ID='
                 || :new.id_equipement
                 || ', Nom: '
                 || :new.nom_equipement );
   elsif deleting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'EQUIPEMENT',
                 'DELETE',
                 'Suppression équipement ID='
                 || :old.id_equipement
                 || ', Nom: '
                 || :old.nom_equipement );
   end if;
end;
/

-- Trigger sur AFFECTATION_EQUIP
create or replace trigger trg_affectation_audit after
   insert or delete on affectation_equip
   for each row
begin
   if inserting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'AFFECTATION_EQUIP',
                 'INSERT',
                 'Affectation équipement ID='
                 || :new.id_equipement
                 || ' au projet ID='
                 || :new.id_projet );
   elsif deleting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'AFFECTATION_EQUIP',
                 'DELETE',
                 'Suppression affectation équipement ID='
                 || :old.id_equipement
                 || ' du projet ID='
                 || :old.id_projet );
   end if;
end;
/

-- Trigger sur ECHANTILLON
create or replace trigger trg_echantillon_audit after
   insert or delete on echantillon
   for each row
begin
   if inserting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'ECHANTILLON',
                 'INSERT',
                 'Nouvel échantillon ID='
                 || :new.id_echantillon
                 || ' pour expérience ID='
                 || :new.id_exp );
   elsif deleting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'ECHANTILLON',
                 'DELETE',
                 'Suppression échantillon ID='
                 || :old.id_echantillon
                 || ' de expérience ID='
                 || :old.id_exp );
   end if;
end;
/

-- Trigger sur CHERCHEUR
create or replace trigger trg_chercheur_audit after
   insert or delete on chercheur
   for each row
begin
   if inserting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'CHERCHEUR',
                 'INSERT',
                 'Nouveau chercheur ID='
                 || :new.id_chercheur
                 || ', Nom: '
                 || :new.prenom
                 || ' '
                 || :new.nom );
   elsif deleting then
      insert into log_operation (
         date_operation,
         nom_utilisateur,
         nom_table,
         type_operation,
         description
      ) values ( sysdate,
                 user,
                 'CHERCHEUR',
                 'DELETE',
                 'Suppression chercheur ID='
                 || :old.id_chercheur
                 || ', Nom: '
                 || :old.prenom
                 || ' '
                 || :old.nom );
   end if;
end;
/