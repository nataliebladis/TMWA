/*       1         2         3         4         5         6         7         8
********************************************************************************
  Oracle Script Name:  transactions_Jan-Apr21.sql
  Created by        :  Natalie Bladis
  Created on        :  2023-10-04
  Abstract          :  Build a view for just adding rate schedule codes.

  Tables            : 

*******************************************************************************/

/******************************************************************************/

-- Pull transactions from January 2021 and February 2021 from ECIS
-- in lrdat0
-- SELECT *
--FROM loaddata.loadtransaction1
--WHERE rym BETWEEN 202101 AND 202103;

/***************************************/
-- List of columns to fill:
/***************************************/
--PKEY
--RYM : from Build_Usagev05 billdate -2 digits
--RCLASS : 
--RATE_SCH : from Step02c RSCH
--SSIZE
--ACT : from Step02c ACT
--CUS : from Step02c OLD_CUS
--PRM : from Step02c OLD_PRM
--UTL : from Step02c UTL_TYP
--SRVCID : from Step02c service_seq      -- combined with premise = service id
--MTR
--BLD : Build_Usage_v05 BILLDATE
--RFSVCID : Build_Usage_v05 SERVICENUMBERSEQUENCE -- I'm not sure about this. 
--CON
--CLS
--DYS : Build_Usage_v05 NUMBEROFDAYS
--EFD : Build_Usage_v05 FROMDATE
--EDT : Build_Usage_v05 TODATE
--UNITS : from step02c num_units -- generally equal except in some cases where numbers or 0 or 1.
--TOT_Use : Build_Usage_v05 TOT_USE
--T1_Use : Build_Usage_v05 BLKUSE_1
--T2_USE : Build_Usage_v05 BLKUSE_2
--T3_USE : Build_Usage_v05 BLKUSE_3
--T4_USE : Build_Usage_v05 BLKUSE_4
--T5_USE : Build_Usage_v05 BLKUSE_5
--TOT_REV : 
--T0_AMT : Step02c TO_AMT_24 -- I am not sure about this one. 
-- PU_AMT
-- T1_AMT : Build_Usage_v05 BLKAMT_1
-- T2_AMT : Build_Usage_v05 BLKAMT_2
-- T3_AMT : Build_Usage_v05 BLKAMT_3
-- T4_AMT  : Build_Usage_v05 BLKAMT_4
-- T5_AMT : Build_Usage_v05 BLKAMT_5        SMALL NOTE - There is also the blk rate in Build_usage_v05
-- BF_AMT
-- LNG : GIS.GISVIEWNEW MAPCOORDINATESEAST_CMTR
--LAT :  GIS.GISVIEWNEW MAPCOORDINATESNORTH_CMTR
-- X
-- Y



with date_range as
 (select 20210301 as startdte, 20210430 as enddte from dual),

-- Mailing address CTE for Customer Names 
mailing_addr AS (
  SELECT
    a.addr_comp
    , a.addr_cis_no
    , a.addr_seq_no
    , a.acc_rn
    , a.addr_first_name
    , a.addr_middle_name
    , a.addr_last_name
    , a.addr_mailing_name
    , a.addr_address_1
    , a.addr_city
    , a.addr_state
    , a.addr_zip_code
  FROM cis.FCIADDR a
),

-- 
prem_addr as 
(
SELECT a.prem_no
       , a.acc_rn
       , a.prem_service_addr1_no
       , a.prem_service_addr1_name
       , a.prem_town
       , CASE WHEN (a.prem_state = 32) THEN 'NV' ELSE TO_CHAR(a.prem_state) END as state
       , a.prem_zip --prem_comp is a mandatroy identifier but it take on only the value of 1 so has been excluded. The only other foreign key in the model is fciprem.prem_no = fwacmas.wacm_premise_no
FROM cis.fciprem a
),

step02 as 
(
select '--f1--' as f1
        ,f1.cihis_cust
        ,f1.cihis_cis -- question not sure about this field
        ,f1.cihis_date
        ,f1.cihis_reference
        ,f1.acc_rn AS HistoryID
        ,f1.cihis_date AS BillDate
        ,f1.cihis_seq AS history_seq
        ,f1.cihis_cycle AS bill_cycle
        ,c1.description AS Cycle_Desc --Billing Cycle description
        ,f1.cihis_addr_seq AS AddressSeqNum --Address seq number to link to addresses
        ,f1.cihis_curr_amt AS CurrentBillAmt --Current amount of charges
        ,'--f2--' as blank1
        ,f2.wacm_ref_acct AS old_act  --ECIS account number
        ,f2.wacm_cust AS act          --enQuesta act num 
        ,f2.wacm_master AS master_act --Master billing account
        ,(f2.wacm_premise_no / 10000) AS old_prm --ECIS premise number
        ,f2.wacm_premise_no AS prm            --enQuesta premise
        ,f2.wacm_occupant_cis_no AS old_cus   --ECIS & Enquesta same number
        ,f2.wacm_occupant_cis_no AS cisnumber --ECIS & Enquesta same number
        ,f2.wacm_mult_family as num_families  -- number of familes and units are 
        ,f2.wacm_no_units as num_units        -- generally equal except in some cases where numbers or 0 or 1.
        ,'--f3--' as blank2
        ,f3.cihis_service AS service_seq      -- combined with premise = service id
        ,f3.cihis_metered_item_rate as driver_rate
        -- calculate ratekindid from the meter_item_rate, which is a driver rate.
        ,(CASE 
               WHEN   f3.cihis_metered_item_rate = 0
                 THEN 0
               WHEN f3.cihis_metered_item_rate = 2500
                THEN 2
              ELSE
                NULL
              END) as ratekindid 
        -- calculate a utility type for meter, flat, backflow, and fire
        -- Utility type is derived from the ciratemaster table. 
        -- at some point I can compute utility type directly from 
        -- metered_item_rate and the cihis_rate1 fields.     
        ,CASE
             WHEN r1.ratekindid = 0
                  AND r1.rate BETWEEN 1 AND 2500 THEN
              'W'
             WHEN r1.ratekindid = 2
                  AND (r1.rate BETWEEN 1 AND 19 OR r1.rate = 100) THEN
              'U'
             WHEN r1.ratekindid = 2
                  AND (r1.rate BETWEEN 20 AND 31 OR r1.rate BETWEEN 110 AND 116 OR
                  r1.rate BETWEEN 210 AND 260) THEN
              'F'
             WHEN r1.ratekindid = 2
                  AND r1.rate IN (40, 41) THEN
              'D'
             WHEN r1.ratekindid = 2
                  AND r1.rate = 50 THEN
              'B'
           END AS utl_typ
        ,f3.cihis_rate1 as rate
        ,r2.rsch
        -- rate description is useful until it build the lookup for rate schedule codes.
        ,r1.description  
        ,f3.cihis_class_num1
        ,f3.cihis_class_type1
        ,sum(CASE WHEN f3.cihis_type_code = 24 THEN 1 ELSE NULL END) as typ24
        ,sum(CASE WHEN f3.cihis_type_code = 24 THEN f3.cihis_amt ELSE NULL END) as t0_amt_24
        ,sum(CASE WHEN f3.cihis_type_code = 2 THEN 1 ELSE NULL END) AS typ02
        ,min(CASE WHEN f3.cihis_type_code = 2 THEN change_date(f3.cihis_from_date, 'MMDDYYYY') ELSE NULL END) as his_from_date
        ,max(CASE WHEN f3.cihis_type_code = 2 THEN change_date(f3.cihis_to_date, 'MMDDYYYY') ELSE NULL END) as his_to_date
        ,sum(CASE WHEN f3.cihis_type_code = 2 THEN f3.cihis_use ELSE NULL END) AS t_use
        ,sum(CASE WHEN f3.cihis_type_code = 2 THEN f3.cihis_amt ELSE NULL END) as t_use_amt
        ,sum(CASE WHEN f3.cihis_type_code = 34 THEN 1 ELSE NULL END) as typ34
        ,sum(CASE WHEN f3.cihis_type_code = 34 THEN f3.cihis_amt ELSE NULL END) as t0_amt_34


    from cis.fcihistf f1
    left outer join enquestacis.cibillingcycle c1
      on f1.cihis_cycle = c1.cycle
    left outer join cis.fwacmas f2
      on f1.cihis_cust = f2.wacm_cust
    left outer join cis.fcihistv f3
      on f1.acc_rn = f3.cihis_fixedid
    left outer join 
         (select * from enquestacis.ciratemaster where application = 3) r1
      on (CASE WHEN f3.cihis_metered_item_rate = 0 AND f3.cihis_rate1 = 550
                THEN 1
               WHEN   f3.cihis_metered_item_rate = 0
                 THEN 0
               WHEN f3.cihis_metered_item_rate = 2500
                THEN 2
              ELSE
                NULL
              END) = r1.ratekindid
     and f3.cihis_rate1 = r1.rate
   left outer join shawn.rateclass r2
      on r1.ratekindid = r2.ratekindid
     and f3.cihis_rate1 = r2.rate 

   where f1.cihis_code = 99
     and f3.cihis_type_code in (24, 2, 34)
         --metered_item rate: 0 for metered, 2500 for flat rate keep.
         -- 2501 is not for flat rates services but a service charge adjustment
         -- 2502 also not a flat rate service but for ditch accounts
     and f3.cihis_metered_item_rate in (0, 2500)
         -- rate 3999 is a template and 550 is IWS service credit. exclude
     and f3.cihis_rate1 not in (3999, 550)
     and f1.cihis_date between (select startdte from date_range) and
         (select enddte from date_range) 
     --and f2.wacm_cust = 100689300
   group by 
         f1.cihis_cust
        ,f1.cihis_cis 
        ,f1.cihis_date
        ,f1.cihis_reference
        ,f1.acc_rn 
        ,f1.cihis_date 
        ,f1.cihis_seq 
        ,f1.cihis_cycle 
        ,c1.description 
        ,f1.cihis_addr_seq 
        ,f1.cihis_curr_amt 
        ,f2.wacm_ref_acct 
        ,f2.wacm_cust  
        ,f2.wacm_master 
        ,(f2.wacm_premise_no / 10000) 
        ,f2.wacm_premise_no 
        ,f2.wacm_occupant_cis_no 
        ,f2.wacm_occupant_cis_no 
        ,f2.wacm_mult_family 
        ,f2.wacm_no_units 
        ,f3.cihis_service 
        ,f3.cihis_metered_item_rate
        ,f3.cihis_rate1
        ,f3.cihis_class_num1
        ,f3.cihis_class_type1
        ,r1.ratekindid
        ,r1.rate
        ,r1.description
        ,r2.rsch
),


/*****************************************************************************/
-- Block Usage CTE
blkuse as 
(
select  c2.consumptionhistid 
       ,c2.readsequence 
       ,sum(case when c2.blocknumber = 1 then c2.blockusage else null end) as blkuse_1
       ,sum(case when c2.blocknumber = 2 then c2.blockusage else null end) as blkuse_2
       ,sum(case when c2.blocknumber = 3 then c2.blockusage else null end) as blkuse_3
       ,sum(case when c2.blocknumber = 4 then c2.blockusage else null end) as blkuse_4
       ,sum(case when c2.blocknumber = 5 then c2.blockusage else null end) as blkuse_5
       ,sum(case when c2.blocknumber = 1 then c2.blockamount else null end) as blkamt_1
       ,sum(case when c2.blocknumber = 2 then c2.blockamount else null end) as blkamt_2
       ,sum(case when c2.blocknumber = 3 then c2.blockamount else null end) as blkamt_3
       ,sum(case when c2.blocknumber = 4 then c2.blockamount else null end) as blkamt_4
       ,sum(case when c2.blocknumber = 5 then c2.blockamount else null end) as blkamt_5
       ,sum(case when c2.blocknumber = 1 then c2.blockrate else null end) as blkrate_1
       ,sum(case when c2.blocknumber = 2 then c2.blockrate else null end) as blkrate_2
       ,sum(case when c2.blocknumber = 3 then c2.blockrate else null end) as blkrate_3
       ,sum(case when c2.blocknumber = 4 then c2.blockrate else null end) as blkrate_4
       ,sum(case when c2.blocknumber = 5 then c2.blockrate else null end) as blkrate_5
from enqcopy1.ciconsumptionhistblock c2 
group by  c2.consumptionhistid, c2.readsequence
),

blkuse_header as
(
select  c1.accountnumber
       ,c1.consumptionhistid
       ,c1.readsequence 
       ,c1.device
       ,date_to_number(c1.billdate) as billdate
       ,c1.hasblocks
       ,c1.numberofdays
       ,date_to_number(c1.fromdate) as fromdate
       ,date_to_number(c1.todate) as todate
       ,c1.rate1
       ,c1.ratekind1
       ,c1.servicenumbersequence
       ,c1.transactioncode
  from enqcopy1.ciconsumptionhist c1
  where c1.transactioncode = 102
),

wacm as
(
select  f1.wacm_cust 
       ,f1.wacm_address_seq_no
       ,f1.wacm_occupant_cis_no
       ,f1.wacm_premise_no as premiseid
       ,f1.wacm_ref_acct
       ,f1.wacm_no_units
  from enqcopy1.fwacmas f1
),

gis_data as (
SELECT gis.PREMISEID
       , gis.MAPCOORDINATESNORTH_CMTR
       , gis.MAPCOORDINATESEAST_CMTR
FROM GIS.GISVIEWNEW gis
)

/* end of CTEs */

/*****************************************************************************/

/************************************************************/



-- SELECT * 
-- FROM gis_data;



--select *
--from step02 s
--;



select s1.* 
       ,b3.premiseid
       ,b1.accountnumber
       --,b3.wacm_address_seq_no
       ,b1.servicenumbersequence
       ,b1.device
       --,b1.consumptionhistid
       ,b1.billdate
       ,b1.numberofdays
       ,b1.fromdate
       ,b1.todate
       ,b1.rate1
       ,nvl(b2.blkuse_1, 0) + 
        nvl(b2.blkuse_2, 0) + 
        nvl(b2.blkuse_3, 0) + 
        nvl(b2.blkuse_4, 0) + 
        nvl(b2.blkuse_5, 0) as tot_use
       ,nvl(b2.blkamt_1, 0) + 
        nvl(b2.blkamt_2, 0) + 
        nvl(b2.blkamt_3, 0) + 
        nvl(b2.blkamt_4, 0) + 
        nvl(b2.blkamt_5, 0) as tot_amt
       ,b2.blkuse_1
       ,b2.blkuse_2
       ,b2.blkuse_3
       ,b2.blkuse_4
       ,b2.blkuse_5
       ,b2.blkamt_1
       ,b2.blkamt_2
       ,b2.blkamt_3
       ,b2.blkamt_4
       ,b2.blkamt_5
       ,b2.blkrate_1
       ,b2.blkrate_2
       ,b2.blkrate_3
       ,b2.blkrate_4
       ,b2.blkrate_5
       
from step02 s1
left outer join blkuse_header b1
on s1.prm = b1.premiseid
     left outer join blkuse b2
     on b1.consumptionhistid = b2.consumptionhistid
     and b1.readsequence = b2.readsequence
     left outer join wacm b3
     on b1.accountnumber = b3.wacm_cust 
where b1.billdate between 20210301 and 20210430
      -- and b1.accountnumber = 100038300 */

; 
