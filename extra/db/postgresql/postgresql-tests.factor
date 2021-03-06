! You will need to run  'createdb factor-test' to create the database.
! Set username and password in  the 'connect' word.

USING: kernel db.postgresql alien continuations io classes
prettyprint sequences namespaces tools.test db
db.tuples db.types unicode.case ;
IN: db.postgresql.tests

: test-db ( -- postgresql-db )
    { "localhost" "postgres" "foob" "factor-test" } postgresql-db ;

[ ] [ test-db [ ] with-db ] unit-test

[ ] [
    test-db [
        [ "drop table person;" sql-command ] ignore-errors
        "create table person (name varchar(30), country varchar(30));"
            sql-command

        "insert into person values('John', 'America');" sql-command
        "insert into person values('Jane', 'New Zealand');" sql-command
    ] with-db
] unit-test

[
    {
        { "John" "America" }
        { "Jane" "New Zealand" }
    }
] [
    test-db [
        "select * from person" sql-query
    ] with-db
] unit-test

[
    {
        { "John" "America" }
        { "Jane" "New Zealand" }
    }
] [ test-db [ "select * from person" sql-query ] with-db ] unit-test

[
] [
    test-db [
        "insert into person(name, country) values('Jimmy', 'Canada')"
        sql-command
    ] with-db
] unit-test

[
    {
        { "John" "America" }
        { "Jane" "New Zealand" }
        { "Jimmy" "Canada" }
    }
] [ test-db [ "select * from person" sql-query ] with-db ] unit-test

[
    test-db [
        [
            "insert into person(name, country) values('Jose', 'Mexico')" sql-command
            "insert into person(name, country) values('Jose', 'Mexico')" sql-command
            "oops" throw
        ] with-transaction
    ] with-db
] must-fail

[ 3 ] [
    test-db [
        "select * from person" sql-query length
    ] with-db
] unit-test

[
] [
    test-db [
        [
            "insert into person(name, country) values('Jose', 'Mexico')"
            sql-command
            "insert into person(name, country) values('Jose', 'Mexico')"
            sql-command
        ] with-transaction
    ] with-db
] unit-test

[ 5 ] [
    test-db [
        "select * from person" sql-query length
    ] with-db
] unit-test


: with-dummy-db ( quot -- )
    >r T{ postgresql-db } db r> with-variable ;
