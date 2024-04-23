#!/usr/bin/env python3
from dotenv import load_dotenv
import numpy as np; load_dotenv()
from mysql.connector import connect
import pandas as pd
import os

config = {
    'host': os.getenv('HOST'),
    'database': 'HR',
    'user': os.getenv('USER_'),
    'password': os.getenv('PASSWORD')
}

file = '~/Downloads/xx.csv'


def main():
    df = pd.read_csv(
        file,
        parse_dates=['dob', 'startDate', 'termDate'],
        dayfirst=True,
        dtype = {
            'rate': np.float64,
        }
    )
    # convert NaN and NaT to None
    df.replace({np.nan: None, pd.NaT: None}, inplace=True)

    with connect(**config) as conn:
        if conn.is_connected():
            print('connected')

        with conn.cursor() as cur:
            data = list(df.itertuples(index=False))
            query = """insert into employees (employeeId, gender, dob, startDate, termDate, rate, paymentGroup, costCentre, hours, state, status)
            values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"""

            cur.executemany(query, data)
            conn.commit()

            cur.execute('select * from employees limit 5;')
            print(cur.fetchall())


if __name__ == '__main__':
    main()
