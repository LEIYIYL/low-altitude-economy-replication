# Replication files

This folder contains the analysis-ready data and Stata code for the manuscript **Policy-industrial capital collaboration and firm innovation in the low-altitude economy: Evidence from government-guided funds' equity participation in China**.

## Files

- `analysis.do`: replication code.
- `README.md`: instructions.
- `data/analysis_data.dta`: main firm-year panel (4,530 observations and 419 firms).
- `data/stacked_data.dta`: analysis-ready data for stacked DID (23,581 records; the estimator retains 23,502 observations after removing singleton observations).
- `data/psm_sample_reported.dta`: archived estimation sample for the PSM-DID result reported in the manuscript (1,744 observations).

All firm identifiers in the shared files are anonymized. The datasets are already prepared for estimation; the code does not repeat the upstream data cleaning, matching, or variable construction.

## Variable names

The main dataset uses the same variable symbols as the manuscript:

| Manuscript variable | Data column |
| --- | --- |
| Firm innovation | `Innovation` |
| Jointly backed fund investment | `DID` |
| Compensation mechanisms | `Compensation` |
| Industrial relatedness | `Similarity` |
| Other venture capital participation | `VC` |
| Firm size | `Size` |
| Leverage | `Lev` |
| Return on assets | `ROA` |
| Asset turnover | `ATO` |
| Operating cash flow ratio | `Cashflow` |
| Fixed asset ratio | `FIXED` |
| Revenue growth | `Growth` |
| Tobin's Q | `TobinQ` |
| Firm age | `Firm_Age` |

`Firm_ID` and `Year` are the panel identifiers. `Innovation_All`, `Employees`, `ROE`, and `List_Age` are used in the additional robustness checks. Names beginning with `Pre_`, `Post_`, `SA_`, or `Stack_` are analysis-ready auxiliary variables for the event-study, Sun-Abraham, or stacked DID estimators.

## Software

The files were validated with Stata/MP 18. The following user-written commands are required:

```stata
ssc install ftools, replace
ssc install reghdfe, replace
ssc install coefplot, replace
ssc install avar, replace
ssc install eventstudyinteract, replace
ssc install bdiff, replace
```

These commands only need to be installed once.

## How to run

Open Stata, set the working directory to this folder, and run:

```stata
cd "path/to/GitHub_replication"
do analysis_en.do
```

The do-file follows the manuscript order: descriptive statistics, baseline regressions, parallel-trends and placebo tests, robustness checks, moderating effects, and heterogeneity analyses. Regression output is saved in `output/regression_results_en.log`; the two figures and placebo simulation results are also saved in `output/`. The placebo test uses 1,000 repetitions and the regional coefficient-difference test uses 500 bootstrap repetitions, so the full run may take several minutes.

## Data construction and scope

The analytical panel was constructed from the authors' previously compiled dataset. The underlying information was obtained from Tonghuashun iFind, CVSource, CSMAR, publicly available patent records of the China National Intellectual Property Administration, and other public sources. This package begins with the final analytical sample and does not reconstruct the upstream identification of low-altitude economy firms, investment events, fund limited partners, compensation arrangements, or business-text similarity.