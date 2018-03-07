title: Problem Using a Coldfusion Struct Built From a Query
date: 2009-11-11
url_code: problem-using-a-coldfusion-struct-built-from-a-query

The other day I ran into an unusual problem when using a fairly simple Coldfusion struct containing string values and keyed by strings - nothing out of the ordinary. I was using the keys and the values to update fields in the database e.g.

    UPDATE	table_name
    SET	     #key# = <cfqueryparam cf_sql_type="cf_sql_varchar" value="#struct[key]#">
    WHERE	 column = something

Running that query I got the error:

    Invalid data coldfusion.sql.QueryColumn@ff685d for CFSQLTYPE CF_SQL_VARCHAR

It was a surprise to learn that I was trying to feed a query column in rather than a string so I went back to look at where the struct was created.

Sure enough it was loaded up from a database query, running through the list of columns and setting those as the keys and the associated cell values as the values in the struct.

The query used would only every have one row as it was obtained using a 'WHERE' clause on a unique value. As such the values in the struct were set simply using query.column, without referencing a row.
I tried to reproduce this by creating a test query with one column, adding a row and setting a value in the cell in that row. Then I looped through the column list and set the column as the key and the cell as the value - there was no reference to the query row.

    <!--- Create a test query and add a single column of type varchar. --->
    <cfset query = QueryNew("key",'VarChar')>

    <!--- Add a row and an arbitrary value in. --->
    <cfset rows = QueryAddRow(query)>
    <cfset query.key[1] = "value">

    <!--- Output the query to have a look. --->
    <cfdump var="#query#" label="Constructed query">

    <!--- Create a new struct. --->
    <cfset queryStruct = {}>

    <!--- 
    Loop over the list of query columns and set the each column as a key 
    in the struct, with the column value as the value.
     --->
    <cfloop list="#query.ColumnList#" index="field">
        <cfset queryStruct[field] = query[field]>
    </cfloop>

I then tried to output the values in the struct using both dot notation and the square bracket notation, catching any errors and outputting them. Before outputting the value I've also grabbed the underlying class of the key and output that too.

    <!--- Try to display the values from the struct. --->
    <h3>From struct built from query.</h3>
    <cftry>
        <strong>Dot notation</strong>
        <cfoutput>
            <!--- Use dot notation and display the class name above the value. --->
            Class name: #queryStruct.key.getClass().getName()#
            Struct value: #queryStruct.key#
        </cfoutput>
        <cfcatch type="any">
            <cfoutput>
            Error: #cfcatch.Message#
            </cfoutput>
        </cfcatch>
    </cftry>

    <cftry>
        <strong>Key with bracket notation</strong>
        <cfoutput>
            Class name: #queryStruct['key'].getClass().getName()#
            Struct value: #queryStruct['key']#
        </cfoutput>
        <cfcatch type="any">
            <cfoutput>
            Error: #cfcatch.Message#
            </cfoutput>
        </cfcatch>
    </cftry>

The image at the end shows the results.

The error message says that the value can't be output because a complex value is being treated as a simple one, in this case it's because we're trying to print out a class of `coldfusion.sql.QueryColumn`. Notice that the class name of the key is shown as such. Weirdly enough this error doesn't occur when we use dot notation, only when using a string in square backets.

Now if we build the struct up from the query again but this time reference the row that we're working on - I used the CurrentRow variable of the query - and output the results in the same way we get the results we'd expect.

    <!--- 
    Loop over the list of query columns and set the each column as a key 
    in the struct, with the column value as the value.
     --->
    <cfloop list="#query.ColumnList#" index="field">
        <cfset queryStruct[field] = query[field][query.CurrentRow]>
    </cfloop>

It makes sense that the value from the query doesn't go into the struct as a string without the reference to the row but it's confusing that it goes in at all in that case. It's also very confusing that you can retrieve the value and output it as a simple value when you use the dot notation but not using the square brackets. The first point can be attributed to the weak-typing in Coldfusion, but why there is a difference with the retrieval methods I don't know.
