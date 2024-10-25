# US-immigration
Stata codes for constructing the share of immigration and its historical IV


Codes are provided into two separate .do files: share of immigrants from 1) historical years and 2) current years (covering 2005-2021 ACS year).
To replicate these codes, first you have to download data file from IPUMS. And you should include regional indicators, icpsrst (stateicp) and icpsrcty (countyicp), birth place (bpl), year of immigration (yrimmig).

1. For the historical immigrant share and its IV, I used full count data sets including 1900, 1910, 1920 and 1930 census year, and 1970 1% metro fm1/fm2, 1% metro 1980 ACS data from IPUMS.
   There are two main crosswalks files: 1) from 
