********************************************************************************
* County variables - immigrant share & other variables
* Data: IPUMS - 2005-2021 ACS
* Two Crosswalk Processes
* 1) 2000PUMAs;2005-2011 ACS years: 2000puma > 2010puma > fips
* 2) 2010PUMAs;2012-2021 ACS years: 2010puma > fips
* Written by Jae Young Baak 
* First created date: 2023-11-05
* Last update: 2024-03-16 // Add inc variables
* Outcome files: immIV_sc_covariates.dta
********************************************************************************

***
clear all
set more off
set matsize 1000
cd "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_current"

/* use "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_hist/usa_00026.dta", clear
drop if year < 2005
drop if age<15
drop if age>64
drop sample serial cbserial cluster region metro metarea metaread strata gq momrule poprule mom2rule pop2rule sex age birthyr citizen occ occ2010 ind indnaics
save currentACS.dta, replace */

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
gen fweight=pPUMA00_Pop10/100 // fweight ∈ [0,1] // temptemp.dta

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

/* tab cty_fips if share_t > 0.55 // 12086: FL, Miami-dade county
tab bpl_final if share_t > 0.55 // Cuba */ 

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
gen bpl_oneout = Mot-Moct // oneout version
save immshare_current.dta, replace

/* keep if year == 2005 & cty_fips == 1001
collapse (sum) Mot */ // 193,000,000

************ > new immigrants
****
use "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_hist_agedrop/immshare_hist_new.dta", clear
expand 17
sort cty_fips bpl_final
quietly by cty_fips bpl_final: gen dup=cond(_N==1,0,_n)
gen year = 2004 + dup
order year cty_fips bpl_final
merge 1:1 year cty_fips bpl_final using immshare_current.dta // _merge == 1: 1,666 / 2: 81,753 / 3: 2,589,797
drop if bpl_final == 50 // Not identified in immshare_hist_agedrop.dta - 53,431 obs (All from using)
tab cty_fips if _merge == 1 // # 833 - fips 55901 (17*49) 17년 49개bpl
tab cty_fips if _merge == 2 // # 28,322: Alaska(17*49*29), Hawaii (17*49*5) 17년 * 49개bpl * # of unmatched fips
keep if _merge == 3
drop _merge
drop dup
order year cty_fips bpl_final Moct Mot bpl_oneout Moct_Mot immshare_ct cty_pop
save immshare_new.dta, replace
**********************************

use immshare_new.dta, clear

** Current National Imm * Historical share
foreach value in 1890s 1900s 1910s 1920s 1960s 1970s {
	gen Mot_share`value' = Mot*share`value' // Mot: the number of nation immigrants from origin country O to US, at time t, where t = 2005~2021
											// share`var': historical share (for specific county)	Sh_oc𝛕
	gen bpl_oneout_share`value' = bpl_oneout*share`value'
} 

** egen share_real = total(Moct), by(year cty_fips) // the current share of immigrant in each county (without US bpl)
foreach value in 1890s 1900s 1910s 1920s 1960s 1970s {
	egen predicted_imm_`value' = total(Mot_share`value'), by(year cty_fips)
	egen oneout_predicted_imm_`value' = total(bpl_oneout_share`value'), by(year cty_fips)
}
collapse (first) immshare_ct cty_pop predicted_imm_1890s predicted_imm_1900s predicted_imm_1910s predicted_imm_1920s predicted_imm_1970s predicted_imm_1960s oneout_predicted_imm_1890s oneout_predicted_imm_1900s oneout_predicted_imm_1910s oneout_predicted_imm_1920s oneout_predicted_imm_1970s oneout_predicted_imm_1960s, by (year cty_fips)

sort cty_fips year // different order!
foreach value in 1890s 1900s 1910s 1920s 1960s 1970s {
	by cty_fips: gen immIV_`value' = predicted_imm_`value'/cty_pop[_n-1] // predicted immigrant share
	by cty_fips: gen immIVoneout_`value' = oneout_predicted_imm_`value'/cty_pop[_n-1] // predicted immigrant share (oneout version)
}
sort year cty_fips

save immIV_new_temp.dta, replace
keep year cty_fips immshare_ct cty_pop immIV_1890s immIVoneout_1890s immIV_1900s immIVoneout_1900s immIV_1910s immIVoneout_1910s immIV_1920s immIVoneout_1920s immIV_1960s immIVoneout_1960s immIV_1970s immIVoneout_1970s
order year cty_fips immshare_ct cty_pop immIV_1890s immIVoneout_1890s immIV_1900s immIVoneout_1900s immIV_1910s immIVoneout_1910s immIV_1920s immIVoneout_1920s immIV_1960s immIVoneout_1960s immIV_1970s immIVoneout_1970s
save immIV_new_final.dta, replace
***
use immIV_new_final.dta, clear
merge 1:1 year cty_fips using Weighted_data_by2010ctyfips_allyears.dta
keep if _merge == 3  // 578 not matched (from using) (Alaska(17*29), Hawaii (17*5) 17년 * 34counties)
drop _merge
merge 1:1 year cty_fips using Income_Weighted_data_by2010ctyfips_allyears_income.dta
keep if _merge == 3  // 578 not matched (from using) 34counties * 17years
drop _merge
order year statefip cty_fips immshare_ct cty_pop

**
foreach value in 1 4 5 6 8 9 10 11 12 13 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56{
	gen st_`value' = 0
}
gen states_ne = 0 // north-east
gen states_mw = 0 // mid-west
gen states_s = 0 // south
gen states_w = 0 // west
gen states_ne_ne = 0 // north-east region / New England Division: Maine 23, New Hampshire 33, Vermont 50, Massachusetts 25, Rhode Island 44, Connecticut 9
gen states_ne_ma = 0 // north-east / Middle Atlantic Division: New York, New Jersey, Pennsylvania
gen states_mw_en = 0 // mid-west / East North Central Division: Ohio 39, Indiana 18, Illinois 17, Michigan 26, Wisconsin 55
gen states_mw_wn = 0 // mid-west / West North Central Division: Minnesota, Iowa, Missouri, North Dakota, South Dakota, Nebraska, Kansas
gen states_s_sa = 0 // south / South Atlantic Division: Delaware, Maryland, District of Columbia, Virginia, West Virginia, North Carolina, South Carolina, Georgia, Florida
gen states_s_es = 0 // south / East South Central Division: Kentucky 21, Tennessee 47, Alabama 1, Mississippi 28
gen states_s_ws = 0 // south / West South Central Division: Arkansas 5, Louisiana 22, Oklahoma 40, Texas 48
gen states_w_m = 0 // west / Mountain Division: Montana, Idaho, Wyoming, Colorado, New Mexico, Arizona, Utah, Nevada
gen states_w_p = 0 // west / Pacific Division: Washington 53, Oregon 41, California 6, Alaska 2, Hawaii 15

// gen states division variables(Census gov) - https://www.census.gov/programs-surveys/geography/about/glossary.html#par_textimage_10

foreach value in 1 4 5 6 8 9 10 11 12 13 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56{
	replace st_`value' = 1 if statefip == `value'
}

foreach value in 9 23 25 33 34 36 42 44 50 {
	replace states_ne = 1 if statefip == `value'
}

foreach value in 17 18 19 20 26 27 29 31 38 39 46 55 {
	replace states_mw = 1 if statefip == `value'
}

foreach value in 1 5 10 11 12 13 21 22 24 28 37 40 45 47 48 51 54 {
	replace states_s = 1 if statefip == `value'
}

foreach value in 2 4 6 8 15 16 30 32 35 41 49 53 56 {
	replace states_w = 1 if statefip == `value'
}

foreach value in 9 23 25 33 44 50{
	replace states_ne_ne = 1 if statefip == `value'
}

foreach value in 34 36 42{
	replace states_ne_ma = 1 if statefip == `value'
}

foreach value in 17 18 26 39 55 {
	replace states_mw_en = 1 if statefip == `value'
}

foreach value in 19 20 27 29 31 38 46 {
	replace states_mw_wn = 1 if statefip == `value'
}

foreach value in 10 11 12 13 24 37 45 51 54 {
	replace states_s_sa = 1 if statefip == `value'
}

foreach value in 1 21 28 47 {
	replace states_s_es = 1 if statefip == `value'
}

foreach value in 5 22 40 48 {
	replace states_s_ws = 1 if statefip == `value'
}

foreach value in 4 8 16 30 32 35 49 56 {
	replace states_w_m = 1 if statefip == `value'
}

foreach value in 2 6 15 41 53 {
	replace states_w_p = 1 if statefip == `value'
}
gen test = states_ne_ne + states_ne_ma + states_mw_en + states_mw_wn + states_s_sa + states_s_es + states_s_ws + states_w_m + states_w_p
tab test
drop test

order year statefip cty_fips immshare_ct cty_pop immIV_1890s immIV_1900s immIV_1910s immIV_1920s immIV_1960s immIV_1970s immIVoneout_1890s immIVoneout_1900s immIVoneout_1910s immIVoneout_1920s immIVoneout_1960s immIVoneout_1970s states_ne_ne states_ne states_mw states_s states_w states_ne_ma  states_mw_en  states_mw_wn states_s_sa states_s_es states_s_ws states_w_m  states_w_p colgrad child english1 english2 noenglish1 commute person_no medicaid num_medicaid poverty_n poverty_alln unemployed numlabforce outright_own mortgaged_own renter numhh incwage_tot incearn_tot inctot_tot incwage_col incearn_col inctot_col incwage_noncol incearn_noncol inctot_noncol incwage_imm incwage_nat incearn_imm incearn_nat inctot_imm inctot_nat incwage_imm_noncol incwage_nat_noncol incearn_imm_noncol incearn_nat_noncol inctot_imm_noncol inctot_nat_noncol incwage_imm_col incwage_nat_col incearn_imm_col incearn_nat_col inctot_imm_col inctot_nat_col

save Imm_vars_new.dta, replace
***
use Imm_vars_new.dta, clear
merge m:1 cty_fips using "sc_cty.dta" // Social capital I &n II (3,089 ctys)
sort year cty_fips
keep if _merge==3 // 901/33
drop _merge
foreach var in colgrad noncolgrad child english1 english2 noenglish1 commute nat imm {
	gen `var'_sh = `var'/person_no, after(`var')
}
foreach var in nat_col nat_noncol{
	gen `var'_sh = `var'/nat, after(`var')
}
foreach var in imm_col imm_noncol {
	gen `var'_sh = `var'/imm, after(`var')
}
gen medicaid_sh = medicaid/num_medicaid, after(medicaid)
gen poverty_n_sh = poverty_n/poverty_alln, after(poverty_n)
gen unemployed_sh = unemployed/numlabforce, after(unemployed)
foreach var in outright_own mortgaged_own renter {
	gen `var'_sh = `var'/numhh, after(`var')
}

gen cpi99 = 0
replace cpi99 = 0.882 if year == 2005
replace cpi99 = 0.853 if year == 2006
replace cpi99 = 0.826 if year == 2007
replace cpi99 = 0.804 if year == 2008
replace cpi99 = 0.774 if year == 2009
replace cpi99 = 0.777 if year == 2010
replace cpi99 = 0.764 if year == 2011
replace cpi99 = 0.741 if year == 2012
replace cpi99 = 0.726 if year == 2013
replace cpi99 = 0.715 if year == 2014
replace cpi99 = 0.704 if year == 2015
replace cpi99 = 0.703 if year == 2016
replace cpi99 = 0.694 if year == 2017
replace cpi99 = 0.679 if year == 2018
replace cpi99 = 0.663 if year == 2019
replace cpi99 = 0.652 if year == 2020
replace cpi99 = 0.644 if year == 2021

foreach var in incwage_tot incearn_tot inctot_tot incwage_col incearn_col inctot_col incwage_noncol incearn_noncol inctot_noncol incwage_imm incwage_nat incearn_imm incearn_nat inctot_imm inctot_nat incwage_imm_noncol incwage_nat_noncol incearn_imm_noncol incearn_nat_noncol inctot_imm_noncol inctot_nat_noncol incwage_imm_col incwage_nat_col incearn_imm_col incearn_nat_col inctot_imm_col inctot_nat_col {
	gen `var'_adj = `var'*cpi99, after(`var')
}

foreach var in colgrad child english1 english2 noenglish1 commute medicaid poverty_n unemployed outright_own mortgaged_own renter incwage_tot incearn_tot inctot_tot incwage_col incearn_col inctot_col incwage_noncol incearn_noncol inctot_noncol incwage_imm incwage_nat incearn_imm incearn_nat inctot_imm inctot_nat incwage_imm_noncol incwage_nat_noncol incearn_imm_noncol incearn_nat_noncol inctot_imm_noncol inctot_nat_noncol incwage_imm_col incwage_nat_col incearn_imm_col incearn_nat_col inctot_imm_col inctot_nat_col incwage_tot_adj incearn_tot_adj inctot_tot_adj incwage_col_adj incearn_col_adj inctot_col_adj incwage_noncol_adj incearn_noncol_adj inctot_noncol_adj incwage_imm_adj incwage_nat_adj incearn_imm_adj incearn_nat_adj inctot_imm_adj inctot_nat_adj incwage_imm_noncol_adj incwage_nat_noncol_adj incearn_imm_noncol_adj incearn_nat_noncol_adj inctot_imm_noncol_adj inctot_nat_noncol_adj incwage_imm_col_adj incwage_nat_col_adj incearn_imm_col_adj incearn_nat_col_adj inctot_imm_col_adj inctot_nat_col_adj {
	gen `var'_log = log(`var'), after(`var')
}

save immIV_sc_covariates_new.dta, replace

















/*
****
use "/Users/jaeyoungbaak/Dropbox/Research/Project_I/DataWork/Research_imm/immshare_hist_agedrop/immshare_hist_agedrop.dta", clear
expand 17
sort cty_fips bpl_final
quietly by cty_fips bpl_final: gen dup=cond(_N==1,0,_n)
gen year = 2004 + dup
order year cty_fips bpl_final
merge 1:1 year cty_fips bpl_final using immshare_current.dta // _merge == 1: 833 / 2: 81,753 / 3: 2,589,797
drop if bpl_final == 50 // Not identified in immshare_hist_agedrop.dta - 53,431 obs (All from using)
tab cty_fips if _merge == 1 // # 833 - fips 55901 (17*49) 17년 49개bpl
tab cty_fips if _merge == 2 // # 28,322: Alaska(17*49*29), Hawaii (17*49*5) 17년 * 49개bpl * # of unmatched fips
keep if _merge == 3
drop _merge
drop dup
order year cty_fips bpl_final Moct Mot bpl_oneout Moct_Mot immshare_ct cty_pop
save immshare_agedrop.dta, replace
**********************************

use immshare_agedrop.dta, clear

** Current National Imm * Historical share
foreach value in 1900 1910 1920 1930 1970 {
	gen Mot_share`value' = Mot*share`value' // Mot: the number of nation immigrants from origin country O to US, at time t, where t = 2010, 2019, 2020
											// share`var': historical share (for specific county)	Sh_oc𝛕
	gen bpl_oneout_share`value' = bpl_oneout*share`value'
} 

** egen share_real = total(Moct), by(year cty_fips) // the current share of immigrant in each county (without US bpl)
foreach value in 1900 1910 1920 1930 1970 {
	egen predicted_imm_`value' = total(Mot_share`value'), by(year cty_fips)
	egen oneout_predicted_imm_`value' = total(bpl_oneout_share`value'), by(year cty_fips)
}
collapse (first) immshare_ct cty_pop predicted_imm_1900 predicted_imm_1910 predicted_imm_1920 predicted_imm_1930 predicted_imm_1970 oneout_predicted_imm_1900 oneout_predicted_imm_1910 oneout_predicted_imm_1920 oneout_predicted_imm_1930 oneout_predicted_imm_1970, by (year cty_fips)

sort cty_fips year // different order!
foreach value in 1900 1910 1920 1930 1970 {
	by cty_fips: gen immIV_`value' = predicted_imm_`value'/cty_pop[_n-1] // predicted immigrant share
	by cty_fips: gen immIVoneout_`value' = oneout_predicted_imm_`value'/cty_pop[_n-1] // predicted immigrant share (oneout version)
}
sort year cty_fips

save immIV_agedrop_temp.dta, replace
keep year cty_fips immshare_ct cty_pop immIV_1900 immIVoneout_1900 immIV_1910 immIVoneout_1910 immIV_1920 immIVoneout_1920 immIV_1930 immIVoneout_1930 immIV_1970 immIVoneout_1970
order year cty_fips immshare_ct cty_pop immIV_1900 immIV_1910 immIV_1920 immIV_1930 immIV_1970 immIVoneout_1900 immIVoneout_1910 immIVoneout_1920 immIVoneout_1930 immIVoneout_1970
save immIV_agedrop_final.dta, replace
***
use immIV_agedrop_final.dta, clear
merge 1:1 year cty_fips using Weighted_data_by2010ctyfips_allyears.dta
keep if _merge == 3  // 578 not matched (from using) (Alaska(17*29), Hawaii (17*5) 17년 * 34counties)
drop _merge
merge 1:1 year cty_fips using Income_Weighted_data_by2010ctyfips_allyears_income.dta
keep if _merge == 3  // 578 not matched (from using) 34counties * 17years
drop _merge
order year statefip cty_fips immshare_ct cty_pop

**
gen states_ne = 0 // north-east
gen states_mw = 0 // mid-west
gen states_s = 0 // south
gen states_w = 0 // west

// gen states division variables(Census gov) - https://www.census.gov/programs-surveys/geography/about/glossary.html#par_textimage_10

foreach value in 9 23 25 33 34 36 42 44 50 {
	replace states_ne = 1 if statefip == `value'
}

foreach value in 17 18 19 20 26 27 29 31 38 39 46 55 {
	replace states_mw = 1 if statefip == `value'
}

foreach value in 1 5 10 11 12 13 21 22 24 28 37 40 45 47 48 51 54 {
	replace states_s = 1 if statefip == `value'
}

foreach value in 2 4 6 8 15 16 30 32 35 41 49 53 56 {
	replace states_w = 1 if statefip == `value'
}
gen test = states_mw + states_ne + states_s + states_w
tab test
drop test

order year statefip cty_fips immshare_ct cty_pop immIV_1900 immIV_1910 immIV_1920 immIV_1930 immIV_1970 immIVoneout_1900 immIVoneout_1910 immIVoneout_1920 immIVoneout_1930 immIVoneout_1970 states_ne states_mw states_s states_w colgrad child english1 english2 noenglish1 commute person_no medicaid num_medicaid poverty_n poverty_alln unemployed numlabforce outright_own mortgaged_own renter numhh incwage_tot incearn_tot inctot_tot incwage_col incearn_col inctot_col incwage_noncol incearn_noncol inctot_noncol

save Imm_vars.dta, replace

/* use sc_cty.dta, clear
drop county_name num_below_p50 pop2018
order cty_fips ec_county child_ec_county ec_grp_mem_county ec_high_county child_high_ec_county ec_grp_mem_high_county exposure_grp_mem_county exposure_grp_mem_high_county child_exposure_county child_high_exposure_county bias_grp_mem_county bias_grp_mem_high_county child_bias_county child_high_bias_county clustering_county support_ratio_county volunteering_rate_county civic_organizations_county

foreach var in ec child_ec ec_grp_mem ec_high child_high_ec ec_grp_mem_high exposure_grp_mem exposure_grp_mem_high child_exposure child_high_exposure bias_grp_mem bias_grp_mem_high child_bias child_high_bias clustering support_ratio volunteering_rate civic_organizations ec_se child_ec_se ec_high_se child_high_ec_se {
	rename `var'_county `var'
}

order cty_fips ec ec_high child_ec child_high_ec ec_grp_mem ec_grp_mem_high exposure_grp_mem exposure_grp_mem_high child_exposure child_high_exposure bias_grp_mem bias_grp_mem_high child_bias child_high_bias clustering support_ratio volunteering_rate civic_organizations ec_se child_ec_se ec_high_se child_high_ec_se

save sc_cty.dta, replace */
use Imm_Vars.dta, clear
merge m:1 cty_fips using "sc_cty.dta" // Social capital I &n II (3,089 ctys)
sort year cty_fips
keep if _merge==3 // 901/33
drop _merge
foreach var in colgrad child english1 english2 noenglish1 commute {
	gen `var'_sh = `var'/person_no, after(`var')
}
gen medicaid_sh = medicaid/num_medicaid, after(medicaid)
gen poverty_n_sh = poverty_n/poverty_alln, after(poverty_n)
gen unemployed_sh = unemployed/numlabforce, after(unemployed)
foreach var in outright_own mortgaged_own renter {
	gen `var'_sh = `var'/numhh, after(`var')
}
foreach var in colgrad child english1 english2 noenglish1 commute medicaid poverty_n unemployed outright_own mortgaged_own renter incwage_tot incearn_tot inctot_tot incwage_col incearn_col inctot_col incwage_noncol incearn_noncol inctot_noncol incwage_imm incwage_nat incearn_imm incearn_nat inctot_imm inctot_nat incwage_imm_noncol incwage_nat_noncol incearn_imm_noncol incearn_nat_noncol inctot_imm_noncol inctot_nat_noncol incwage_imm_col incwage_nat_col incearn_imm_col incearn_nat_col inctot_imm_col inctot_nat_col {
	gen `var'_log = log(`var'), after(`var')
}
save immIV_sc_covariates.dta, replace
use immIV_sc_covariates.dta, clear */

***
***
***
