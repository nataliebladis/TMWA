/*       1         2         3         4         5         6         7         8
********************************************************************************
  Oracle Script Name:  lemmon_wtr_use_v2.sql
  Created by        :  Natalie Bladis
  Created on        :  2023-09-27
  Abstract          :  Determines total water usage for each meter and premise 
                       in Lemmon Valley
  
  Database          :  LRDAT0

  Tables            :  loadres.lemmon_water_use
                       loaddata.transaction1

*******************************************************************************/



-- THIS ONE WORKS 
DECLARE
  v_sql VARCHAR2(1000);
BEGIN
  FOR col_rec IN (SELECT column_name 
                  FROM all_tab_columns
                  WHERE table_name = 'LEMMON_WATER_USE') LOOP
    v_sql := 'ALTER TABLE lemmon_water_use RENAME COLUMN "' || col_rec.column_name || '" TO ' || UPPER(col_rec.column_name);
    EXECUTE IMMEDIATE v_sql;
  END LOOP;
END;
/



-- THE FINAL QUERY SO FAR

WITH lemmon_totals AS (
    SELECT
        w.prm,
        t.mtr,
        SUM(CASE WHEN EXTRACT(YEAR FROM TO_DATE(t.rym, 'YYYYMM')) = 2016 THEN t.tot_use ELSE 0 END) AS use_2016,
        SUM(CASE WHEN EXTRACT(YEAR FROM TO_DATE(t.rym, 'YYYYMM')) = 2017 THEN t.tot_use ELSE 0 END) AS use_2017,
        SUM(CASE WHEN EXTRACT(YEAR FROM TO_DATE(t.rym, 'YYYYMM')) = 2018 THEN t.tot_use ELSE 0 END) AS use_2018,
        SUM(CASE WHEN EXTRACT(YEAR FROM TO_DATE(t.rym, 'YYYYMM')) = 2019 THEN t.tot_use ELSE 0 END) AS use_2019,
        SUM(CASE WHEN EXTRACT(YEAR FROM TO_DATE(t.rym, 'YYYYMM')) = 2020 THEN t.tot_use ELSE 0 END) AS use_2020
    FROM
        loadres.lemmon_water_use w
    LEFT OUTER JOIN
        loaddata.loadtransaction1 t
    ON
        w.prm = t.prm
    WHERE
        EXTRACT(YEAR FROM TO_DATE(t.rym, 'YYYYMM')) BETWEEN 2016 AND 2020
    GROUP BY  -- Group by premise and meter, I also thought about grouping by service id as well. 
        w.prm,
        t.mtr
    ORDER BY
        w.prm,
        t.mtr
)

SELECT DISTINCT lwu.prm,
       lwu.mtr, 
       transaction_info.srvcid,
       transaction_info.rclass,
       transaction_info.ssize,
       lwu.use_2016,
       lwu.use_2017,
       lwu.use_2018,
       lwu.use_2019,
       lwu.use_2020 
FROM lemmon_totals lwu
LEFT OUTER JOIN (
     SELECT prm
       , srvcid
       , rclass
       , ssize  
     FROM loaddata.loadtransaction1 
) transaction_info 
ON lwu.prm = transaction_info.prm;

    
SELECT t.prm
       , t.srvcid
       , t.rclass
       , t.ssize  
FROM loaddata.loadtransaction1 t;
