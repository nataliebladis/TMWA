SELECT customernumber
, SUM(totpayamt) as total_profit_month
, MIN(billdate) as min_billdate
, MAX(billdate) as max_billdate
FROM loadres.bill_summary
GROUP BY customernumber
ORDER BY total_profit_month DESC;


SELECT customernumber
, SUM(totpayamt) as total_profit_month
FROM loadres.bill_summary
--WHERE customernumber = 232992300
GROUP BY customernumber
ORDER BY total_profit_month DESC
FETCH FIRST 10 ROWS ONLY;



SELECT * 
FROM enquesta.cihistorymaster;

SELECT aprem_no, aprem_cycle, aprem_init_service_date, 
       change_date(aprem_init_service_date,'MMDDYYYY') AS aprem_init_date
FROM cis.fciaprem;
     
