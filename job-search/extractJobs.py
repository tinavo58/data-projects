#!/usr/bin/env python3
import json
import os
import glob
import numpy
from datetime import datetime
from mysql.connector import (
    connect
)
from dotenv import load_dotenv; load_dotenv()
from pydantic import (
    BaseModel,
    model_validator
)
import pandas as pd


class Description(BaseModel):
    description: str

class JobAd(BaseModel):
    id: int
    advertiser: Description
    area: str | None
    areaId: int | None
    areaWhereValue: str | None
    automaticInclusion: bool
    classification: Description
    companyName: str | None
    displayType: str | None
    location: str | None
    locationId: int | None
    locationWhereValue: str | None
    isPremium: bool
    isStandOut: bool
    listingDate: datetime
    roleId: str | None
    salary: str
    subClassification: Description
    suburb: str | None
    suburbId: int | None
    suburbWhereValue: str | None
    title: str
    workType: str
    isPrivateAdvertiser: bool

    @model_validator(mode='before')
    def _return_None(cls, values):
        fieldsList = ['area', 'areaId', 'areaWhereValue', 'suburb', 'suburbId', 'suburbWhereValue', 'companyName', 'roleId']

        for field in fieldsList:
            if not field in values:
                values[field] = None

        return values


config = {
    'user': os.getenv('USER_INDIVIDUAL'),
    'password': os.getenv('PASSWORD'),
    'host': os.getenv('HOST'),
    'database': 'Mysql_Learners.db'
}


def connect_msql(config):
    try:
        return connect(**config)
    except Exception as e:
        print(f"{e}: please check your config and try again.")
        return


def extractData():
    data = []
    for file in glob.glob("./seek-jobs/*.json"):
        with open(file, encoding='utf-8') as f:
            content = json.load(f)
            data.append(content['data'])

    data = [JobAd(**job) for each in data for job in each]
    return data


def main():
    # getting jobs from json files
    data = extractData()

    # convert to df
    df = pd.DataFrame([job.model_dump() for job in data])

    # flatten dict values in the following cols
    cols = ['advertiser', 'classification', 'subClassification']
    df[cols] = df[cols].map(lambda x: x['description'])

    # save to csv
    df.to_csv('data-analyst-jobs-seek.csv', index=False, encoding='utf-8')

    print("file saved...")


if __name__ == '__main__':
    main()
