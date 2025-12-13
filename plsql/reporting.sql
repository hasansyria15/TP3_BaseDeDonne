-- ========================================
-- REPORTING - PROCÉDURES ET VUES
-- ========================================
-- Procédures de reporting avec curseurs et vues pour consultation

/*
  Procédure : RAPPORT_PROJETS_PAR_CHERCHEUR

  Objectif :
    Afficher la liste des projets d'un chercheur avec le budget total.
    Utilise un curseur implicite (FOR loop) et DBMS_OUTPUT pour afficher
    les résultats.

  Paramètres :
    p_id_chercheur : Identifiant du chercheur

  Sortie :
    Affichage dans DBMS_OUTPUT de :
    - Informations du chercheur
    - Liste des projets (titre, domaine, budget, dates)
    - Budget total de tous les projets

  Exceptions :
    -20201 : Chercheur inexistant
    -20202 : Aucun projet trouvé pour ce chercheur

  Utilisation :
    SET SERVEROUTPUT ON;
    EXEC rapport_projets_par_chercheur(1);
*/
create or replace procedure rapport_projets_par_chercheur (
   p_id_chercheur chercheur.id_chercheur%type
) as
   v_nom              chercheur.nom%type;
   v_prenom           chercheur.prenom%type;
   v_budget_total     number := 0;
   v_nb_projets       number := 0;
   v_chercheur_existe number;
begin
   -- Vérifier que le chercheur existe
   select count(*)
     into v_chercheur_existe
     from chercheur
    where id_chercheur = p_id_chercheur;

   if v_chercheur_existe = 0 then
      raise_application_error(
         -20201,
         'Chercheur inexistant (ID: '
         || p_id_chercheur
         || ').'
      );
   end if;

   -- Récupérer les informations du chercheur
   select nom,
          prenom
     into
      v_nom,
      v_prenom
     from chercheur
    where id_chercheur = p_id_chercheur;

   -- Afficher l'en-tête du rapport
   dbms_output.put_line('================================================================');
   dbms_output.put_line('  RAPPORT DES PROJETS PAR CHERCHEUR');
   dbms_output.put_line('================================================================');
   dbms_output.put_line('Chercheur : '
                        || v_prenom
                        || ' '
                        || v_nom
                        || ' (ID: '
                        || p_id_chercheur || ')');
   dbms_output.put_line('================================================================');
   dbms_output.put_line('');

   -- Utiliser un curseur implicite (FOR loop) pour parcourir les projets
   for rec_projet in (
      select id_projet,
             titre,
             domaine,
             budget,
             date_debut,
             date_fin,
             ( date_fin - date_debut ) as duree_jours
        from projet
       where id_chercheur_resp = p_id_chercheur
       order by date_debut desc
   ) loop
      -- Incrémenter le compteur
      v_nb_projets := v_nb_projets + 1;

      -- Calculer le budget total
      v_budget_total := v_budget_total + nvl(
         rec_projet.budget,
         0
      );

      -- Afficher les détails du projet
      dbms_output.put_line('Projet #' || v_nb_projets);
      dbms_output.put_line('  ID          : ' || rec_projet.id_projet);
      dbms_output.put_line('  Titre       : ' || rec_projet.titre);
      dbms_output.put_line('  Domaine     : ' || rec_projet.domaine);
      dbms_output.put_line('  Budget      : '
                           || to_char(
         rec_projet.budget,
         '999,999,999.99'
      ) || ' $');
      dbms_output.put_line('  Date début  : ' || to_char(
         rec_projet.date_debut,
         'DD/MM/YYYY'
      ));
      dbms_output.put_line('  Date fin    : ' || to_char(
         rec_projet.date_fin,
         'DD/MM/YYYY'
      ));
      dbms_output.put_line('  Durée       : '
                           || rec_projet.duree_jours || ' jours');
      dbms_output.put_line('----------------------------------------------------------------');
   end loop;

   -- Vérifier si le chercheur a des projets
   if v_nb_projets = 0 then
      dbms_output.put_line('');
      dbms_output.put_line('*** Aucun projet trouvé pour ce chercheur ***');
      dbms_output.put_line('');
      raise_application_error(
         -20202,
         'Aucun projet trouvé pour le chercheur '
         || v_prenom
         || ' '
         || v_nom
         || '.'
      );
   end if;

   -- Afficher le résumé
   dbms_output.put_line('');
   dbms_output.put_line('================================================================');
   dbms_output.put_line('  RÉSUMÉ');
   dbms_output.put_line('================================================================');
   dbms_output.put_line('Nombre total de projets : ' || v_nb_projets);
   dbms_output.put_line('Budget total            : '
                        || to_char(
      v_budget_total,
      '999,999,999.99'
   ) || ' $');
   dbms_output.put_line('Budget moyen par projet : '
                        || to_char(
      v_budget_total / v_nb_projets,
      '999,999,999.99'
   ) || ' $');
   dbms_output.put_line('================================================================');
exception
   when others then
      if sqlcode in ( - 20201,
                      - 20202 ) then
         raise;
      else
         raise_application_error(
            -20203,
            'Erreur lors de la génération du rapport : ' || sqlerrm
         );
      end if;
end rapport_projets_par_chercheur;
/


-- Fonction retourn les équipements par état en tableau record
create or replace function statistiques_equipements return sys_refcursor is
   v_cursor sys_refcursor;
begin
   open v_cursor for select etat,
                            count(*) as nb_equipements
                                         from equipement
                      group by etat
                      order by etat;
   return v_cursor;
end statistiques_equipements;
/