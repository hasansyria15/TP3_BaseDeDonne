-- Procédure : PLANIFIER_EXPERIENCE
create or replace procedure planifier_experience (
 p_id_projet number,
 p_titre_exp varchar2,
 p_date_real date,
 p_id_equipement number
) is
 v_id_exp experience.id_exp%type;
begin
 insert into experience (
  id_exp,
  id_projet,
  titre_exp,
  date_realisation,
  statut
 ) values (
  seq_experience.nextval,
  p_id_projet,
  p_titre_exp,
  p_date_real,
  'En cours'
 ) returning id_exp into v_id_exp;

 savepoint avant_affectation_equipement;

 insert into affectation_equip (
  id_affect,
  id_projet,
  id_equipement,
  date_affectation
 ) values (
  seq_affect.nextval,
  p_id_projet,
  p_id_equipement,
  sysdate
 );

 commit;
exception
 when others then
  rollback to avant_affectation_equipement;
  commit;
end planifier_experience;
/
