# US-immigration
Stata codes for constructing the share of immigration and its historical IVs


Codes are provided into two separate .do files: share of immigrants from 1) historical years (1910s, 1920s, and 1960s) and 2) current years (covering 2005-2021 ACS year).
To replicate these codes, first you have to download raw data file from IPUMS. And you should include regional indicators, icpsrst (stateicp) and icpsrcty (countyicp), birth place (bpl), year of immigration (yrimmig).

You can find crosswalk file from: 1) https://fpeckert.me/eglp/  2) https://justinwiltshire.com/crosswalks-from-county-groups-to-counties and 3) https://www.nhgis.org/geographic-crosswalks
1) A Method to Construct Geographical Crosswalks with an Application to US Counties since 1790 (Eckert et al., 2020, NBER)
2) Crosswalks from ‘County Groups’ to Counties for the 1970 and 1980 U.S. Decennial Census Metro Samples (Wiltshire, 2021, Unpublished manuscript)
3) Geographic Crosswalks (IPUMS NHGIS)


## Explanation of Main Steps (immi_2000s_final.do)
# Loading and Preprocessing Data
You load the ACS microdata, keep individuals between certain years, and remove extraneous variables.
The dataset focuses on individuals of working age (15–64), though those lines are also commented out.
Crosswalks (2000 vs. 2010 PUMAs)

For ACS years 2005–2011, you use a crosswalk from 2000 PUMAs to 2010 PUMAs to county FIPS.
For ACS years 2012–2021, you directly use the 2010 PUMA to county FIPS crosswalk.
This ensures each person is correctly assigned to a county (via PUMA -> county FIPS).

# Computing Fractional Weights (fweight / popweight)
You create a fractional weight (fweight or popweight) for each observation, often used for allocating PUMA-level population to counties when a single PUMA spans multiple counties.
Collapsing Data

The collapse commands aggregate the data to county-year-bpl (birthplace) level, summing up the relevant fractional weights.
BPL (Birth Place) Merges & US Territories

You merge birthplaces with a final list of valid codes (BPL_FINAL.dta).
US territories are assigned code 50, and you drop those that cannot be matched.

# Generating Moct and Mot
Moct: number of immigrants from origin country O in county C at time t.
Mot: total immigrants from origin country O to the US at time t (aggregated across all counties).

# Share_t
share_t = Moct / Mot, the share of immigrants from origin O in a specific county C relative to the entire country in year t.
Combining 2005–2011 and 2012–2021

You append the two separate time spans into one dataset and compute additional county-level aggregates (cty_pop, immshare_ct).
Historical Merging

You integrate historical shares (e.g., 1890s, 1900s, etc.) by merging in another dataset (immshare_hist_final.dta) expanded by year.
Predicted Immigrant Share

For each historical period (e.g., 1890s, 1900s, etc.), you multiply current national immigrant counts (Mot) by historical county shares (share1890s, etc.) to get a predicted total count for each county.
You sum these predictions across birthplaces, then scale by the county’s population in the previous year to get a predicted immigrant share (immIV_1890s, etc.).

# One-Out Measure
The bpl_oneout variable excludes the current origin from the total to avoid self-influence in certain calculations (the “one-out” version).
You similarly create predicted shares using these “one-out” counts (immIVoneout_1890s, etc.).

# Final Output
You save a final dataset with all relevant variables: actual immigrant share, county population, and predicted historical immigrant share measures for each year and county (immIV_new_final.dta).
