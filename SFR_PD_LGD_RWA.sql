DELIMITER $$
CREATE PROCEDURE Retail_PD_Model_Implementation (
    IN Reporting_Year  VARCHAR(5),
    IN Reporting_Time  VARCHAR(3)
)
Begin

    set @Reporting_Date = last_day(str_to_date(concat(Reporting_Time, ' 1 ', RIGHT(Reporting_Year, 4)) , '%M %d %Y'));
    set @Moody_date = date_sub(@Reporting_Date, interval 1 month);
    set @Moody_Year = concat('Y', year(@Moody_date));
    set @Moody_Time = left(date_format(@Moody_date, '%M'), 3);


-- Data cleaning
     update t_loan_retail
     set Funding_TDS = 0
     where Funding_TDS < 0;

 ---GDS
     update t_loan_retail
     set Funding_GDS = 0
     where Funding_GDS < 0;

--   arrears_days
     update t_loan_retail
     set Arrears_Days = 0
     where Arrears_Days is null;

    DROP TEMPORARY TABLE IF EXISTS i_temp_t_loan_retail;
    CREATE TEMPORARY TABLE i_temp_t_loan_retail(
        Year									VARCHAR(5)
        , Time									VARCHAR(3)
        , Loan_Number							INT
        , CIF_Number							INT
        , SL_Date								DATE
        , Funded_Date							DATE
        , Partner_Participation					DECIMAL(20,5)
        , Underwriter_Code						VARCHAR(5)
        , Branch								VARCHAR(25)
        , RemainingPrincipal_excl_Partner		DECIMAL(20,5)
        , RemainingPrincipal_incl_Partner       DECIMAL(20,5)
        , Appraisal_Value						DECIMAL(20,5)
        , Interest_Rate							DECIMAL(20,5)
        , Term									INT
        , Age_At_SL                             INT
        , Postal_Code							VARCHAR(25)
        , FSA                                   VARCHAR(3)
        , Province								VARCHAR(5)
        , City                                  VARCHAR(25)
        , Arrears_Days							INT
        , Arrears_Status						VARCHAR(100)
        , Funding_GDS_Ratio						DECIMAL(10,5)
        , Funding_TDS_Ratio						DECIMAL(10,5)
        , Alt_Prime_Indicator                   VARCHAR(10)
        , Delinquency_Status                    TINYINT
        , PRIMARY KEY (Year, Time, SL_Date, Loan_Number)
    );

    TRUNCATE TABLE i_temp_t_loan_retail;
    INSERT INTO i_temp_t_loan_retail
    select
        Year
         , Time
         , Loan_Number
         , CIF_Number
         , SL_Date
         , Funded_Date
         , Partner_Participation
         , Underwriter_Code
         , Branch
         , RemainingPrincipal_excl_Partner
         , RemainingPrincipal_excl_Partner + IFNull(Partner_Participation,0)				as RemainingPrincipal_incl_Partner
         , Appraisal_Value
         , Loan_Rate/100                                         as Interest_Rate
         , Term
         , TIMESTAMPDIFF(month, Funded_Date, SL_Date)        as Age_At_SL
         , Postal_Code
         , LEFT(Postal_Code, 3)                              as FSA
         , Province
         , City
         , IFNULL(Arrears_Days, 0)                           as Arrears_Days
         , Arrears_Status
         , IF(Funding_GDS / 100 > 1, 1, Funding_GDS / 100)   as Funding_GDS_Ratio
         , IF(Funding_TDS / 100 > 1, 1, Funding_TDS / 100)   as Funding_TDS_Ratio
         , CASE  WHEN Underwriter_Code = 'PRM'		Then 'PRIME'
                 WHEN Branch in ( '2000', '2001','2010', '2011')	THEN 'PRIME'
                 WHEN Underwriter_Code = 'CMA'		Then 'Alt'
         END as Alt_Prime_Indicator
         , CASE
               WHEN (Arrears_Status like '%Tech%' OR Arrears_Status like '%not*arrear%')	THEN 0
               WHEN IFNULL(Arrears_Days, 0) <30											    THEN 0
               WHEN IFNULL(Arrears_Days, 0) <60											    THEN 1
               WHEN IFNULL(Arrears_Days, 0) >=60											THEN 2
        END as Delinquency_Status
    from t_loan_retail
    where year = Reporting_Year and time = Reporting_Time;



    DROP TEMPORARY TABLE IF EXISTS ii_temp_t_loan_retail;
    CREATE TEMPORARY TABLE ii_temp_t_loan_retail(
        Year									VARCHAR(5)
        , Time									VARCHAR(3)
        , Loan_Number							INT
        , CIF_Number							INT
        , SL_Date								DATE
        , Funded_Date							DATE
        , Partner_Participation					DECIMAL(20,5)
        , Underwriter_Code						VARCHAR(5)
        , Branch								VARCHAR(25)
        , RemainingPrincipal_excl_Partner		DECIMAL(20,5)
        , RemainingPrincipal_incl_Partner       DECIMAL(20,5)
        , Appraisal_Value						DECIMAL(20,5)
        , Interest_Rate							DECIMAL(20,5)
        , Term									INT
        , Age_At_SL                             INT
        , Postal_Code							VARCHAR(25)
        , FSA                                   VARCHAR(3)
        , Province								VARCHAR(5)
        , City                                  VARCHAR(25)
        , Arrears_Days							INT
        , Arrears_Status						VARCHAR(100)
        , Funding_GDS_Ratio						DECIMAL(10,5)
        , Funding_TDS_Ratio						DECIMAL(10,5)
        , Alt_Prime_Indicator                   VARCHAR(10)
        , Delinquency_Status                    TINYINT
        , Max_Beacon_Score_App                  INT
        , Max_BNI_Score_App                     INT
        , province_state_name                   VARCHAR(25)
        , SL_date_HPI                           INT
        , Funded_Date_HPI                       INT
        , PRIMARY KEY (Year, Time, SL_Date, Loan_Number)
    );


    TRUNCATE TABLE ii_temp_t_loan_retail;
    INSERT INTO ii_temp_t_loan_retail
    select
        ittlr.*
         , tbb.Max_Beacon_Score_App
         , tbb.Max_BNI_Score_App
         , tpm.province_state_name
         , date_format(ittlr.SL_Date, '%Y%m') as SL_date_HPI
         , if (year(ittlr.Funded_Date) < 2005, '200501', date_format(ittlr.Funded_Date, '%Y%m')) as Funded_Date_HPI
    from i_temp_t_loan_retail                 as ittlr
    LEFT JOIN t_beacon_bni                    as tbb
    on ittlr.Loan_Number = tbb.Loan_Number
    left join t_Province_Mapping              as tpm
    on ittlr.province = tpm.province;


    DROP TEMPORARY TABLE IF EXISTS iii_temp_t_loan_retail;
    CREATE TEMPORARY TABLE iii_temp_t_loan_retail (
        Year									VARCHAR(5)
        , Time									VARCHAR(3)
        , Loan_Number							INT
        , CIF_Number							INT
        , SL_Date								DATE
        , Funded_Date							DATE
        , Partner_Participation					DECIMAL(20,5)
        , Underwriter_Code						VARCHAR(5)
        , Branch								VARCHAR(25)
        , RemainingPrincipal_excl_Partner		DECIMAL(20,5)
        , RemainingPrincipal_incl_Partner       DECIMAL(20,5)
        , Appraisal_Value						DECIMAL(20,5)
        , Interest_Rate							DECIMAL(20,5)
        , Term									INT
        , Age_At_SL                             INT
        , Postal_Code							VARCHAR(25)
        , FSA                                   VARCHAR(3)
        , Province								VARCHAR(5)
        , City                                  VARCHAR(25)
        , Arrears_Days							INT
        , Arrears_Status						VARCHAR(100)
        , Funding_GDS_Ratio						DECIMAL(10,5)
        , Funding_TDS_Ratio						DECIMAL(10,5)
        , Alt_Prime_Indicator                   VARCHAR(10)
        , Delinquency_Status                    TINYINT
        , Max_Beacon_Score_App                  INT
        , Max_BNI_Score_App                     INT
        , province_state_name                   VARCHAR(25)
        , SL_date_HPI                           INT
        , Funded_Date_HPI                       INT
        , HPI_Index_prov_curr                   DECIMAL(20,10)
        , HPI_Index_prov_base                   DECIMAL(20,10)
        , HPI_Index_can_curr                    DECIMAL(20,10)
        , HPI_Index_can_base                    DECIMAL(20,10)
        , Appr_Val_Prov                         DECIMAL(25,10)
        , Appr_Val_Can                          DECIMAL(25,10)
        , Appr_Val_WF                           DECIMAL(25,10)
        , PRIMARY KEY (Year, Time, SL_Date, Loan_Number)
    );

    TRUNCATE TABLE iii_temp_t_loan_retail;
    INSERT INTO iii_temp_t_loan_retail
    select
        iittlr.*
         ,thp_curr.HPI_Index as HPI_Index_prov_curr
         ,thp_base.HPI_Index as HPI_Index_prov_base
         ,thn_curr.HPI_Index as HPI_Index_can_curr
         ,thn_base.HPI_Index as HPI_Index_can_base
         ,iittlr.Appraisal_Value *(thp_curr.HPI_Index/thp_base.HPI_Index) as Appr_Val_Prov
         ,iittlr.Appraisal_Value *(thn_curr.HPI_Index/thn_base.HPI_Index) as Appr_Val_Can
         ,iittlr.Appraisal_Value * ifnull(thp_curr.HPI_Index/thp_base.HPI_Index, thn_curr.HPI_Index/thn_base.HPI_Index) as Appr_Val_WF
    from ii_temp_t_loan_retail  iittlr
             left join t_hpi_province  thp_curr
                       on iittlr.province_state_name = thp_curr.HPI_Province
                           and iittlr.SL_date_HPI = thp_curr.date
             left join t_hpi_province thp_base
                       on iittlr.province_state_name = thp_base.HPI_Province
                           and iittlr.Funded_Date_HPI = thp_base.date
             left join t_hpi_national  thn_curr
                       on iittlr.SL_date_HPI = thn_curr.date
             left join t_hpi_national  thn_base
                       on iittlr.Funded_Date_HPI = thn_base.date;


    DROP TEMPORARY TABLE IF EXISTS unemployment_rate;
    create temporary table unemployment_rate
    (
        Date               DATE
        ,Value             DECIMAL(25, 10)
        ,Previous_date     DATE
        ,Previous_value    DECIMAL(25, 10)
        ,First_differences DECIMAL(25, 10)
        ,Comments          VARCHAR(50)
    );
    TRUNCATE TABLE unemployment_rate;
    INSERT INTO unemployment_rate
    with t as
             (select Date
                     , Value
                     ,'Moody_Historical' as Comments
              from t_Moody_Macro_Historical
              where Year = @Moody_Year and Time = @Moody_Time
              union
              select Date
                     , Value
                     ,'Moody_Forecast'
              from t_Moody_Macro_Forecast as Comments
              where Year = @Moody_Year and Time = @Moody_Time)
    select
        a1.Date
         , a1.Value
         , a2.Date as Previous_date
         , a2.Value as Previous_value
         , (a1.Value - a2.Value)/100 as First_differences
         , a1.Comments
    from  t a1
              left join t a2
                        on  a1.Date= last_day(date_add(a2.Date, interval 3 month));

    # ---approach 1  lag function
# with tmmh as
#          (select Date, Value from t_Moody_Macro_Historical
#           where Year = 'Y2018' and Time = 'Nov'
#           union
#           select Date, Value from t_Moody_Macro_Forecast
#           where Year = 'Y2018' and Time = 'Nov')
# select tmmh.Date
#        ,tmmh.VALUE
#        ,lag(Date, 3, 0) over(order by Date) as previous_quarter
#        ,lag(VALUE, 3, 0) over(order by Date) as previous_value
#        ,(tmmh.VALUE- lag(VALUE, 3, 0) over(order by Date))/100 as First_Differences
#        from tmmh

# ---approach 2 self_join
#     with tmmh2 as
#          (select Date, Value from t_Moody_Macro_Historical
#           where Year = 'Y2018' and Time = 'Nov'
#           union
#           select Date, Value from t_Moody_Macro_Forecast
#           where Year = 'Y2018' and Time = 'Nov');

    DROP TEMPORARY TABLE IF EXISTS iv_temp_t_loan_retail;
    CREATE TEMPORARY TABLE iv_temp_t_loan_retail(
        Year									VARCHAR(5)
        , Time									VARCHAR(3)
        , Loan_Number							INT
        , CIF_Number							INT
        , SL_Date								DATE
        , Funded_Date							DATE
        , Partner_Participation					DECIMAL(20,5)
        , Underwriter_Code						VARCHAR(5)
        , Branch								VARCHAR(25)
        , RemainingPrincipal_excl_Partner		DECIMAL(20,5)
        , RemainingPrincipal_incl_Partner       DECIMAL(20,5)
        , Appraisal_Value						DECIMAL(20,5)
        , Interest_Rate							DECIMAL(20,5)
        , Term									INT
        , Age_At_SL                             INT
        , Postal_Code							VARCHAR(25)
        , FSA                                   VARCHAR(3)
        , Province								VARCHAR(5)
        , City                                  VARCHAR(25)
        , Arrears_Days							INT
        , Arrears_Status						VARCHAR(100)
        , Funding_GDS_Ratio						DECIMAL(10,5)
        , Funding_TDS_Ratio						DECIMAL(10,5)
        , Alt_Prime_Indicator                   VARCHAR(10)
        , Delinquency_Status                    TINYINT
        , Max_Beacon_Score_App                  INT
        , Max_BNI_Score_App                     INT
        , province_state_name                   VARCHAR(25)
        , SL_date_HPI                           INT
        , Funded_Date_HPI                       INT
        , HPI_Index_prov_curr                   DECIMAL(20,10)
        , HPI_Index_prov_base                   DECIMAL(20,10)
        , HPI_Index_can_curr                    DECIMAL(20,10)
        , HPI_Index_can_base                    DECIMAL(20,10)
        , Appr_Val_Prov                         DECIMAL(25,10)
        , Appr_Val_Can                          DECIMAL(25,10)
        , Appr_Val_WF                           DECIMAL(25,10)
        , LTV_Incl_Part_Prov_WF                 DECIMAL(25,10)
        , Unemployment_diff_2Q                  DECIMAL(25,10)
        , Metro_Region                          VARCHAR(50)
        ,PRIMARY KEY (Year, Time, SL_Date, Loan_Number)
    );

    TRUNCATE Table iv_temp_t_loan_retail;
    INSERT INTO iv_temp_t_loan_retail
    select
        iiittlr.*
        ,CASE
            WHEN Appr_Val_WF = 0 then Null
            ELSE RemainingPrincipal_incl_Partner/Appr_Val_WF
        END AS LTV_Incl_Part_Prov_WF
        ,ur.First_differences    as Unemployment_diff_2Q
        ,tfm.Metro_Name          as Metro_Region
    from iii_temp_t_loan_retail iiittlr
    left join unemployment_rate ur
    on iiittlr.SL_Date = ur.Date
    left join t_fsa_mapping tfm
    on iiittlr.FSA = tfm.FSA;


    DROP TEMPORARY TABLE if EXISTS i_temp_t_loan_retail_WOE;
    Create TEMPORARY TABLE i_temp_t_loan_retail_WOE(
        Year									VARCHAR(5)
        , Time									VARCHAR(3)
        , Loan_Number							INT
        , CIF_Number							INT
        , SL_Date								DATE
        , Funded_Date							DATE
        , Partner_Participation					DECIMAL(20,5)
        , Underwriter_Code						VARCHAR(5)
        , Branch								VARCHAR(25)
        , RemainingPrincipal_excl_Partner		DECIMAL(20,5)
        , RemainingPrincipal_incl_Partner       DECIMAL(20,5)
        , Appraisal_Value						DECIMAL(20,5)
        , Interest_Rate							DECIMAL(20,5)
        , Term									INT
        , Age_At_SL                             INT
        , Postal_Code							VARCHAR(25)
        , FSA                                   VARCHAR(3)
        , Province								VARCHAR(5)
        , City                                  VARCHAR(25)
        , Arrears_Days							INT
        , Arrears_Status						VARCHAR(100)
        , Funding_GDS_Ratio						DECIMAL(10,5)
        , Funding_TDS_Ratio						DECIMAL(10,5)
        , Alt_Prime_Indicator                   VARCHAR(10)
        , Delinquency_Status                    TINYINT
        , Max_Beacon_Score_App                  INT
        , Max_BNI_Score_App                     INT
        , province_state_name                   VARCHAR(25)
        , SL_date_HPI                           INT
        , Funded_Date_HPI                       INT
        , HPI_Index_prov_curr                   DECIMAL(20,10)
        , HPI_Index_prov_base                   DECIMAL(20,10)
        , HPI_Index_can_curr                    DECIMAL(20,10)
        , HPI_Index_can_base                    DECIMAL(20,10)
        , Appr_Val_Prov                         DECIMAL(25,10)
        , Appr_Val_Can                          DECIMAL(25,10)
        , Appr_Val_WF                           DECIMAL(25,10)
        , LTV_Incl_Part_Prov_WF                 DECIMAL(25,10)
        , Unemployment_diff_2Q                  DECIMAL(25,10)
        , Metro_Region                          VARCHAR(50)
        , PD_delq_WOE                           DECIMAL(25, 15)
        , PD_term_WOE                           DECIMAL(25, 15)
        , PD_Region_WOE                         DECIMAL(25, 15)
        , PD_TDS_GDS_WOE                        DECIMAL(25, 15)
        , PD_API_LTV_WOE                        DECIMAL(25, 15)
        , PD_Beacon_BNI_WOE                     DECIMAL(25, 15)
        , PRIMARY KEY (Year, Time, SL_Date, Loan_Number)
);

    TRUNCATE TABLE i_temp_t_loan_retail_WOE;
    INSERT INTO i_temp_t_loan_retail_WOE
    select
        a.*
         ,b.WOE                        as PD_delq_WOE
         ,c.WOE                        as PD_term_WOE
         ,ifnull(d.WOE, e.WOE)         as PD_Region_WOE
         ,ifnull(f.WOE, 0)             as PD_TDS_GDS_WOE
         ,COALESCE(g.WOE, h.WOE)       as PD_API_LTV_WOE
         ,COALESCE(i.WOE, j.WOE, k.WOE, l.WOE)   as PD_Beacon_BNI_WOE
    from iv_temp_t_loan_retail         as a
#    ----- delq status WOE
             left join t_woe_Delq      as b
                       on a.Delinquency_Status = b.DelQ_Current and b.Valid_To_Date = '9999-12-31'
#    ------term_age WOE
             left join t_woe_term_age c
                       on  a.Term > c.Term_Min
                       and a.Term <= c.Term_Max
                       and a.Age_At_SL > c.MoB_Min
                       and a.Age_At_SL <= c.MoB_Max
                       and c.Valid_To_Date = '9999-12-31'
#   ----- Metro & province
             left join t_woe_Region   as d
                       on a.Metro_Region = d.Metro_Region
                       AND a.Province = d.Province
                       and d.Valid_To_Date = '9999-12-31'
             left join t_woe_region   as e
                       on e.Metro_Region = 'Other'
                       and a.Province = e.Province
                       and e.Valid_To_Date = '9999-12-31'
             left join t_WOE_TDS_GDS   as f
                       on a.Funding_TDS_Ratio > f.TDS_Min
                       and a.Funding_TDS_Ratio <= f.TDS_Max
                       and a.Funding_GDS_Ratio > f.GDS_Min
                       and a.Funding_GDS_Ratio <= f.GDS_Max
                       and f.Valid_To_Date ='9999-12-31'
             left join t_woe_ltv    as g
                       on  a.Alt_Prime_Indicator = g.ALT_Prime_Ind
                       and a.LTV_Incl_Part_Prov_WF > g.BF_LTV_Min
                       and a.LTV_Incl_Part_Prov_WF <= g.BF_LTV_Max
                       and g.Valid_To_Date = '9999-12-31'
             left join t_woe_ltv    as h
                       on h.BF_LTV_Min is null
                       and a.Alt_Prime_Indicator = h.ALT_Prime_Ind
                       and h.Valid_To_Date = '9999-12-31'
             left join t_woe_Beacon_BNI  as i
                       on a.Max_Beacon_Score_App > i.Beacon_Min
                       and a.Max_Beacon_Score_App <= i.Beacon_Max
                       and a.Max_BNI_Score_App > i.BNI_Min
                       and a.Max_BNI_Score_App <= i.BNI_Max
                       and i.Valid_To_Date = '9999-12-31'
             left join t_woe_Beacon_BNI  as j
                       on ifnull(a.Max_Beacon_Score_App, -1) = ifnull(j.Beacon_Min, -1)
                       and a.Max_BNI_Score_App > j.BNI_Min
                       and a.Max_BNI_Score_App <= j.BNI_Max
                       and j.Valid_To_Date = '9999-12-31'
             left join t_woe_Beacon_BNI  as k
                       on ifnull(a.Max_BNI_Score_App, -1) = ifnull(k.BNI_min, -1)
                       and a.Max_Beacon_Score_App > k.Beacon_Min
                       and a.Max_Beacon_Score_App <= k.Beacon_Max
                       and k.Valid_To_Date = '9999-12-31'
             left join t_woe_Beacon_BNI  as  l
                       on ifnull(a.Max_BNI_Score_App,-1)= ifnull(l.BNI_Min, -1)
                       and ifnull(a.Max_Beacon_Score_App, -1) = ifnull(l.Beacon_Min, -1)
                       and l.Valid_To_Date = '9999-12-31';


    set @PD_Intercept              =   (select Intercept from t_woe_coeff);
    set @PD_LTV                    =   (select LTV from t_woe_coeff);
    set @PD_Beacon_BNI             =   (select Beacon_BNI from t_woe_coeff);
    set @PD_Delq                   =   (select Delq from t_woe_coeff);
    set @PD_Term_Age               =   (select Term_age from t_woe_coeff);
    set @PD_Provincial_Risk        =   (select Provincial_Risk from t_woe_coeff);
    SET @PD_TDS_GDS                =   (Select TDS_GDS From t_woe_coeff);
    set @PD_UE                     =   (select UE from t_woe_coeff);


    DROP TEMPORARY TABLE IF EXISTS i_temp_t_loan_retail_WOE_PD;
    CREATE TEMPORARY TABLE i_temp_t_loan_retail_WOE_PD(
        Year									VARCHAR(5)
        , Time									VARCHAR(3)
        , Loan_Number							INT
        , CIF_Number							INT
        , SL_Date								DATE
        , Funded_Date							DATE
        , Partner_Participation					DECIMAL(20,5)
        , Underwriter_Code						VARCHAR(5)
        , Branch								VARCHAR(25)
        , RemainingPrincipal_excl_Partner		DECIMAL(20,5)
        , RemainingPrincipal_incl_Partner       DECIMAL(20,5)
        , Appraisal_Value						DECIMAL(20,5)
        , Interest_Rate							DECIMAL(20,5)
        , Term									INT
        , Age_At_SL                             INT
        , Postal_Code							VARCHAR(25)
        , FSA                                   VARCHAR(3)
        , Province								VARCHAR(5)
        , City                                  VARCHAR(25)
        , Arrears_Days							INT
        , Arrears_Status						VARCHAR(100)
        , Funding_GDS_Ratio						DECIMAL(10,5)
        , Funding_TDS_Ratio						DECIMAL(10,5)
        , Alt_Prime_Indicator                   VARCHAR(10)
        , Delinquency_Status                    TINYINT
        , Max_Beacon_Score_App                  INT
        , Max_BNI_Score_App                     INT
        , province_state_name                   VARCHAR(25)
        , SL_date_HPI                           INT
        , Funded_Date_HPI                       INT
        , HPI_Index_prov_curr                   DECIMAL(20,10)
        , HPI_Index_prov_base                   DECIMAL(20,10)
        , HPI_Index_can_curr                    DECIMAL(20,10)
        , HPI_Index_can_base                    DECIMAL(20,10)
        , Appr_Val_Prov                         DECIMAL(25,10)
        , Appr_Val_Can                          DECIMAL(25,10)
        , Appr_Val_WF                           DECIMAL(25,10)
        , LTV_Incl_Part_Prov_WF                 DECIMAL(25,10)
        , Unemployment_diff_2Q                  DECIMAL(25,10)
        , Metro_Region                          VARCHAR(50)
        , PD_delq_WOE                           DECIMAL(25,10)
        , PD_term_WOE                           DECIMAL(25,10)
        , PD_Region_WOE                         DECIMAL(25,10)
        , PD_TDS_GDS_WOE                        DECIMAL(25,10)
        , PD_API_LTV_WOE                        DECIMAL(25,10)
        , PD_Beacon_BNI_WOE                     DECIMAL(25,10)
        , Log_Odds                              DECIMAL(25,10)
        , PD_Final                              DECIMAL(25, 10)
        , PRIMARY KEY (Year, Time, SL_Date, Loan_Number)
    );
    TRUNCATE TABLE i_temp_t_loan_retail_WOE_PD;
    INSERT INTO i_temp_t_loan_retail_WOE_PD
    select
        *,
        (@PD_Intercept
            + (@PD_LTV * PD_API_LTV_WOE)
            + (@PD_Beacon_BNI * PD_Beacon_BNI_WOE)
            + (@PD_Delq * PD_delq_WOE)
            + (@PD_Term_Age * PD_term_WOE)
            + (@PD_Provincial_Risk * PD_Region_WOE)
            + (@PD_TDS_GDS * PD_TDS_GDS_WOE)
            + (@PD_UE * Unemployment_diff_2Q))           as Log_Odds
            , (1/(1+ exp(-(@PD_Intercept
        + (@PD_LTV * PD_API_LTV_WOE)
        + (@PD_Beacon_BNI * PD_Beacon_BNI_WOE)
        + (@PD_Delq * PD_delq_WOE)
        + (@PD_Term_Age * PD_term_WOE)
        + (@PD_Provincial_Risk * PD_Region_WOE)
        + (@PD_TDS_GDS * PD_TDS_GDS_WOE)
        + (@PD_UE * Unemployment_diff_2Q)))))            as PD_Final
    from i_temp_t_loan_retail_WOE;



     CREATE TABLE t_Retail_PD_Model_All (
         Year									VARCHAR(5)
         , Time									VARCHAR(3)
         , Loan_Number							INT
         , SL_Date								DATE
         , Funded_Date                           DATE
         , Interest_Rate                         DECIMAL(20,5)
         , Term                                  INT
         , Age_At_SL                             INT
         , Province                              VARCHAR(5)
         , Metro_Region                          VARCHAR(50)
         , Funding_GDS_Ratio                     DECIMAL(10,5)
         , Funding_TDS_Ratio                     DECIMAL(10,5)
         , Alt_Prime_Indicator                   VARCHAR(10)
         , Delinquency_Status                    TINYINT
         , Max_Beacon_Score_App                  INT
         , Max_BNI_Score_App                     INT
         , RemainingPrincipal_excl_Partner       DECIMAL(20,5)
         , Appr_Val_Prov                         DECIMAL(25,10)
         , Appr_Val_Can                          DECIMAL(25,10)
         , Appr_Val_WF                           DECIMAL(25,10)
         , Arrears_Days                          INT
         , Arrears_Status                        VARCHAR(100)
         , LTV_Incl_Part_Prov_WF                 DECIMAL(25,10)
         , Unemployment_diff_2Q                  DECIMAL(25,10)
         , PD_delq_WOE                           DECIMAL(25,10)
         , PD_term_WOE                           DECIMAL(25,10)
         , PD_Region_WOE                         DECIMAL(25,10)
         , PD_TDS_GDS_WOE                        DECIMAL(25,10)
         , PD_API_LTV_WOE                        DECIMAL(25,10)
         , PD_Beacon_BNI_WOE                     DECIMAL(25,10)
         , Log_Odds                              DECIMAL(25,10)
         , PD_Final                              DECIMAL(25,10)
         , PRIMARY KEY (Year, Time, SL_Date, Loan_Number)
     );


    DELETE FROM t_Retail_PD_Model_All
    WHERE Year = Reporting_Year and Time = Reporting_Time;
    INSERT INTO t_Retail_PD_Model_All
    select
         Year
         , Time
         , Loan_Number
         , SL_Date
         , Funded_Date
         , Interest_Rate
         , Term
         , Age_At_SL
         , Province
         , Metro_Region
         , Funding_GDS_Ratio
         , Funding_TDS_Ratio
         , Alt_Prime_Indicator
         , Delinquency_Status
         , Max_Beacon_Score_App
         , Max_BNI_Score_App
         , RemainingPrincipal_excl_Partner
         , Appr_Val_Prov
         , Appr_Val_Can
         , Appr_Val_WF
         , Arrears_Days
         , Arrears_Status
         , LTV_Incl_Part_Prov_WF
         , Unemployment_diff_2Q
         , PD_delq_WOE
         , PD_term_WOE
         , PD_Region_WOE
         , PD_TDS_GDS_WOE
         , PD_API_LTV_WOE
         , PD_Beacon_BNI_WOE
         , Log_Odds
         , PD_Final
    from i_temp_t_loan_retail_WOE_PD;

END$$

DELIMITER ;


call Retail_PD_Model_Implementation('Y2018', 'Dec');

