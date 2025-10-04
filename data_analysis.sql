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



--!> 9. Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
With issued_books_list as (
    Select
        b.branch_id
        , iss.issued_id
        , iss.issued_book_isbn
    From branch b
    Join employees e On e.branch_id = b.branch_id
    Join issued_status iss on e.emp_id = iss.issued_emp_id
)
, returned_books as (
    Select 
        ibl.branch_id
        , ibl.issued_id
        , ibl.issued_book_isbn
        , CASE 
            WHEN rs.issued_id IS NOT NULL THEN TRUE
            ELSE False
        END as returned_book
    From issued_books_list ibl
    Left Join return_status rs On rs.issued_id = ibl.issued_id
)
, total_revenue as (
    Select
        rb.branch_id
        , count(*) as books_issued
        , count(*) FILTER (WHERE rb.returned_book = TRUE) as books_returned
        , count(*) FILTER (Where rb.returned_book = FALSE) as books_not_returned
        , sum(b.rental_price) FILTER (WHERE rb.returned_book = TRUE) as revenue
    From returned_books rb
    Join books b on b.isbn = rb.issued_book_isbn
    Group By rb.branch_id
    Order By rb.branch_id
)
Select *
From total_revenue


--!> 10. Create a table of active members. Members who have issued at least one book in the few weeks
Create Table active_members as(
    Select *
    From members
    Where member_id In (
        Select
            DISTINCT issued_member_id
        From issued_status
        Where issued_date Between '2024-03-01' AND '2024-03-21'
    )
)
Select *
From active_members


--!> 11. Write a query to find TOP-3 employee who have issued at least three book
Select
    e.emp_id
    , count(*) as books_issued
    , sum(b.rental_price) as total_revenue
From employees e
Join issued_status iss On iss.issued_emp_id = e.emp_id
Join books b on b.isbn = iss.issued_book_isbn
Group By e.emp_id
Having count(*) >= 2
Order by sum(b.rental_price) DESC
Limit 3


/*--!> 12. Complex task
--!> Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
--!> The procedure should function as follows: 
--!> The stored procedure should take the book_id as an input parameter. 
--!> The procedure should first check if the book is available (status = 'yes'). 
--!> If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
--!> If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/

Select * From books

Select * From issued_status


--?> Create the procedure
Create or Replace Procedure issue_a_book(
    p_issued_id varchar(15)
    , p_issued_member_id varchar(15)
    , p_book_id varchar(30)
    , p_emp_id varchar(15))
Language plpgsql
AS $$
Declare
    book_id varchar(30);
    book_title text;
    book_status text;
Begin
    --?> Logic is here
    Select
        b.isbn
        , b.book_title
        , b.status
    Into book_id, book_title, book_status
    From books b
    Where b.isbn = p_book_id;
    
    --?> Conditional output
    IF book_status = 'yes' Then
        RAISE NOTICE 'Id: %, Book: % -> Is available and now will be issued!', book_id, book_title;

        --?> Insert a new issue row
        Insert Into issued_status(
            issued_id
            , issued_member_id
            , issued_book_name
            , issued_date
            , issued_book_isbn
            , issued_emp_id)
        Values(
            p_issued_id
            , p_issued_member_id
            , book_title
            , CURRENT_DATE
            , book_id
            , p_emp_id);

        --?> Mark book as issued (status = 'no')
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_book_id;
    Else
        RAISE NOTICE 'At this moment Id: %, Book: %, is not available and cannot be issued!', book_id, book_title;
    End If;
End;
$$;

Call issue_a_book(
    'IS141'
    , 'C101'
    , '978-0-14-118776-1'
    , 'E102'
    )
