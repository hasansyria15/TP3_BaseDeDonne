/*
  Fonction : CALCULER_DUREE_PROJET

  Objectif :
    Calculer la durée d'un projet en jours en fonction de ses dates
    de début et de fin. Utilise un SELECT INTO pour récupérer les dates.

  Paramètres :
    p_id_projet : Identifiant du projet

  Retour :
    Durée du projet en jours (NUMBER)

  Exceptions :
    -20011 : Projet introuvable
    -20012 : Erreur lors du calcul
*/
create or replace function calculer_duree_projet (
   p_id_projet in projet.id_projet%type
) return number as
   v_date_debut projet.date_debut%type;
   v_date_fin   projet.date_fin%type;
begin
   select date_debut,
          date_fin
     into
      v_date_debut,
      v_date_fin
     from projet
    where id_projet = p_id_projet;

   return ( v_date_fin - v_date_debut ); -- en jours (NUMBER)

exception
   when no_data_found then
      raise_application_error(
         -20011,
         'Projet introuvable : ' || p_id_projet
      );
   when others then
      raise_application_error(
         -20012,
         'Erreur calcul_duree_projet: ' || sqlerrm
      );
end;
/


/*
  Fonction : VERIFIER_DISPONIBILITE_EQUIPEMENT

  Objectif :
    Vérifier si un équipement est disponible en consultant son état
    et les affectations en cours. Utilise une collection TABLE OF RECORD
    pour stocker les affectations actives.

  Paramètres :
    p_id_equipement : Identifiant de l'équipement à vérifier

  Retour :
    1 : Équipement disponible
    0 : Équipement non disponible ou affecté

  Collections :
    - t_affectation_rec : RECORD contenant les infos d'affectation
    - t_affectations_tab : TABLE OF RECORD des affectations
*/
create or replace function verifier_disponibilite_equipement (
   p_id_equipement in equipement.id_equipement%type
) return number as
   -- Définition du TYPE RECORD pour stocker les affectations
   type t_affectation_rec is record (
         id_projet        affectation_equip.id_projet%type,
         id_equipement    affectation_equip.id_equipement%type,
         date_affectation affectation_equip.date_affectation%type,
         duree_jours      affectation_equip.duree_jours%type,
         date_fin         date
   );

   -- Définition du TYPE TABLE OF RECORD
   type t_affectations_tab is
      table of t_affectation_rec index by pls_integer;

   -- Déclaration de la collection
   v_affectations t_affectations_tab;

   -- Variables
   v_etat         equipement.etat%type;
   v_count        number := 0;
   v_index        pls_integer := 1;
begin
   -- 1) Vérifier l'état de l'équipement
   begin
      select etat
        into v_etat
        from equipement
       where id_equipement = p_id_equipement;
   exception
      when no_data_found then
         return 0; -- Équipement inexistant
   end;

   -- Si l'état n'est pas 'Disponible', retourner 0
   if v_etat != 'Disponible' then
      return 0;
   end if;

   -- 2) Charger les affectations actives dans la collection TABLE OF RECORD
   for rec in (
      select id_projet,
             id_equipement,
             date_affectation,
             duree_jours,
             date_affectation + duree_jours as date_fin
        from affectation_equip
       where id_equipement = p_id_equipement
         and date_affectation + duree_jours >= sysdate  -- Affectations actives
   ) loop
      v_affectations(v_index).id_projet := rec.id_projet;
      v_affectations(v_index).id_equipement := rec.id_equipement;
      v_affectations(v_index).date_affectation := rec.date_affectation;
      v_affectations(v_index).duree_jours := rec.duree_jours;
      v_affectations(v_index).date_fin := rec.date_fin;
      v_index := v_index + 1;
   end loop;

   -- 3) Vérifier si des affectations actives existent dans la collection
   if v_affectations.count > 0 then
      -- Il y a des affectations actives -> équipement non disponible
      return 0;
   else
      -- Aucune affectation active -> équipement disponible
      return 1;
   end if;
exception
   when others then
      -- En cas d'erreur, considérer comme non disponible
      return 0;
end verifier_disponibilite_equipement;
/

/*
  Fonction : MOYENNE_MESURES_EXPERIENCE

  Objectif :
    Calculer la moyenne des valeurs mesurées pour une expérience donnée.
    Utilise un SELECT INTO pour récupérer directement le résultat.

  Paramètres :
    p_id_exp : Identifiant de l'expérience

  Retour :
    La moyenne des mesures (NUMBER) ou NULL si aucune mesure

  Exceptions :
    -20040 : Expérience inexistante
    -20041 : Aucune mesure pour cette expérience
*/
create or replace function moyenne_mesures_experience (
   p_id_exp in experience.id_exp%type
) return number as
   v_moyenne    number;
   v_nb_mesures number;
   v_exp_exists number;
begin
   -- 1) Vérifier que l'expérience existe
   select count(*)
     into v_exp_exists
     from experience
    where id_exp = p_id_exp;

   if v_exp_exists = 0 then
      raise_application_error(
         -20040,
         'Expérience inexistante : ' || p_id_exp
      );
   end if;

   -- 2) Calculer la moyenne avec SELECT INTO
   select avg(valeur_mesuree),
          count(*)
     into
      v_moyenne,
      v_nb_mesures
     from echantillon
    where id_exp = p_id_exp
      and valeur_mesuree is not null;

   -- 3) Vérifier s'il y a des mesures
   if v_nb_mesures = 0 then
      raise_application_error(
         -20041,
         'Aucune mesure disponible pour l''expérience ' || p_id_exp
      );
   end if;

   return v_moyenne;
exception
   when no_data_found then
      raise_application_error(
         -20041,
         'Aucune mesure pour l''expérience ' || p_id_exp
      );
   when others then
      if sqlcode in ( - 20040,
                      - 20041 ) then
         raise;
      else
         raise_application_error(
            -20042,
            'Erreur calcul moyenne: ' || sqlerrm
         );
      end if;
end moyenne_mesures_experience;
/