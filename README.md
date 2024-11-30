# US-immigration
Stata codes for constructing the share of immigration and its historical IVs


Codes are provided into two separate .do files: share of immigrants from 1) historical years (1910s, 1920s, and 1960s) and 2) current years (covering 2005-2021 ACS year).
To replicate these codes, first you have to download raw data file from IPUMS. And you should include regional indicators, icpsrst (stateicp) and icpsrcty (countyicp), birth place (bpl), year of immigration (yrimmig).

You can find crosswalk file from: 1) https://fpeckert.me/eglp/  2) https://justinwiltshire.com/crosswalks-from-county-groups-to-counties and 3) https://www.nhgis.org/geographic-crosswalks
1) A Method to Construct Geographical Crosswalks with an Application to US Counties since 1790 (Eckert et al., 2020, NBER)
2) Crosswalks from ‘County Groups’ to Counties for the 1970 and 1980 U.S. Decennial Census Metro Samples (Wiltshire, 2021, Unpublished manuscript)
3) Geographic Crosswalks (IPUMS NHGIS)
