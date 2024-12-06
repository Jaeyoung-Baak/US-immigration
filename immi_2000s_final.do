********************************************************************************
* County variables - immigrant share & other variables
* Data: IPUMS - 2005-2021 ACS
* Two Crosswalk Processes
* 1) 2000PUMAs;2005-2011 ACS years: 2000puma > 2010puma > fips
* 2) 2010PUMAs;2012-2021 ACS years: 2010puma > fips
* Written by Jae Young Baak 
* First created date: 2023-11-05
* Last update: 2024-07-16
* Outcome files: immIV_new_final.dta
********************************************************************************

***
clear all
set more off
set matsize 1000
cd ""

*2000PUMAs: 2005-2011* ACS year
*2010PUMAs: 2012-2021 ACS year
***************
** upto 2011 **
***************
use currentACS.dta, clear
keep if year < 2012
sort year statefip countyfip puma
joinby statefip puma using puma2000_2010_cw.dta, unm(b)
save puma00_puma10_temp.dta, replace
tab _merge
drop if _merge == 1 // louisiana only, 6,509 obs
drop if _merge == 2 // statefip: puerto rico only, 99 obs

order year statefip puma State10 PUMA10 bpl
sort year State10 PUMA10 statefip puma bpl
gen fweight=pPUMA00_Pop10/100 // fweight ∈ [0,1] 

collapse (sum) fweight [fw=perwt], by(year State10 PUMA10 bpl)
ren State10 statefip
ren PUMA10 puma
save puma_fip_weight_upto2011_temp.dta, replace

sort year statefip puma
joinby statefip puma using cw2010_puma_fips.dta, unm(b)
drop _merge // all matched
sort year statefip bpl cty_fips
collapse (sum) fweight [pw=popweight], by(year statefip bpl cty_fips)
drop statefip
order year cty_fips bpl fweight
save puma_fip_weight_upto2011.dta, replace
**********
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1
tab bpl if merge_bpl == 1, nol // US territories: 1~56, 100(american samoa) 105(guam) 110(perto rico) 115(u.s. virgin islands)
replace bpl_final = 50 if bpl_final ==. // US territories: 50
tab bpl if merge_bpl == 2
drop if merge_bpl == 2 // # of 18
drop bpl_name bpl_temp merge_bpl
order year cty_fips bpl_final
sort year cty_fips bpl_final
save cty_bpl_temp_upto2011.dta, replace

preserve 

collapse (sum) fweight, by(year cty_fips bpl_final)
collapse (first) bpl_final fweight, by(year cty_fips)
replace bpl_final = 1
drop fweight
expand 50
sort year cty_fips
quietly by year cty_fips: gen dup=cond(_N==1,0,_n)
replace bpl_final=dup
drop dup
save bpl_upto2011.dta, replace

restore

collapse (sum) fweight, by(year cty_fips bpl_final)
rename fweight Moct // Moct: distribution of immigrants by area weight from country of origin O to county C at t (t: upto 2010)
save Moct_upto2011.dta, replace

collapse (sum) Moct, by(year bpl_final)
rename Moct Mot // Mot: number of immigrants from country of origin O to US at t, aggregate imm for each country
save Mot_upto2011.dta, replace

use bpl_upto2011.dta, clear
merge m:1 year cty_fips bpl_final using "Moct_upto2011.dta"
sort year cty_fips bpl_final // merge==2: 0
replace Moct = 0 if Moct ==.
drop _merge
merge m:1 year bpl_final using "Mot_upto2011.dta"
sort year cty_fips bpl_final
drop _merge // all matched

sort year cty_fips bpl_final
gen share_t = Moct/Mot

save share_upto2011.dta, replace


***************
** from 2012 **
***************
use currentACS.dta, clear
keep if year > 2011

sort year statefip countyfip puma
joinby statefip puma using cw2010_puma_fips.dta, unm(b) // using 2010 puma file & all matched
tab _merge
drop _merge // All matched
save puma_fip_weight_from2012.dta, replace
**********
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1
tab bpl if merge_bpl == 1, nol // US territories: 1~56, 100(american samoa) 105(guam) 110(perto rico) 115(u.s. virgin islands)
replace bpl_final = 50 if bpl_final ==. 
tab bpl if merge_bpl == 2 // # of 16
drop if merge_bpl == 2

save cty_bpl_temp_from2012.dta,replace

preserve 

collapse (sum) popweight, by(year cty_fips bpl_final)
collapse (first) bpl_final popweight, by(year cty_fips)
replace bpl_final = 1
drop popweight
expand 50
sort year cty_fips
quietly by year cty_fips: gen dup=cond(_N==1,0,_n)
replace bpl_final=dup
drop dup
save bpl_from2012.dta, replace

restore

collapse (sum) popweight [fw=perwt], by(year cty_fips bpl_final)
rename popweight Moct // Moct: distribution of immigrants by area weight from country of origin O to county C at t, t: ~2011
save Moct_from2012.dta, replace

collapse (sum) Moct, by(year bpl_final)
rename Moct Mot // Mot: number of immigrants from country of origin O to US at t, aggregate imm for each country
save Mot_from2012.dta, replace

use bpl_from2012.dta, clear
merge m:1 year cty_fips bpl_final using "Moct_from2012.dta"
sort year cty_fips bpl_final // merge==2: 0
replace Moct = 0 if Moct ==.
drop _merge
merge m:1 year bpl_final using "Mot_from2012.dta"
sort year cty_fips bpl_final
drop _merge // all matched

gen share_t = Moct/Mot
save share_from2012.dta, replace

****
use share_upto2011.dta, clear
append using share_from2012.dta
ren share_t Moct_Mot // Moct/Mot (Share)
save share_2000s_temp.dta, replace
****
use share_2000s_temp.dta, clear
sort year cty_fips
by year cty_fips: egen cty_pop = sum(Moct) // immshare
drop if bpl_final == 50
save ctypop_temp.dta, replace

collapse (sum) Moct (first) cty_pop, by (year cty_fips) // current immigrant share

sort cty_fips year
by cty_fips: gen immshare_ct = Moct / cty_pop[_n-1] // Constructing immshare_ct: (# of imm)/(Totpop_c,t-1) 
sort year cty_fips
save immshare_temp.dta, replace
****
use share_2000s_temp.dta, clear
joinby year cty_fips using immshare_temp.dta, unm(b)
tab _merge
drop _merge // all matched
sort year cty_fips bpl_final
gen bpl_oneout = Mot-Moct // leave-one-out version
save immshare_current.dta, replace

***********************************************
** Merging current data with historical data **
***********************************************
use immshare_hist_final.dta, clear
expand 17 // The number of sample years (2005-2021)
sort cty_fips bpl_final
quietly by cty_fips bpl_final: gen dup=cond(_N==1,0,_n)
gen year = 2004 + dup
order year cty_fips bpl_final
merge 1:1 year cty_fips bpl_final using immshare_current.dta
drop if bpl_final == 50
tab cty_fips if _merge == 1
tab cty_fips if _merge == 2
keep if _merge == 3
drop _merge
drop dup
order year cty_fips bpl_final Moct Mot bpl_oneout Moct_Mot immshare_ct cty_pop
save immshare_new.dta, replace

**********************************
**   Construct shift-share IV   **
**********************************
use immshare_new.dta, clear

** Current National Imm * Historical share
foreach value in 1910s 1920s 1960s {
	gen Mot_share`value' = Mot*share`value' // Mot: the number of nation immigrants from origin country O to US, at time t, where t = 2005~2021
											// share`var': historical share (for specific county) Sh_oc𝛕
	gen bpl_oneout_share`value' = bpl_oneout*share`value'
} 

** egen share_real = total(Moct), by(year cty_fips) // the current share of immigrant in each county (without US bpl)
foreach value in 1910s 1920s 1960s {
	egen predicted_imm_`value' = total(Mot_share`value'), by(year cty_fips)
	egen oneout_predicted_imm_`value' = total(bpl_oneout_share`value'), by(year cty_fips)
}
collapse (first) immshare_ct cty_pop predicted_imm_1910s predicted_imm_1920s predicted_imm_1960s oneout_predicted_imm_1910s oneout_predicted_imm_1920s oneout_predicted_imm_1960s, by (year cty_fips)

sort cty_fips year // different order!
foreach value in 1910s 1920s 1960s {
	by cty_fips: gen immIV_`value' = predicted_imm_`value'/cty_pop[_n-1] // predicted immigrant share
	by cty_fips: gen immIVoneout_`value' = oneout_predicted_imm_`value'/cty_pop[_n-1] // predicted immigrant share (oneout version)
}
sort year cty_fips
keep year cty_fips immshare_ct cty_pop immIV_1910s immIVoneout_1910s immIV_1920s immIVoneout_1920s immIV_1960s immIVoneout_1960s
order year cty_fips immshare_ct cty_pop immIV_1910s immIVoneout_1910s immIV_1920s immIVoneout_1920s immIV_1960s immIVoneout_1960s

save immIV_new_final.dta, replace


*** End of this file ***
