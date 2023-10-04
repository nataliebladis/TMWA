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
