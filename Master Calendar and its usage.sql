create database casestudy3

select * from dbo.t_drivers
select * from dbo.t_employee
select * from dbo.t_performanceheader
select * from dbo.t_performanceline
select * from dbo.t_questions

create table Calendar
(
Date_ date,
Weekno int,
WeekName varchar(10),
weekstartdate date,
weekenddate date,
month_ int,
Monthstartdate date,
monthenddate date,
quarter_ int,
quarterstartdate date,
quarterenddate date,
year_ int 
)
alter table calendar
alter column month_ date
drop table calendar
------for entering date
DECLARE @start_date date = '2015-08-31'

Declare @end_date date = '2024-12-31'

WHILE ( @start_date <= @end_date)
BEGIN
    insert into Calendar ([date_])
    values (@start_date)
    SET @start_date  = Dateadd(day, 1, @start_date) 
END

select * from Calendar

----For weekno
alter table calendar 
add sno int identity(0,1)



update calendar
set weekno=((sno/7)+1)

alter table calendar
drop column sno

---for weekstartdate

UPDATE Calendar
SET WeekStartDate = DATEADD(dd, - (datepart(dw, DATE_))+2, date_)

update calendar
set weekstartdate=dateadd(dd,-(datepart(dw,DATE_)+5),date_) where datepart(weekday,date_)=1

select * from calendar

--for weekenddate
update calendar 
set weekenddate=dateadd(dd,8-(datepart(dw,date_)),date_)

update calendar
set weekenddate=date_ where datepart(weekday,date_)=1

select * from calendar


--adding weekname
update calendar
set weekname = concat(day(weekstartdate),cast(datename(m,weekstartdate) as char(3)),
'--to--',day(weekenddate),cast(datename(m,weekenddate) as char(3))
)
alter table calendar
alter column weekname varchar(max)

--adding month
alter table calendar 
add month_ date

update calendar
set month_=(eomonth(date_))
select * from calendar

-- for month start date
update calendar
set monthstartdate=concat(year(date_),'-',month(date_),'-','01')

--for month end date
update calendar
set monthenddate=(eomonth(date_))
select * from calendar

--quarter
--Quarter starting from 1 June

update calendar
set quarter_=case
when month(date_)>=6 and month(date_)<=8 
then 'Q1'
when month(date_)>=9 and month(date_)<=11 
then 'Q2'
when month(date_)=12 or month(date_)<=2  
then 'Q3'
else 'Q4'
end;

alter table calendar
alter column quarter_ varchar(max)

--quarterstartdate

UPDATE Calendar
SET  QuarterStartDate=dateadd(m,-1,(DATEADD(q, DATEdiff(q, 0, DATE_), 0)))

--quarterenddate
UPDATE Calendar
SET QuarterEndDate = eomonth(dateadd(m,-1,DATEADD(d, - 1, DATEADD(q, DATEDIFF(q, 0, DATE_) + 1, 0))))

select * from calendar
--year
alter table calendar
alter column year_ varchar(max)

alter table calendar
alter column monthenddate varchar(max)
update calendar
set year_ = 
CASE 
WHEN MONTH(MONTH_)<=5

THEN CONCAT('FY',CAST(SUBSTRING(monthstartdate,3,2) AS int)-1,'-',CAST(SUBSTRING([monthstartdate],3,2) AS int) )

WHEN MONTH(MONTH_)>5

THEN CONCAT('FY',CAST(SUBSTRING([monthstartdate],3,2) AS int),'-',CAST(SUBSTRING([monthstartdate],3,2) AS int )+1 )
eND


select * from calendar
--select * from t_drivers
--select * from t_employee
select * from t_performanceheader
--select * from t_performanceline
--select * from t_questions


-- 2
select avg(cast(userscore as float)) avg_userscore,
avg(cast(managerscore as float)) avg_managerscore,
avg(cast(TotalScore as float)) avg_totalscore from dbo.t_performanceheader
where weekname = (
select weekname from dbo.t_performanceheader where (cast(headerid as int)) = 
(select max(cast(headerid as int)) from dbo.t_performanceheader ))


select avg(cast(userscore as float)) avg_userscore,
avg(cast(managerscore as float)) avg_managerscore,
avg(cast(TotalScore as float)) avg_totalscore from dbo.t_performanceheader
where weekname = 

(select max(ph.weekname) from calendar c inner join t_performanceheader ph on c.date_=ph.Submitteddate )



-----3-------


select * from calendar
select * from t_performanceheader

select count(employeeid) from t_performanceheader

where weekname = 
(select max(ph.weekname) weekn_ from calendar c 
inner join t_performanceheader ph on c.date_=ph.Submitteddate ) 
and  cast(totalscore as float)=22 or 
cast(TotalScore as float)=0

select count(employeeid) from t_performanceheader where 
cast(totalscore as float)=22 or cast(TotalScore as float)=0


SELECT count(P1.Employeeid) [EmployeeCount] 
,Max(c1.weekno) [Week No] 
FROM t_performanceheader P1 
INNER JOIN Calendar C1 ON C1.[Date_] = convert(DATE, P1.Submitteddate) 
WHERE( convert(float,P1.TotalScore) = 22.0
OR convert(float,P1.TotalScore) = 0) 
AND WeekNo = (SELECT max(weekno) 
FROM t_performanceheader P1 
INNER JOIN calendar C1 ON C1.DATE_ = convert(date, P1.Submitteddate)) 
GROUP BY P1.TotalScore

----4----

select distinct tt.lob,tt.weekno,tt.userscore,count(tt.Employeeid) 
over(partition by tt.weekno,tt.lob,tt.userscore) [No. of employee] from 
(
select  e.LOB,c.weekno,ph.Employeeid,cast(ph.Userscore as float) Userscore from
calendar c 
inner join t_performanceheader ph on C.DATE_ = Ph.Submitteddate
inner join t_employee e on e.employeeid=ph.employeeid
where cast(ph.TotalScore as float)=22 or cast(ph.totalscore as float)=0
) tt order by tt.weekno,tt.LOB,tt.Userscore


---5---

select tt.lob,tt.weekno,avg(cast(tt.userscore as float)) avg_userscore,
avg(cast(tt.managerscore as float)) avg_managerscore,
avg(cast(tt.TotalScore as float)) avg_totalscore from
(select e.lob,c.weekno,ph.userscore,ph.managerscore,ph.TotalScore from
calendar c 
inner join t_performanceheader ph on c.date_=ph.submitteddate
inner join t_employee e on e.employeeid=ph.employeeid ) tt group by tt.lob, tt.weekno

--6--
select tt.* from 
(select c.weekno,ph.isDefaulter,count(ph.isdefaulter) [no. of defaulter] from
calendar c 
inner join t_performanceheader ph on c.date_=ph.submitteddate
group by c.weekno,ph.isDefaulter)tt where tt.isDefaulter=0 

--7--
select * from calendar
--select * from t_drivers
select * from t_employee
select * from t_performanceheader
--select * from t_performanceline
--select * from t_questions


select a.LOB,a.weekno,round((sum(cast(a.isdefaulter as float))/
count(a.employeeid))*100,2) compilance_percent from 

(select  ph.employeeid, c.weekno, c.weekname,e.lob,
ph.isDefaulter
from
t_performanceheader ph 
inner join t_employee e on  e.employeeid=ph.employeeid
inner join calendar c on c.date_=ph.submitteddate
) a group by a.LOB,a.weekno 


--8--

select * from calendar
--select * from t_drivers
select * from t_employee
select * from t_performanceheader
select * from t_performanceline
--select * from t_questions

update t_performanceheader
set mgrdefaulter=isnull(mgrdefaulter,0)

select a.LOB,a.weekno,round((sum(cast(a.mgrDefaulter as float))/
count(a.mgrDefaulter))*100,2) compilance_percent_manager
from 

(select c.weekno, c.weekname,e.lob,
ph.mgrDefaulter
from
t_performanceheader ph 
inner join t_employee e on  e.employeeid=ph.employeeid
inner join calendar c on c.date_=ph.submitteddate
) a group by a.LOB,a.weekno 


--9--
select * from t_drivers
select * from t_performanceheader
select * from t_performanceline
select * from t_questions
select * from t_employee

select tt.weekno,tt.lob,tt.driverid,avg(cast(tt.userscore as int)) avg_key from
(
select ds.driverid,e.lob,c.weekno,ph.userscore from

t_questions qs 
inner join t_drivers ds on qs.driverid=ds.driverid 
inner join (select headerid,questionid,userresponse 
from t_performanceline) pl on pl.questionid=qs.questionid
inner join t_performanceheader ph on ph.headerid=pl.headerid
inner join t_employee e on e.employeeid=ph.employeeid
inner join calendar c on c.date_=ph.submitteddate
where pl.Userresponse=1  
) tt
group by
tt.weekno,tt.lob,tt.driverid

union

--10--

select * from calendar
select * from t_drivers
select * from t_employee
select * from t_performanceheader
select * from t_performanceline
select * from t_questions

update t_performanceline
set Skiplevelresponse=isnull(skiplevelresponse,0)


select count(case tt.coc 
when 0 
then 1 
else null 
end),  CASE 
        WHEN convert(INT, tt.Userscore) > 18
            THEN 'gold'
        WHEN convert(INT, tt.Userscore) > 11
            AND convert(INT, tt.Userscore) < 17
            THEN 'silver'
        WHEN convert(INT, tt.Userscore) < 11
            THEN 'bronze'
        ELSE 'NO SCORE GIVEN'
        END AS [Grade of Employee], tt.employeecode,tt.name,tt.managercode,
tt.managername,tt.grade,tt.employementtype,tt.designation,
tt.region,tt.isdefaulter,tt.mgrdefaulter,tt.totalscore, tt.userscore,tt.avg_self ,tt.avg_mgr ,tt.avg_skip
from
(select avg_table.Questionid,
c.quarter_,e.Employeeid, e.name,e.managercode,
e.managername,e.grade,e.employementtype,e.designation,
e.region,ph.isdefaulter, ph.mgrdefaulter,ph.totalscore as float,
avg_table.avg_self ,avg_table.avg_mgr ,avg_table.avg_skip,ph.Userscore,
ph.TotalScore,e.Employeecode,ph.COC


from

t_employee e
inner join t_performanceheader ph on e.Employeeid=ph.employeeid 
inner join calendar c on ph.submitteddate=c.date_
inner join (select questionid,headerid, round(avg(cast(Userresponse as float)),2) avg_self
, round(avg(cast(Managerresponse as float)),2) avg_mgr
, round(avg(cast(Skiplevelresponse as float)),2) avg_skip from t_performanceline
group by questionid,headerid) avg_table on avg_table.Headerid=ph.Headerid
group by avg_table.Questionid,
c.quarter_,e.Employeeid, e.name,e.managercode,
e.managername,e.grade,e.employementtype,e.designation,
e.region,ph.isDefaulter,ph.mgrDefaulter,ph.TotalScore,ph.Userscore,
avg_table.avg_self,avg_table.avg_mgr ,avg_table.avg_skip,ph.Userscore,
ph.TotalScore,e.Employeecode,ph.COC
)tt

select * from t_employee

inner join t_performanceline pl on ph.headerid=pl.Headerid 
select * from calendar




(select questionid,headerid, round(avg(cast(Userresponse as float)),2) avg_self
, round(avg(cast(Managerresponse as float)),2) avg_mgr
, round(avg(cast(Skiplevelresponse as float)),2) avg_skip from t_performanceline
group by questionid,headerid) avg_table




--11--
SELECT CASE 
		WHEN company = 'services'
			AND lob = 'GTM'
			AND Bussinessunit = 'sbo'
			THEN 'sbo'
		WHEN company = 'services'
			AND lob = 'bsg-support'
			AND Bussinessunit = 'bsg'
			THEN 'services(ets)'
		WHEN company = 'services'
			AND lob = 'cloud services'
			AND (
				Bussinessunit = 'bsg'
				OR Bussinessunit = 'delivery-sdm'
				OR Bussinessunit = 'delivery'
				)
			THEN 'services(ets)'
		WHEN company = 'services'
			AND lob = 'EAS'
			AND (
				Bussinessunit = 'bgs'
				OR Bussinessunit = 'delivery'
				)
			THEN 'services(ets)'
		WHEN company = 'services'
			AND lob = 'EAS'
			AND Bussinessunit = 'corporate planning and strategy'
			THEN 'startegy and planning, corp comunication'
		WHEN company = 'services'
			AND lob = 'GTM'
			AND Bussinessunit = 'bfsi'
			THEN 'bfsi'
		WHEN lob = 'administration'
			THEN 'administration'
		WHEN lob = 'finance'
			OR lob = 'finac'
			OR lob = 'audit'
			OR lob = 'legal'
			THEN 'administration'
		WHEN lob = 'human resource'
			OR lob = 'hr'
			THEN 'human resource'
		WHEN Company = 'CARE'
			THEN 'care'
		WHEN Company = 'learning'
			THEN 'learning'
		WHEN Company = 'consumer distribution'
			THEN 'consumer distribution'
		WHEN company = 'fi'
			THEN 'finanacial inclusion'
		ELSE Company
		END AS final_lob
	,lob
	,employeeid
FROM t_employee
 

--------------------------12------------------------------
select * from t_employee
select * from t_performanceheader


select distinct tt.managercode,round(avg(cast(tt.userscore as float)),2) avg_userscore,
round(avg(cast(tt.managerscore as float)),2) avg_managerscore 
from
(
select e.*,ph.userscore,ph.managerscore
from t_performanceheader ph inner join
(select distinct e1.employeeid,e1.Name,e1.managercode,e2.Managername from t_employee e1
inner join t_employee e2 on e1.Managercode=e2.Managercode  ) e on e.Employeeid=ph.Employeeid
) tt group by tt.managercode

-----------------13----------------

select Region, Managercode ,Managername,
CASE
WHEN CONVERT(FLOAT,p.managerscore)=0
THEN NULL
WHEN CONVERT(FLOAT,p.managerscore)>0
THEN convert(float,Managerscore)/sum(convert(float,Managerscore))
END as REVIEWcomp,
CASE 
WHEN CONVERT(FLOAT,p.Userscore)=0
THEN NULL
WHEN CONVERT(FLOAT,p.Userscore)>0
THEN convert(float,Userscore)/sum(convert(float,Userscore))
END as USERcomp
from t_performanceheader p
inner join t_employee e
on p.Employeeid=e.Employeeid
group by Region, Managercode ,Managername,Managerscore,Userscore


---------------------14-------------------
select * from t_employee
select e.employeecode,e.name,
e.company,e.lob,e.Bussinessunit,
e.grade,e.managercode,e.managername,e.designation,tt.self_def_count,tt.mgr_def_count,tt.cumulativescore,tt.coc_def_count 
from t_employee e
inner join 
(select ph.employeeid ,
sum(case
when ph.isdefaulter='0' then 1
else 0
end) as self_def_count,
sum(case
when ph.mgrdefaulter='0' then 1
else 0
end) as mgr_def_count,
sum(cast(ph.totalscore as float)) cumulativescore,
sum(case
when ph.coc='0' then 1 else 0 end) as coc_def_count 
from t_performanceheader ph 
group by ph.Employeeid ) tt on tt.Employeeid=e.Employeeid


select * from t_performanceheader
--------------------------15--------------------------
select * from t_employee
select * from calendar

select * from t_performanceheader

select c.weekno, count(e.employeeid) [Employee under p9]
from
t_employee e
inner join t_performanceheader ph on ph.Employeeid=e.employeeid 
inner join calendar c on ph.submitteddate=c.date_
where e.grade='P9' group by c.weekno 

