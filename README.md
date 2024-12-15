# SFR PD&LGD&RWA Project 

## Introduction
The primary goal of this project is to assess the credit risk and capital adequacy of a financial institution's individual retail loan products portfolio by calculating PD, LGD, and, ultimately, RWA.

## Project Steps
### 1. Data cleaning<br/>
Data quality was assessed for model implementation and abnormal values of TDS and GDS smaller than '0' were detected, which were inconsistent with their definition. '0' was set to replace the incorrect TDS and GDS values. '0' was set to 'Arrears days' which shows null

### 2. Exploratory Data Analysis -- PD Model (Profitability of Default) Implementation<br/>
 7 input model drivers:
   * Current LTV including Partner Adjusted by HPI Segmented by Alt/Prime
   * Current Beacon and Current BNI 
   * Delinquency status
   * Term at Renewal and Month on Books
   * Province and metro
   * TDS and GDS
   * Unemployment rate 2 quarters difference

 Model driver specification is outlined in the following pic

   ![PD model model driver specification!](https://github.com/user-attachments/assets/8d3da9be-3026-4cbd-9989-bdaff7f90650)<br/>
   
 * For readability and simplicity, created temp tables to store extracted data temporarily<br/>

 
   ![temp table!](https://github.com/user-attachments/assets/af025809-dd46-4290-b264-121ae4ac4673)

   
  * Performed data extraction, data aggregation, and data transformation for the 7 model drivers<br/>

   ![model drivers](https://github.com/user-attachments/assets/be877319-12cd-453a-a593-630777aa3630)<br/>




 * Implemented data transformation based on model specification and fit WOE (weight of evidence) to each model driver
 * Applied regression model to calculate PD core

   <br/>LGD (Loss Given Default) Calculation:
    * Aggregated relevant fields for required 6 input model drivers
    * Implemented data transformation based on model specification and fit WOE (weight of evidence) to each model driver
    * Applied regression model to calculate LGD core


   <br/>RWA (Risk of Assessts) Calculation:
    * categorized into 2 scenarios: defaulted loans and not defaulted loans
    * capital requirement calculation

  ## Tools Used
   * MySQL (Stored Procedure, CTE, Join, Variables etc. )
   * Python (Pandas, Numpy, SciPy)
   * Jupyter Notebook
   
   

