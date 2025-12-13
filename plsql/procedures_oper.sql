-------------------
--Procedures-------
-------------------

/*
  Procédure : AJOUTER_PROJET

  Objectif :
    Ajouter un nouveau projet dans la base de données avec validation
    des données et vérification de l'existence du chercheur responsable.

  Paramètres :
    p_id_projet         : Identifiant unique du projet
    p_titre             : Titre du projet
    p_domaine           : Domaine de recherche du projet
    p_budget            : Budget alloué au projet (doit être > 0)
    p_date_debut        : Date de début du projet
    p_date_fin          : Date de fin du projet (doit être > date_debut)
    p_id_chercheur_resp : Identifiant du chercheur responsable

  Exceptions :
    -20001 : Budget invalide (≤ 0)
    -20002 : Date de fin antérieure à la date de début
    -20003 : Chercheur responsable inexistant
    OTHERS : Rollback automatique en cas d'erreur
*/
create or replace procedure ajouter_projet (
   p_id_projet         projet.id_projet%type,
   p_titre             projet.titre%type,
   p_domaine           projet.domaine%type,
   p_budget            projet.budget%type,
   p_date_debut        projet.date_debut%type,
   p_date_fin          projet.date_fin%type,
   p_id_chercheur_resp projet.id_chercheur_resp%type
) is
   v_exists number;
begin
    -- Validation
   if p_budget <= 0 then
      raise_application_error(
         -20001,
         'Le budget doit être supérieur à zéro.'
      );
   end if;
   if p_date_fin < p_date_debut then
      raise_application_error(
         -20002,
         'La date de fin doit être postérieure à la date de début.'
      );
   end if;

    -- Vérifier existence du chercheur responsable
   select count(*)
     into v_exists
     from chercheur
    where id_chercheur = p_id_chercheur_resp;

   if v_exists = 0 then
      raise_application_error(
         -20003,
         'Le chercheur responsable spécifié n''existe pas.'
      );
   end if;

    -- Insertion du projet
   insert into projet (
      id_projet,
      titre,
      domaine,
      budget,
      date_debut,
      date_fin,
      id_chercheur_resp
   ) values ( p_id_projet,
              p_titre,
              p_domaine,
              p_budget,
              p_date_debut,
              p_date_fin,
              p_id_chercheur_resp );

   commit;
exception
   when others then
      rollback;
      raise;
end ajouter_projet;
/

/*
  Procédure : AFFECTER_EQUIPEMENT

  Objectif :
    Affecter un équipement à un projet pour une durée spécifique.
    Vérifie la disponibilité de l'équipement avant l'affectation.

  Paramètres :
    p_id_projet         : Identifiant du projet
    p_id_equipement     : Identifiant de l'équipement à affecter
    p_date_affectation  : Date de début de l'affectation
    p_duree_jours       : Durée de l'affectation en jours (doit être > 0)

  Exceptions :
    -20011 : Durée invalide (≤ 0)
    -20012 : Équipement non disponible
    OTHERS : Rollback automatique en cas d'erreur
*/
create or replace procedure affecter_equipement (
   p_id_projet        affectation_equip.id_projet%type,
   p_id_equipement    affectation_equip.id_equipement%type,
   p_date_affectation affectation_equip.date_affectation%type,
   p_duree_jours      affectation_equip.duree_jours%type
) is
   v_dispo number;
begin
    -- Validation
   if p_duree_jours <= 0 then
      raise_application_error(
         -20011,
         'La durée doit être supérieure à zéro.'
      );
   end if;

    -- Vérifier disponibilité de l'équipement
   select count(*)
     into v_dispo
     from equipement
    where id_equipement = p_id_equipement
      and etat = 'Disponible';

   if v_dispo = 0 then
      raise_application_error(
         -20012,
         'L''équipement spécifié n''est pas disponible.'
      );
   end if;

    -- Insertion de l'affectation
   insert into affectation_equip (
      id_projet,
      id_equipement,
      date_affectation,
      duree_jours
   ) values ( p_id_projet,
              p_id_equipement,
              p_date_affectation,
              p_duree_jours );

   commit;
exception
   when others then
      rollback;
      raise;
end affecter_equipement;
/

/*
  Procédure : PLANIFIER_EXPERIENCE

  Objectif :
    Créer une expérience pour un projet donné avec affectation automatique
    d'équipement et journalisation. Utilise des SAVEPOINT pour garantir
    l'intégrité transactionnelle.

  Paramètres :
    p_id_projet         : Identifiant du projet
    p_titre_exp         : Titre de l'expérience
    p_date_realisation  : Date de réalisation de l'expérience
    p_statut            : Statut ('En cours', 'Terminée', 'Annulée')
    p_resultat          : Résultat de l'expérience (obligatoire si statut = 'Terminée')
    p_id_equipement     : Identifiant de l'équipement à affecter
    p_duree_jours       : Durée d'affectation de l'équipement en jours

  Exceptions :
    -20020 : Projet inexistant
    -20021 : Statut invalide
    -20022 : Résultat manquant pour une expérience terminée
    OTHERS : Rollback au SAVEPOINT en cas d'erreur

  Appels :
    - affecter_equipement() : Affecte l'équipement au projet
    - journaliser_action()  : Enregistre l'opération dans LOG_OPERATION
*/
create or replace procedure planifier_experience (
   p_id_projet        experience.id_projet%type,
   p_titre_exp        experience.titre_exp%type,
   p_date_realisation experience.date_realisation%type,
   p_statut           experience.statut%type,
   p_resultat         experience.resultat%type,
   p_id_equipement    equipement.id_equipement%type,
   p_duree_jours      affectation_equip.duree_jours%type
) is
   v_exists number;
   v_id_exp experience.id_exp%type;
begin
    -- Vérifier projet existe
   select count(*)
     into v_exists
     from projet
    where id_projet = p_id_projet;

   if v_exists = 0 then
      raise_application_error(
         -20020,
         'Projet inexistant.'
      );
   end if;

    -- Valider statut
   if p_statut not in ( 'En cours',
                        'Terminée',
                        'Annulée' ) then
      raise_application_error(
         -20021,
         'Statut invalide. Valeurs acceptées : En cours, Terminée, Annulée.'
      );
   end if;

    -- Valider resultat selon statut (règle du MCD)
   if
      p_statut = 'Terminée'
      and ( p_resultat is null
      or trim(p_resultat) is null )
   then
      raise_application_error(
         -20022,
         'Le résultat est obligatoire pour une expérience terminée.'
      );
   end if;

    -- Début transaction logique
   savepoint sp_planif;

    -- 1) Créer l'expérience
   insert into experience (
      id_exp,
      id_projet,
      titre_exp,
      date_realisation,
      resultat,
      statut
   ) values ( experience_seq.nextval,      -- si tu utilises séquence
              p_id_projet,
              p_titre_exp,
              p_date_realisation,
              p_resultat,
              p_statut ) returning id_exp into v_id_exp;

    -- 2) SAVEPOINT AVANT AFFECTATION (exigence)
   savepoint sp_avant_affect;
   begin
        -- 3) Affecter l'équipement
      affecter_equipement(
         p_id_projet        => p_id_projet,
         p_id_equipement    => p_id_equipement,
         p_date_affectation => p_date_realisation,
         p_duree_jours      => p_duree_jours
      );
   exception
      when others then
            -- Rollback partiel : annule l'affectation mais garde l'expérience
         rollback to sp_avant_affect;
         raise;
   end;

    -- 4) Journaliser l’action (LOG_OPERATION)
   journaliser_action(
      p_table       => 'EXPERIENCE',
      p_operation   => 'INSERT',
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

/*
  Procédure : SUPPRIMER_PROJET

  Objectif :
    Supprimer un projet et toutes ses dépendances (expériences, échantillons,
    affectations d'équipement) de manière transactionnelle. Utilise un curseur
    FOR UPDATE pour verrouiller le projet et éviter les suppressions concurrentes.

  Paramètres :
    p_id_projet : Identifiant du projet à supprimer

  Exceptions :
    -20001 : Projet introuvable
    -20002 : Erreur lors de la suppression
    NO_DATA_FOUND : Projet inexistant
    OTHERS : Rollback automatique en cas d'erreur

  Ordre de suppression :
    1. Échantillons liés aux expériences du projet
    2. Expériences du projet
    3. Affectations d'équipement du projet
    4. Projet lui-même
*/
create or replace procedure supprimer_projet (
   p_id_projet in projet.id_projet%type
) as
    -- Curseur de mise à jour : verrouille le projet pour éviter suppression concurrente
   cursor c_projet is
   select id_projet
     from projet
    where id_projet = p_id_projet
   for update;

   v_id_projet projet.id_projet%type;
begin
    -- 1) Vérifier/verrouiller le projet (curseur FOR UPDATE)
   open c_projet;
   fetch c_projet into v_id_projet;
   if c_projet%notfound then
      close c_projet;
      raise no_data_found;
   end if;
   close c_projet;

    -- 2) Supprimer les échantillons liés aux expériences du projet
   delete from echantillon
    where id_exp in (
      select id_exp
        from experience
       where id_projet = p_id_projet
   );

    -- 3) Supprimer les expériences du projet
   delete from experience
    where id_projet = p_id_projet;

    -- 4) Supprimer les affectations d’équipement du projet
   delete from affectation_equip
    where id_projet = p_id_projet;

    -- 5) Supprimer le projet
   delete from projet
    where id_projet = p_id_projet;

    -- 6) Journaliser l'action
   journaliser_action(
      p_table       => 'PROJET',
      p_operation   => 'DELETE',
      p_description => 'Suppression du projet ' || p_id_projet
   );

   commit;
exception
   when no_data_found then
      rollback;
        -- Message clair
      raise_application_error(
         -20001,
         'Projet '
         || p_id_projet
         || ' introuvable.'
      );
   when others then
      rollback;
      raise_application_error(
         -20002,
         'Erreur suppression projet '
         || p_id_projet
         || ' : '
         || sqlerrm
      );
end;
/

/*
  Procédure : JOURNALISER_ACTION

  Objectif :
    Insérer une entrée de journal dans la table LOG_OPERATION pour tracer
    les opérations effectuées sur les tables du système. Cette procédure
    est appelée par d'autres procédures métier pour assurer la traçabilité.

  Paramètres :
    p_table       : Nom de la table concernée (ex: 'EXPERIENCE', 'PROJET')
    p_operation   : Type d'opération ('INSERT', 'UPDATE', 'DELETE')
    p_description : Description textuelle de l'action effectuée

  Exceptions :
    -20030 : Opération invalide (doit être INSERT, UPDATE ou DELETE)
    OTHERS : Rollback automatique en cas d'erreur

  Note :
    L'opération est automatiquement normalisée en majuscules.
    L'utilisateur et la date sont enregistrés automatiquement.
*/
create or replace procedure journaliser_action (
   p_table       log_operation.table_concernee%type,
   p_operation   log_operation.operation%type,
   p_description log_operation.description%type
) is
   v_op log_operation.operation%type;
begin
    -- Normalisation de l'opération en majuscules
   v_op := upper(trim(p_operation));
   if v_op not in ( 'INSERT',
                    'UPDATE',
                    'DELETE' ) then
      raise_application_error(
         -20030,
         'Operation invalide (INSERT/UPDATE/DELETE).'
      );
   end if;

   insert into log_operation (
      id_log,
      table_concernee,
      operation,
      utilisateur,
      date_op,
      description
   ) values ( log_operation_seq.nextval,  -- si tu utilises une séquence
              p_table,
              v_op,
              user,
              sysdate,
              p_description );

   commit;
exception
   when others then
      rollback;
      raise;
end journaliser_action;
/