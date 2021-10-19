#! /usr/bin/python3

import re
import requests

from argparse import ArgumentParser


API_URL = "https://api.github.com/repos/%s/%s/pulls"
HEADERS = {'Accept': 'application/vnd.github.v3+json'}
PATTERN = r'^(https?:\/\/)?(w{3}\.)?(github.com\/)?([.\w-]+)\/([.\w-]+)[\w/-]*?$'
MIN_CONTRIB_HEADER_LEN = len('Contributor') + 2
MIN_LABELS_HEADER_LEN = len('Labels') + 2
MIN_PULLS_HEADER_LEN = len('Pull requests') + 2
NUM_HEADERS = 3


def get_args():
    """Parses command line arguments"""
    parser = ArgumentParser(usage='./script.sh [Github repository address]')
    parser.add_argument('repo_url', help='Github repository address.')
    parser.add_argument('-t', '--access-token', help='Github access token.')
    parser.add_argument('-p', '--pages-number', type=int, default=1, 
                        help='The number of pages to parse.')
    args = parser.parse_args()
    return args


def get_data_per_page(response):
    """Retrieves PRs' data from one page"""
    data = dict()
    global LEFT_REQUESTS
    LEFT_REQUESTS = response.headers.get('X-RateLimit-Remaining')
    for i in response.json():
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
    """Receives PRs' data from all pages and sorts them"""
    data = get_data_per_page(response)
    counter = 1

    while 'next' in response.links.keys():
        if counter >= LIMIT:
            break
        url = response.links['next']['url']
        response = requests.get(url, headers=HEADERS)
        data.update(get_data_per_page(response))
        counter +=1

    data = dict(sorted(
        data.items(),
        key=lambda x: x[1]['pulls'],
        reverse=True
    ))
    
    data_filtered = dict(sorted(
        dict(filter(
            lambda x: x[1]['pulls'] > 1, 
            data.items()
        )).items(),
        key=lambda x: x[1]['pulls'],
        reverse=True))
    return data, data_filtered


def get_data_handler(response):
    """Receives PRs' data and generates required variables for output"""
    data, data_filtered = get_data(response)
    contrib_header_len = (max([len(c) for c in data.keys()]) + 2 if data 
                          else MIN_CONTRIB_HEADER_LEN)
    contrib_header_len_filtered = (max([len(c) for c in data_filtered.keys()]) + 2 
                                   if data_filtered else MIN_CONTRIB_HEADER_LEN)
    pulls_header_len = MIN_PULLS_HEADER_LEN
    
    try:
        labels_header_len = max(
            [sum([len(i) + 2 for i in v['labels']]
        ) for v in data.values()])
    except ValueError:
        labels_header_len = MIN_LABELS_HEADER_LEN
    try:
        labels_header_len_filtered = max(
            [sum([len(i) + 2 for i in v['labels']]
        ) for v in data_filtered.values()])
    except ValueError:
        labels_header_len_filtered = MIN_LABELS_HEADER_LEN
        
    if contrib_header_len < MIN_CONTRIB_HEADER_LEN:
        contrib_header_len = MIN_CONTRIB_HEADER_LEN
    if labels_header_len < MIN_LABELS_HEADER_LEN:
        labels_header_len = MIN_LABELS_HEADER_LEN
    if contrib_header_len_filtered < MIN_CONTRIB_HEADER_LEN:
        contrib_header_len_filtered = MIN_CONTRIB_HEADER_LEN
    if labels_header_len_filtered < MIN_LABELS_HEADER_LEN:
        labels_header_len_filtered = MIN_LABELS_HEADER_LEN

    row_len = (contrib_header_len + pulls_header_len + 
               labels_header_len + NUM_HEADERS)
    row_len_filtered = (contrib_header_len_filtered + pulls_header_len + 
               labels_header_len_filtered + NUM_HEADERS)
    vars = {
        'contrib_header_len': contrib_header_len, 
        'pulls_header_len': pulls_header_len,
        'labels_header_len': labels_header_len,
        'row_len': row_len,
        'contrib_header_len_filtered': contrib_header_len_filtered, 
        'labels_header_len_filtered': labels_header_len_filtered,
        'row_len_filtered': row_len_filtered,
    }
    return data, data_filtered, vars


def get_response(data, data_filtered, vars):
    """Generates the response for output"""
    header_filtered = [
        "\n{:{}{}}".format('List of most productive contributors', 
                           '^',
                           vars['row_len']),
        "{:{}{}}".format('Contributor', 
                         '^',
                         vars['contrib_header_len_filtered']) + 
        '|' +
        "{:{}{}}".format('Pull requests', 
                         '^',
                         vars['pulls_header_len']) +
        '|' +
        "{:{}{}}".format('Labels',
                         '^',
                         vars['labels_header_len_filtered'])
    ]
    border_filtered = [
        "{:{}{}{}}".format('', 
                           '-', 
                           '^', 
                           vars['contrib_header_len_filtered']) + 
        '+' +
        "{:{}{}{}}".format('', 
                           '-', 
                           '^', 
                           vars['pulls_header_len']) +
        '+' +
        "{:{}{}{}}".format('',
                           '-',
                           '^',
                           vars['labels_header_len_filtered'])
    ]
    header = [
        "\n{:{}{}}".format('List of all contributors', 
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
    pulls_row_len = vars['pulls_header_len'] - 1

    if not data_filtered:
        response = header_filtered + border_filtered
    else:
        contrib_row_len_filtered = vars['contrib_header_len_filtered'] - 1
        labeles_row_len_filtered = vars['labels_header_len_filtered'] - 1
        body = list()
        for k, v in data_filtered.items():
            row = " {:<{}}".format(k, contrib_row_len_filtered) + '|'
            row += " {:<{}}".format(v['pulls'], pulls_row_len) + '|'
            row += " {:<{}}".format(', '.join(v['labels']), labeles_row_len_filtered)
            body.append(row)
        response = header_filtered + border_filtered + body
    response_len = len(response)
    response += [f'({response_len - 3} rows)\n']

    if not data:
        response += header + border
    else:
        contrib_row_len = vars['contrib_header_len'] - 1
        labeles_row_len = vars['labels_header_len'] - 1
        body = list()
        for k, v in data.items():
            row = " {:<{}}".format(k, contrib_row_len) + '|'
            row += " {:<{}}".format(v['pulls'], pulls_row_len) + '|'
            row += " {:<{}}".format(', '.join(v['labels']), labeles_row_len)
            body.append(row)
        response += header + border + body
    response += [f'({len(response) - response_len - 4} rows)\n']
    return response


def main():
    args = get_args()
    repo_url = args.repo_url
    global LIMIT
    LIMIT = args.pages_number

    match = re.match(PATTERN, repo_url)
    if not match:
        print('❗Check the repository address. The address '
              'has to contain at least a Github repository '
              'including the Github domain, repository owner '
              'and its name.❗')
        return 

    params = {
        'state': 'open',
        'per_page': 100,
        'page': 1
    }
    token = args.access_token
    if token:
        global HEADERS
        HEADERS['Authorization'] = 'token %s' % token

    pull_url = API_URL % (match.group(4), match.group(5))
    resp = requests.get(pull_url, params, headers=HEADERS)
    if resp.status_code != 200:
        print("❗Make sure you've passed "
              "an existent repository address. "
              "Note private repositories are unreachable. Also, you could "
              "have exhausted the entire supply of requests❗")
        return

    data, data_filtered, vars = get_data_handler(resp)
    response = get_response(data, data_filtered, vars)
    print('\n'.join(response))
    print('Left ' + LEFT_REQUESTS + ' requests')


if __name__ == '__main__':
    main()
