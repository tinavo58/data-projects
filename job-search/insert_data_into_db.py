#!/usr/bin/env python3
import os
import pandas as pd
import numpy as np
from dotenv import load_dotenv; load_dotenv()
from mysql.connector import connect

config = {
    'user': os.getenv('USER_'),
    'host': os.getenv('HOST'),
    'password': os.getenv('PASSWORD'),
    'database': 'Mysql_Learners'
}

file = './job-search/data_analyst_jobs.csv'
df = pd.read_csv(file, header=None)
df.replace({np.nan: None}, inplace=True)

with connect(**config) as conn:
    if conn.is_connected:
        print('connected')

    with conn.cursor() as cur:
        query = """insert into Jobs values (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        data = list(df.itertuples(index=False))
        cur.executemany(query, data)
        conn.commit()

        print('insert process completed')
