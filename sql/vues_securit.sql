-- Vue : V_PROJETS_PUBLICS
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

-- Vue : V_RESULTATS_EXPERIENCE
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
        (p.date_fin - p.date_debut) as duree_projet
 from experience e
 join projet p on e.id_projet = p.id_projet
 join chercheur c on p.id_chercheur_resp = c.id_chercheur
 left join echantillon ech on e.id_exp = ech.id_exp
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

-- Fonction de hachage (SHA256)
create or replace function hash_nom (
 p_nom varchar2
) return varchar2 as
begin
 return standard_hash(p_nom, 'SHA256');
end;
/

-- Privilèges
GRANT EXECUTE ON ajouter_projet TO role_lab_gest;
GRANT EXECUTE ON affecter_equipement TO role_lab_gest;
GRANT EXECUTE ON planifier_experience TO role_lab_gest;
GRANT EXECUTE ON journaliser_action TO role_lab_gest;
GRANT EXECUTE ON calculer_duree_projet TO role_lab_gest;
GRANT EXECUTE ON verifier_disponibilite_equipement TO role_lab_gest;
GRANT EXECUTE ON moyenne_mesures_experience TO role_lab_gest;


GRANT SELECT ON v_projets_publics TO role_lab_lect;
GRANT SELECT ON v_resultats_experience TO role_lab_lect;
GRANT EXECUTE ON statistiques_equipements TO role_lab_lect;
GRANT EXECUTE ON budget_moyen_par_domaine TO role_lab_lect;
GRANT EXECUTE ON rapport_projets_par_chercheur TO role_lab_lect;
GRANT EXECUTE ON rapport_activite_projets TO role_lab_lect;

-- Trigger audit PROJET
create or replace trigger trg_projet_audit
after insert or delete on projet
for each row
begin
 if inserting then
  insert into log_operation (
   date_operation,
   nom_utilisateur,
   nom_table,
   type_operation,
   description
  ) values (
   sysdate,
   user,
   'PROJET',
   'INSERT',
   'Nouveau projet ID=' || :new.id_projet
  );
 elsif deleting then
  insert into log_operation (
   date_operation,
   nom_utilisateur,
   nom_table,
   type_operation,
   description
  ) values (
   sysdate,
   user,
   'PROJET',
   'DELETE',
   'Suppression projet ID=' || :old.id_projet
  );
 end if;
end;
/

-- Trigger audit EXPERIENCE
create or replace trigger trg_experience_audit
after insert or delete on experience
for each row
begin
 if inserting then
  insert into log_operation (
   date_operation,
   nom_utilisateur,
   nom_table,
   type_operation,
   description
  ) values (
   sysdate,
   user,
   'EXPERIENCE',
   'INSERT',
   'Nouvelle expérience ID=' || :new.id_exp
  );
 elsif deleting then
  insert into log_operation (
   date_operation,
   nom_utilisateur,
   nom_table,
   type_operation,
   description
  ) values (
   sysdate,
   user,
   'EXPERIENCE',
   'DELETE',
   'Suppression expérience ID=' || :old.id_exp
  );
 end if;
end;
/
