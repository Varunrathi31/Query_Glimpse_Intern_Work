--THIS QUERY WRITTEN TO FETCH DATA FROM 1 OR MORE TABLES.
--THIS IS REAL DATA WHERE I AM WORKING ON A STARTUP COMPANY.
--TO SHOW WHAT I DO IN MY INTERNSHIP PERIOD, PLEASE SEE A GLIMPSE OF IT.



--Write SQL query to give operator_id with their no.of service(GPS, FUEL, FASTAG) operator are using.
--COUNT = 1 for any 1 product(GPS,FUEL,FASTAG)

SELECT operator_id, 
COUNT( DISTINCT service_type) no_of_service_using_by_operator
FROM ocms_operator_vehicles
WHERE deleted = 0 and is_active = 1 
GROUP BY operator_id
ORDER BY operator_id ASC



--WRITE SQL QUERY WHERE WANT TO SHOW OPERATION_ID WITH THEIR RESPECTIVE GPS PRODUCT USING, FUEL SERVICE USING AND FASTAG SERVICE USING.

SELECT operator_id,
	   SUM(CASE WHEN service_t2ype = 'GPS' THEN 1 
                          WHEN service_type = 'FASTAG'  THEN 0 
                          WHEN service_type = 'FUEL'  THEN 0
		   END) AS number_of_GPS,
       SUM(CASE WHEN service_type = 'FUEL'  THEN 1 
                          WHEN service_type = 'GPS'  THEN 0 
                          WHEN service_type = 'FASTAG'  THEN 0
           END) AS number_of_FUEL,
       SUM(CASE WHEN service_type = 'FASTAG' THEN 1 
                          WHEN service_type = 'GPS' THEN 0 
                          WHEN service_type = 'FUEL' THEN 0
           END) AS number_of_FASTAG
FROM ocms_operator_vehicles
WHERE deleted = 0 AND is_active = 1
GROUP BY operator_id
ORDER BY operator_id ASC



-- SHOW OPERATOR_CODE, service_type : GPS,  GPS_count > 5 AND FROM PUNJAB

SELECT		o.code,
			ov.service_type,
			COUNT(ov.service_type) AS GPS_count
FROM	   ocms_operators o
INNER JOIN ocms_operator_vehicles ov
           ON o.id = ov.operator_id
INNER JOIN ocms_vehicles v
           ON v.id = ov.vehicle_id
WHERE ov.service_type = 'GPS' AND LEFT(vehicle_number,2) = 'PB' AND ov.deleted = 0 AND ov.is_active = 1
GROUP BY ov.operator_id, o.code, ov.service_type
HAVING COUNT(ov.service_type) > 5
ORDER BY ov.operator_id ASC



--SHOW OPERATOR_CODE HAVE gps_count > 5, fastag_count > 3 AND fuel_count > 1 AND FROM PUNJAB

SELECT      o.code,
            SUM(CASE
                    WHEN ov.service_type = 'GPS' THEN 1
                    ELSE 0
                 END) AS gps_count,
            SUM(CASE
                    WHEN ov.service_type = 'FASTAG' THEN 1
                    ELSE 0
                END) AS fastag_count,
            SUM(CASE
                    WHEN ov.service_type = 'FUEL' THEN 1
                    ELSE 0
                END) AS fuel_count
FROM        ocms_operator_vehicles ov
INNER JOIN  ocms_vehicles v
            ON v.id =  ov.vehicle_id
INNER JOIN  ocms_operators o
            ON o.id = ov.operator_id
WHERE ov.deleted = 0 AND ov.is_active = 1 AND LEFT(v.vehicle_number,2) = 'PB'
GROUP BY ov.operator_id, o.code
HAVING gps_count > 5 AND fastag_count > 3 AND fuel_count > 1



--Vehicle whose GPS(service) renewal date is crossed, show their last 30 days app_usage ((no. of times operator open the app)/30)
--Conditions like renewal month and year is June 2021, max_session_duration each day is more than 5 sec

SELECT  vod.operator_code,
        ISNULL(tbl6.grouping, '0') AS grouping
FROM    renewal_vehicle_overall_details vod
LEFT JOIN 
    (
        SELECT  operator_code, 
                ( CASE WHEN app_usage_percent = 0 THEN 'exact zero'
                    WHEN app_usage_percent > 0 AND app_usage_percent <= 20 THEN '0-20' 
                    WHEN app_usage_percent > 20 AND app_usage_percent <= 40 THEN '20-40'
                    WHEN app_usage_percent > 40 AND app_usage_percent <= 60 THEN '40-60'
                    WHEN app_usage_percent > 60 AND app_usage_percent <= 80 THEN '60-80' 
                WHEN app_usage_percent > 80 AND app_usage_percent <= 100 THEN '80-100' END) AS grouping
        FROM
        (
        SELECT operator_code, (((1.00 * COUNT(data_date))/30) * 100) AS app_usage_percent
        FROM
            (
            SELECT operator_code, renewal_date_fixed, data_date, max_session_duration
            FROM
                (
					SELECT tbl1.operator_code,
							tbl1.renewal_date_fixed,
							tbl2.data_date,
							tbl2.max_session_duration
					FROM
							(
								SELECT operator_code, MIN(renewal_date) AS renewal_date_fixed
								FROM renewal_vehicle_overall_details 
								WHERE date(renewal_date) >= '2021-06-01' AND date(renewal_date) <= '2021-06-30'
								GROUP BY operator_code
							) AS tbl1
							LEFT JOIN 
							( 
								SELECT operator_code, data_date, max_session_duration 
								FROM operator_app_data
								WHERE max_session_duration > (0.0833333333)
							) AS tbl2
							ON tbl1.operator_code = tbl2.operator_code
							order BY 1, 3
                ) AS tbl3
            WHERE (date(renewal_date_fixed) - date(data_date) > 0) AND (date(renewal_date_fixed) - date(data_date) < 31)
            ) AS tbl4
    GROUP BY operator_code ) AS tbl5

    ) AS tbl6
ON vod.operator_code = tbl6.operator_code
