version 18.0
clear all
set more off

* Run this file after setting Stata's working directory to this folder.
capture confirm file "data/analysis_data.dta"
if _rc {
    display as error "Set Stata's working directory to the replication folder, then run: do analysis_en.do"
    exit 601
}

capture mkdir "output"
capture log close
log using "output/regression_results_en.log", text replace

global controls VC Size Lev ROA ATO Cashflow FIXED Growth TobinQ Firm_Age

* Required user-written commands: reghdfe, coefplot, eventstudyinteract, avar, bdiff.
foreach command in reghdfe coefplot eventstudyinteract avar bdiff {
    capture which `command'
    if _rc {
        display as error "Required command not installed: `command'. See README.md."
        log close
        exit 199
    }
}


****************************************************************************
* Table 2. Descriptive statistics
****************************************************************************
use "data/analysis_data.dta", clear
tabstat Innovation DID Compensation Similarity $controls, ///
    statistics(n mean p50 sd min max) columns(statistics)


****************************************************************************
* Table 3. Baseline regressions
****************************************************************************
reghdfe Innovation DID, absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing
reghdfe Innovation DID $controls
reghdfe Innovation DID $controls, absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing


****************************************************************************
* Figure 1. Parallel trends test
****************************************************************************
use "data/analysis_data.dta", clear
reghdfe Innovation Pre_5 Pre_4 Pre_3 Pre_2 Current ///
    Post_1 Post_2 Post_3 Post_4 Post_5 Pre_1 $controls, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

coefplot, baselevels omitted ///
    keep(Pre_5 Pre_4 Pre_3 Pre_2 Pre_1 Current Post_1 Post_2 Post_3 Post_4 Post_5) ///
    order(Pre_5 Pre_4 Pre_3 Pre_2 Pre_1 Current Post_1 Post_2 Post_3 Post_4 Post_5) ///
    coeflabels(Pre_5 = "<=-5" Pre_4 = "-4" Pre_3 = "-3" Pre_2 = "-2" ///
        Pre_1 = "-1 (ref.)" Current = "0" Post_1 = "1" Post_2 = "2" ///
        Post_3 = "3" Post_4 = "4" Post_5 = ">=5") ///
    vertical recast(connect) ///
    ciopts(recast(rcap) lcolor(gs7) lpattern(dash) lwidth(thin)) ///
    lcolor(gs6) mcolor(gs5) msymbol(Oh) ///
    yline(0, lcolor(red) lpattern(solid)) ///
    xline(6, lcolor(gs8) lpattern(dash)) ///
    xtitle("Years relative to investment") ///
    ytitle("Estimated effect on innovation") ///
    graphregion(color(white)) bgcolor(white)
graph export "output/figure1_parallel_trends.png", replace width(3200)


****************************************************************************
* Figure 2. Placebo test (1,000 repetitions)
****************************************************************************
use "data/analysis_data.dta", clear
tempfile placebo_base treatment_years placebo_firms placebo_results
save `placebo_base', replace

quietly reghdfe Innovation DID $controls, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing
local true_coefficient = _b[DID]

preserve
    keep if Treat == 1
    bysort Firm_ID (Invest_Year): keep if _n == 1
    keep Invest_Year
    drop if missing(Invest_Year)
    sort Invest_Year
    generate draw_id = _n
    count
    local treated_firms = r(N)
    rename Invest_Year placebo_year
    save `treatment_years', replace
restore

set seed 20260726
tempname results
postfile `results' int repetition double(coefficient standard_error p_value) ///
    using `placebo_results', replace

quietly forvalues i = 1/1000 {
    use `placebo_base', clear
    bysort Firm_ID: keep if _n == 1
    keep Firm_ID
    generate random_number = runiform()
    sort random_number Firm_ID
    keep in 1/`treated_firms'
    generate draw_id = _n
    merge 1:1 draw_id using `treatment_years', assert(3) nogen
    keep Firm_ID placebo_year
    save `placebo_firms', replace

    use `placebo_base', clear
    merge m:1 Firm_ID using `placebo_firms', keep(1 3) nogen
    generate placebo_DID = !missing(placebo_year) & Year >= placebo_year
    capture quietly reghdfe Innovation placebo_DID $controls, ///
        absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing
    if _rc == 0 & _se[placebo_DID] > 0 & _se[placebo_DID] < . {
        local b = _b[placebo_DID]
        local se = _se[placebo_DID]
        local p = 2 * ttail(e(df_r), abs(`b' / `se'))
        post `results' (`i') (`b') (`se') (`p')
    }
}
postclose `results'

use `placebo_results', clear
save "output/placebo_results.dta", replace
twoway ///
    (kdensity coefficient, yaxis(1) lcolor(navy)) ///
    (scatter p_value coefficient, yaxis(2) msymbol(Oh) msize(tiny) mcolor(navy%45)), ///
    xline(`true_coefficient', lcolor(red) lpattern(dash)) ///
    yline(0.1, axis(2) lcolor(red) lpattern(dash)) ///
    xtitle("Placebo coefficient") ///
    ytitle("Kernel density", axis(1)) ///
    ytitle("p-value", axis(2)) ///
    ylabel(0(0.2)1, axis(2) angle(horizontal)) ///
    yscale(range(0 1) axis(2)) ///
    legend(order(1 "Kernel density" 2 "p-value") rows(1)) ///
    graphregion(color(white)) plotregion(color(white))
graph export "output/figure2_placebo_test.png", replace width(3200)


****************************************************************************
* Table 4. Robustness checks
****************************************************************************

* Stacked DID
use "data/stacked_data.dta", clear
reghdfe Innovation Stack_DID $controls, ///
    absorb(Stack_Firm_FE Stack_Year_FE) vce(cluster Firm_ID)

* Sun-Abraham estimator; the reported result is the coefficient for SA_Lag1.
use "data/analysis_data.dta", clear
eventstudyinteract Innovation SA_Lead5 SA_Lead4 SA_Lead3 SA_Lead2 SA_Current ///
    SA_Lag1 SA_Lag2 SA_Lag3 SA_Lag4 SA_Lag5, absorb(Firm_ID Year) ///
    cohort(First_Treat_Year) control_cohort(Never_Treated) ///
    covariates($controls) vce(cluster Firm_ID)
matrix list e(b_iw)
matrix list e(V_iw)

* PSM-DID estimation sample used for the result reported in the manuscript.
use "data/psm_sample_reported.dta", clear
reghdfe Innovation DID $controls, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

* Alternative innovation measure: all patent applications.
use "data/analysis_data.dta", clear
reghdfe Innovation_All DID $controls, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

* Sample restricted to 2017-2024.
reghdfe Innovation DID $controls if Year >= 2017, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

* Excluding 2024.
reghdfe Innovation DID $controls if Year < 2024, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

* Alternative measures of firm size, profitability, and age.
reghdfe Innovation DID VC Employees Lev ROE ATO Cashflow FIXED Growth TobinQ List_Age, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing


****************************************************************************
* Table 5. Moderating effects
****************************************************************************
use "data/analysis_data.dta", clear
reghdfe Innovation c.DID_c##c.Compensation_c $controls, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing
reghdfe Innovation c.DID_c##c.Similarity_c $controls, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing


****************************************************************************
* Table 6. Heterogeneity analysis
****************************************************************************
use "data/analysis_data.dta", clear

* Dependence on airworthiness certification.
reghdfe Innovation DID $controls if High_Certification == 1, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing
reghdfe Innovation DID $controls if High_Certification == 0, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

* First-batch pilot areas and other areas.
reghdfe Innovation DID $controls if Pilot_Area == 1, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing
reghdfe Innovation DID $controls if Pilot_Area == 0, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

* State-owned and non-state-owned firms.
reghdfe Innovation DID $controls if SOE == 1, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing
reghdfe Innovation DID $controls if SOE == 0, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing

* Bootstrap test of the coefficient difference between regional groups.
set seed 20260727
set sortseed 20260727
bdiff, group(Pilot_Area) model(reghdfe Innovation DID $controls, ///
    absorb(Firm_ID Year) vce(cluster Firm_ID) keepsing) bsample reps(500)

log close
display as result "Finished. Results and figures are in the output folder."
