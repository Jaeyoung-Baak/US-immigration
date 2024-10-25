***********************************************************
* Historical immigrant share
* Data: IPUMS - full count (1920), 1% metro fm1, fm2(1970)
* Crosswalk: Eckert(1920), Wiltshire(1970)
* Written by Jae Young Baak 
* First created date: 2023-10-09
* Update: 2024-06-21
* Outcome files: immshare_hist.dta
***********************************************************

* I will provide you two cases: 1) Crosswalk 1920 FIPS county code to 2010 FIPS county code, and 2) Crosswalk 1970 county group (county gp) code to 1970 FIPS county code.
* Please download 1920 fullcount .dta file from the IPUMS and crosswalk file from Eckert's hompage, refer to readme.

***
clear all
set more off
cd "Appropriate repository"

*****************************************
***      Crosswalk (EGLP - Eckert)    ***
*** Pre-processing the crosswalk file ***
***         1900 1910 1920 1930       ***
*****************************************
import delimited "eglp_county_crosswalk_endyr_2010.csv", clear
sort year icpsrst icpsrcty weight
drop icpsrst_2010 icpsrcty_2010 area us_state nhgisst nhgiscty
rename icpsrst stateicp
rename icpsrcty countyicp // To merge original census data and crosswalk file, I matched variable names of crosswalk file with IPUMS data.

keep if year > 1890
save eglptemp.dta, replace

foreach value in 1900 1910 1920 1930 1940 1950 1960 1970 1980 1990 2000 {
	use eglptemp.dta, clear
	keep if year == `value'
	save eglp_`value'.dta, replace
}

***********
** IPUMS **
***********
use .dta, clear // .dta file of 1920 fullcount census.
drop if age<15
drop if age>64
drop sample serial hhwt gq metro metarea metaread pernum perwt bpld mbpl mbpld fbpl fbpld nativity citizen versionhist histid region sex age birthyr occ1950 ind1950
drop if yrimmig == 0
save "Appropriate file name", replace

***********
** 1910s **
***********
use immonly_1920, clear
drop if yrimmig < 1910
drop if yrimmig == 1920 // We only include the new immigrants within decades (1910s) from the census year (1920).
joinby stateicp countyicp using eglp_1920.dta, unm(b)
tab _merge
tab stateicp if _merge == 1
tab statenam if _merge == 2
keep if _merge == 3
gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1910s_temp.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3 
tab bpl if merge_bpl != 3, nol 
replace bpl_final = 35 if bpl ==  429 | bpl ==  440 
drop if bpl_final == .

save 1910s_cty_bpl_temp.dta, replace

preserve // make 50 entities(bpl_final) for each county fips

collapse (sum) weight, by(cty_fips bpl_final)
collapse (first) bpl_final weight, by(cty_fips)
replace bpl_final = 1
replace weight = 0
expand 50
sort cty_fips
quietly by cty_fips: gen dup=cond(_N==1,0,_n)
replace bpl_final=dup
drop dup
drop weight
save 1910sbpl.dta, replace

restore

collapse (sum) weight, by(cty_fips bpl_final) 
rename weight Moc1910s // Moc1910s: distribution of immigrants by area weight from country of origin O to county C at 1910s
save Moc1910s.dta, replace

collapse (sum) Moc1910s, by(bpl_final)
rename Moc1910s Mo1910s // Mo1910s: number of immigrants from country of origin O to US at 1910s, aggregate imm for each country
save Mo1910s.dta, replace

use 1910sbpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1910s.dta"
sort cty_fips bpl_final
replace Moc1910s = 0 if Moc1910s ==.
drop _merge
merge m:1 bpl_final using "Mo1910s.dta"
sort cty_fips bpl_final
drop _merge

gen share1910s = Moc1910s/Mo1910s
save share1910s.dta, replace


********************************************
*** 1970 crosswalk (Justin C. Wiltshire) ***
*** from 1970 county group to 1970 fips  ***
********************************************
/* new immigrants
use 1970.dta, clear
drop if age<15 // 1,169,569
drop if age>64 // 404,877
keep if sample == 197003
save 1970.dta, replace */
use 1970.dta, clear
tab yrimmig
tab yrimmig, nol
keep if yrimmig == 1960 |  yrimmig == 1965

joinby cntygp97 using cw_ctygrp_cty_1970m.dta, unm(b)
tab _merge
keep if _merge == 3
drop _merge
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1
replace bpl_final = 50 if bpl_final ==. // US territories: 50
drop if merge_bpl == 2
drop merge_bpl
save 1970cty_bpl_new_temp.dta, replace

preserve // make 50 entities(bpl_final) for each county fips

collapse (sum) afact, by(cty_fips bpl_final)
collapse (first) bpl_final afact, by(cty_fips)
replace bpl_final = 1
replace afact = 0
expand 50
sort cty_fips
quietly by cty_fips: gen dup=cond(_N==1,0,_n)
replace bpl_final=dup
drop dup
drop afact
save 1970bpl_new.dta, replace

restore

collapse (sum) afact, by(cty_fips bpl_final) // ** No need to consider perwt: all weights are same as 100 (flat) > No need: collapse (sum) weight [fw=perwt], by(cty_fips bpl_final)
rename afact Moc1970 // Moc1970: distribution of immigrants by area weight from country of origin O to county C at 1970
save Moc1970_new.dta, replace

collapse (sum) Moc1970, by(bpl_final)
rename Moc1970 Mo1970 // Mo1970: number of immigrants from country of origin O to US at 1970, aggregate imm for each country
save Mo1970_new.dta, replace

use 1970bpl_new.dta, clear

merge m:1 cty_fips bpl_final using "Moc1970_new.dta"
sort cty_fips bpl_final
replace Moc1970 = 0 if Moc1970 ==.
drop _merge
merge m:1 bpl_final using "Mo1970_new.dta"
sort cty_fips bpl_final
drop _merge // all matched

gen share1970 = Moc1970/Mo1970
** David Dorn: 12025 > 12086(1997) // 46113 > 46102 (2015)
replace cty_fips = 12086 if cty_fips == 12025 // 1997 changes
replace cty_fips = 46113 if cty_fips == 46102 // 2015 changes

ren Moc1970 Moc1960s
ren Mo1970 Mo1960s
ren share1970 share1960s

save share1970_new.dta, replace

**********************************
** Merging 1890s - 1920s & 1970 **
**********************************
use share1910s.dta, clear
joinby cty_fips bpl_final using share1970_new.dta, unm(b)
drop _merge


sort cty_fips bpl_final
drop if bpl_final == 50
save immshare_hist_new.dta, replace

*** End of this file ***




/*
not new imm / snapshot including all

********************************************
*** 1970 crosswalk (Justin C. Wiltshire) ***
*** from 1970 county group to 1970 fips  ***
*** No need to consider perwt			 ***
*** : all weights are same as 100 (flat) ***
********************************************
// use cw_ctygrp_cty_1970m.dta, clear // Eckert file
// rename county_grp70 cntygp97
// save cw_ctygrp_cty_1970m.dta, replace

/* use usa_00008.dta, clear
keep if year == 1970
replace perwt = 50 // We can use the data by combining fm1 & fm2 because they are mutually exclusive. All perwt/hhwt are same as 100, and by two different sample > need to wt/2
replace hhwt = 50 // https://forum.ipums.org/t/it-is-a-good-idea-to-pool-the-1970-form-1-metro-sample-and-1970-form-2-metro-sample-together/2047
save 1970acs.dta, replace */
use 1970acs.dta, clear
drop if age<15 // 1,169,569
drop if age>64 // 404,877

joinby cntygp97 using cw_ctygrp_cty_1970m.dta, unm(b)
drop if _merge == 1 // unmatched observations: Alaska & Hawaii - not identified in Wiltshire's crosswalk
drop _merge
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1 // all US
replace bpl_final = 50 if bpl_final ==. // US territories: 50
drop if merge_bpl == 2 // # 30
drop merge_bpl
save 1970cty_bpl_temp.dta, replace

preserve // make 50 entities(bpl_final) for each county fips

collapse (sum) afact, by(cty_fips bpl_final)
collapse (first) bpl_final afact, by(cty_fips)
replace bpl_final = 1
replace afact = 0
expand 50
sort cty_fips
quietly by cty_fips: gen dup=cond(_N==1,0,_n)
replace bpl_final=dup
drop dup
drop afact
save 1970bpl.dta, replace

restore

collapse (sum) afact, by(cty_fips bpl_final) // ** No need: collapse (sum) weight [fw=perwt], by(cty_fips bpl_final)
rename afact Moc1970 // Moc1970: distribution of immigrants by area weight from country of origin O to county C at 1970
save Moc1970.dta, replace

collapse (sum) Moc1970, by(bpl_final)
rename Moc1970 Mo1970 // Mo1970: number of immigrants from country of origin O to US at 1970, aggregate imm for each country
save Mo1970.dta, replace

use 1970bpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1970.dta"
sort cty_fips bpl_final
replace Moc1970 = 0 if Moc1970 ==.
drop _merge
merge m:1 bpl_final using "Mo1970.dta"
sort cty_fips bpl_final
drop _merge // all matched

gen share1970 = Moc1970/Mo1970
drop if cty_fips == . // missing value
** David Dorn: 12025 > 12086(1997) // 46113 > 46102 (2015)
replace cty_fips = 12086 if cty_fips == 12025 // 1997 changes
replace cty_fips = 46113 if cty_fips == 46102 // 2015 changes

save share1970.dta, replace
use 1970cty_bpl_temp.dta, replace
use share1970.dta, clear
*/
