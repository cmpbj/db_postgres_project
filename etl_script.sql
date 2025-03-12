--- Project 01

-- 01. Materialized View

create materialized view if not exists bi_analytics_aggregate_sales as
with
	order_details as (
		select *
		from northwind.public.order_details
	)

	, orders as (
		select *
		from northwind.public.orders
	)

	, aggregation as (
		select
			extract(year from orders.order_date) as year
			, extract(month from orders.order_date) as month
			, sum((order_details.unit_price * order_details.quantity) * (1-order_details.discount)) as accumulated_sales
		from order_details
		inner join orders
			on order_details.order_id = orders.order_id
		group by
			extract(year from orders.order_date)
			, extract(month from orders.order_date)
		order by
			extract(year from orders.order_date)
			, extract(month from orders.order_date)
	)

select *
from aggregation;

-- function

create or replace function func_refresh_sales_accumulated_monthly_mv()
returns trigger as $$
begin
	refresh materialized view northwind.public.bi_analytics_aggregate_sales;
	return null;
end;
$$ language plpgsql;


-- Triggers

create trigger trg_refresh_sales_accumulated_monthly_mv_order_details
after insert or update or delete on northwind.public.order_details
for each statement
execute function func_refresh_sales_accumulated_monthly_mv();


create trigger trg_refresh_sales_accumulated_monthly_mv_orders
after insert or update or delete on northwind.public.orders
for each statement
execute function func_refresh_sales_accumulated_monthly_mv();


-- testing the triggers

INSERT INTO orders VALUES (10808, 'OLDWO', 2, '1998-01-01', '1998-01-29', '1998-01-09', 3, 45.5299988, 'Old World Delicatessen', '2743 Bering St.', 'Anchorage', 'AK', '99508', 'USA');
INSERT INTO order_details VALUES (10808, 56, 38, 20, 0.150000006);

select * from northwind.public.bi_analytics_aggregate_sales;


--- Project 02

-- Create a snapshot for employee table
create table northwind.public.snapshot_employees as
select * from northwind.public.employees;

-- Create validation columns
alter table northwind.public.snapshot_employees
add column valid_from timestamp with time zone DEFAULT now(),
add column valid_to timestamp,
alter column valid_to set DEFAULT null;

-- Create function

CREATE OR REPLACE FUNCTION func_snapshot()
RETURNS TRIGGER 
LANGUAGE plpgsql 
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO northwind.public.snapshot_employees (
            employee_id, last_name, first_name, title, title_of_courtesy, birth_date, 
            hire_date, address, city, region, postal_code, country, home_phone, 
            extension, photo, notes, reports_to, photo_path, valid_from, valid_to
        )
        VALUES (
            NEW.employee_id, NEW.last_name, NEW.first_name, NEW.title, NEW.title_of_courtesy, NEW.birth_date, 
            NEW.hire_date, NEW.address, NEW.city, NEW.region, NEW.postal_code, NEW.country, NEW.home_phone, 
            NEW.extension, NEW.photo, NEW.notes, NEW.reports_to, NEW.photo_path, NOW(), NULL
        );
    
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE northwind.public.snapshot_employees
        SET valid_to = NOW()
        WHERE employee_id = OLD.employee_id AND valid_to IS NULL;
    
    ELSIF TG_OP = 'UPDATE' THEN

        UPDATE northwind.public.snapshot_employees
        SET valid_to = NOW()
        WHERE employee_id = OLD.employee_id
          AND valid_to IS NULL;

   
        INSERT INTO northwind.public.snapshot_employees (
            employee_id, last_name, first_name, title, title_of_courtesy, birth_date, 
            hire_date, address, city, region, postal_code, country, home_phone, 
            extension, photo, notes, reports_to, photo_path, valid_from, valid_to
        )
        VALUES (
            NEW.employee_id, NEW.last_name, NEW.first_name, NEW.title, NEW.title_of_courtesy, NEW.birth_date, 
            NEW.hire_date, NEW.address, NEW.city, NEW.region, NEW.postal_code, NEW.country, NEW.home_phone, 
            NEW.extension, NEW.photo, NEW.notes, NEW.reports_to, NEW.photo_path, NOW(), NULL
        );
    END IF;

    RETURN NULL;
END;
$$;


-- create trigger
CREATE TRIGGER trg_emp_table_modification
after update or insert or delete on northwind.public.employees
for each row
execute function func_snapshot();

-- Test function

INSERT INTO northwind.public.employees (
    employee_id, last_name, first_name, title, title_of_courtesy, birth_date, 
    hire_date, address, city, region, postal_code, country, home_phone, 
    extension, photo, notes, reports_to, photo_path
) VALUES (
    9999, 'Johnson', 'Alice', 'Data Engineer', 'Ms.', '1990-05-15', 
    '2025-03-11', '123 Main St', 'Seattle', 'WA', '98101', 'USA', 
    '555-1234', '101', NULL, 'New employee in the Data team', 3, NULL
);

DELETE FROM northwind.public.employees WHERE employee_id = 9999;

UPDATE northwind.public.employees 
SET title = 'Senior Data Engineer' 
WHERE employee_id = 5;


-- create a procedure to update employee title

create or replace procedure update_employee_title(
	p_employee_id int,
	p_new_title varchar(100)
)
as $$
begin
	UPDATE northwind.public.employees 
	SET title = p_new_title
	WHERE employee_id = p_employee_id;
end;
$$ language plpgsql;


CALL update_employee_title(1, 'Estagiario');