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
) is
   v_nom              chercheur.nom%type;
   v_prenom           chercheur.prenom%type;
   v_budget_total     number;
   v_nb_projets       number;
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
   -- Resultat : Prenom Nom (ID: X)

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


/*
  Fonction : STATISTIQUES_EQUIPEMENTS

  Objectif :
    Retourner le nombre d'équipements par état (Disponible, En maintenance, etc.)
    Retourne un tableau de RECORD.

  Retour :
    Tableau de RECORD contenant pour chaque état :
    - etat : État de l'équipement
    - nombre : Nombre d'équipements dans cet état
*/
create or replace function statistiques_equipements return sys_refcursor as
   -- Définir le TYPE RECORD
   type t_stat_rec is record (
         etat   equipement.etat%type,
         nombre number
   );

   -- Définir le TYPE TABLE OF RECORD
   type t_stats_tab is
      table of t_stat_rec index by pls_integer;
   v_stats  t_stats_tab;
   v_cursor sys_refcursor;
begin
   -- Ouvrir le curseur avec les statistiques
   open v_cursor for select etat,
                            count(*) as nombre
                                         from equipement
                      group by etat
                      order by nombre desc;

   return v_cursor;
end statistiques_equipements;
/

/*
  Procédure : RAPPORT_ACTIVITE_PROJETS

  Objectif :
    Afficher le nombre d'expériences réalisées par projet et leur taux
    de réussite. Appelle la fonction moyenne_mesures_experience.

  Sortie :
    Affichage via DBMS_OUTPUT :
    - Nom du projet
    - Nombre d'expériences
    - Nombre d'expériences terminées
    - Taux de réussite
    - Moyenne des mesures

  Utilisation :
    SET SERVEROUTPUT ON;
    EXEC rapport_activite_projets();
*/
create or replace procedure rapport_activite_projets as
   v_nb_experiences  number;
   v_nb_terminees    number;
   v_taux_reussite   number;
   v_moyenne_mesures number;
begin
   dbms_output.put_line('================================================================');
   dbms_output.put_line('  RAPPORT D''ACTIVITÉ DES PROJETS');
   dbms_output.put_line('================================================================');
   dbms_output.put_line('');

   -- Curseur implicite pour parcourir les projets
   for rec_projet in (
      select p.id_projet,
             p.titre,
             p.domaine,
             count(e.id_exp) as nb_experiences
        from projet p
        left join experience e
      on p.id_projet = e.id_projet
       group by p.id_projet,
                p.titre,
                p.domaine
       order by p.titre
   ) loop
      -- Compter les expériences terminées
      select count(*)
        into v_nb_terminees
        from experience
       where id_projet = rec_projet.id_projet
         and statut = 'Terminée';

      -- Calculer le taux de réussite
      if rec_projet.nb_experiences > 0 then
         v_taux_reussite := round(
            v_nb_terminees * 100.0 / rec_projet.nb_experiences,
            2
         );
      else
         v_taux_reussite := 0;
      end if;

      -- Afficher les informations du projet
      dbms_output.put_line('Projet: ' || rec_projet.titre);
      dbms_output.put_line('  Domaine            : ' || rec_projet.domaine);
      dbms_output.put_line('  Expériences totales: ' || rec_projet.nb_experiences);
      dbms_output.put_line('  Expériences terminées: ' || v_nb_terminees);
      dbms_output.put_line('  Taux de réussite   : '
                           || v_taux_reussite || '%');

      -- Afficher la moyenne des mesures pour chaque expérience
      if rec_projet.nb_experiences > 0 then
         dbms_output.put_line('  Expériences:');
         for rec_exp in (
            select id_exp,
                   titre_exp,
                   statut
              from experience
             where id_projet = rec_projet.id_projet
         ) loop
            begin
               v_moyenne_mesures := moyenne_mesures_experience(rec_exp.id_exp);
               dbms_output.put_line('    - '
                                    || rec_exp.titre_exp
                                    || ' ('
                                    || rec_exp.statut
                                    || ') : Moyenne = ' || round(
                  v_moyenne_mesures,
                  2
               ));
            exception
               when others then
                  dbms_output.put_line('    - '
                                       || rec_exp.titre_exp
                                       || ' ('
                                       || rec_exp.statut || ') : Pas de mesures');
            end;
         end loop;
      end if;

      dbms_output.put_line('----------------------------------------------------------------');
   end loop;

   dbms_output.put_line('================================================================');
end rapport_activite_projets;
/

/*
  Fonction : BUDGET_MOYEN_PAR_DOMAINE

  Objectif :
    Calculer le budget moyen par domaine scientifique.
    Utilise une table PL/SQL en mémoire (TABLE OF RECORD).

  Retour :
    SYS_REFCURSOR contenant les budgets moyens par domaine
*/
create or replace function budget_moyen_par_domaine return sys_refcursor as
   -- Définir le TYPE RECORD pour stocker les budgets par domaine
   type t_budget_rec is record (
         domaine      projet.domaine%type,
         budget_moyen number,
         nb_projets   number
   );

   -- Définir le TYPE TABLE OF RECORD (table PL/SQL en mémoire)
   type t_budgets_tab is
      table of t_budget_rec index by pls_integer;

   -- Déclarer la table en mémoire
   v_budgets t_budgets_tab;
   v_index   pls_integer;
   v_cursor  sys_refcursor;
begin
   -- Remplir la table PL/SQL en mémoire
   for rec in (
      select domaine,
             avg(budget) as budget_moyen,
             count(*) as nb_projets
        from projet
       where budget is not null
       group by domaine
       order by budget_moyen desc
   ) loop
      v_budgets(v_index).domaine := rec.domaine;
      v_budgets(v_index).budget_moyen := rec.budget_moyen;
      v_budgets(v_index).nb_projets := rec.nb_projets;
      v_index := v_index + 1;
   end loop;

   -- Retourner un curseur avec les données de la table en mémoire
   open v_cursor for select domaine,
                            round(
                                        avg(budget),
                                        2
                                     ) as budget_moyen,
                            count(*) as nb_projets
                                       from projet
                     where budget is not null
                     group by domaine
                     order by budget_moyen desc;

   return v_cursor;
end budget_moyen_par_domaine;
/