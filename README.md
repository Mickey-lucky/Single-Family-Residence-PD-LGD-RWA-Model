# SFR PD&LGD&RWA Project 

## Introduction
The primary goal of this project is to assess the credit risk and capital adequacy of the personal retail loan products portfolio of a financial institution via the calculation of PD, LGD, and ultimately RWA.

## Highlights of Project Steps
1. Data cleaning
   * Data quality was assessed for model implementation and minus values of TDS and GDS were detected, which were inconsistent with their definition. 0 was set to the incorrect TDS and GDS value. 0 was set to 'Arrears days' which shows null

2. Exploratory Data Analysis
   PD (Profitability of Default) Calculation:
    * Aggregated relevant fields for required 7 input model drivers
    * Implemented data transformation based on model specification and fit WOE (weight of evidence) to each model driver
    * Applied regression model to calculate PD core

   LGD (Loss Given Default) Calculation:
    * Aggregated relevant fields for required 6 input model drivers
    * Implemented data transformation based on model specification and fit WOE (weight of evidence) to each model driver
    * Applied regression model to calculate LGD core


   RWA (Risk of Assessts) Calculation:
    * 2 scenarios: defaulted loans and not defaulted loans
    * capital requirement calculation
   
   

