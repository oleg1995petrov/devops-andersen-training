#! /usr/bin/python3

import re
import requests

from argparse import ArgumentParser


PULL_API_URL = "https://api.github.com/repos/%s/%s/pulls"
PATTERN = r'^(https?:\/\/)?(w{3}\.)?\w+\.\w+\/([-\w]+)\/([\w-]+)[\w/-]*?$'
MIN_CONTRIB_HEADER_LEN = len('Contributor') + 2
MIN_LABELS_HEADER_LEN = len('Labels') + 2
MIN_PULLS_HEADER_LEN = len('Pull requests') + 2
NUM_HEADERS = 3


def get_args():
    """Parses command line arguments"""
    parser = ArgumentParser(
        usage='./script.sh [Github repository address]'
    )
    parser.add_argument('repo_url', help='Github repository address')
    return parser.parse_args()


def get_data_per_page(response):
    """Retrieves PRs's data from one page"""
    data = {}
    j = response.json()
    for i in j:
        contrib = i['user']['login']
        labels = set([label['name'] for label in i['labels']])
        if contrib not in data:
            data[contrib] = {'pulls': 1,
                             'labels': labels}
        else:
            data[contrib]['pulls'] += 1
            data[contrib]['labels'].union(labels)
    return data


def get_data(response):
    """Retrieves PR's data from all pages"""
    data = get_data_per_page(response)
    while 'next' in response.links.keys():
        response = requests.get(response.links['next']['url'])
        data.update(get_data_per_page(response))

    data = dict(sorted(
        dict(filter(
            lambda x: x[1]['pulls'] > 1, 
            data.items()
        )).items(),
        key=lambda x: x[1]['pulls'],
        reverse=True))
    return data


def get_data_handler(response):
    """Retrieves data and forms required variables for output"""
    data = get_data(response)
    contrib_header_len = (max([len(c) for c in data.keys()]) + 2 if data 
                         else MIN_CONTRIB_HEADER_LEN)
    pulls_header_len = MIN_PULLS_HEADER_LEN
    try:
        labels_header_len = max(
            [sum([len(i) + 2 for i in v['labels']]
        ) for v in data.values()])
    except ValueError:
        labels_header_len = MIN_LABELS_HEADER_LEN
        
    if contrib_header_len < MIN_CONTRIB_HEADER_LEN:
        contrib_header_len = MIN_CONTRIB_HEADER_LEN
    if labels_header_len < MIN_LABELS_HEADER_LEN:
        labels_header_len = MIN_LABELS_HEADER_LEN
    row_len = (contrib_header_len + pulls_header_len + 
               labels_header_len + NUM_HEADERS)
    vars = {
        'contrib_header_len': contrib_header_len, 
        'pulls_header_len': pulls_header_len,
        'labels_header_len': labels_header_len,
        'row_len': row_len,
    }
    return (data, vars)


def get_response(data, vars):
    """Generates the response for output"""
    header = [
        "\n{:{}{}}".format('List of most prodactive contributors', 
                           '^',
                           vars['row_len']),
        "{:{}{}}".format('Contributor', 
                         '^',
                         vars['contrib_header_len']) + 
        '|' +
        "{:{}{}}".format('Pull requests', 
                         '^',
                         vars['pulls_header_len']) +
        '|' +
        "{:{}{}}".format('Labels',
                         '^',
                         vars['labels_header_len'])
    ]
    border = [
        "{:{}{}{}}".format('', 
                           '-', 
                           '^', 
                           vars['contrib_header_len']) + 
        '+' +
        "{:{}{}{}}".format('', 
                           '-', 
                           '^', 
                           vars['pulls_header_len']) +
        '+' +
        "{:{}{}{}}".format('',
                           '-',
                           '^',
                           vars['labels_header_len'])
    ]

    if not data:
        return header + border
    
    contrib_row_len = vars['contrib_header_len'] - 1
    pulls_row_len = vars['pulls_header_len'] - 1
    labeles_row_len = vars['labels_header_len'] - 1
    body = list()
    for k, v in data.items():
        row = " {:<{}}".format(k, contrib_row_len) + '|'
        row += " {:<{}}".format(v['pulls'], pulls_row_len) + '|'
        row += " {:<{}}".format(', '.join(v['labels']), labeles_row_len)
        body.append(row)
    response = header + border + body
    return response


def get_response_handler(data, vars):
    """Receives the response for output"""
    response = get_response(data, vars)
    response += [f'({len(response) - 3} rows)\n']
    return response


def main():
    repo_url = get_args().repo_url
    match = re.match(PATTERN, repo_url)
    if not match:
        print('❗Check the repository address. The address '
              'has to contain at least a Github repository '
              'including the Github domain, repository owner '
              'and its name.❗')
        return 
    pull_url = PULL_API_URL % (match.group(3), match.group(4))
    params = {
        'accept': 'application/vnd.github.v3+json',
        'state': 'open',
        'per_page': 100,
    }
    resp = requests.get(pull_url, params)
    if resp.status_code != 200:
        print("❗Make sure you've passed "
              "an existent repository address. "
              "Note private repositories are unreachable.❗")
        return
    data, vars = get_data_handler(resp)
    response = get_response_handler(data, vars)
    print('\n'.join(response))


if __name__ == '__main__':
    main()
