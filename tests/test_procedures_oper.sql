SET SERVEROUTPUT ON;

-- Test AJOUTER_PROJET
begin
savepoint sp_test1;

insert into chercheur values (
9999,
'Test',
'Chercheur',
'Physique',
'test@lab.com'
);
commit;

ajouter_projet(
p_id_projet => 9001,
p_titre => 'Projet Test',
p_domaine => 'Physique',
p_budget => 50000,
p_date_debut => sysdate,
p_date_fin => sysdate + 365,
p_id_chercheur_resp => 9999
);

rollback to sp_test1;
exception
when others then
rollback to sp_test1;
dbms_output.put_line(sqlerrm);
end;
/

-- Test AFFECTER_EQUIPEMENT
begin
savepoint sp_test2;

insert into chercheur values (
9999,
'Test',
'Chercheur',
'Physique',
'test@lab.com'
);

insert into projet values (
9001,
'Projet Test',
'Physique',
50000,
sysdate,
sysdate + 365,
9999
);

insert into equipement values (
9001,
'Microscope Test',
'Disponible',
'Microscope'
);
commit;

affecter_equipement(
p_id_projet => 9001,
p_id_equipement => 9001,
p_date_affectation => sysdate,
p_duree_jours => 30
);

rollback to sp_test2;
exception
when others then
rollback to sp_test2;
dbms_output.put_line(sqlerrm);
end;
/

-- Test PLANIFIER_EXPERIENCE
begin
savepoint sp_test3;

insert into chercheur values (
9999,
'Test',
'Chercheur',
'Physique',
'test@lab.com'
);

insert into projet values (
9001,
'Projet Test',
'Physique',
50000,
sysdate,
sysdate + 365,
9999
);

insert into equipement values (
9001,
'Microscope Test',
'Disponible',
'Microscope'
);
commit;

planifier_experience(
p_id_projet => 9001,
p_titre_exp => 'Experience Test',
p_date_realisation => sysdate + 10,
p_statut => 'En cours',
p_resultat => null,
p_id_equipement => 9001,
p_duree_jours => 20
);

rollback to sp_test3;
exception
when others then
rollback to sp_test3;
dbms_output.put_line(sqlerrm);
end;
/

-- Test SUPPRIMER_PROJET
begin
savepoint sp_test4;

insert into chercheur values (
9999,
'Test',
'Chercheur',
'Physique',
'test@lab.com'
);

insert into projet values (
9001,
'Projet Test',
'Physique',
50000,
sysdate,
sysdate + 365,
9999
);
commit;

supprimer_projet(
p_id_projet => 9001
);

rollback to sp_test4;
exception
when others then
rollback to sp_test4;
dbms_output.put_line(sqlerrm);
end;
/

-- Test JOURNALISER_ACTION
begin
savepoint sp_test5;

journaliser_action(
p_table => 'PROJET',
p_operation => 'INSERT',
p_description => 'Test journalisation'
);

rollback to sp_test5;
exception
when others then
rollback to sp_test5;
dbms_output.put_line(sqlerrm);
end;
/
