#!/usr/bin/env python3
import csv
import time
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
}


def extract_text(tag):
    """return the content of tag if existed"""
    if tag is not None:
        return tag.text


def extract_data(soup):
    """return list of job ads info"""

    # extract 'normalJob' job ads
    # since there are very little of `premiumJob`, this is not extracted
    ads = soup.find_all('article', {'data-automation': 'normalJob'})
    data = []

    for job in ads:
        title = job.find('a', {'data-automation': 'jobTitle'})
        company = job.find('a', {'data-automation': 'jobCompany'})
        jobType = job.find('p', class_='y735df0')
        location = job.findAll('a', {'data-type': 'location'})
        salary = job.find('span', {'data-automation': 'jobSalary'})
        classification = job.find('a', {'data-type': 'classification'})
        subClass = job.find('a', {'data-type': "subClassification"})
        shortDesc = job.find('span', {'data-automation': 'jobShortDescription'})
        timePosted = job.find('div', class_='y735df0 _1iz8dgs5i _1iz8dgs0 _14zgbb20')

        jobDict = {
            'jobTitle': extract_text(title),
            'jobCompany': extract_text(company),
            'jobType': extract_text(jobType),
            'jobLocation': ', '.join([loc.text for loc in location]),
            'jobSalary': extract_text(salary),
            'classification': extract_text(classification),
            'subClassification': extract_text(subClass),
            'jobShortDescription': extract_text(shortDesc),
            'timePosted': extract_text(timePosted)
        }
        data.append(jobDict)

    return data


def main():
    url = 'https://www.seek.com.au/data-analyst-jobs'

    while True:
        res = requests.get(url=url, headers=headers)
        soup = BeautifulSoup(res.text, 'html.parser')
        data = extract_data(soup)

        with open('./job-search/data_anaylyst_jobs.csv', 'a+', encoding='utf8') as f:
            f = csv.DictWriter(
                f,
                fieldnames=['jobTitle', 'jobCompany', 'jobType', 'jobLocation', 'jobSalary', 'classification', 'subClassification', 'jobShortDescription', 'timePosted']
            )
            f.writerows(data)

        print('writing to file completed...')

        nxt_page = soup.find('a', title='Next')
        if nxt_page is not None:
            url = urljoin(res.url.rsplit('/', maxsplit=1)[0], nxt_page['href'])
            time.sleep(2)

        else:
            break


if __name__ == '__main__':
    main()
