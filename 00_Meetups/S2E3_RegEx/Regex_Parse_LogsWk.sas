/**************************************************

Extraction de lignes de code sur filtrage par mot-clef

Source : logs Workspace Server
Pré-requis : logs workspace doivent être activées
adhérence à SAS EG
***************************************************/

/*-- Chemin logs --*/
%let dirwrklog=<SASCONFIG>/Lev1/%sysfunc(dequote(&_SASSERVERNAME))/WorkspaceServer/Logs;

filename fwrklog "&dirwrklog";

%let prefixlog=WorkspaceServer;

/*-- expression régulière --*/

/* 1. étapes exécutées en 10 min ou plus */

/*non        real time    3:41.74             */
/*oui        real time    2:05:16.21   */
/*non        real time    0.05 seconds */
/*oui        real time    37:12.21            */

%*let regex='/^.*real time\s+(\d{0,2}:*\d{2}:\d{2}\.\d{2}).*$/';

/* 1.bis étapes exécutées en 30 min ou plus */

%*let regex='/^.*real time\s+(\d{0,2}:*[345]\d{1}:\d{2}\.\d{2}).*$/';


/* 1.ter avec capture sur deux lignes du type de traitement DATA ou PROC */

%let regex1='/^.*NOTE:\s+(\w+\s+\w+\s*\w*)\s+used.*$/';
%let regex2='/^.*real time\s+(\d{0,2}:*\d{2}:\d{2}\.\d{2}).*$/';  

/*-- requête générique sur le nom du fichier --*/

* XXApp_WorkspaceServer_2022-12-01_server_4733.log ;

DATA resultat;
length fic filelog $128. statement $32.;
format realtime time11.2;
retain statement;
/* charger uniquement les fichiers du mois de décembre, pas du mois en cours sinon conflits ! */
       infile fwrklog(*&prefixlog.*2022-12*.log) filename=fic;    
       input;

       /* 1ere ligne */
       re1=prxparse(&regex1);
       if prxmatch(re1,strip(_infile_)) gt 0 then
             do;
                    statement=prxposn(re1,1,strip(_infile_));
                    *output;
             end;
       /* 2e ligne */
       re2=prxparse(&regex2);
       /* attention aux artefacts de mesure : la ligne récap. à la fin de la session */
       /* ne doit pas être prise en compte car c'est uniquement un cumul de durée */

       if statement ne 'The SAS System' and prxmatch(re2,strip(_infile_)) gt 0 then
             do;
                    _realtime=prxposn(re2,1,strip(_infile_));
                    /* formatage en numérique avec l'informat spécifique aux time log */
                    realtime=input(_realtime,stimer.);
                    filelog=fic;
                    output;
             end;
       keep filelog statement realtime;
run;
