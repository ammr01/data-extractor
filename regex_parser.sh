#!/bin/bash
# Author : amr
# OS : Debian 12 x86_64
# Date : 09-Dec-2024
# Project Name : regex_parser



# License: MIT License
# 
# Copyright (c) 2024 Amro Alasmer
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 


# 
list=()

error_flag=0
default_error_code=1

err(){
    # err [message] <type> <isexit> <exit/return code>
    #
    #   I- message (mandatory): text to print
    #
    #  II- type (optional "default is (1/note)"): 
    #      1 : note (Default)
    #      2 : warning
    #      3 : error: the text is printed into stderr, and it needs two more arguments
    #
    #
    # III- isexit (optional "default is 1"):
    #      0 : exit after printing 
    #          (set exit code in the next
    #           arg, default error code
    #           is used if error code
    #           is not set).
    #      1 : return a status code after printing 
    #          (set return code in the next
    #           arg, default return code
    #           is used if return code
    #           is not set).
    #      2 : do not exit or return
    #
    #  IV- error/return code : 
    #      to set error/return code, must be numeric, 
    #      if not numeric or not set, the default 
    #      value will be used. 
    
    local text="$1"
    local type=${2-1}
    local isexit=${3-1}
    local error_code=${4-$default_error_code}
    local typestr=""
    local fd=1
    
    if ! [[ "$type" =~ ^[0-9]+$ ]]; then
        type=1
    fi

    if ! [[ "$isexit" =~ ^[0-9]+$ ]]; then
        isexit=1
    fi

    if ! [[ "$error_code" =~ ^[0-9]+$ ]]; then
        error_code=$default_error_code
    fi
    case $type in 
    1)
        typestr="NOTE"
        fd=1 #stdout
    ;;
    2)
        typestr="WARNING"
        fd=1 #stdout
    ;; 
    3)
        typestr="ERROR"
        fd=2 #stderr
    ;;
    *)
        typestr="NOTE"
        fd=1 #stdout
    ;;
    esac
    
    if [ $error_flag -eq 0 ]; then 
        >&$fd echo -e "[$typestr:START]\n$text\n[$typestr:END]"
        if [ "$isexit" -eq 0 ]; then
            exit "$error_code"
        elif [ "$isexit" -eq 1 ]; then
            return "$error_code"
        fi

    fi
    
}



check_dependencies(){
 
    which perl 1>/dev/null  ||    err "please install perl before use this script, for debian based system use \"sudo apt install perl dos2unix\"" 3 0 9
    which dos2unix 1>/dev/null  ||    err "please install perl before use this script, for debian based system use \"sudo apt install perl dos2unix\"" 3 0 10
}

show_help(){
    echo "Usage: $0 "
}


extract(){
    if [ $# -lt 2 ]; then
        err "Few arguments to extract() function!" 3 1 88; return $?
    elif [ $# -gt 3 ]; then
        err "Many arguments to extract() function!" 3 1 89; return $?
    fi

    local input="$1"
    local regex="$2"
    local capture_group="$3"
    
    if [ -z "$capture_group" ]; then
        perl -nle "print   /"$regex"/g" <<< "$input"

    else
        perl -nle "print \"\$capture_group\"  /"$regex"/g" <<< "$input"

    fi
}


if [ $# -lt 1 ]; then
    show_help; exit 1
fi
check_dependencies
configs=`mktmp`
inputs=`mktmp`
while [ $# -gt 0 ]; do
    case $1 in 
    -h|--help)
        show_help; exit 0
    ;;
    
    
    -i|--input-file)
        if [ -n "$2" ]; then        
            input_file="$(realpath "$2" )"
            if [ ! -f "$input_file" ]; then
                err "input file is not found : $input_file" 3 0 15
            fi
            shift 2
            dos2unix "$input_file" 1>/dev/null 2>/dev/null || err "dos2unix Error!" 3 0 28
            cat "$input_file" >> "$inputs" 
        else
            err "-i option requires argument." 3 0 8
        fi
    ;;
    -o|--output-file)
        if [ -n "$2" ]; then        
            output_file="$(realpath "$2" )"
            shift 2
        else
            err "-o option requires argument." 3 0 9
        fi
    ;;

    -c|--config-file)
        if [ -n "$2" ]; then        
            config_file="$(realpath "$2" )"
            
            if [ ! -f "$config_file" ] ; then
                err "cannot find file: $config_file, staus code: $?" 2 2 0   
            fi
            shift 2
            dos2unix "$config_file" 1>/dev/null 2>/dev/null || err "dos2unix Error!" 3 0 28
            cat "$config_file" >> "$configs"
        else
            err "-c option requires argument." 3 0 9
        fi
    ;;

    *)
        show_help;exit 1
    ;;
    esac
done

get_fields "$configs"
fields=("${list[@]}")



format "$output_file" ||   err "cannot create or write into file: $output_file, staus code: $?" 2 2 0   


for field in "${fields[@]}"; do

    extract "$inputs" "$regex" "$capture_group" 
done
