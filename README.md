# Library Management SQL Project

## Project Overview

This project is designed to manage and analyze a library’s database using SQL. It covers a range of common database tasks such as querying data, generating reports, managing book rentals, and handling overdue fines. The goal is to demonstrate practical use cases and SQL techniques for managing a library system efficiently.

## Data Preview

The main tables involved in this project include:

- **Books**: Contains details about each book including title, category, rental price, and availability status.
- **Issued Status**: Tracks the issuance of books to members.
- **Members**: Records member information and registration dates.
- **Employees**: Contains employee and branch information.
- **Return Status**: Records the return of issued books.
- **Fines**: Stores fines imposed for overdue books.

## Project Tasks and Features

1. **Filter Books by Category**  
   Retrieve all books in a specific category, such as "History".<br>
  ```sql
  Select * From books
  Where category = 'History';  -- 7 books in category 'History'
  ```
<br>

2. **Calculate Total Rental Income by Category**  
   Aggregate rental income grouped by book categories.<br>
  ```sql
  With rent_income as (
      Select
          b.isbn,
          b.book_title,
          b.category,
          b.rental_price
      From books b
      Join issued_status iss On iss.issued_book_isbn = b.isbn
  )
  Select 
      category,
      sum(rental_price) as total_income,
      count(*) as books_quantity
  From rent_income
  Group By category
  Order By total_income DESC;
  ```
<br>

3. **List Recent Members**  
   Find members who registered within a recent timeframe (e.g., last 180 days).<br>
```sql
Select * 
From members
Where reg_date BETWEEN 
    Date '2021-06-01' 
    AND Date '2021-06-01' + INTERVAL '180 days'
Order By reg_date ASC;
```
<br>

4. **Employee and Manager Report**  
   Display employee details alongside their branch manager’s information.<br>
```sql
Select 
    emp.emp_id,
    emp.emp_name,
    b.manager_id as manager_id,
    emp2.emp_name as manager_name
From employees emp
Join branch b On emp.branch_id = b.branch_id
Join employees emp2 On emp2.emp_id = b.manager_id;
```
<br>

5. **Create Table of Expensive Books**  
   Generate a table for books with rental prices above a certain threshold.<br>
```sql
Drop Table if EXISTS expensive_books;

Create Table expensive_books as (
    Select * From books
    Where rental_price > 5.5
);

Select * From expensive_books;
```
<br>

6. **Identify Books Not Yet Returned**  
   Find books that are currently issued and not returned.<br>
```sql
Select 
    DISTINCT b.isbn,
    b.book_title,
    b.author,
    b.category
From issued_status iss
Join books b On iss.issued_book_isbn = b.isbn
Left Join return_status rs On iss.issued_id = rs.issued_id
Where rs.issued_id is NULL;
```
<br>

7. **Find Members with Overdue Books**  
   List members who have books overdue by more than 30 days, including details like due date and days past due.<br>
```sql
With overdue_books as (
    Select
        iss.issued_id,
        iss.issued_member_id,
        iss.issued_book_isbn,
        iss.issued_date,
        to_char(iss.issued_date + INTERVAL '30 days', 'YYYY-MM-DD') as due_date,
        EXTRACT(day FROM CURRENT_DATE - (iss.issued_date + INTERVAL '30 days')) AS days_past_due
    From issued_status iss
    Left Join return_status rs On rs.issued_id = iss.issued_id
    Where rs.issued_id is NULL
        And EXTRACT(day FROM CURRENT_DATE - (iss.issued_date + INTERVAL '30 days')) > 30
)
Select
    m.member_id,
    m.member_name,
    b.book_title,
    ob.issued_date,
    ob.due_date,
    ob.days_past_due
From overdue_books ob
Join members m On m.member_id = ob.issued_member_id
Join books b On b.isbn = ob.issued_book_isbn;
```
<br>

8. **Fine Management**  
   - Create a fines table to track late fees.  
   - Implement a function to calculate and apply fines based on overdue days.<br>
```sql
-- 8.1 Create a Table fines
Drop Table if Exists fines;

Create Table fines(
    fine_id SERIAL PRIMARY KEY NOT NULL,
    issued_id VARCHAR(15) NOT NULL,
    fine_date DATE DEFAULT CURRENT_DATE NOT NULL,
    fine_amount NUMERIC(6,2) NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_issued FOREIGN KEY (issued_id) 
    REFERENCES issued_status(issued_id) ON DELETE CASCADE
);

-- 8.2 Function to calculate fines
Create or Replace Function apply_late_fines()
Returns void
Language plpgsql
As $$
Declare
    rec Record;
    days_late Integer;
    fine_amount Numeric;
BEGIN
    For rec In
        Select 
            iss.issued_id,
            iss.issued_date
        From issued_status iss
        Left Join return_status rs On rs.issued_id = iss.issued_id
        Where rs.issued_id is NULL
            and (CURRENT_DATE - (iss.issued_date + INTERVAL '30 days')) > 30
    Loop 
        days_late := (CURRENT_DATE - (rec.issued_date + INTERVAL '30 days'));
        fine_amount := days_late * 1.0;

        If not EXISTS (
            Select 1 
            From fines
            WHERE issued_id = rec.issued_id
        ) THEN 
            Insert into fines (issued_id, fine_amount, fine_date, is_paid)
            Values (rec.issued_id, fine_amount, CURRENT_DATE, TRUE);
        END IF;
    END LOOP;
END;
$$;

-- Call the function
Select apply_late_fines();

-- Check the result
Select * From fines;
```
<br>

9. **Branch Performance Report**  
   Generate a report per branch showing the number of books issued, returned, and total revenue from rentals.<br>
```sql
With issued_books_list as (
    Select
        b.branch_id,
        iss.issued_id,
        iss.issued_book_isbn
    From branch b
    Join employees e On e.branch_id = b.branch_id
    Join issued_status iss on e.emp_id = iss.issued_emp_id
),
returned_books as (
    Select 
        ibl.branch_id,
        ibl.issued_id,
        ibl.issued_book_isbn,
        CASE 
            WHEN rs.issued_id IS NOT NULL THEN TRUE
            ELSE False
        END as returned_book
    From issued_books_list ibl
    Left Join return_status rs On rs.issued_id = ibl.issued_id
),
total_revenue as (
    Select
        rb.branch_id,
        count(*) as books_issued,
        count(*) FILTER (WHERE rb.returned_book = TRUE) as books_returned,
        count(*) FILTER (Where rb.returned_book = FALSE) as books_not_returned,
        sum(b.rental_price) FILTER (WHERE rb.returned_book = TRUE) as revenue
    From returned_books rb
    Join books b on b.isbn = rb.issued_book_isbn
    Group By rb.branch_id
    Order By rb.branch_id
)
Select *
From total_revenue;
```
<br>

10. **Active Members Table**  
    Create a table of members who have issued at least one book recently.<br>
```sql
Create Table active_members as (
    Select *
    From members
    Where member_id In (
        Select DISTINCT issued_member_id
        From issued_status
        Where issued_date Between '2024-03-01' AND '2024-03-21'
    )
);

Select * From active_members;
```
<br>

11. **Top Employees by Book Issues**  
    Identify the top 3 employees who have issued the most books and generated the highest revenue.<br>
```sql
Select
    e.emp_id,
    count(*) as books_issued,
    sum(b.rental_price) as total_revenue
From employees e
Join issued_status iss On iss.issued_emp_id = e.emp_id
Join books b on b.isbn = iss.issued_book_isbn
Group By e.emp_id
Having count(*) >= 3
Order By sum(b.rental_price) DESC
Limit 3;
```
<br>

12. **Stored Procedure for Issuing Books**  
    Develop a procedure that updates the status of a book when it is issued, ensuring availability checks and status updates.<br>
```sql
Create or Replace Procedure issue_a_book(
    p_issued_id varchar(15),
    p_issued_member_id varchar(15),
    p_book_id varchar(30),
    p_emp_id varchar(15)
)
Language plpgsql
AS $$
Declare
    book_id varchar(30);
    book_title text;
    book_status text;
Begin
    Select
        b.isbn,
        b.book_title,
        b.status
    Into book_id, book_title, book_status
    From books b
    Where b.isbn = p_book_id;
    
    IF book_status = 'yes' Then
        RAISE NOTICE 'Id: %, Book: % -> Is available and now will be issued!', book_id, book_title;

        Insert Into issued_status(
            issued_id,
            issued_member_id,
            issued_book_name,
            issued_date,
            issued_book_isbn,
            issued_emp_id)
        Values(
            p_issued_id,
            p_issued_member_id,
            book_title,
            CURRENT_DATE,
            book_id,
            p_emp_id);

        UPDATE books
        SET status = 'no'
        WHERE isbn = p_book_id;
    Else
        RAISE NOTICE 'At this moment Id: %, Book: %, is not available and cannot be issued!', book_id, book_title;
    End If;
End;
$$;

-- Example call:
Call issue_a_book(
    'IS141',
    'C101',
    '978-0-14-118776
```
<br>

## How to Use

- Run the queries sequentially to explore the dataset and analyze library operations.
- Use the stored procedures and functions for automated management tasks such as fine calculation and book issuance.
- Adapt and extend the SQL scripts as needed for your specific database setup.

## Technologies Used

- PostgreSQL (PL/pgSQL)
- SQL (Advanced querying, joins, CTEs, window functions)
- Database design principles (Foreign keys, constraints)

## Notes

- Ensure the database schema aligns with the described tables before running the queries.
- Always backup your database before performing any updates or inserts.
- This project is aimed at demonstrating SQL capabilities for managing a library database with practical business logic.
