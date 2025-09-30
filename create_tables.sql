--!> 1. Creating Tables
    --!> 1.1 Create Table 'Branch'
Drop Table if exists branch

Create Table branch(
    branch_id VARCHAR(15) PRIMARY KEY
    , manager_id VARCHAR(15)
    , branch_address VARCHAR(30)
    , contact_no VARCHAR(30) 
)


    --!> 1.2 Create Table 'employees'
Drop Table if exists employees

Create Table employees (
    emp_id VARCHAR(15) PRIMARY KEY
    , emp_name VARCHAR(30)
    , position VARCHAR(30)
    , salary FLOAT
    , branch_id VARCHAR(15)                     --?> Foreign Key
)


    --!> 1.3 Create Table 'books'
Drop Table if exists books

Create Table books (
    isbn VARCHAR(30) PRIMARY KEY
    , book_title VARCHAR(60)
    , category VARCHAR(30)
    , rental_price FLOAT
    , status VARCHAR(3)
    , author VARCHAR(60)
    , publisher VARCHAR(60)
)


    --!> 1.4 Create Table 'members'
Drop Table if exists members

Create Table members (
    member_id VARCHAR(15) PRIMARY KEY
    , member_name VARCHAR(60)
    , member_address VARCHAR(60)
    , reg_date DATE
)


    --!> 1.5 Create Table 'issued_status'
Drop Table if exists issued_status

Create Table issued_status (
    issued_id VARCHAR(15) PRIMARY KEY
    , issued_member_id VARCHAR(15)              --?> Foreign Key
    , issued_book_name VARCHAR(60)
    , issued_date DATE
    , issued_book_isbn VARCHAR(30)              --?> Foreign Key
    , issued_emp_id VARCHAR(15)                 --?> Foreign Key
)

    --!> 1.6 Create Table 'return_status'
Drop Table if exists return_status

Create Table return_status (
    return_id VARCHAR(15) PRIMARY KEY
    , issued_id VARCHAR(15)                     --?> Foreign Key
    , return_book_name VARCHAR(60)
    , return_date DATE
    , return_book_isbn VARCHAR(30)              --?> Foreign Key
)

--!> 2. Managing Foreign Keys
    --!> 2.1 Foreign Keys for 'issued_status'
Alter Table issued_status
Add Constraint fk_members
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id)
, Add Constraint fk_books 
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
, Add Constraint fk_employees
    FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id)

    --!> 2.2 Foreign Keys for 'employees'
Alter Table employees
Add Constraint fk_branch
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)

    --!> 2.3 Foreign Keys for 'return_status'
Alter Table return_status
Add Constraint fk_issued_status
    FOREIGN KEY (issued_id) REFERENCES issued_status(issued_id)
, Add Constraint fk_books
    Foreign Key (return_book_isbn) REFERENCES books(isbn)