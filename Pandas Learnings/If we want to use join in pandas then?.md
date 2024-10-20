In Pandas, you can use the merge() function to perform joins between two DataFrames. The merge() function allows you to specify the type of join you want to perform (inner, outer, left, or right) and the columns on which to join.

Here’s how to use joins in Pandas:

Example

import pandas as pd

# Sample DataFrames
df1 = pd.DataFrame({
    'key': ['A', 'B', 'C'],
    'value1': [1, 2, 3]
})

df2 = pd.DataFrame({
    'key': ['B', 'C', 'D'],
    'value2': [4, 5, 6]
})

# Inner Join
inner_join = pd.merge(df1, df2, on='key', how='inner')
print("Inner Join:\n", inner_join)

# Left Join
left_join = pd.merge(df1, df2, on='key', how='left')
print("\nLeft Join:\n", left_join)

# Right Join
right_join = pd.merge(df1, df2, on='key', how='right')
print("\nRight Join:\n", right_join)

# Outer Join
outer_join = pd.merge(df1, df2, on='key', how='outer')
print("\nOuter Join:\n", outer_join)

Types of Joins

	•	Inner Join: Returns rows with keys that are present in both DataFrames.
	•	Left Join: Returns all rows from the left DataFrame and matched rows from the right DataFrame.
	•	Right Join: Returns all rows from the right DataFrame and matched rows from the left DataFrame.
	•	Outer Join: Returns all rows from both DataFrames, filling in NaNs where there are no matches.

You can also join on multiple keys by passing a list to the on parameter, like this:

pd.merge(df1, df2, on=['key1', 'key2'], how='inner')

This is how you can perform joins using Pandas! If you have a specific use case in mind, feel free to share, and I can provide a tailored example.
