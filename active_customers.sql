WITH cteactivecode AS (
  SELECT customernumber
  FROM enquesta.wawatercustomermaster
)

 

SELECT DISTINCT a.customernumber,
                a.workorderyear,
                a.ordernumber,
                a.cisnumber,
                a.ordertype,
                a.servicepremisenumber,
                a.completecode,
                c.cihis_amt,
                c.cihis_type_code
FROM enquesta.ciworkorder a
JOIN cteactivecode b ON b.customernumber = a.customernumber
JOIN cis.fcihistv c ON c.cihis_wo_num = a.ordernumber -- Joining on ordernumber
WHERE a.ordertype = 3512
  AND a.completecode = 1 /* 9 = void, 0 = NP, 1 = HS, 3 = HS, 6 = HD */
  AND a.workorderyear = 2023
  AND c.cihis_type_code = 4
  AND a.customernumber = c.cihis_cust --this removes duplicates and bad data from conversion
  
  SELECT *
  FROM shawn.rateclass;
