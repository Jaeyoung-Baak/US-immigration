***************
**  Analysis **
***************

clear all
set more off
set matsize 10000
use immIV_sc_covariates_new.dta, clear // Imm_vars + Social capital(Chetty)
drop if year == 2005


***********************************
**  Immigrants on Connectedness  **
**     IV 1910s, 1920s 1960s     **
***********************************
** Pooled OLS
foreach var in ec ec_grp_mem exposure_grp_mem bias_grp_mem ec_high ec_grp_mem_high exposure_grp_mem_high bias_grp_mem_high clustering support_ratio volunteering_rate civic_organizations {
	reg `var' immshare_ct if year == 2021, vce(robust)
	est store reg`var'
}
esttab reg* using Part_EC_pool_FE_IV.csv, nogap stats(N cdf arf arfp r2) title("Pooled OLS") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
** FE
foreach var in ec ec_grp_mem exposure_grp_mem bias_grp_mem ec_high ec_grp_mem_high exposure_grp_mem_high bias_grp_mem_high clustering support_ratio volunteering_rate civic_organizations {
	ivreg2 `var' immshare_ct colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) robust
	est store reg`var'
}
esttab reg* using Part_EC_pool_FE_IV.csv, nogap stats(N cdf arf arfp r2) title("FE") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
** IV with control variables and state fixed effect
** Imm > EC 2021
foreach var in ec ec_grp_mem exposure_grp_mem bias_grp_mem ec_high ec_grp_mem_high exposure_grp_mem_high bias_grp_mem_high clustering support_ratio volunteering_rate civic_organizations {
	ivreg2 `var' (immshare_ct = immIV_1910s immIV_1920s immIV_1960s) colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) robust first
	est store reg`var'
}
esttab reg* using Part_EC_pool_FE_IV.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("IMM > EC") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
***
ivreg2 ec (immshare_ct = immIV_1910s immIV_1920s immIV_1960s) colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) cl(statefip) first

***********************************
**     Immigrants on Income      **
**     102060s.                  **
***********************************
** Pooled OLS
foreach var in incwage_tot incearn_tot inctot_tot {
	reg `var'_adj_log immshare_ct, vce(robust)
	est store reg`var'
}
esttab reg* using Part_Inc_pool_FE_FEIV.csv, nogap stats(N cdf arf arfp r2) title("Pooled OLS") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
** FE
foreach var in incwage_tot incearn_tot inctot_tot {
	xi: xtivreg28 `var'_adj_log immshare_ct colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_Inc_pool_FE_FEIV.csv, nogap stats(N cdf arf arfp r2) title("FE") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
** FE-IV
foreach var in incwage_tot incearn_tot inctot_tot incwage_noncol incearn_noncol inctot_noncol incwage_col incearn_col inctot_col {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIV_1910s immIV_1920s immIV_1960s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_Inc_pool_FE_FEIV.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("FEIV-102060s")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

** FE-IV (Heterogeneity)
foreach var in incwage_nat incearn_nat inctot_nat incwage_imm incearn_imm inctot_imm {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIV_1910s immIV_1920s immIV_1960s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_Inc_hetero.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("Nat vs. Imm")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
foreach var in incwage_nat_noncol incearn_nat_noncol inctot_nat_noncol incwage_nat_col incearn_nat_col inctot_nat_col {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIV_1910s immIV_1920s immIV_1960s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_Inc_hetero.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("Nat: noncol vs. col")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

foreach var in incwage_imm_noncol incearn_imm_noncol inctot_imm_noncol incwage_imm_col incearn_imm_col inctot_imm_col {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIV_1910s immIV_1920s immIV_1960s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_Inc_hetero.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("Imm: noncol vs. col")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

************************
**  Robustness check  **
**  Single Instrument **
************************

foreach var in ec ec_grp_mem exposure_grp_mem bias_grp_mem ec_high ec_grp_mem_high exposure_grp_mem_high bias_grp_mem_high clustering support_ratio volunteering_rate civic_organizations {
	ivreg2 `var' (immshare_ct = immIV_1910s) colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_SingleInst.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("(EC) Single Ins 1910") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

foreach var in ec ec_grp_mem exposure_grp_mem bias_grp_mem ec_high ec_grp_mem_high exposure_grp_mem_high bias_grp_mem_high clustering support_ratio volunteering_rate civic_organizations {
	ivreg2 `var' (immshare_ct = immIV_1920s) colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_SingleInst.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("(EC) Single Ins 1920") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

foreach var in ec ec_grp_mem exposure_grp_mem bias_grp_mem ec_high ec_grp_mem_high exposure_grp_mem_high bias_grp_mem_high clustering support_ratio volunteering_rate civic_organizations {
	ivreg2 `var' (immshare_ct = immIV_1960s) colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_SingleInst.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("(EC) Single Ins 1960") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

**

foreach var in incwage_tot incearn_tot inctot_tot incwage_noncol incearn_noncol inctot_noncol incwage_col incearn_col inctot_col {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIV_1910s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_SingleInst.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("(Inc) Single Ins 1910") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
foreach var in incwage_tot incearn_tot inctot_tot incwage_noncol incearn_noncol inctot_noncol incwage_col incearn_col inctot_col {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIV_1920s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_SingleInst.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("(Inc) Single Ins 1920") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
foreach var in incwage_tot incearn_tot inctot_tot incwage_noncol incearn_noncol inctot_noncol incwage_col incearn_col inctot_col {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIV_1960s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_SingleInst.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("(Inc) Single Ins 1960") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

************************
**  Robustness check  **
**  leave-one-out     **
************************

foreach var in ec ec_grp_mem exposure_grp_mem bias_grp_mem ec_high ec_grp_mem_high exposure_grp_mem_high bias_grp_mem_high clustering support_ratio volunteering_rate civic_organizations {
	ivreg2 `var' (immshare_ct = immIVoneout_1910s immIVoneout_1920s immIVoneout_1960s) colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_leaveout.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("leave-one-out EC") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear
ivreg2 ec_grp_mem (immshare_ct = immIVoneout_1910s immIVoneout_1920s immIVoneout_1960s) colgrad_sh unemployed_sh st_* if year == 2021, fwl(st_*) robust first

foreach var in incwage_tot incearn_tot inctot_tot incwage_noncol incearn_noncol inctot_noncol incwage_col incearn_col inctot_col {
	xi: xtivreg2 `var'_adj_log (immshare_ct = immIVoneout_1910s immIVoneout_1920s immIVoneout_1960s) colgrad_sh unemployed_sh i.year, i(cty_fips) fe cl(cty_fips) robust first
	est store reg`var'
}
esttab reg* using Part_RBcheck_leaveout.csv, nogap stats(N cdf arf arfp r2 widstat idstat) title("leave-one-out Income") r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
est clear

  
*** End of this file ***
