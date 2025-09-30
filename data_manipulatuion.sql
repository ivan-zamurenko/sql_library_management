--> Preview data
Select * From members
Select * From issued_status
Select * From employees
Select * From books


--!> 1. CRUD operations (Create, Read, Update, Delete)
    --!> 1.1 Create a new 'Book' record
Insert into books (
    isbn
    , book_title
    , category
    , rental_price
    , status
    , author
    , publisher
) VALUES (
    '978-1-60129-456-2'
    , 'To Kill a Mockingbird'
    , 'Classic'
    , 6.00
    , 'yes'
    , 'Harper Lee'
    , 'J.B. Lippincott & Co.'
)                                                       --?> 1 affected row

Select * From books
WHERE isbn = '978-1-60129-456-2'


    --!> 1.2 Update an existing Member's Address
Update members
Set member_address = '71 St. Johns Park, Tralee'
Where member_id = 'C104'                                --?> 1 affected row

Select * From members
Where member_id = 'C104'


    --!> 1.3 Delete a record from 'Issued_status' table
Delete From issued_status
Where issued_id = 'IS131'                               --?> 1 affected row


    --!> 1.4 Show all Books issued by a specific Employee
Select
    issued_book_isbn
    , issued_book_name
From issued_status
Where issued_emp_id = 'E104'                            --?> 4 books found


    --!> 1.5 List Employees who have issued more than one book
Select 
    issued_emp_id
    , count(*) as books_amount
From issued_status
Group By issued_emp_id
Having count(*) > 1                                     --?> 8 employees have been found


--!> 2. CTAS operations (Create Table As Select)
    --!> 2.1  Generate new tables based on query results - each book and total book_issued_count
    Create Table book_issued_count as (
        Select
            b.isbn
            , b.book_title
            , count(iss.issued_id) as book_count
        From books b
        Join issued_status iss On iss.issued_book_isbn = b.isbn
        Group By b.isbn, b.book_title
        Order By book_count Desc
    )