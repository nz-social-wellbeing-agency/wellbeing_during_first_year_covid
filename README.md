# Wellbeing during the first year of COVID-19

Two tranches of analysis looking at the wellbeing surveys by Stats NZ that cover the first year of the COVID-19 pandemic in New Zealand.

## Overview
This analysis examined how wellbeing changed during the first year of the COVID-19 pandemic in New Zealand. It used GSS 2016 and GSS 2018 wellbeing measures as a reference point and the wellbeing supplement of the HLFS, asked quarterly during 2020 and 2021, to examine changes in wellbeing throughout this time.

This code contributed to two documents published by the Agency: **Wellbeing during the first year of COVID-19: An analysis of the wellbeing supplement to the NZ Household Labour Force Survey** and its overview Te Atatū – Insights paper: **Wellbeing in the first year of COVID-19: Summary**. This code should be read and used alongside these two documents.

## Dependencies
It is necessary to have an IDI project if you wish to run the code.  Visit the Stats NZ website for more information about this. 

This analysis has been developed for the IDI_Clean_202203 refresh of the IDI. As changes in database structure can occur between refreshes, the initial preparation of the input information may require updating to run the code in other refreshes.
 
The R code makes use of several publicly available R packages, we also use the [Dataset Assembly Tool](https://github.com/nz-social-wellbeing-agency/dataset_assembly_tool) and associated resources. Stats NZ who maintain the IDI have already installed in the IDI the all the key packages that this analysis depends on. Should the version of  these packages be important, this analysis was conducted using `odbc` version 1.2.3,  `DBI` version 1.1.0, `dplyr` version 1.0.0, and `dbplyr` version 1.4.4.

## Folder descriptions

The repository is divided into two tranches of analysis. The first tranche of analysis led to the results reported in the first half of the research paper. The second tranche of analysis led to the results reported in the second half of the research paper.

## Instructions to run the project

Prior to running the project be sure to review the associated report and documentation.

For tranche 1, folders are run in the following order:
 * Support
 * Definitions
 * Assembly
 * Analysis

For tranche 2, folders are run in the following order:
 * Assembly
 * Analysis
 * Output

## Citation

Social Wellbeing Agency (2022). Wellbeing during first year of covid. Source code. https://github.com/nz-social-wellbeing-agency/wellbeing_during_first_year_covid

## Getting Help
If you have any questions email info@swa.govt.nz
