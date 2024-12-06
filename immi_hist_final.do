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
cd "Your directory"

*********************************
*** Crosswalk (EGLP - Eckert) ***
***    1900 1910 1920 1930    ***
*********************************
import delimited "eglp_county_crosswalk_endyr_2010.csv", clear
sort year icpsrst icpsrcty weight
drop icpsrst_2010 icpsrcty_2010 area us_state nhgisst nhgiscty
rename icpsrst stateicp
rename icpsrcty countyicp

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
// foreach value in 1900 1910 1920 1930 {
// 	use `value'_full.dta, clear
// 	drop if age<15
// 	drop if age>64
// 	drop sample serial hhwt gq metro metarea metaread pernum perwt bpld mbpl mbpld fbpl fbpld nativity citizen versionhist histid region sex age birthyr occ1950 ind1950
// 	drop if yrimmig == 0 * drop U.S. native-born individuals
// 	save "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_hist_final/Immonly_`value'.dta", replace
// }
***********
** 1890s **
***********
use immonly_1900, clear
** Immigrants who arrived during the 1890s
drop if yrimmig < 1890 // 6,356,309 dropped
drop if yrimmig == 1900 // 152,139 drppped >> finally 2,432,629 remained
joinby stateicp countyicp using eglp_1900.dta, unm(b)
tab _merge
tab stateicp if _merge == 1 // 6,280 (only master - north dakota, south dakota, virginia, oklahoma, nevada, new mexico, oregon, district of columbia)
tab statenam if _merge == 2 // 2,125
keep if _merge == 3
gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1890s_temp.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3 //   puerto rico (1,148), US virgin(213), north america(187); western europe (310) southern europe (115)... #2,059
tab bpl if merge_bpl != 3, nol 
replace bpl_final = 35 if bpl ==  429 | bpl ==  440 // Western | Southern europe > 35 (europe non specified)
drop if bpl_final == . 

save 1890s_cty_bpl_temp.dta, replace

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
save 1890sbpl.dta, replace

restore

collapse (sum) weight, by(cty_fips bpl_final) 
rename weight Moc1890s // Moc1890s: The distribution of immigrants from the country of origin (O) to the county (C) during the 1890s, using area weight.
save Moc1890s.dta, replace

collapse (sum) Moc1890s, by(bpl_final)
rename Moc1890s Mo1890s // Mo1890s: The number of immigrants from country of origin (O) to the United States during the 1890s, aggregated for each country.
save Mo1890s.dta, replace

use 1890sbpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1890s.dta"
sort cty_fips bpl_final
replace Moc1890s = 0 if Moc1890s ==.
drop _merge
merge m:1 bpl_final using "Mo1890s.dta" // bpl_final==50 3,055 not matched
sort cty_fips bpl_final
drop _merge // all matched

gen share1890s = Moc1890s/Mo1890s

save share1890s.dta, replace

***********
** 1900s **
***********
use immonly_1910, clear
** Immigrants who arrived during the 1900s
drop if yrimmig < 1900 // 6,765,292 dropped
drop if yrimmig == 1910 // 232,724 drppped >> finally 4,631,436 remained
joinby stateicp countyicp using eglp_1910.dta, unm(b)
tab _merge
tab stateicp if _merge == 1 // 591 (only master - nevada, oregon, virginia)
tab statenam if _merge == 2 // 973
keep if _merge == 3
gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1900s_temp.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3 //   puerto rico (5,343), US virgin(131), north america(13); western europe (591) # 6,232
tab bpl if merge_bpl != 3, nol 
replace bpl_final = 35 if bpl ==  429 | bpl ==  440 // Western | Southern europe > 35 (europe non specified)
drop if bpl_final == . // Unspecified (total: 5,625: including puerto rico + US virgin)

save 1900s_cty_bpl_temp.dta, replace

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
save 1900sbpl.dta, replace

restore

collapse (sum) weight, by(cty_fips bpl_final) 
rename weight Moc1900s // Moc1890s: The distribution of immigrants from the country of origin (O) to the county (C) during the 1900s, using area weight.
save Moc1900s.dta, replace

collapse (sum) Moc1900s, by(bpl_final)
rename Moc1900s Mo1900s // Mo1900s: The number of immigrants from country of origin (O) to the United States during the 1900s, aggregated for each country.
save Mo1900s.dta, replace

use 1900sbpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1900s.dta"
sort cty_fips bpl_final
replace Moc1900s = 0 if Moc1900s ==.
drop _merge
merge m:1 bpl_final using "Mo1900s.dta" // bpl_final==50 3,109 not matched
sort cty_fips bpl_final
drop _merge // all matched

gen share1900s = Moc1900s/Mo1900s

save share1900s.dta, replace


***********
** 1910s **
***********
use immonly_1920, clear
** Immigrants who arrived during the 1910s
drop if yrimmig < 1910 // 8,740,965 dropped
drop if yrimmig == 1920 // 4,788 drppped >> finally 3,422,450 remained
joinby stateicp countyicp using eglp_1920.dta, unm(b)
tab _merge
tab stateicp if _merge == 1 // 276 (only master - nevada, oregon, virginia)
tab statenam if _merge == 2 // 894
keep if _merge == 3
gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1910s_temp.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3 //   puerto rico (22,149), US virgin(2,392), north america(230); western europe (193) southern europe (652)
tab bpl if merge_bpl != 3, nol 
replace bpl_final = 35 if bpl ==  429 | bpl ==  440 // Western | Southern europe > 35 (europe non specified)
drop if bpl_final == . // Unspecified (total:26,104: including puerto rico + US virgin 24,541)

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
rename weight Moc1910s // Moc1910s: The distribution of immigrants from the country of origin (O) to the county (C) during the 1910s, using area weight.
save Moc1910s.dta, replace

collapse (sum) Moc1910s, by(bpl_final)
rename Moc1910s Mo1910s // Mo1910s: The number of immigrants from country of origin (O) to the United States during the 1910s, aggregated for each country.
save Mo1910s.dta, replace

use 1910sbpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1910s.dta"
sort cty_fips bpl_final
replace Moc1910s = 0 if Moc1910s ==.
drop _merge
merge m:1 bpl_final using "Mo1910s.dta" // bpl_final==50 3,110 not matched
sort cty_fips bpl_final
drop _merge // all matched

gen share1910s = Moc1910s/Mo1910s

save share1910s.dta, replace

***********
** 1920s **
***********
use immonly_1930.dta, clear
** Immigrants who arrived during the 1920s
drop if yrimmig < 1920 // 9,583,880 dropped
drop if yrimmig == 1930 // 44,662 drppped >> finally 2,669,850 remained

joinby stateicp countyicp using eglp_1930.dta, unm(b)
tab _merge // 133(only master - nevada, oregon), 1,601(only using)
tab stateicp if _merge == 1 // 133 (only master - nevada, oregon)
tab statenam if _merge == 2 // 1,601
keep if _merge == 3
gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1920s_temp.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3
tab bpl if merge_bpl != 3, nol //  puerto rico (98,612), US virgin(7,543), north america(193); western europe (62) southern europe (227)
replace bpl_final = 35 if bpl ==  429 | bpl ==  440 // Western | Southern europe > 35 (europe non specified)
replace bpl_final = 7 if bpl == 519 // southeast asia > 41 (asia non specified)
drop if bpl_final == . // Unspecified (total 106,903: including puerto rico + US virgin 106,155)

save 1920s_cty_bpl_temp.dta, replace

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
save 1920sbpl.dta, replace

restore

collapse (sum) weight, by(cty_fips bpl_final) 
rename weight Moc1920s // Moc1920s: The distribution of immigrants from the country of origin (O) to the county (C) during the 1920s, using area weight.
save Moc1920s.dta, replace


collapse (sum) Moc1920s, by(bpl_final)
rename Moc1920s Mo1920s // Mo1920s: The number of immigrants from country of origin (O) to the United States during the 1920s, aggregated for each country.
save Mo1920s.dta, replace

use 1920sbpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1920s.dta"
sort cty_fips bpl_final
replace Moc1920s = 0 if Moc1920s ==.
drop _merge
merge m:1 bpl_final using "Mo1920s.dta"
sort cty_fips bpl_final
drop _merge // all matched

gen share1920s = Moc1920s/Mo1920s
drop if cty_fips == . // missing value
save share1920s.dta, replace

********************************************
*** 1970 crosswalk (Justin C. Wiltshire) ***
*** from 1970 county group to 1970 fips  ***
*** No need to consider perwt		 ***
*** : all weights are same as 100 (flat) ***
********************************************
use 1970.dta, clear
drop if age<15
drop if age>64
tab yrimmig
tab yrimmig, nol
keep if yrimmig == 1960 |  yrimmig == 1965 

joinby cntygp97 using cw_ctygrp_cty_1970m.dta, unm(b)
tab _merge
keep if _merge == 3 // unmatched observations: Alaska & Hawaii - not identified in Wiltshire's crosswalk
drop _merge
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1 // american samoa
replace bpl_final = 50 if bpl_final ==. // US territories: 50
drop if merge_bpl == 2 // # 30
drop merge_bpl
save 1960scty_bpl_new_temp.dta, replace

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
save 1960sbpl.dta, replace

restore

collapse (sum) afact, by(cty_fips bpl_final) // ** No need: collapse (sum) weight [fw=perwt], by(cty_fips bpl_final) : all weights are same as 100 (flat)
rename afact Moc1960s // Moc1960s: The distribution of immigrants from the country of origin (O) to the county (C) during the 1960s, using area weight.
save Moc1960s.dta, replace 

collapse (sum) Moc1960s, by(bpl_final)
rename Moc1960s Mo1960s // Mo1960s: The number of immigrants from country of origin (O) to the United States during the 1960s, aggregated for each country.
save Mo1960s.dta, replace

use 1960sbpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1960s.dta"
sort cty_fips bpl_final
replace Moc1970 = 0 if Moc1970 ==.
drop _merge
merge m:1 bpl_final using "Mo1960s.dta"
sort cty_fips bpl_final
drop _merge // all matched

gen share1960s = Moc1960s/Mo1960s
** David Dorn: 12025 > 12086(1997) // 46113 > 46102 (2015)
replace cty_fips = 12086 if cty_fips == 12025 // 1997 changes
replace cty_fips = 46113 if cty_fips == 46102 // 2015 changes


save share1960s.dta, replace


********************************************
*** 1980 crosswalk (Justin C. Wiltshire) ***
*** from 1980 county group to "1970" fips **
*** No need to consider perwt		 ***
*** : all weights are same as 100 (flat) ***
********************************************
/* use cw_ctygrp_cty_1980m.dta, clear
ren county_grp80 cntygp98
save cw_ctygrp_cty_1980m.dta, replace */
use 1980.dta, clear
replace cntygp98 = statefip*1000 + cntygp98 // It is essential to match the variable names between the crosswalk and census data.
* unique cntygp98

tab yrimmig
tab yrimmig, nol
keep if yrimmig == 1970 |  yrimmig == 1975
joinby cntygp98 using cw_ctygrp_cty_1980m.dta, unm(b)

tab _merge
tab cntygp98 if _merge == 1 // 607: alaska, hawaii
keep if _merge == 3 // unmatched observations: Alaska & Hawaii - not identified in Wiltshire's crosswalk
drop _merge
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)

replace bpl_final = 50 if bpl_final ==. // US territories: 50
drop if merge_bpl == 2 // # 10
drop merge_bpl
save 1970scty_bpl_new_temp.dta, replace

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
save 1970sbpl.dta, replace

restore

collapse (sum) afact, by(cty_fips bpl_final) // ** No need: collapse (sum) weight [fw=perwt], by(cty_fips bpl_final)
rename afact Moc1970s // Moc1980: distribution of immigrants by area weight from country of origin O to county C at 1980
save Moc1970s.dta, replace

collapse (sum) Moc1970s, by(bpl_final)
rename Moc1970s Mo1970s // Mo1980: number of immigrants from country of origin O to US at 1980, aggregate imm for each country
save Mo1970s.dta, replace

use 1970sbpl.dta, clear

merge m:1 cty_fips bpl_final using "Moc1970s.dta"
sort cty_fips bpl_final
replace Moc1970s = 0 if Moc1970s ==.
drop _merge
merge m:1 bpl_final using "Mo1970s.dta"
sort cty_fips bpl_final
drop _merge // all matched

gen share1970s = Moc1970s/Mo1970s
** David Dorn: 12025 > 12086(1997) // 46113 > 46102 (2015)
replace cty_fips = 12086 if cty_fips == 12025 // 1997 changes
replace cty_fips = 46113 if cty_fips == 46102 // 2015 changes

save share1970s.dta, replace

**********************************
** Merging 1890s - 1920s & 1970 **
**********************************
use share1890s.dta, clear
joinby cty_fips bpl_final using share1900s.dta, unm(b)
drop _merge
joinby cty_fips bpl_final using share1910s.dta, unm(b)
drop _merge
joinby cty_fips bpl_final using share1920s.dta, unm(b)
drop _merge
joinby cty_fips bpl_final using share1960s.dta, unm(b)
drop _merge
joinby cty_fips bpl_final using share1970s.dta, unm(b)
drop _merge

sort cty_fips bpl_final
drop if bpl_final == 50
save immshare_hist_final.dta, replace

*** End of this file ***
