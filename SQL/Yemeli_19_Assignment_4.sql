/*
    Name: Patrick R. Yemeli
    DTSC660: Data and Database Managment with SQL
    Module 5
    Assignment 4
*/

--------------------------------------------------------------------------------
/*				                 Banking DDL           		  		          */
--------------------------------------------------------------------------------

CREATE TABLE branch (branch_name VARCHAR(40),
					 branch_city VARCHAR(15),
					 assets NUMERIC(20,1) CHECK (assets > 0),
					 CONSTRAINT branch_pkey PRIMARY KEY (branch_name)
);
  
CREATE TABLE customer (cust_ID VARCHAR(15),
					   customer_name VARCHAR(30) NOT NULL,
					   customer_street VARCHAR(40),
					   customer_city VARCHAR(15),
					   CONSTRAINT customer_pkey PRIMARY KEY (cust_ID)
);
  
CREATE TABLE loan (loan_number VARCHAR(20) unique,
				   branch_name VARCHAR(40),
				   amount NUMERIC(20,1),
				   CONSTRAINT loan_pkey PRIMARY KEY (loan_number,branch_name),
				   CONSTRAINT loan_fkey FOREIGN KEY (branch_name) REFERENCES branch (branch_name)
				   ON DELETE SET NULL
				   ON UPDATE CASCADE				 
);
--delete null cus if cancel loan all value set to null
--update cascade cus if update loan then all value update

CREATE TABLE borrower (cust_ID VARCHAR(15),
					   loan_number VARCHAR(20),
					   CONSTRAINT borrower_pkey PRIMARY KEY (cust_ID, loan_number),
					   CONSTRAINT borrower_1_fkey FOREIGN KEY (cust_ID) REFERENCES customer (cust_ID)
					   ON DELETE CASCADE
					   ON UPDATE CASCADE,
					   CONSTRAINT borrower_2_fkey FOREIGN KEY (loan_number) REFERENCES loan (loan_number)
					   ON DELETE CASCADE
					   ON UPDATE CASCADE
);
 --here in borrower if delet all nee to be delete cus is the main agent 
 --and if update everything update
 
CREATE TABLE account (account_number VARCHAR(20),
					  branch_name VARCHAR(40),
					  balance NUMERIC(20,1) DEFAULT 0.0,
					  CONSTRAINT account_pkey PRIMARY KEY (account_number),
					  CONSTRAINT account_fkey FOREIGN KEY (branch_name) REFERENCES branch (branch_name)
					  ON DELETE SET NULL
					  ON UPDATE CASCADE
);

--here it say to not introduce a FKEY in account_number
CREATE TABLE depositor (cust_ID VARCHAR(15),
						account_number VARCHAR(20),
						CONSTRAINT depositor_pkey PRIMARY KEY (cust_ID, account_number),						
						CONSTRAINT depositor_fkey FOREIGN KEY (cust_ID) REFERENCES customer (cust_ID)
						ON UPDATE CASCADE
);

---the value for fill this table come from another file


--------------------------------------------------------------------------------
/*				                  Question 1           		  		          */
--------------------------------------------------------------------------------
--always folow this path to make function

CREATE OR REPLACE FUNCTION Yemeli_19_monthlyPayment(P_Morgage NUMERIC(20,2),APR NUMERIC(6,6),years INTEGER)
RETURNS NUMERIC(20,2) --format of the answer i want
LANGUAGE PLPGSQL     --the coding language i am using
AS
$$
	DECLARE --here I declare the input base on formula given
	A_Monthly_Pmt_Amt NUMERIC(11,6);   
	i_Monthly_Intrest_Rate NUMERIC(15,6);
	n_Num_Pmts INTEGER;   
	BEGIN --here I put the formula
	i_Monthly_Intrest_Rate := apr / 12;
	n_Num_Pmts := years * 12;
	A_Monthly_Pmt_Amt := ROUND ( (P_Morgage * (i_Monthly_Intrest_Rate +(i_Monthly_Intrest_Rate / (((1 + i_Monthly_Intrest_Rate)^n_Num_Pmts) - 1)))), 2);
	
	RETURN A_Monthly_Pmt_Amt; --here we give thr answer
	END;
$$;

--pass the years=30, the intrest=0.04125,  morgage value=250000.00

select Yemeli_19_monthlyPayment(250000.00, 0.04125, 30)

--drop function Yemeli_19_monthlyPayment


--------------------------------------------------------------------------------
/*				                  Question 2           		  		          */
--------------------------------------------------------------------------------

    ------------------------------- Part (a) ------------------------------
    SELECT cus.cust_ID , cus.customer_name
		FROM customer AS cus LEFT OUTER JOIN borrower bor ON cus.cust_ID=bor.cust_ID
			Left JOIN loan loa ON bor.loan_number=loa.loan_number
		WHERE cus.cust_ID NOT IN (SELECT account_number FROM account) ;
								
								
	
	
	INSERT INTO customer (cust_ID, customer_name, customer_street, customer_city)
VALUES ('191919', 'Patrick Yemel', '2 Ford Drive', 'Harrison');

-- Insert Values into loan

INSERT INTO loan (loan_number, branch_name, amount)
VALUES ('462819195', 'Brooklyn Bridge Bank', '7500.00');



    ------------------------------- Part (b) ------------------------------
   SELECT c.cust_ID , cu.customer_name
   	FROM customer AS c
	INNER JOIN customer AS cu ON c.cust_ID= cu.cust_ID
	AND c.customer_street = cu.customer_street
	AND c.customer_city =cu.customer_city
	WHERE c.customer_city LIKE (SELECT customer_city FROM customer WHERE cust_ID = '12345');   


    ------------------------------- Part (c) ------------------------------
   SELECT br.branch_name
   FROM customer cu  LEFT JOIN depositor d ON cu.cust_ID = d.cust_ID 
   LEFT JOIN account a ON a.account_number = d.account_number 
   LEFT JOIN branch br ON a.branch_name = br.branch_name
   WHERE cu.customer_city LIKE  'Harrison'
   AND  1 >=  (SELECT  COUNT (cust.cust_ID)
					FROM customer AS cust  
					WHERE cust.cust_ID = cu.cust_ID)



    ------------------------------- Part (d) ------------------------------
SELECT*  
	FROM customer c
	LEFT JOIN borrower b ON c.cust_ID = b.cust_ID
	LEFT JOIN loan l ON l.loan_number = b.loan_number
	LEFT JOIN branch br ON l.branch_name=br.branch_name
	WHERE branch_city = 'Brooklyn'

--------------------------------------------------------------------------------
/*				                  Question 3           		  		          */
--------------------------------------------------------------------------------

   CREATE OR REPLACE FUNCTION Yemeli_19_bankTriggerFunction()
   RETURNS TRIGGER
   LANGUAGE PLPGSQL
   AS
   $$
   			BEGIN
--here delete account_number in both depositor and account giving cust_ID
			DELETE FROM account
			WHERE account.cust_ID 
			IN (SELECT acc.ID
			FROM account AS acc
			WHERE acc.account_number = OLD.account_number);
			RETURN OLD;		
			END;			
	$$;
	
	CREATE  TRIGGER Yemeli_19_bankTrigger
	AFTER DELETE ON account
	FOR EACH ROW
	--DELETE FROM depositor
    WHEN (old.cust_ID  LIKE depositor.cust_ID)
		 EXECUTE PROCEDURE Yemeli_19_bankTriggerFunction();								 
	
	
	
	
	
/*	
 CREATE FUNCTION trigger_function_name()
   RETURNS TRIGGER
   LANGUAGE PLPGSQL
   AS
   $$
   			BEGIN
			
			END;
			
	$$;
	

	CREATE [CONSTRAINT] TRIGGER name {before|after|instead of}
	{event [or...]}
			ON table
			[FROM referenced_table_name]
			[NOT DEfERRABLE | [DEFERRABLE]{initially immediate} |initially DEFERRED]
             [FOR [EACH] {ROW|STATeMENT} ]
			 [WHEN (condition)]
			 EXECUTE PROCEDURE function_name (arguments)								 
	INSERT
	UPDATE [OF colum_name [,...]]
	DELETE
	TRUNCATE 
	
	
*/	

--------------------------------------------------------------------------------
/*				                  Question 4           		  		          */
--------------------------------------------------------------------------------
/*A temporary table exist solely for storing data within a session. 
The best time to use temporary tables are when you need to
store information within SQL server for use over a number of SQL transactions. 
Like a normal table, you'll create it, interact with it (insert/update/delete)
and when you are done, you'll drop it
*/

--way of set the syntax for procedure

-- create table instructor_course_nums with attribut ID,name, and tot_courses
 
 CREATE TEMPORARY TABLE instructor_course_nums (
			ID VARCHAR(15),
			name VARCHAR(26),
			tot_courses INTEGER);

--use procedure to calculate the total number of course(tot_course) taught by the instructor			
-- ins_ID is the variable put there to represent instructor ID

CREATE OR REPLACE PROCEDURE Yemeli_19_insCourseNumsProc(
	INOUT ins_ID VARCHAR(15))

LANGUAGE PLPGSQL
AS
$$
			DECLARE d_count INTEGER := 0;
			BEGIN
  --  calculate the total number of course(tot_course=nbr of course_id)
			SELECT COUNT(tea.course_id) INTO d_count
			FROM teaches AS tea INNER JOIN instructor_course_nums AS ins ON tea.ID = ins.ID
			WHERE tea.ID = Yemeli_19_insCourseNumsProc.ins_ID;
  
 -- let find here the intructor name and stor it into ins_name (represent the name of instructor in the instructor table)
			DECLARE ins_name VARCHAR(25) := '';
			SET ins_name = (SELECT ins.name --into ins_name
			FROM instructor_course_nums as ins 
			WHERE instructor_course_nums.ID = Yemeli_19_insCourseNumsProc.ins_ID);
  
		IF NOT EXISTS (SELECT ID
			FROM instructor_course_nums
			WHERE ID = Yemeli_19_insCourseNumsProc.ins_ID)
			
-- if that dont exist we will then update or insert as new parameter 
		THEN
				UPDATE instructor_course_nums
				SET tot_courses = d_count
				WHERE ID = Yemeli_19_insCourseNumsProc.ins_ID;
		--first step fail then put(insert()) entry as new in the table using the parameter labled up
		ELSE 
				INSERT INTO instructor_course_nums (ID, name, tot_courses)
				VALUES (Yemeli_19_insCourseNumsProc.i_ID, ins_name, d_count);
		END IF;
		END;
$$

