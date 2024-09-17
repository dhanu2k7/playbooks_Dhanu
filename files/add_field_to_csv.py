import argparse, os, json, csv, sys

parser = argparse.ArgumentParser(description="get a CSV file as entry and the ",
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-c", "--column", default="ip", help="column name to compare with host in the CSV entry file")
parser.add_argument("-O", "--output", help="CSV output file that will contains the list of hosts with the name in inventory, if empty it will edit the existing file")
parser.add_argument("-o", "--field", default="hostname", help="field to compare with the column name")
parser.add_argument("-d", "--delimiter", default=",", help="delimiter for CSV file")
parser.add_argument("input", help="CSV file")
parser.add_argument("json", help="JSON file to be inserted in the CSV")
args = parser.parse_args()

if args.output is None:
    args.output = args.input

# config = vars(args)
# print(config)

# execute command and extract hostnames from inventory 
with open(args.json, mode='r') as json_file:
    input_dict = json.load(json_file)

element_list = []
for element in input_dict:
    for data in element.keys():
        if data.encode("ascii", "ignore") not in element_list:
            element_list.append(data.encode("ascii", "ignore"))

print(element_list)
#read csv input and add a new variable in the dict contains corresponding value
#output are column_list and output_dict
output_dict = []
column_list = []
with open(args.input, mode='r') as file:
    first_line = file.readline().rstrip()
    column_list = first_line.split(args.delimiter)
    for element in element_list:
        if element not in column_list:
            column_list.append(element)
    print(column_list)
    if args.column not in column_list:
        print >>sys.stderr, 'ERROR: %s column does not exist in the file %s' % (args.column,args.input)
        sys.exit(1)

with open(args.input, mode='r') as csv_file:
    csv_reader = csv.DictReader(csv_file, delimiter=args.delimiter)
    for row in csv_reader:
        count = 0
        value = ""
        for element in input_dict:
            if element[args.field].encode("ascii", "ignore").lower() == row[args.column].lower():
                for key in element_list:
                    if key != args.column:
                        row[key] = ""
                for key in element.keys():
                    if key != args.column:
                        key_bis = key.encode("ascii", "ignore")
                        row[key_bis] = element[key_bis].encode("ascii", "ignore")
        output_dict.append(row)
print(output_dict)

#create the output file
with open(args.output, mode='w') as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=column_list)
    writer.writeheader()
    for row in output_dict:
        writer.writerow(row)
