Phase 2

In phase 2, there are lots of files, created by different method. Here is the explanation of it.

    For ETL process, run only the data_cleaning.ipynb file. This file perform data cleaning and load the final data into the csv file called final_result.csv. This file also create a script call data_loading.sql, which is used to load the final_result.csv into database (in our case, PostgreSQL).
    After the final_result.csv is created, use data_staging.ipynb file. This file will create these files: covid19_metrics_dimension.csv, date_dimension.csv, province_dimension.csv and vaccination_dimension.csv. In addition, it will create a script called dimension_creating.sql, which is used to create relational schema in DBMS.
