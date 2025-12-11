begin
   execute immediate 'DROP TABLE MA_TABLE CASCADE CONSTRAINTS';
exception
   when others then
      if sqlcode != -942 then  -- L'erreur n'est pas liée à l'inexistence de la table
         raise;
      end if;
end;
/

begin
   execute immediate '
    CREATE TABLE MA_TABLE (
      id NUMBER
    )';
exception
   when others then
      dbms_output.put_line('Erreur lors de la création de MA_TABLE : ' || sqlerrm);
end;
/