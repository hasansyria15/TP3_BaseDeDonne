-- ========================
-- TABLE CHERCHEUR
-- ========================
insert into chercheur (
   id_chercheur,
   nom,
   prenom,
   specialite,
   date_embauche
) values ( 1,
           'Dupont',
           'Alice',
           'Biotech',
           to_date('2018-03-15','YYYY-MM-DD') );
insert into chercheur (
   id_chercheur,
   nom,
   prenom,
   specialite,
   date_embauche
) values ( 2,
           'Nguyen',
           'Bao',
           'IA',
           to_date('2019-06-10','YYYY-MM-DD') );
insert into chercheur (
   id_chercheur,
   nom,
   prenom,
   specialite,
   date_embauche
) values ( 3,
           'Martin',
           'Chloé',
           'Physique',
           to_date('2020-01-25','YYYY-MM-DD') );
insert into chercheur (
   id_chercheur,
   nom,
   prenom,
   specialite,
   date_embauche
) values ( 4,
           'Roy',
           'David',
           'Chimie',
           to_date('2017-11-02','YYYY-MM-DD') );
insert into chercheur (
   id_chercheur,
   nom,
   prenom,
   specialite,
   date_embauche
) values ( 5,
           'Tremblay',
           'Éric',
           'Mathématiques',
           to_date('2016-05-18','YYYY-MM-DD') );

-- ========================
-- TABLE PROJET
-- ========================
insert into projet (
   id_projet,
   titre,
   domaine,
   budget,
   date_debut,
   date_fin,
   id_chercheur_resp
) values ( 101,
           'NanoCapteurs',
           'Biotech',
           500000,
           to_date('2023-01-01','YYYY-MM-DD'),
           to_date('2025-01-01','YYYY-MM-DD'),
           1 );
insert into projet (
   id_projet,
   titre,
   domaine,
   budget,
   date_debut,
   date_fin,
   id_chercheur_resp
) values ( 102,
           'DeepPredict',
           'IA',
           350000,
           to_date('2022-09-01','YYYY-MM-DD'),
           to_date('2024-09-01','YYYY-MM-DD'),
           2 );
insert into projet (
   id_projet,
   titre,
   domaine,
   budget,
   date_debut,
   date_fin,
   id_chercheur_resp
) values ( 103,
           'QuantumSense',
           'Physique',
           450000,
           to_date('2023-03-10','YYYY-MM-DD'),
           to_date('2025-03-10','YYYY-MM-DD'),
           3 );

-- ========================
-- TABLE EQUIPEMENT
-- ========================
insert into equipement (
   id_equipement,
   nom,
   categorie,
   date_acquisition,
   etat
) values ( 201,
           'Microscope BioPro X',
           'Analyse biologique',
           to_date('2019-04-20','YYYY-MM-DD'),
           'Disponible' );
insert into equipement (
   id_equipement,
   nom,
   categorie,
   date_acquisition,
   etat
) values ( 202,
           'Serveur GPU A100',
           'Calcul haute performance',
           to_date('2021-12-10','YYYY-MM-DD'),
           'Disponible' );
insert into equipement (
   id_equipement,
   nom,
   categorie,
   date_acquisition,
   etat
) values ( 203,
           'Laser Quantix',
           'Instrumentation',
           to_date('2020-08-05','YYYY-MM-DD'),
           'En maintenance' );
insert into equipement (
   id_equipement,
   nom,
   categorie,
   date_acquisition,
   etat
) values ( 204,
           'Spectromètre NanoX',
           'Analyse chimique',
           to_date('2018-06-01','YYYY-MM-DD'),
           'Hors service' );

-- ========================
-- TABLE AFFECTATION_EQUIP
-- ========================
insert into affectation_equip (
   id_affect,
   id_projet,
   id_equipement,
   date_affectation,
   duree_jours
) values ( 301,
           101,
           201,
           to_date('2023-02-01','YYYY-MM-DD'),
           90 );
insert into affectation_equip (
   id_affect,
   id_projet,
   id_equipement,
   date_affectation,
   duree_jours
) values ( 302,
           102,
           202,
           to_date('2023-04-15','YYYY-MM-DD'),
           120 );
insert into affectation_equip (
   id_affect,
   id_projet,
   id_equipement,
   date_affectation,
   duree_jours
) values ( 303,
           103,
           203,
           to_date('2024-01-10','YYYY-MM-DD'),
           60 );

-- ========================
-- TABLE EXPERIENCE
-- ========================
insert into experience (
   id_exp,
   id_projet,
   titre_exp,
   date_realisation,
   resultat,
   statut
) values ( 401,
           101,
           'Analyse ADN MicroCapteurs',
           to_date('2023-04-10','YYYY-MM-DD'),
           'Succès partiel',
           'Terminée' );
insert into experience (
   id_exp,
   id_projet,
   titre_exp,
   date_realisation,
   resultat,
   statut
) values ( 402,
           101,
           'Test bio-compatibilité',
           to_date('2023-06-20','YYYY-MM-DD'),
           null,
           'En cours' );
insert into experience (
   id_exp,
   id_projet,
   titre_exp,
   date_realisation,
   resultat,
   statut
) values ( 403,
           102,
           'Optimisation des réseaux neuronaux',
           to_date('2023-03-05','YYYY-MM-DD'),
           'Précision 94%',
           'Terminée' );
insert into experience (
   id_exp,
   id_projet,
   titre_exp,
   date_realisation,
   resultat,
   statut
) values ( 404,
           103,
           'Simulation quantique Photon',
           to_date('2024-02-14','YYYY-MM-DD'),
           null,
           'En cours' );

-- ========================
-- TABLE ECHANTILLON
-- ========================
insert into echantillon (
   id_echantillon,
   id_exp,
   type_echantillon,
   date_prelevement,
   mesure
) values ( 501,
           401,
           'Cellules souches',
           to_date('2023-04-12','YYYY-MM-DD'),
           12.5 );
insert into echantillon (
   id_echantillon,
   id_exp,
   type_echantillon,
   date_prelevement,
   mesure
) values ( 502,
           401,
           'Protéines',
           to_date('2023-04-15','YYYY-MM-DD'),
           18.3 );
insert into echantillon (
   id_echantillon,
   id_exp,
   type_echantillon,
   date_prelevement,
   mesure
) values ( 503,
           403,
           'Jeux de données IA',
           to_date('2023-03-06','YYYY-MM-DD'),
           200.0 );

-- ========================
-- TABLE LOG_OPERATION
-- ========================
insert into log_operation (
   id_log,
   table_concernee,
   operation,
   utilisateur,
   date_op,
   description
) values ( 601,
           'CHERCHEUR',
           'INSERT',
           'admin_rd',
           sysdate,
           'Ajout initial de chercheurs' );
insert into log_operation (
   id_log,
   table_concernee,
   operation,
   utilisateur,
   date_op,
   description
) values ( 602,
           'PROJET',
           'INSERT',
           'admin_rd',
           sysdate,
           'Création des projets initiaux' );
insert into log_operation (
   id_log,
   table_concernee,
   operation,
   utilisateur,
   date_op,
   description
) values ( 603,
           'EQUIPEMENT',
           'INSERT',
           'admin_rd',
           sysdate,
           'Ajout d’équipements au stock' );