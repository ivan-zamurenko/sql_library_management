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