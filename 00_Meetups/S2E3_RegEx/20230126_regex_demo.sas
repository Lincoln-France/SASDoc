/*-------------------------------------------*/
		/* Meet-up : SAS regex DEMO*/
/* Date : 26/01/2023*/
/* Auteur : AB*/
/*-------------------------------------------*/

/**************************/
/*== Chargement Fichier ==*/
/**************************/

/*On utilise l'outil de chargement manuel*/

/**************************************************************/
/*== Utilisation des fonctions classiques find/substr/index ==*/
/**************************************************************/

/* 1 - réponse répondant au plus grand nombre de cas*/
data mail_present_fct_classique;
	set mail_present_meetup;
	format prenom $20. nom $20. domaine $20. t ;
	prenom = SUBSTR(adresse_mail,1,INDEX(adresse_mail,'.')-1);
	nom = SUBSTR(adresse_mail,INDEX(adresse_mail,'.')+1,INDEX(adresse_mail,'@')-1-INDEX(adresse_mail,'.'));
	domaine = SUBSTR(adresse_mail,INDEX(adresse_mail,'@')+1,INDEX(adresse_mail,'.fr')-1-INDEX(adresse_mail,'@'));
run;
/*Pb avec les adresses en .com et les deux adresses qui n'en sont pas*/

/*2 - Récupérer les .com*/
data mail_present_fct_classique1;
	set mail_present_meetup;
	format prenom $20. nom $20. domaine $20. t ;
	prenom = SUBSTR(adresse_mail,1,INDEX(adresse_mail,'.')-1);
	nom = SUBSTR(adresse_mail,INDEX(adresse_mail,'.')+1,INDEX(adresse_mail,'@')-1-INDEX(adresse_mail,'.'));
	if find(adresse_mail,'.fr') > 0 then domaine = SUBSTR(adresse_mail,INDEX(adresse_mail,'@')+1,INDEX(adresse_mail,'.fr')-1-INDEX(adresse_mail,'@'));
	else domaine = SUBSTR(adresse_mail,INDEX(adresse_mail,'@')+1,INDEX(adresse_mail,'.com')-1-INDEX(adresse_mail,'@'));	
run;

/*3 - Améliorons pour supprimer les deux adresses qui ne sont pas des adresses mails.*/
data mail_present_fct_classique2;
	set mail_present_meetup;
	format prenom $20. nom $20. domaine $20.;

	retain condition; 
   	if _N_=1 then;
	condition = find(adresse_mail,'@');

	if condition >= 1 then
	do;
		prenom = SUBSTR(adresse_mail,1,INDEX(adresse_mail,'.')-1);
		nom = SUBSTR(adresse_mail,INDEX(adresse_mail,'.')+1,INDEX(adresse_mail,'@')-1-INDEX(adresse_mail,'.'));
		if find(adresse_mail,'.fr') > 0 then domaine = SUBSTR(adresse_mail,INDEX(adresse_mail,'@')+1,INDEX(adresse_mail,'.fr')-1-INDEX(adresse_mail,'@'));
		else domaine = SUBSTR(adresse_mail,INDEX(adresse_mail,'@')+1,INDEX(adresse_mail,'.com')-1-INDEX(adresse_mail,'@'));	
	end;
run;

/*----------------------------------------------------------------*/
/*Utilisation des expressions régulières/prxparse/prxposn/prxmatch*/
/*----------------------------------------------------------------*/
data mail_present_prx_func (drop=re);
   set mail_present_meetup;
   format prenom $20. nom $20. domaine $20. ;
	
   re=prxparse("/(\S+)\.(\S+)@(.+)(.fr|.com)/");

   if prxmatch(re, adresse_mail) then 
      do;
         prenom=prxposn(re, 1, adresse_mail);
         nom=prxposn(re, 2, adresse_mail);
		 domaine = prxposn(re, 3, adresse_mail);
      end;
run;
