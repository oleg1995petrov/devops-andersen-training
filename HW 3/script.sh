#! /usr/bin/python3

from argparse import ArgumentParser
from distutils import spawn
from subprocess import Popen, PIPE


def get_args():
    """Parses command line arguments"""
    parser = ArgumentParser()
    parser.add_argument('process', help='PID or name of process')
    parser.add_argument('-n', '--num-lines', type=int, default=5, help=(
                        'The maximum number of lines that will be '
                        'outputted if it is specifed otherwise -> 5.'))
    parser.add_argument('-e', '--extend', nargs='*', choices=(
                        ('country', 'city', 'address', 'updated')), help=(
                        'Displays additional information about ' 
                        'organizations. Accepts one or more following '
                        'fields separated by space: "updated", "country", '
                        '"city", "address".'))
    args = parser.parse_args()
    return args


def storage_is_full(storage, vars):
    """Checks if the storage contain enough rows"""
    return len(storage) >= vars['num_lines']


def get_organizations(data):
    """Returns organizations from raw data"""
    return [row.split(':')[-1].strip() for row in data.splitlines() if 
            row.startswith('Organization:')]


def add_organizations(organizations, storage):
    """Adds organizations to the storage"""
    for org in organizations:
        if org not in storage:
            storage[org] = {'connections': 1}
        else:
            storage[org]['connections'] += 1


def add_field_info(organization, field, value, storage ):
    """Adds specified field about organizations to the storage"""
    if not storage[organization].get(field):
        storage[organization][field] = (
            value.title() if field == 'city' else value
        )


def add_extra_info(organizations, fields, data, storage):
    """Adds additional fields about organizations to the storage"""
    data_arr = data.split('# end')
    for i in range(len(organizations)):
        for field in fields:
            value = ''
            for row in data_arr[i].splitlines():
                if row.startswith(field.capitalize()):
                    value = row.split(':')[1].strip()
            add_field_info(organizations[i], field, value, storage)


def get_response(data, vars, header_content):
    """Generates response with stored data"""
    if not data:
        return ["\n{:{}{}}".format('List of organizations', '^', 
                 vars['row_len']),
                 "{:{}{}}".format('Organization', '^', 
                 vars['org_header_len']) + '|' + 
                 "{:{}{}}".format('Connections', '^', 
                 vars['conn_header_len']),
                 ("{:{}{}{}}".format('', '-', '^', 
                 vars['org_header_len']) + '+' + 
                 "{:{}{}{}}".format('', '-', '^', 
                 vars['conn_header_len']))]

    headers = ['organization', 'connections'] + vars['extra_fields']
    response = ["\n{:{}{}}".format('List of organizations', '^', 
                vars['row_len'] + len(headers) - 1)]

    border_content = {
        'organization': vars['org_header_len'],
        'connections': vars['conn_header_len'],
        'updated': vars['updated_header_len'],
        'country': vars['country_header_len'],
        'city': vars['city_header_len'],
        'address': vars['address_header_len']
    }

    header = border = ''
    
    for h in headers:
        header += header_content[h]
        border += "{:{}{}{}}".format('', '-', '^', border_content[h])
        if h != headers[-1]:
            header += '|'
            border += '+'

    response.append(header)
    response.append(border)

    row_content = {
        'organization': vars['org_col_len'],
        'connections': vars['conn_col_len'],
        'updated': vars['updated_col_len'],
        'country': vars['country_col_len'],
        'city': vars['city_col_len'], 
        'address': vars['address_col_len']
    }

    for k, v in data.items():
        row = " {:<{}}".format(k, row_content['organization']) + '|'
        for h in headers[1:]:
            row += " {:<{}}".format(v[h], row_content[h])
            if h != headers[-1]:
                row += '|'
        response.append(row)
    return response


def main():
    args = get_args()
    netstat_exists = True if spawn.find_executable('netstat') else False
    vars = {
        'num_lines': args.num_lines,
        'extra_fields': args.extend or [],
    }

    if netstat_exists:
        cmd1 = Popen(('sudo', 'netstat', '-tunapl'), stdout=PIPE)
        cmd2 = Popen(('awk', f'/{args.process}/ ' + '{print $5}'), 
                       stdin=cmd1.stdout, stdout=PIPE)
    else:
        cmd1 = Popen(('sudo', 'ss', '-tunap'), stdout=PIPE)
        cmd2 = Popen(('awk', f'/{args.process}/ ' + '{print $6}'), 
                      stdin=cmd1.stdout, stdout=PIPE)
    cmd1.stdout.close()
    cmd3 = Popen(('cut', '-d:', '-f1'), stdin=cmd2.stdout, stdout=PIPE)
    cmd2.stdout.close()
    cmd4 = Popen(('sort',), stdin=cmd3.stdout, stdout=PIPE)
    cmd3.stdout.close()
    cmd5 = Popen(('uniq', '-c'), stdin=cmd4.stdout, stdout=PIPE)
    cmd4.stdout.close()
    cmd6 = Popen(('sort',), stdin=cmd5.stdout, stdout=PIPE)
    cmd5.stdout.close()
    cmd7 = Popen(('tail', '-n+1'), stdin=cmd6.stdout, stdout=PIPE)
    cmd6.stdout.close()
    cmd8 = Popen(('grep', '-oP', '(\d+\.){3}\d+'), stdin=cmd7.stdout, 
                  stdout=PIPE)
    cmd7.stdout.close()
    cmd_res = cmd8.communicate()[0]
    cmd8.stdout.close()

    ip_array = cmd_res.splitlines()[::-1]
    data = {}

    for ip in ip_array:
        extra_fields = vars['extra_fields']
        org_data = Popen(('whois', ip), stdout=PIPE, 
                          encoding='utf-8').communicate()[0]

        organizations = get_organizations(org_data)
        if organizations:
            if storage_is_full(data, vars):
                break
            add_organizations(organizations, data)
        else: 
            continue
            
        if extra_fields:
            add_extra_info(organizations, extra_fields, org_data, data)

    data = dict(sorted(data.items(), 
                key=lambda x: (x[0], x[1]['connections'])))

    vars['org_max_len'] = (max([len(org) for org in data.keys()]) 
                           if data else len('Organization'))
    vars['org_header_len'] = vars['org_max_len'] + 2
    vars['conn_header_len'] = len('Connections') + 2
    vars['org_col_len'] = vars['org_header_len'] - 1
    vars['conn_col_len'] = vars['conn_header_len'] - 1

    header_content = {
        'organization': '{:{}{}}'.format('Organization', '^', 
                        vars['org_header_len']),
        'connections': '{:{}{}}'.format('Connections', '^', 
                        vars['conn_header_len'])
    }

    if data:
        vars['updated_header_len'] = (len('yyyy-mm-dd') + 2 
            if 'updated' in extra_fields else 0)
        vars['country_header_len'] = (len('Country') + 2 
            if 'country' in extra_fields else 0)
        vars['city_header_len'] = (max([len(v['city']) for v in 
            data.values()]) + 2 if 'city' in extra_fields else 0)
        vars['address_header_len'] = (max([len(v['address']) for v in
            data.values()]) + 2 if 'address' in extra_fields else 0)
        vars['row_len'] = (vars['org_header_len'] + vars['conn_header_len'] + 
            vars['updated_header_len'] + vars['country_header_len'] + 
            vars['city_header_len'] + vars['address_header_len'])
        vars['updated_col_len'] = vars['updated_header_len'] - 1
        vars['country_col_len'] = vars['country_header_len'] - 1 
        vars['city_col_len'] = vars['city_header_len'] - 1
        vars['address_col_len'] = vars['address_header_len'] - 1

        header_content.update(
            {'updated': '{:{}{}}'.format('Updated', '^', 
                         vars['updated_header_len']),
             'country': '{:{}{}}'.format('Country', '^', 
                         vars['country_header_len']),
             'city': '{:{}{}}'.format('City', '^', 
                         vars['city_header_len']),
             'address': '{:{}{}}'.format('Address', '^', 
                         vars['address_header_len'])}
        )
    else:
        vars['row_len'] = (vars['org_header_len'] + 
                          vars['conn_header_len'] + 1)
    
    response = get_response(data, vars, header_content)[: 3 + vars['num_lines']]
    response += [f'({len(response) - 3} rows)\n']
    print('\n'.join(response))


if __name__ == '__main__':
    main()
