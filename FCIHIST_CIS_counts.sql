

-- Explore CIHIS_CYCLE : Seems to indicate bill cycle (geographic location where 
SELECT DISTINCT(a.CIHIS_CYCLE) 
FROM CIS.FCIHISTF a
ORDER BY a.cihis_cycle DESC;

-- Explore CIHIS_CIS

SELECT DISTINCT a.CIHIS_CIS,
       COUNT(a.CIHIS_CIS) as count 
FROM CIS.FCIHISTF a
GROUP BY a.CIHIS_CIS
ORDER BY a.CIHIS_CIS DESC; -- 99999999 has 4684 records, all other CIHIS_CIS values have only 1 count
