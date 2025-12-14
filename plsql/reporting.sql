-- Procédure : RAPPORT_PROJETS_PAR_CHERCHEUR
create or replace procedure rapport_projets_par_chercheur (
 p_id_chercheur chercheur.id_chercheur%type
) is
 v_nom chercheur.nom%type;
 v_prenom chercheur.prenom%type;
 v_budget_total number := 0;
 v_nb_projets number := 0;
 v_chercheur_existe number;
begin
 select count(*)
  into v_chercheur_existe
  from chercheur
 where id_chercheur = p_id_chercheur;

 if v_chercheur_existe = 0 then
  raise_application_error(-20201,'Chercheur inexistant (ID: ' || p_id_chercheur || ').');
 end if;

 select nom, prenom
  into v_nom, v_prenom
  from chercheur
 where id_chercheur = p_id_chercheur;

 dbms_output.put_line('Chercheur : ' || v_prenom || ' ' || v_nom || ' (ID: ' || p_id_chercheur || ')');

 for rec_projet in (
  select id_projet,
         titre,
         domaine,
         budget,
         date_debut,
         date_fin,
         (date_fin - date_debut) as duree_jours
    from projet
   where id_chercheur_resp = p_id_chercheur
   order by date_debut desc
 ) loop
  v_nb_projets := v_nb_projets + 1;
  v_budget_total := v_budget_total + nvl(rec_projet.budget,0);

  dbms_output.put_line('Projet #' || v_nb_projets);
  dbms_output.put_line('ID : ' || rec_projet.id_projet);
  dbms_output.put_line('Titre : ' || rec_projet.titre);
  dbms_output.put_line('Domaine : ' || rec_projet.domaine);
  dbms_output.put_line('Budget : ' || rec_projet.budget);
  dbms_output.put_line('Date début : ' || rec_projet.date_debut);
  dbms_output.put_line('Date fin : ' || rec_projet.date_fin);
  dbms_output.put_line('Durée : ' || rec_projet.duree_jours || ' jours');
 end loop;

 if v_nb_projets = 0 then
  raise_application_error(-20202,'Aucun projet trouvé pour le chercheur ' || v_prenom || ' ' || v_nom || '.');
 end if;

 dbms_output.put_line('Nombre de projets : ' || v_nb_projets);
 dbms_output.put_line('Budget total : ' || v_budget_total);
 dbms_output.put_line('Budget moyen : ' || (v_budget_total / v_nb_projets));
exception
 when others then
  if sqlcode in (-20201,-20202) then
   raise;
  else
   raise_application_error(-20203,'Erreur génération rapport : ' || sqlerrm);
  end if;
end rapport_projets_par_chercheur;
/

-- Fonction : STATISTIQUES_EQUIPEMENTS
create or replace function statistiques_equipements
 return sys_refcursor
as
 v_cursor sys_refcursor;
begin
 open v_cursor for
  select etat, count(*) as nombre
   from equipement
  group by etat
  order by nombre desc;

 return v_cursor;
end statistiques_equipements;
/

-- Procédure : RAPPORT_ACTIVITE_PROJETS
create or replace procedure rapport_activite_projets as
 v_nb_experiences number;
 v_nb_terminees number;
 v_taux_reussite number;
 v_moyenne_mesures number;
begin
 for rec_projet in (
  select p.id_projet,
         p.titre,
         p.domaine,
         count(e.id_exp) as nb_experiences
    from projet p
    left join experience e
      on p.id_projet = e.id_projet
   group by p.id_projet, p.titre, p.domaine
   order by p.titre
 ) loop
  select count(*)
   into v_nb_terminees
   from experience
  where id_projet = rec_projet.id_projet
    and statut = 'Terminée';

  if rec_projet.nb_experiences > 0 then
   v_taux_reussite := round(v_nb_terminees * 100 / rec_projet.nb_experiences,2);
  else
   v_taux_reussite := 0;
  end if;

  dbms_output.put_line('Projet : ' || rec_projet.titre);
  dbms_output.put_line('Domaine : ' || rec_projet.domaine);
  dbms_output.put_line('Expériences : ' || rec_projet.nb_experiences);
  dbms_output.put_line('Terminées : ' || v_nb_terminees);
  dbms_output.put_line('Taux réussite : ' || v_taux_reussite || '%');

  if rec_projet.nb_experiences > 0 then
   for rec_exp in (
    select id_exp, titre_exp, statut
     from experience
    where id_projet = rec_projet.id_projet
   ) loop
    begin
     v_moyenne_mesures := moyenne_mesures_experience(rec_exp.id_exp);
     dbms_output.put_line(' - ' || rec_exp.titre_exp || ' : ' || round(v_moyenne_mesures,2));
    exception
     when others then
      dbms_output.put_line(' - ' || rec_exp.titre_exp || ' : aucune mesure');
    end;
   end loop;
  end if;
 end loop;
end rapport_activite_projets;
/

-- Fonction : BUDGET_MOYEN_PAR_DOMAINE
create or replace function budget_moyen_par_domaine
 return sys_refcursor
as
 v_cursor sys_refcursor;
begin
 open v_cursor for
  select domaine,
         round(avg(budget),2) as budget_moyen,
         count(*) as nb_projets
    from projet
   where budget is not null
   group by domaine
   order by budget_moyen desc;

 return v_cursor;
end budget_moyen_par_domaine;
/
