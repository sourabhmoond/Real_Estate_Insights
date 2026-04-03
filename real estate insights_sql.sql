create database capstone1;
use capstone1;

alter table fact_properties modify Listing_Date date;
describe fact_properties;

-- 1. Find the average price per square feet?
select sum(Price_INR)/sum(Built_up_Area_SqFt) from fact_properties;

-- 2. Find the maximum average price per sq. ft. among properties?
select max(Price_per_sq_ft) from 
(select Price_INR/Built_up_Area_SqFt as Price_per_sq_ft from Fact_Properties) dt;

-- 3. Find the minimum average price per sq. ft. among properties?
select min(Price_per_sq_ft) from 
(select Price_INR/Built_up_Area_SqFt as Price_per_sq_ft from Fact_Properties) dt;

-- 4 Find the average month to sale among properties?
select avg(Months) from 
(select datediff(now(),Listing_date)/30 as Months from Fact_Properties) dt;

-- 5 Find the month and year wise sum of average Price per sq. ft. ?
describe market_trends;

update market_trends set month_year = rpad(month_year,10,'-01');
alter table market_trends modify month_year date;

select year(month_year) yr, month(month_year) mon, sum(avg_price_per_sqft) from market_trends
group by yr, mon
order by yr, mon;

-- 6 Find the month and year wise sum of Demand_Index ?
select year(month_year) yr, month(month_year) mon, sum(Demand_Index) from market_trends
group by yr, mon
order by yr, mon;

-- 7 Find the average Price per sq. ft. by Transaction_type ?
select Transaction_Type, avg(Price_per_sq_ft) from 
(select Price_INR/Built_up_Area_SqFt as Price_per_sq_ft, Transaction_Type from Fact_Properties) dt
group by Transaction_Type;

-- 8 Find the average Price per sq. ft. in tier 1 cities?
select avg(Price_per_sq_ft) from 
(select (Price_INR)/(Built_up_Area_SqFt) as Price_per_sq_ft, city from Fact_Properties) f
where city in (select city from Location_Master where tier = 'tier 1');

-- 9 Find the average Price per sq. ft. in tier 2 cities?
select avg(Price_per_sq_ft) from 
(select (Price_INR)/(Built_up_Area_SqFt) as Price_per_sq_ft, city from Fact_Properties) f
where city in (select city from Location_Master where tier = 'tier 2');

-- 10 Find the average crime rate in tier 1 city?
select avg(crime_rate) from location_master
where tier = "tier 1";

-- 11 Find the average crime rate in tier 2 city?
select avg(crime_rate) from location_master
where tier = "tier 2";

-- 12 Find the average price per sq. ft. of city those have gym amenities?
alter table amenities rename column Property_ID to P_ID;
describe amenities;

select sum(Price_INR)/sum(Built_up_Area_SqFt) from
(select f.*, a.* from fact_properties f join amenities a on f.property_ID = a.P_ID
where a.has_gym =1) d;

-- 13 Find the average price per sq. ft. of city without amenities?
select sum(Price_INR)/sum(Built_up_Area_SqFt) from
(select f.*, a.* from fact_properties f join amenities a on f.property_ID = a.P_ID
where a.has_gym =0 and a.has_swimming_pool =0 and a.has_parking =0 and a.has_security =0 and a.has_power_backup =0) d;

-- 14 Find the average price per sq. ft. of city those have parking amenities?
select sum(Price_INR)/sum(Built_up_Area_SqFt) from
(select f.*, a.* from fact_properties f join amenities a on f.property_ID = a.P_ID
where a.has_parking =1) d;

-- 15 Find the average price per sq. ft. of city those have security amenities?
select sum(Price_INR)/sum(Built_up_Area_SqFt) from
(select f.*, a.* from fact_properties f join amenities a on f.property_ID = a.P_ID
where a.has_security =1) d;

-- 16 Calculate the month-on-month percentage growth in the Demand_Index for the city of 'Mumbai'.
select City,month_year,demand_index,prev_index,ifnull(round(((demand_index-prev_index)/prev_index)*100,2),0) as `MOM%` from
(select *, lag(demand_index,1,0) over (partition by city) as prev_index from market_trends
where city ='mumbai') dt;

-- 17 List the Top 5 cities where the average price per sq. ft. is higher than the overall market price per sq. ft..
select city, Price_per_sq_ft from
(select city, sum(Price_INR)/sum(Built_up_Area_SqFt) as Price_per_sq_ft from Fact_Properties
group by city order by Price_per_sq_ft) dt
where Price_per_sq_ft > (select sum(Price_INR)/sum(Built_up_Area_SqFt) from Fact_properties) limit 5;

-- 18 Identify properties ID whose price per sq. ft. is 20% higher than the average price per sq. ft.
--     for their specific BHK type in the same city.
select Property_ID from fact_properties f,(select city, BHK, sum(Price_INR)/sum(Built_up_Area_SqFt) as avg_price_per_sq_ft 
from fact_properties group by city, BHK) dt where
f.city=dt.city and f.BHK = dt.BHK 
and (f.Price_INR)/(f.Built_up_Area_SqFt) > dt.avg_price_per_sq_ft + (dt.avg_price_per_sq_ft)/5;