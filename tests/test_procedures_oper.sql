-- ========================================
-- TESTS DES PROCÉDURES
-- ========================================
-- À exécuter avec : admin_lab@XEPDB1

   SET SERVEROUTPUT ON;

-- ========================================
-- TEST 1 : AJOUTER_PROJET
-- ========================================
begin
   dbms_output.put_line('TEST 1 : AJOUTER_PROJET');
   savepoint sp_test1;

   -- Créer données de test
   insert into chercheur (
      id_chercheur,
      nom,
      prenom,
      specialite,
      email
   ) values ( 9999,
              'Test',
              'Chercheur',
              'Physique',
              'test@lab.com' );
   commit;

   -- Tester la procédure
   ajouter_projet(
      p_id_projet         => 9001,
      p_titre             => 'Projet Test',
      p_domaine           => 'Physique',
      p_budget            => 50000,
      p_date_debut        => sysdate,
      p_date_fin          => sysdate + 365,
      p_id_chercheur_resp => 9999
   );

   dbms_output.put_line('✓ Projet ajouté');

   -- Restaurer
   rollback to sp_test1;
   dbms_output.put_line('✓ Base restaurée');
   dbms_output.put_line('');
exception
   when others then
      rollback to sp_test1;
      dbms_output.put_line('✗ ERREUR: ' || sqlerrm);
end;
/


-- ========================================
-- TEST 2 : AFFECTER_EQUIPEMENT
-- ========================================
begin
   dbms_output.put_line('TEST 2 : AFFECTER_EQUIPEMENT');
   savepoint sp_test2;

   -- Créer données de test
   insert into chercheur (
      id_chercheur,
      nom,
      prenom,
      specialite,
      email
   ) values ( 9999,
              'Test',
              'Chercheur',
              'Physique',
              'test@lab.com' );

   insert into projet (
      id_projet,
      titre,
      domaine,
      budget,
      date_debut,
      date_fin,
      id_chercheur_resp
   ) values ( 9001,
              'Projet Test',
              'Physique',
              50000,
              sysdate,
              sysdate + 365,
              9999 );

   insert into equipement (
      id_equipement,
      nom_equipement,
      etat,
      type_equipement
   ) values ( 9001,
              'Microscope Test',
              'Disponible',
              'Microscope' );
   commit;

   -- Tester la procédure
   affecter_equipement(
      p_id_projet        => 9001,
      p_id_equipement    => 9001,
      p_date_affectation => sysdate,
      p_duree_jours      => 30
   );

   dbms_output.put_line('✓ Équipement affecté');

   -- Restaurer
   rollback to sp_test2;
   dbms_output.put_line('✓ Base restaurée');
   dbms_output.put_line('');
exception
   when others then
      rollback to sp_test2;
      dbms_output.put_line('✗ ERREUR: ' || sqlerrm);
end;
/


-- ========================================
-- TEST 3 : PLANIFIER_EXPERIENCE
-- ========================================
begin
   dbms_output.put_line('TEST 3 : PLANIFIER_EXPERIENCE');
   savepoint sp_test3;

   -- Créer données de test
   insert into chercheur (
      id_chercheur,
      nom,
      prenom,
      specialite,
      email
   ) values ( 9999,
              'Test',
              'Chercheur',
              'Physique',
              'test@lab.com' );

   insert into projet (
      id_projet,
      titre,
      domaine,
      budget,
      date_debut,
      date_fin,
      id_chercheur_resp
   ) values ( 9001,
              'Projet Test',
              'Physique',
              50000,
              sysdate,
              sysdate + 365,
              9999 );

   insert into equipement (
      id_equipement,
      nom_equipement,
      etat,
      type_equipement
   ) values ( 9001,
              'Microscope Test',
              'Disponible',
              'Microscope' );
   commit;

   -- Tester la procédure
   planifier_experience(
      p_id_projet        => 9001,
      p_titre_exp        => 'Expérience Test',
      p_date_realisation => sysdate + 10,
      p_statut           => 'En cours',
      p_resultat         => null,
      p_id_equipement    => 9001,
      p_duree_jours      => 20
   );

   dbms_output.put_line('✓ Expérience planifiée');

   -- Restaurer
   rollback to sp_test3;
   dbms_output.put_line('✓ Base restaurée');
   dbms_output.put_line('');
exception
   when others then
      rollback to sp_test3;
      dbms_output.put_line('✗ ERREUR: ' || sqlerrm);
end;
/


-- ========================================
-- TEST 4 : SUPPRIMER_PROJET
-- ========================================
begin
   dbms_output.put_line('TEST 4 : SUPPRIMER_PROJET');
   savepoint sp_test4;

   -- Créer données de test
   insert into chercheur (
      id_chercheur,
      nom,
      prenom,
      specialite,
      email
   ) values ( 9999,
              'Test',
              'Chercheur',
              'Physique',
              'test@lab.com' );

   insert into projet (
      id_projet,
      titre,
      domaine,
      budget,
      date_debut,
      date_fin,
      id_chercheur_resp
   ) values ( 9001,
              'Projet Test',
              'Physique',
              50000,
              sysdate,
              sysdate + 365,
              9999 );
   commit;

   -- Tester la procédure
   supprimer_projet(p_id_projet => 9001);
   dbms_output.put_line('✓ Projet supprimé');

   -- Restaurer
   rollback to sp_test4;
   dbms_output.put_line('✓ Base restaurée');
   dbms_output.put_line('');
exception
   when others then
      rollback to sp_test4;
      dbms_output.put_line('✗ ERREUR: ' || sqlerrm);
end;
/


-- ========================================
-- TEST 5 : JOURNALISER_ACTION
-- ========================================
begin
   dbms_output.put_line('TEST 5 : JOURNALISER_ACTION');
   savepoint sp_test5;

   -- Tester la procédure
   journaliser_action(
      p_table       => 'PROJET',
      p_operation   => 'INSERT',
      p_description => 'Test de journalisation'
   );
   dbms_output.put_line('✓ Action journalisée');

   -- Restaurer
   rollback to sp_test5;
   dbms_output.put_line('✓ Base restaurée');
   dbms_output.put_line('');
exception
   when others then
      rollback to sp_test5;
      dbms_output.put_line('✗ ERREUR: ' || sqlerrm);
end;
/