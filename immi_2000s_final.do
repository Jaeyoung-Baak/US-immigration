****************************************************************
* County variables - immigrant share & other variables
* Data: IPUMS - 2005-2021 ACS
* Two Crosswalk Processes
* 1) 2000PUMAs; 2005-2011 ACS years: 2000puma > 2010puma > fips
* 2) 2010PUMAs; 2012-2021 ACS years: 2010puma > fips
* Written by Jae Young Baak 
* First created date: 2023-11-05
* Last update: 2024-11-02 // Add inc variables
* Outcome files: immIV_new_final.dta
****************************************************************

***
clear all
set more off
set matsize 1000
cd "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_current_final"

*-----------------------------------------------------*
* (Optional) The following lines show how raw ACS data 
* might have been pre-processed but are commented out
*-----------------------------------------------------*
/*
use "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_hist/usa_00026.dta", clear
drop if year < 2005
drop if age<15
drop if age>64
drop sample serial cbserial cluster region metro metarea metaread strata gq momrule poprule mom2rule pop2rule sex age birthyr citizen occ occ2010 ind indnaics
save currentACS.dta, replace
*/

*-----------------------------------------------------*
*  P A R T   1 :  2005 - 2011 (Using 2000 PUMAs)
*-----------------------------------------------------*
use currentACS.dta, clear
keep if year < 2012                     // Keep ACS records from 2005 to 2011
sort year statefip countyfip puma
joinby statefip puma using puma2000_2010_cw.dta, unm(b) 
    // Match each observation to 2000->2010 PUMA crosswalk data
save puma00_puma10_temp.dta, replace
tab _merge

order year statefip puma State10 PUMA10 bpl
sort year State10 PUMA10 statefip puma bpl
gen fweight = pPUMA00_Pop10/100        // Fractional weight (between 0 and 1)

*-----------------------------------------------------*
* Aggregate fractional weights by year/state/PUMA/bpl
*-----------------------------------------------------*
collapse (sum) fweight [fw=perwt], by(year State10 PUMA10 bpl) 
    // Summation of fweights, using population weights (perwt)
ren State10 statefip
ren PUMA10 puma
save puma_fip_weight_upto2011_temp.dta, replace

sort year statefip puma
joinby statefip puma using cw2010_puma_fips.dta, unm(b) 
    // Match each observation to county FIPS crosswalk
drop _merge
sort year statefip bpl cty_fips
collapse (sum) fweight [pw=popweight], by(year statefip bpl cty_fips)
    // Sum of fractional weights, weighted by popweight
drop statefip
order year cty_fips bpl fweight
save puma_fip_weight_upto2011.dta, replace

*-----------------------------------------------------*
* Merge with final BPL (country of birth) info
*-----------------------------------------------------*
merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1
tab bpl if merge_bpl == 1, nol         // Checking US territories
replace bpl_final = 50 if bpl_final ==.// Assign code 50 for US territories
tab bpl if merge_bpl == 2
drop if merge_bpl == 2                // Drop unmerged countries
drop bpl_name bpl_temp merge_bpl
order year cty_fips bpl_final
sort year cty_fips bpl_final
save cty_bpl_temp_upto2011.dta, replace

preserve
    *---------------------------------------------*
    * Create a dataset with 50 rows per county
    * representing all possible bpl_final values
    *---------------------------------------------*
    collapse (sum) fweight, by(year cty_fips bpl_final)
    collapse (first) bpl_final fweight, by(year cty_fips)
    replace bpl_final = 1
    drop fweight
    expand 50
    sort year cty_fips
    quietly by year cty_fips: gen dup = cond(_N==1,0,_n)
    replace bpl_final=dup
    drop dup
    save bpl_upto2011.dta, replace
restore

*-----------------------------------------------------*
* Moct: Number of immigrants from country O to county C
* at time t, t ≤ 2011 (using the collapsed fweight)
*-----------------------------------------------------*
collapse (sum) fweight, by(year cty_fips bpl_final)
rename fweight Moct
save Moct_upto2011.dta, replace

*-----------------------------------------------------*
* Mot: Number of immigrants from country O to the US 
* at time t, aggregated for each country
*-----------------------------------------------------*
collapse (sum) Moct, by(year bpl_final)
rename Moct Mot
save Mot_upto2011.dta, replace

*-----------------------------------------------------*
* Merge Moct and Mot back into the dataset to compute 
* share_t = Moct / Mot
*-----------------------------------------------------*
use bpl_upto2011.dta, clear
merge m:1 year cty_fips bpl_final using "Moct_upto2011.dta"
sort year cty_fips bpl_final
replace Moct = 0 if Moct ==.
drop _merge
merge m:1 year bpl_final using "Mot_upto2011.dta"
sort year cty_fips bpl_final
drop _merge
sort year cty_fips bpl_final
gen share_t = Moct / Mot
save share_upto2011.dta, replace


*-----------------------------------------------------*
*  P A R T   2 :  2012 - 2021 (Using 2010 PUMAs)
*-----------------------------------------------------*
use currentACS.dta, clear
keep if year > 2011
sort year statefip countyfip puma
joinby statefip puma using cw2010_puma_fips.dta, unm(b)  // Match to 2010 PUMA -> county FIPS
tab _merge
drop _merge
save puma_fip_weight_from2012.dta, replace

merge m:1 bpl using "BPL_FINAL.dta", gen(merge_bpl)
tab bpl if merge_bpl == 1
tab bpl if merge_bpl == 1, nol
replace bpl_final = 50 if bpl_final ==. 
tab bpl if merge_bpl == 2 
drop if merge_bpl == 2

save cty_bpl_temp_from2012.dta, replace

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
rename popweight Moct
save Moct_from2012.dta, replace

collapse (sum) Moct, by(year bpl_final)
rename Moct Mot
save Mot_from2012.dta, replace

use bpl_from2012.dta, clear
merge m:1 year cty_fips bpl_final using "Moct_from2012.dta"
sort year cty_fips bpl_final
replace Moct = 0 if Moct ==.
drop _merge
merge m:1 year bpl_final using "Mot_from2012.dta"
sort year cty_fips bpl_final
drop _merge

gen share_t = Moct / Mot
save share_from2012.dta, replace

*-----------------------------------------------------*
* Append 2005-2011 and 2012-2021 shares
*-----------------------------------------------------*
use share_upto2011.dta, clear
append using share_from2012.dta
ren share_t Moct_Mot
save share_2000s_temp.dta, replace

*-----------------------------------------------------*
* Create a county population measure and immigrant share
*-----------------------------------------------------*
use share_2000s_temp.dta, clear
sort year cty_fips
by year cty_fips: egen cty_pop = sum(Moct)  // total immigrants across all bpl_final!=50
drop if bpl_final == 50
save ctypop_temp.dta, replace

collapse (sum) Moct (first) cty_pop, by(year cty_fips)
sort cty_fips year
by cty_fips: gen immshare_ct = Moct / cty_pop[_n-1]
    // Immigrant share in year t using population from year t-1
sort year cty_fips
save immshare_temp.dta, replace

*-----------------------------------------------------*
* Merge immshare back with original share data
*-----------------------------------------------------*
use share_2000s_temp.dta, clear
joinby year cty_fips using immshare_temp.dta, unm(b)
tab _merge
drop _merge
sort year cty_fips bpl_final
gen bpl_oneout = Mot - Moct   // "One-out" version: exclude own origin from total
save immshare_current.dta, replace


*-----------------------------------------------------*
* Merge with historical data to create immshare_new.dta
*-----------------------------------------------------*
use "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_hist_final/immshare_hist_final.dta", clear
expand 17                                 // Create rows for 17 years
sort cty_fips bpl_final
quietly by cty_fips bpl_final: gen dup=cond(_N==1,0,_n)
gen year = 2004 + dup
order year cty_fips bpl_final
merge 1:1 year cty_fips bpl_final using immshare_current.dta
drop if bpl_final == 50                   // Not identified in historical data
tab cty_fips if _merge == 1               // Observations only in master
tab cty_fips if _merge == 2               // Observations only in using
keep if _merge == 3                       // Keep matched
drop _merge
drop dup
order year cty_fips bpl_final Moct Mot bpl_oneout Moct_Mot immshare_ct cty_pop
save immshare_new.dta, replace


*-----------------------------------------------------*
* Construct predicted immigrant shares using historical 
* proportions and current total immigrant numbers
*-----------------------------------------------------*
use immshare_new.dta, clear

* Current National Imm * Historical share
foreach value in 1890s 1900s 1910s 1920s 1960s 1970s {
    gen Mot_share`value' = Mot * share`value'         // Predicted # from country O in county (historical share × current total)
    gen bpl_oneout_share`value' = bpl_oneout * share`value'
}

*-----------------------------------------------------*
* Summarize across all birthplaces within each county 
* to get total predicted immigrant population
*-----------------------------------------------------*
foreach value in 1890s 1900s 1910s 1920s 1960s 1970s {
    egen predicted_imm_`value' = total(Mot_share`value'), by(year cty_fips)
    egen oneout_predicted_imm_`value' = total(bpl_oneout_share`value'), by(year cty_fips)
}

collapse (first) immshare_ct cty_pop ///
         predicted_imm_1890s predicted_imm_1900s predicted_imm_1910s predicted_imm_1920s ///
         predicted_imm_1970s predicted_imm_1960s ///
         oneout_predicted_imm_1890s oneout_predicted_imm_1900s oneout_predicted_imm_1910s ///
         oneout_predicted_imm_1920s oneout_predicted_imm_1970s oneout_predicted_imm_1960s, by (year cty_fips)

sort cty_fips year
foreach value in 1890s 1900s 1910s 1920s 1960s 1970s {
    by cty_fips: gen immIV_`value' = predicted_imm_`value' / cty_pop[_n-1] 
        // Predicted immigrant share in year t using t-1 county population
    by cty_fips: gen immIVoneout_`value' = oneout_predicted_imm_`value' / cty_pop[_n-1]
        // "One-out" predicted share
}
sort year cty_fips

save immIV_new_temp.dta, replace

*** End of this file ***
