SELECT status, COUNT(*) AS order_count
FROM raw_orders
GROUP BY status
ORDER BY 2 DESC, 1