************************************************
* Historical Immigrant Share
* Data Sources:
*   - IPUMS Full-Count (1900-1930)
*   - 1% Metro (fm1) for 1970 & 1% Metro (1980)
* Crosswalks:
*   - Eckert (1900-1930)
*   - Wiltshire (1970, 1980)
* Written by: Jae Young Baak
* First created: 2023-10-09
* Last updated: 2024-11-02
* Output data file: immshare_hist.dta
************************************************

clear all
set more off
cd "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_hist_final"

***************************************
*** Crosswalk (EGLP - Eckert) *******
***    1900, 1910, 1920, 1930      ***
***************************************
import delimited "eglp_county_crosswalk_endyr_2010.csv", clear
sort year icpsrst icpsrcty weight
drop icpsrst_2010 icpsrcty_2010 area us_state nhgisst nhgiscty
    // Dropping columns not needed
rename icpsrst stateicp
rename icpsrcty countyicp

keep if year > 1890    // Keep only years from 1900 onward
save eglptemp.dta, replace

*-----------------------------------------------------*
* Split the EGLP crosswalk into separate files by year
*-----------------------------------------------------*
foreach value in 1900 1910 1920 1930 1940 1950 1960 1970 1980 1990 2000 {
    use eglptemp.dta, clear
    keep if year == `value'
    save eglp_`value'.dta, replace
}

***************
*** IPUMS *****
***************
* (Commented out code to process IPUMS data for each year)
*
* foreach value in 1900 1910 1920 1930 {
*   use `value'_full.dta, clear
*   drop if age<15
*   drop if age>64
*   drop sample serial hhwt gq metro metarea metaread pernum perwt bpld mbpl mbpld fbpl fbpld nativity citizen versionhist histid region sex age birthyr occ1950 ind1950
*   drop if yrimmig == 0   // drop US native-born
*   save "Immonly_`value'.dta", replace
* }

***********
** 1890s **
***********
use immonly_1900, clear
* Immigrants who arrived during the 1890s
drop if yrimmig < 1890       // Remove earlier arrivals
drop if yrimmig == 1900     // Remove arrivals in 1900 itself
                            // End up with only 1890–1899 arrivals
joinby stateicp countyicp using eglp_1900.dta, unm(b) 
    // Match each immigrant record to its county using the 1900 Eckert crosswalk
tab _merge
tab stateicp if _merge == 1 // Observations only in master
tab statenam if _merge == 2 // Observations only in using
keep if _merge == 3         // Keep matched observations only

gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1890s_temp.dta, replace

*-----------------------------------------------------*
* Merge with BPL_FINAL to unify birthplace codes
*-----------------------------------------------------*
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3  // Checking non-matches
tab bpl if merge_bpl != 3, nol
replace bpl_final = 35 if bpl == 429 | bpl == 440  // Set certain unspecified Europe codes to 35
drop if bpl_final == .                            // Drop if no final BPL is assigned

save 1890s_cty_bpl_temp.dta, replace

preserve 
    *---------------------------------------------*
    * Create a dataset with 50 birthplaces (bpl_final)
    * for each county (cty_fips)
    *---------------------------------------------*
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

*-----------------------------------------------------*
* Mo_c: number of immigrants from origin O to county C
*-----------------------------------------------------*
collapse (sum) weight, by(cty_fips bpl_final)
rename weight Moc1890s
save Moc1890s.dta, replace

*-----------------------------------------------------*
* Mo: total immigrants from origin O to the US 
*-----------------------------------------------------*
collapse (sum) Moc1890s, by(bpl_final)
rename Moc1890s Mo1890s
save Mo1890s.dta, replace

use 1890sbpl.dta, clear
merge m:1 cty_fips bpl_final using "Moc1890s.dta"
sort cty_fips bpl_final
replace Moc1890s = 0 if Moc1890s ==.
drop _merge
merge m:1 bpl_final using "Mo1890s.dta"
sort cty_fips bpl_final
drop _merge

gen share1890s = Moc1890s / Mo1890s
save share1890s.dta, replace


***********
** 1900s **
***********
use immonly_1910, clear
* Immigrants who arrived during the 1900s
drop if yrimmig < 1900
drop if yrimmig == 1910
joinby stateicp countyicp using eglp_1910.dta, unm(b)
tab _merge
tab stateicp if _merge == 1
tab statenam if _merge == 2
keep if _merge == 3

gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1900s_temp.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3
tab bpl if merge_bpl != 3, nol
replace bpl_final = 35 if bpl == 429 | bpl == 440
drop if bpl_final == .

save 1900s_cty_bpl_temp.dta, replace

preserve
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
rename weight Moc1900s
save Moc1900s.dta, replace

collapse (sum) Moc1900s, by(bpl_final)
rename Moc1900s Mo1900s
save Mo1900s.dta, replace

use 1900sbpl.dta, clear
merge m:1 cty_fips bpl_final using "Moc1900s.dta"
sort cty_fips bpl_final
replace Moc1900s = 0 if Moc1900s ==.
drop _merge
merge m:1 bpl_final using "Mo1900s.dta"
sort cty_fips bpl_final
drop _merge

gen share1900s = Moc1900s / Mo1900s
save share1900s.dta, replace


***********
** 1910s **
***********
use immonly_1920, clear
* Immigrants who arrived during the 1910s
drop if yrimmig < 1910
drop if yrimmig == 1920
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
replace bpl_final = 35 if bpl == 429 | bpl == 440
drop if bpl_final == .

save 1910s_cty_bpl_temp.dta, replace

preserve
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
rename weight Moc1910s
save Moc1910s.dta, replace

collapse (sum) Moc1910s, by(bpl_final)
rename Moc1910s Mo1910s
save Mo1910s.dta, replace

use 1910sbpl.dta, clear
merge m:1 cty_fips bpl_final using "Moc1910s.dta"
sort cty_fips bpl_final
replace Moc1910s = 0 if Moc1910s ==.
drop _merge
merge m:1 bpl_final using "Mo1910s.dta"
sort cty_fips bpl_final
drop _merge

gen share1910s = Moc1910s / Mo1910s
save share1910s.dta, replace


***********
** 1920s **
***********
use immonly_1930.dta, clear
* Immigrants who arrived during the 1920s
drop if yrimmig < 1920
drop if yrimmig == 1930
joinby stateicp countyicp using eglp_1930.dta, unm(b)
tab _merge
tab stateicp if _merge == 1
tab statenam if _merge == 2
keep if _merge == 3

gen cty_fips = nhgisst_2010*100 + nhgiscty_2010
keep year bpl yrimmig statenam nhgisnam area_base weight cty_fips
save 1920s_temp.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl != 3
tab bpl if merge_bpl != 3, nol
replace bpl_final = 35 if bpl == 429 | bpl == 440
replace bpl_final = 7 if bpl == 519 // Example: set specific Asia code
drop if bpl_final == .

save 1920s_cty_bpl_temp.dta, replace

preserve
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
rename weight Moc1920s
save Moc1920s.dta, replace

collapse (sum) Moc1920s, by(bpl_final)
rename Moc1920s Mo1920s
save Mo1920s.dta, replace

use 1920sbpl.dta, clear
merge m:1 cty_fips bpl_final using "Moc1920s.dta"
sort cty_fips bpl_final
replace Moc1920s = 0 if Moc1920s ==.
drop _merge
merge m:1 bpl_final using "Mo1920s.dta"
sort cty_fips bpl_final
drop _merge

gen share1920s = Moc1920s / Mo1920s
drop if cty_fips == .
save share1920s.dta, replace


*******************************************
*** 1970 Crosswalk (Wiltshire)          ***
*** from 1970 county group to 1970 FIPS ***
*******************************************
use 1970.dta, clear
drop if age<15
drop if age>64
tab yrimmig
tab yrimmig, nol
keep if yrimmig == 1960 | yrimmig == 1965

joinby cntygp97 using cw_ctygrp_cty_1970m.dta, unm(b)
    // Linking county group identifiers to actual county FIPS
tab _merge
keep if _merge == 3
drop _merge

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1  // e.g., American Samoa
replace bpl_final = 50 if bpl_final ==. // Assign code 50 to US territories
drop if merge_bpl == 2
drop merge_bpl
save 1960scty_bpl_new_temp.dta, replace

preserve
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

collapse (sum) afact, by(cty_fips bpl_final)
rename afact Moc1960s
save Moc1960s.dta, replace

collapse (sum) Moc1960s, by(bpl_final)
rename Moc1960s Mo1960s
save Mo1960s.dta, replace

use 1960sbpl.dta, clear
merge m:1 cty_fips bpl_final using "Moc1960s.dta"
sort cty_fips bpl_final
replace Moc1960s = 0 if Moc1960s ==.
drop _merge
merge m:1 bpl_final using "Mo1960s.dta"
sort cty_fips bpl_final
drop _merge

gen share1960s = Moc1960s / Mo1960s
* Adjust for county redefinitions in David Dorn data
replace cty_fips = 12086 if cty_fips == 12025  // 1997
replace cty_fips = 46113 if cty_fips == 46102  // 2015

save share1960s.dta, replace


*******************************************
*** 1980 Crosswalk (Wiltshire)          ***
*** from 1980 county group to 1970 FIPS ***
*******************************************
/* 
use cw_ctygrp_cty_1980m.dta, clear
ren county_grp80 cntygp98
save cw_ctygrp_cty_1980m.dta, replace
*/

use 1980.dta, clear
replace cntygp98 = statefip*1000 + cntygp98
    // Combine state FIPS with county group ID to match crosswalk format

tab yrimmig
tab yrimmig, nol
keep if yrimmig == 1970 | yrimmig == 1975

joinby cntygp98 using cw_ctygrp_cty_1980m.dta, unm(b)
tab _merge
tab cntygp98 if _merge == 1  // Typically Alaska, Hawaii
keep if _merge == 3
drop _merge

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
replace bpl_final = 50 if bpl_final ==.
drop if merge_bpl == 2
drop merge_bpl
save 1970scty_bpl_new_temp.dta, replace

preserve
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

collapse (sum) afact, by(cty_fips bpl_final)
rename afact Moc1970s
save Moc1970s.dta, replace

collapse (sum) Moc1970s, by(bpl_final)
rename Moc1970s Mo1970s
save Mo1970s.dta, replace

use 1970sbpl.dta, clear
merge m:1 cty_fips bpl_final using "Moc1970s.dta"
sort cty_fips bpl_final
replace Moc1970s = 0 if Moc1970s ==.
drop _merge
merge m:1 bpl_final using "Mo1970s.dta"
sort cty_fips bpl_final
drop _merge

gen share1970s = Moc1970s / Mo1970s
* Again, county redefinition fixes
replace cty_fips = 12086 if cty_fips == 12025
replace cty_fips = 46113 if cty_fips == 46102

save share1970s.dta, replace


*******************************************************
*** Merge all historical shares: 1890s–1920s & 1970 ***
*******************************************************
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
