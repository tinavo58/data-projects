import tabula
import warnings
import pandas as pd
import glob

warnings.filterwarnings('ignore')

statementsFolder = "./bank-statements"
statement_included_previous_year_transactions = './bank-statements/in-between-years/f5409c4a-c421-40dc-a622-457581502421.pdf'




### extract data from bank statements
# retrieved from Jan-2023 only
statement = tabula.read_pdf(
    statement_included_previous_year_transactions,
    pages='all',
)

statement = statement[4:]

# extract other statements as normal
dfs = []
for pdf in glob.glob(f"{statementsFolder}/*.pdf"):
    dfs.append(tabula.read_pdf(pdf, pages='all'))

dfs = [df for each in dfs for df in each]

# combine all statements
dfs.extend(statement)

# retrieve correct headers
dfs[1].columns
data = []
for df in dfs:
    # check if the correct headers assigned
    if 'Date' in df.columns:
        data.append(df)
    else:
        df = df.swapaxes(0, 1).reset_index().swapaxes(0, 1).reset_index(drop=True)
        df.columns = ['Date', 'Transaction Details', 'Withdrawals ($)', 'Deposits ($)', 'Balance ($)']
        data.append(df)

transactions = pd.concat(data, axis=0).reset_index(drop=True)


### clean up the raw data where needed
# remove balance col
transactions = transactions.iloc[:,:-1]

# remove $ sign, space and replace space with `_` from headers
transactions.columns = [col.replace(' ($)', '').replace(' ', '_').lower() for col in transactions.columns]

# remove na rows & rows with date not in the format `DD MMM`
transactions = transactions.dropna(subset=['date'])
transactions = transactions[transactions['date'].str.contains(r'^\d{2} \w{3}$', regex=True)]

# remove na rows if both `withdrawals` & `deposits` are na
transactions = transactions.dropna(subset=['withdrawals', 'deposits'])

# convert `date` col
transactions['date'] = transactions['date'].map(lambda x: x + ' 2023')
transactions['date'] = pd.to_datetime(transactions['date'], format='%d %b %Y')

# export data to csv file
transactions.to_csv('bank_transactions_2023.csv', index=False)
