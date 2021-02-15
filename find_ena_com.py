#!/usr/bin/env python3

import os
import sys
import subprocess
import json
import re

def ctags_output_to_json(ctags_output):
    ctags_output = ctags_output.stdout.decode('utf8')[:-1].split('\n') # last char is a newline which don't need

    try:
        if len(ctags_output) > 1:
            ctags_output = '[' +','.join(ctags_output) + ']'
        else:
            ctags_output = ''.join(ctags_output)

        functions_json = json.loads(ctags_output)
    except:
        print("failed to transform {} into json".format (ctags_output))
        raise

    return functions_json

def get_ena_com_in_range(file_name, start_line, end_line):
    
    functions_content = subprocess.run([r"sed -n '{},{}p' {}".format(start_line, end_line, file_name)],
                                        stdout=subprocess.PIPE, shell=True)
    functions_content = functions_content.stdout.decode('utf8')

    ena_com_functions = re.findall(r"(_*ena_com_[^ ()]*)\(", functions_content)

    return ena_com_functions

def append_to_ena_com_function_loc(function_name, calling_function):
    try:
        ena_com_functions_loc = subprocess.run(["ctags -x --language-force=c ~/ena-drivers/ena-com/* | grep function | grep {} | xargs echo".format(function_name)], stdout=subprocess.PIPE, stdin=subprocess.PIPE, shell=True)
        ena_com_functions_loc = ena_com_functions_loc.stdout.decode('utf8').split(' ')
        
        os.system("sed -i '{}i // function is called from {}()' {}".format(ena_com_functions_loc[2], calling_function, ena_com_functions_loc[3]))
    except:
        print("failed for function {}".format(function_name))
        exit(0)

def append_calling_function(com_function, netdev_function):
    try:
        ena_com_functions_loc = subprocess.run([r"~/workspace/Software/ctags/ctags --kinds-c=f --fields=+Nne -o - --output-format=json ~/ena-drivers/ena-com/* | grep \"{}\"".format(com_function)], stdout=subprocess.PIPE, stdin=subprocess.PIPE, shell=True)

        ena_com_functions_loc_json = ctags_output_to_json(ena_com_functions_loc)
    except:
        print("failed to get tags for {}".format(com_function))
        raise

    try:
        func_file = ena_com_functions_loc_json["path"]
        func_start = int(ena_com_functions_loc_json["line"])
        func_end = int(ena_com_functions_loc_json["end"])

        # increase line start so to not match the same function
        ena_com_functions = get_ena_com_in_range(func_file, func_start + 1, func_end)

        os.system("sed -i '{}i // function is called from {}()' {}".format(func_start, netdev_function, func_file))

        if len(ena_com_functions):
            # print(ena_com_functions_loc_json)
            for com_func in ena_com_functions:
                print("com_function", com_func)
                try:
                    append_calling_function(com_func, netdev_function + " -> " + com_function)
                except:
                    print("failed to process further ena_com functions for entry {}".format(ena_com_functions_loc_json))
                    exit(1)
        
    except:
        print("couldn't work out function {}".format(com_function))
        print(ena_com_functions_loc.stdout.decode('utf8'))
        exit(1)
    

def main():
    netdev_function_list = subprocess.run(["~/workspace/Software/ctags/ctags --kinds-c=f --output-format=json --fields=NneF -o - ~/ena-drivers/linux/ena_netdev.c"], stdout=subprocess.PIPE, shell=True)
    netdev_function_list = ctags_output_to_json(netdev_function_list)

    for netdev_func in netdev_function_list:
        func_start = netdev_func["line"]
        func_end = netdev_func["end"]
        func_name = netdev_func["name"]

        ena_com_functions = get_ena_com_in_range("~/ena-drivers/linux/ena_netdev.c", func_start, func_end)
        if not len(ena_com_functions):
            continue

        for com_func in ena_com_functions:
            print("com_function", com_func)
            try:
                append_calling_function(com_func, func_name)
            except:
                print("failed to process further ena_com functions for entry {} (netdev)".format(netdev_func))
                exit(1)
                

    exit(0)


if __name__ == '__main__':
    main()
