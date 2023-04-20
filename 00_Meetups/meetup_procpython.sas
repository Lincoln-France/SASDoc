/************************************************************/
/*		Meet-up : Proc python : Chargement de données JSON  */
/* Date : 20/04/2023										*/
/* Auteur : AB												*/
/************************************************************/

/*Arrive t-on à lancer la proc python?*/
proc python;
	submit;
	print("Hello World")
	endsubmit;
run;

/*Corrigeons*/
proc python;
	submit;
print("Hello World")
	endsubmit;
run;

/*-----------------------------------------------------------*/
/*Vérification de la version de python et des packages installés*/
proc python;
	submit;
# version de python
import sys 
print(sys.version) 

# packages installés
help('modules') #test 
	endsubmit;
run;

/*-----------------------------------------------------------*/
/*Récupérartion de l'URL avec les données sources*/
%let URLSrc=%STR(https://raw.githubusercontent.com/fencing93/SAS-MeetUp/main/meetup_procpython/data.json); 

/*Vérifions que nous arrivons à interpréter la macro variable URLSrc*/
proc python;
submit;
url = SAS.symget('URLSrc')
print('La macro URLSrc = '+url)
endsubmit;
run;

/*Utilisation de la proc python pour télécharger les données*/
proc python;
	submit;
import json
import pandas as pd
import urllib.request

url = SAS.symget('URLSrc')

response = urllib.request.urlopen(url)
curr_file = json.loads(response.read()) 

df = pd.json_normalize(curr_file, record_path='students', meta=['school','location',['info','president'],['info','contacts','tel'],['info','contacts','email','general']],errors='ignore') 

df.rename(columns = { 
    'info.president' : 'president', 
    'info.contacts.tel' : 'telephone',
    'info.contacts.email.general' : 'general_email' 
}, inplace=True) 

ds = SAS.df2sd(df,"output_python")
	endsubmit;
run;
/*-----------------------------------------------------------*/
/*Utilisation de SAS pour importer un fichier JSON*/

filename js_dt temp;

proc http
url="&URLSrc" method="get" out=js_dt;
run;

/*Import d'un fichier JSON dans SAS à l'aide de l'instruction
  libname JSON*/
libname js JSON fileref=js_dt;

proc copy in=js out=work;
run;
/*On constate la création d'autant de tables qu'il n'y a de clé.
  Nécessité de passer par une proc sql ou étape data pour avoir 
  la table attendu */

proc sql; 
	create table output_sas as 

	select a.name,
		   b.school,
	       b.location,
		   c.president,
		   d.tel,e.general as email_general 

	from STUDENTS as a 
	left join ROOT as b 
	on a.ordinal_root=b.ordinal_root 

	left join INFO as c 
	on a.ordinal_root=c.ordinal_root 

	left join info_contacts as d 
	on c.ordinal_info=d.ordinal_info 

	left join contacts_email as e 
	on d.ordinal_contacts=e.ordinal_contacts; 
quit; 

 
