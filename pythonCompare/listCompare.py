import csv


source_dict ={}
with open(r'c:\\Temp\\HashkeyMap.src',mode='r') as csv_file:    
    csv_reader = csv.DictReader(csv_file)
    for row in csv_reader:
        key = row['KEYS']
        source_dict[key]=row[" HASH"]
        print(key)
target_dict={}
with open(r'c:\\Temp\\HashkeyMap.trg',mode='r') as csv_file:
    csv_reader = csv.DictReader(csv_file)
    for row in csv_reader:
        key = row['KEYS']
        target_dict[key]=row[" HASH"]
        print(key)

val =  {**source_dict , **target_dict}
for row in val:
    print(row)


def dict_compare(d1, d2):
    d1_keys = set(d1.keys())
    d2_keys = set(d2.keys())
    intersect_keys = d1_keys.intersection(d2_keys)
    added = d1_keys - d2_keys
    removed = d2_keys - d1_keys
    modified = {o : (d1[o], d2[o]) for o in intersect_keys if d1[o] != d2[o]}
    same = set(o for o in intersect_keys if d1[o] == d2[o])
    return added, removed, modified, same

def read_csv():
    with open(r'c:\\Temp\\HashkeyMap.src',mode='r') as csv_file:
        csv_reader = csv.DictReader(csv_file)
        line_count = 0
        for row in csv_reader:
            

            if line_count == 0:
                print(f'Column names are {", ".join(row)}')
                line_count += 1
            print(f'\t Key:{row["KEYS"]} Value:{row}.')
            line_count += 1
        print(f'Processed {line_count} lines.')


def merge_dicts(*dict_args):
    """
    Given any number of dicts, shallow copy and merge into a new dict,
    precedence goes to key value pairs in latter dicts.
    """
    result = {}
    for dictionary in dict_args:
        result.update(dictionary)
    return result