create database databank;


--How many unique nodes are there on the Data Bank system?   

SELECT sum(t.unique_nodes) total_nodes 

FROM ( 

SELECT n.region_id 

,r.region_name 

,count(DISTINCT n.node_id) unique_nodes 

FROM dbo.customer_nodes n 

INNER JOIN dbo.regions r ON r.region_id = n.region_id 

GROUP BY n.region_id 

,r.region_name 

) t 

 
 

--What is the number of nodes per region? 

SELECT n.region_id 

,r.region_name 

,count(DISTINCT n.node_id) unique_nodes 

FROM dbo.customer_nodes n 

INNER JOIN dbo.regions r ON r.region_id = n.region_id 

GROUP BY n.region_id 

,r.region_name 

ORDER BY n.region_id 

 
 

--How many customers are allocated to each region?  

SELECT region_id 

,count(DISTINCT customer_id) customer_base 

FROM dbo.customer_nodes 

GROUP BY region_id 

ORDER BY region_id 

 
 

---What is the unique count and total amount for each transaction type?  

SELECT TXN_TYPE 

,COUNT(TXN_TYPE) UNIQ_COUNT 

,SUM(TXN_AMOUNT) TOTAL_AMOUNT 

FROM DBO.CUSTOMER_TRANSACTIONS 

GROUP BY TXN_TYPE 

 
 

 –For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?  

WITH cte 

AS ( 

SELECT customer_id 

,datepart(month, txn_date) AS month_ 

,Sum(CASE  

WHEN txn_type = 'deposit' 

THEN 1 

ELSE 0 

END) AS DepositCount 

,sum(CASE  

WHEN txn_type = 'purchase' 

THEN 1 

ELSE 0 

END) AS PurchaseCount 

,sum(CASE  

WHEN txn_type = 'withdrawal' 

THEN 1 

ELSE 0 

END) AS WithdrawalCount 

FROM customer_transactions 

GROUP BY customer_id 

,datepart(month, txn_date) 

) 

SELECT month_ 

,COUNT(DISTINCT customer_id) AS CustomerCount 

FROM cte 

WHERE depositcount > 1 

AND ( 

purchasecount = 1 

OR withdrawalcount = 1 

) 

GROUP BY MONTH_ 

ORDER BY month_ 

 
 
 

--What is the average total historical deposit counts and amounts for all customers?  

SELECT avg(t1.count_Dep) avg_deposits 

,avg(t1.sum_dep) avg_amounts 

FROM ( 

SELECT t.customer_id 

,count(t.txn_amount) count_dep 

,sum(t.txn_amount) sum_Dep 

FROM ( 

SELECT customer_id 

,txn_type 

,txn_amount 

FROM dbo.customer_transactions 

WHERE txn_type = 'deposit' 

) t 

GROUP BY t.customer_id 

) t1 

 
 
 

--What is the closing balance for each customer at the end of the month? Also show the change in balance each month in the same table output.  

SELECT t.customer_id 

,datepart(month, t.txn_date) month_ 

,sum(t.bal) closing_balance 

FROM ( 

SELECT customer_id 

,txn_date 

,txn_type 

,CASE  

WHEN txn_type = 'deposit' 

THEN txn_amount * (1) 

WHEN txn_type = 'withdrawal' 

THEN txn_amount * (- 1) 

WHEN txn_type = 'purchase' 

THEN txn_amount * (- 1) 

END AS bal 

FROM dbo.customer_transactions 

) t 

GROUP BY t.customer_id 

,datepart(month, t.txn_date) 

ORDER BY t.customer_id 

 
 
 

–For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?  

WITH cte 

AS ( 

SELECT customer_id 

,datepart(month, txn_date) AS month_ 

,Sum(CASE  

WHEN txn_type = 'deposit' 

THEN 1 

ELSE 0 

END) AS DepositCount 

,sum(CASE  

WHEN txn_type = 'purchase' 

THEN 1 

ELSE 0 

END) AS PurchaseCount 

,sum(CASE  

WHEN txn_type = 'withdrawal' 

THEN 1 

ELSE 0 

END) AS WithdrawalCount 

FROM customer_transactions 

GROUP BY customer_id 

,datepart(month, txn_date) 

) 

SELECT month_ 

,COUNT(DISTINCT customer_id) AS CustomerCount 

FROM cte 

WHERE depositcount > 1 

AND ( 

purchasecount = 1 

OR withdrawalcount = 1 

) 

GROUP BY MONTH_ 

ORDER BY month_ 

---What percentage of customers have a positive first month balance?  

WITH monthly_balance 

AS ( 

SELECT customer_id 

,SUM(CASE  

WHEN txn_type = 'withdrawal' 

OR txn_type = 'purchase' 

THEN (- txn_amount) 

ELSE txn_amount 

END) AS transaction_balance 

FROM customer_transactions 

WHERE datepart(mm, txn_date) = '01' 

GROUP BY customer_id 

) 

SELECT 100 * (cast(A.positivebal AS FLOAT) / cast(A.customers_ AS FLOAT)) AS Percentage_ 

FROM ( 

SELECT count(customer_id) AS customers_ 

,sum(CASE  

WHEN transaction_balance >= 0 

THEN 1 

ELSE 0 

END) AS positivebal 

FROM monthly_balance 

) A 

 
 
 