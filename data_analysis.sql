--> Data preview
Select * From books
Select * From issued_status
Select * From members
Select * From employees

--!> 1. Show all 'books' in specific category
Select * From books
Where category = 'History'                              --?> 7 books in category 'History'


--!> 2. Find total rent income by category
With rent_income as (
    Select
        b.isbn
        , b.book_title
        , b.category
        , b.rental_price
    From books b
    Join issued_status iss On iss.issued_book_isbn = b.isbn
)
Select 
    category
    , sum(rental_price) as total_income
    , count(*) as books_quantity
From rent_income
Group By category
Order By total_income DESC


--!> 3. List Members who registered in the last 180 Days (Start from: 2021-06-01)
Select * 
From members
Where reg_date BETWEEN 
    Date '2021-06-01' 
    AND Date '2021-06-01' + INTERVAL '180 days'
Order By reg_date ASC


--!> 4. List employees with their branch manager's name and their branch details
Select 
    emp.emp_id
    , emp.emp_name
    , b.manager_id as manager_id
    , emp2.emp_name as manager_name
From employees emp
Join branch b On emp.branch_id = b.branch_id
Join employees emp2 On emp2.emp_id = b.manager_id

    
--!> 5. Create a table of books with rental price above a certain thresh hold (5$)
Create Table expensive_books as (
    Select * From books
    Where rental_price > 5.5
)

Select * From expensive_books


--!> 6. Retrieve the list of books which do not returned yet
Select 
    DISTINCT b.isbn
    , b.book_title
    , b.author
    , b.category
From issued_status iss
Join books b On iss.issued_book_isbn = b.isbn
Left Join return_status rs On iss.issued_id = rs.issued_id
Where rs.issued_id is NULL



--!> 7. Identify members with overdue books. Display the member's_id, member's name, book title, issue date, and days overdue (more than 30 days)
With overdue_books as (
    Select
        iss.issued_id
        , iss.issued_member_id
        , iss.issued_book_isbn
        , iss.issued_date
        , to_char(iss.issued_date + INTERVAL '30 days', 'YYYY-MM-DD') as due_date
        , EXTRACT(day FROM CURRENT_DATE - (iss.issued_date + INTERVAL '30 days')) AS days_past_due
    From issued_status iss
    Left Join return_status rs On rs.issued_id = iss.issued_id
    Where rs.issued_id is NULL
        And EXTRACT(day FROM CURRENT_DATE - (iss.issued_date + INTERVAL '30 days'))> 30
)
Select
    m.member_id
    , m.member_name
    , b.book_title
    , ob.issued_date
    , ob.due_date
    , ob.days_past_due
From overdue_books ob
Join members m On m.member_id = ob.issued_member_id
Join books b On b.isbn = ob.issued_book_isbn


--!> 8. Create a table for Fines. Write a function, which will calculate fines depends on overdue
    --?> 8.1 Create a Table fines.
Drop Table if Exists fines

Create Table fines(
    fine_id SERIAL PRIMARY KEY NOT NULL
    , issued_id VARCHAR(15) NOT NULL
    , fine_date DATE DEFAULT CURRENT_DATE NOT NULL
    , fine_amount NUMERIC(6,2) NOT NULL
    , is_paid BOOLEAN DEFAULT FALSE
    , CONSTRAINT fk_issued FOREIGN KEY (issued_id) 
    REFERENCES issued_status(issued_id) ON DELETE CASCADE
)

    --?> 8.2 Write a function for fines calculation.
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
    --?> This is a query which is looking for overdue books
        Select 
            iss.issued_id
            , iss.issued_date
        From issued_status iss
        Left Join return_status rs On rs.issued_id = iss.issued_id
        Where rs.issued_id is NULL
            and extract(day from CURRENT_DATE - (iss.issued_date + INTERVAL '30 days')) > 30
    --?> Now let's count the fines, which is 1$ per day
    Loop 
        --?> Calculate how many days overdue and apply fines
        days_late:= extract(day from CURRENT_DATE - (rec.issued_date + INTERVAL '30 days'));
        fine_amount:= days_late * 1.0;
        --?> Insert fine only if not already fined
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

--?> Call the function
Select apply_late_fines()

--?> Check the result
Select *
From fines


--!> 9.
