/*--------------------*/
/* 	  SAS FEDSQL      */
/* Date : 17/11/2022  */
/* Auteur : AB        */
/*--------------------*/

/*On définit la CASLIB*/
libname casuser cas caslib=casuser;

/*On charge des données sur le serveur*/
/*Enregistrement d'une table*/
%let URLSrc=%STR(https://raw.githubusercontent.com/chainhaus/pythoncourse/master/avocado.csv);

filename avoca temp;

proc http
url="&URLSrc" method="get" out=avoca;
*debug level=1;
run;


data avoca;
infile avoca dlm=',' firstobs=2;
format date yymmdd10. AveragePrice DOLLAR8.2;
input _n date yymmdd10. AveragePrice TotalVolume Var4046 Var4225 Var4770 BagsTotal BagsS BagsL BagsXL Type :$20. Year Region :$20.;
run;

data casuser.avocas;
	set avoca;
run;
/*Autre manière de créer des CASTABLEdepuis la WORK*/
proc casutil;
	load data=work.avoca outcaslib=casuser casout="avocas2" replace;
run;
	
/*On réalise une première requête pour vérifier si la proc sql fonctionne*/
option msglevel=i;
proc sql;
	select count(*) as nb_cmd
	from casuser.avocas;
quit;
/*Surprise elle fonctionne*/

proc fedsql sessref=casauto;
	select count(*) as nb_cmd
	from casuser.avocas;
quit;

/*Création de castable avec la proc sql*/
proc sql;
	create table casuser.nb_comd_avoc as
	select count(*) as nb_cmd
	from casuser.avocas;
quit;
/*! On ne peut pas créer de table sur la session!*/

proc fedsql sessref=casauto;
	create table casuser.nb_comd_avoc as
	select count(*) as nb_cmd
	from casuser.avocas;
quit;
/*Permet de créer des castable*/

/***********************************/
/*Quote ? Double Quote ? Les deux ?*/
/***********************************/
proc fedsql sessref=casauto;
	select count(*) as nb
	from casuser.avocas
	where Region = "Albany";
quit;
/*Ne fonctionne pas, il faut utiliser les simple Quote*/

proc fedsql sessref=casauto;
	select count(*) as nb
	from casuser.avocas
	where Region = 'Albany';
quit;

/***********************************************/
/*Utilisation des mnemonics dans la proc fedsql*/
/***********************************************/

proc fedsql sessref=casauto;
	select count(*) as nb
	from casuser.avocas
	where Region NE 'Albany';
quit;
/*Ne fonctionne pas, les mnemomics EQ, NE, GT, LT, GE, LE ne fonctionne pas dans la procedure fedsql*/


proc fedsql sessref=casauto;
	select count(*) as nb
	from casuser.avocas
	where Region <> 'Albany';
quit;

/***************************************/
/*Les clauses where utilisant des dates*/
/***************************************/
proc fedsql sessref=casauto;
	select count(*) as nb_cmd
	from casuser.avocas
	where date > '22JAN2022'd;
quit;
/*L'ancienne syntaxe ne fonctionne pas, il y a une syntaxe différente*/

proc fedsql sessref=casauto;
	select count(*) as nb_cmd
	from casuser.avocas
	where date > DATE'2016-01-22';
quit;

/*****************/
/* Les jointures */
/*****************/
/*On va regrouper par années et région le nombre total d'avocats vendus*/

proc fedsql sessref=casauto ;
	create table casuser.Nb_AV_Year_Reg as
	select Year, Region, sum(TotalVolume) as ToTalVolume_Y
	from casuser.avocas
	group by 1,2; 
quit;

proc fedsql sessref=casauto;
	create table casuser.Nb_AV_Month_Reg  as
	select Year,month(date) as Month, Region, sum(TotalVolume) as ToTalVolume_M
	from casuser.avocas
	group by 1,2,3;
quit;

/*Jointure*/
proc fedsql sessref=casauto;
	create table casuser.conso_by_region_month  as
	select casuser.Nb_AV_Month_Reg.year, casuser.Nb_AV_Month_Reg.month, casuser.Nb_AV_Month_Reg.region, casuser.Nb_AV_Month_Reg.ToTalVolume_M , casuser.Nb_AV_Year_Reg.ToTalVolume_Y  
	from casuser.Nb_AV_Month_Reg, casuser.Nb_AV_Year_Reg 
	where casuser.Nb_AV_Month_Reg.year =  casuser.Nb_AV_Year_Reg.year and casuser.Nb_AV_Month_Reg.region =  casuser.Nb_AV_Year_Reg.region;
quit;

/*Autre syntaxe : moins lourde*/
proc fedsql sessref=casauto;
	create table conso_by_region_month_2  as
	select Nb_AV_Month_Reg.year, Nb_AV_Month_Reg.month, Nb_AV_Month_Reg.region, Nb_AV_Month_Reg.ToTalVolume_M , Nb_AV_Year_Reg.ToTalVolume_Y  
	from Nb_AV_Month_Reg, Nb_AV_Year_Reg 
	where Nb_AV_Month_Reg.year =  Nb_AV_Year_Reg.year and Nb_AV_Month_Reg.region =  Nb_AV_Year_Reg.region;
quit;

/*jointure entre deux caslib une active, une non active ?*/

/**********************/
/*L'option CALCULATED et le */
/**********************/
proc fedsql sessref=casauto;
	create table conso_by_region_month as
	select *, ToTalVolume_M / ToTalVolume_Y as pct_volume_month
	from conso_by_region_month;
quit;
/*Ne fonctionne pas*/

proc fedsql sessref=casauto;
	create table conso_by_region_month {options replace=true}  as
	select *, ToTalVolume_M / ToTalVolume_Y as pct_volume_month
	from conso_by_region_month;
quit;


proc fedsql sessref=casauto;
	select *, ToTalVolume_M / ToTalVolume_Y as pct_volume_month
	from conso_by_region_month
	where region='Albany' and calculated pct_volume_month>0.16;
quit;
/*Ne fonctionne pas*/

proc fedsql sessref=casauto;
	select *, ToTalVolume_M / ToTalVolume_Y as pct_volume_month
	from conso_by_region_month
	where region='Albany' and ToTalVolume_M / ToTalVolume_Y>0.16;
quit;


/*Utilisation de Calculated ? Autre exemple*/
proc fedsql sessref=casauto;
	select Year,Region, round(SUM(pct_volume_month),0.00001) as Tot
	from conso_by_region_month
	group by 1,2
	having calculated tot<1;
quit;

proc fedsql sessref=casauto;
	select Year,Region, round(SUM(pct_volume_month),0.00001)  as Tot
	from conso_by_region_month
	group by 1,2
	having round(SUM(pct_volume_month),0.00001) <> 1;
quit;

/**********************/
/*Les macros variables*/
/**********************/

%let reg = Albany;
proc sql ;
	select count(*) as nb_cmd
	from casuser.avocas
	where Region="&reg.";
quit;

proc fedsql sessref=casauto;
	select count(*) as nb_cmd
	from casuser.avocas
	where Region="&reg.";
quit;
/*Erreur, il faut utiliser une syntaxe pour pouvoir utiliser des macro-variables dans les clause where avec la fedsql */

proc fedsql sessref=casauto;
	select count(*) as nb_cmd
	from casuser.avocas
	where Region=%TSLIT(&reg.);
quit;

/*Est-ce que ça fonctionne ? */
%let reg2 = 'Albany';

proc fedsql sessref=casauto;
	select count(*) as nb_cmd
	from casuser.avocas
	where Region=&reg2.;
quit;