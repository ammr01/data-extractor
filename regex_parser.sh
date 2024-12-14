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



readonly __NOTE=1
readonly __WARN=2
readonly __WARNING=$__WARN
readonly __ERROR=3
readonly __EXIT=0
readonly __RETURN=1
readonly __NOTHING=2
readonly __STDOUT=1
readonly __STDERR=2
readonly __ERROR_MESSAGE_ENABLE=0
readonly __ERROR_MESSAGE_DISABLE=1
readonly __SUCESS=0
readonly default_error_code=1


error_flag=$__ERROR_MESSAGE_ENABLE
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
    
    if [ $error_flag -eq $__ERROR_MESSAGE_ENABLE ]; then 
        return $__SUCESS
    fi

    local text="$1"
    local type=${2-1}
    local isexit=${3-1}
    local error_code=${4-$default_error_code}
    local typestr=""
    local fd=1

    if ! [[ "$type" =~ ^[0-9]+$ ]]; then
        type=$__NOTE
    fi

    if ! [[ "$isexit" =~ ^[0-9]+$ ]]; then
        isexit=$__RETURN
    fi

    if ! [[ "$error_code" =~ ^[0-9]+$ ]]; then
        error_code=$default_error_code
    fi
    case $type in 
    $__NOTE)
        typestr="NOTE"
        fd=$__STDOUT
    ;;
    $__WARN)
        typestr="WARNING"
        fd=$__STDOUT
    ;; 
    $__ERROR)
        typestr="ERROR"
        fd=$__STDERR
    ;;
    *)
        typestr="NOTE"
        fd=$__STDOUT
    ;;
    esac
    
    >&$fd echo -e "[$typestr:START]\n$text\n[$typestr:END]"
    if [ "$isexit" -eq $__EXIT ]; then
        exit "$error_code"
    elif [ "$isexit" -eq $__RETURN ]; then
        return "$error_code"
    fi

    
}

check_dependencies(){
 
    which perl 1>/dev/null      ||    err "please install perl, dos2unix, and gawk before use this script, for debian based system use \"sudo apt install perl dos2unix gawk\"" $__ERROR $__EXIT 2
    which dos2unix 1>/dev/null  ||    err "please install perl, dos2unix, and gawk before use this script, for debian based system use \"sudo apt install perl dos2unix gawk\"" $__ERROR $__EXIT 3
    which gawk 1>/dev/null      ||    err "please install perl, dos2unix, and gawk before use this script, for debian based system use \"sudo apt install perl dos2unix gawk\"" $__ERROR $__EXIT 4

}


show_help(){
    echo "Usage: $0 [OPTIONS]"

    echo "Options:"
    echo "  -h, --help                          Show help and exit"
    echo "  -i, --input-file <file>             Input data file"
    echo "  -o, --output-file <file>            Output data file 'output format is csv'"
    echo "  -c, --config-file <file>            Config file with parsing instructions"

    echo ""
    echo "Example:"
    echo "  $0 -i input1.txt -i input2.csv -o output.csv -c config1.txt -c config3.conf"
}


handle_output(){
    if [ $# -lt 3 ]; then
        err "Few arguments to handle_output() function!" $__ERROR $__RETURN 5; return $?
    elif [ $# -gt 3 ]; then
        err "Many arguments to handle_output() function!" $__ERROR $__RETURN 6; return $?
    fi

    local tmp_output="$1"
    local tmp_output2="$2"
    local dst_file="$3"
    head "$dst_file"
    sed -i 's/"/""/g' "$dst_file"
    sed -i 's/^.*$/"&"/' "$dst_file"
    head "$dst_file"
    
    if [ `wc -l "$tmp_output" | cut -d' ' -f 1` -le 0 ]; then    
        cat "$dst_file" > "$tmp_output2"    
    else
        paste -d ,  "$tmp_output" "$dst_file" > "$tmp_output2"    
    fi

    cp "$tmp_output2" "$tmp_output"

}


prepare_configs(){
    sed  -i '/^[[:space:]]*$/d' "$configs" 
    sed  -i  's/^[[:space:]]*//' "$configs"
    sed  -i '/^[[:space:]]*#/d' "$configs" 
}


remove_tmp_files(){

    rm "$configs"       || { err "error while removing tmp files!" $__ERROR $__RETURN 7; return $?  ; }
    rm "$inputs"        || { err "error while removing tmp files!" $__ERROR $__RETURN 8; return $?  ; }
    rm "$tmp_output2"   || { err "error while removing tmp files!" $__ERROR $__RETURN 10; return $? ; } 


}



extract(){
    if [ $# -lt 2 ]; then
        err "Few arguments to extract() function!" $__ERROR $__RETURN 11; return $?
    elif [ $# -gt 3 ]; then
        err "Many arguments to extract() function!" $__ERROR $__RETURN 12; return $?
    fi

    local input_file="$1"
    local regex="$2"
    local capture_group="$3"
    
    if [ ! -n "$capture_group" ]; then 

cat "$input_file" | perl -s -nle '
    my $found = 0;
    if (/$regex/mg) {
        print "$&";
        $found = 1;
    }
    print "N/A" unless $found;
' -- -regex="$regex"

    else
 
cat "$input_file" | perl -s -nle '
    my $found = 0;
    if (/$regex/mg) {
        print "$$capture_group";
        $found = 1;
    }
    print "N/A" unless $found;
' -- -capture_group="$capture_group" -regex="$regex"


    fi
}

get_field(){
    gawk -F":" '{print $1}' <<< "$1"
}

get_capture_group(){
    gawk -F: '{print $2}' <<< "$1"
}

get_regex(){
    gawk -F:  '{print $3}' <<< "$1"
}




if [ $# -lt 1 ]; then
    show_help; exit 1
fi
check_dependencies
configs=`mktemp`
inputs=`mktemp`
tmp_output=`mktemp`
tmp_output2=`mktemp`
while [ $# -gt 0 ]; do
    case $1 in 
    -h|--help)
        show_help; exit 0
    ;;
    
    
    -i|--input-file)
        if [ -n "$2" ]; then        
            input_file="$(realpath "$2" )"
            if [ ! -f "$input_file" ]; then
                err "input file is not found : $input_file" $__ERROR $__EXIT 13
            fi
            shift 2
            cat "$input_file" >> "$inputs" 
        else
            err "-i|--input-file option requires argument." $__ERROR $__EXIT 14
        fi
    ;;
    -o|--output-file)
        if [ -n "$2" ]; then        
            output_file="$(realpath "$2" )"
            shift 2
        else
            err "-o|--output-file option requires argument." $__ERROR $__EXIT  15
        fi
    ;;

    -c|--config-file)
        if [ -n "$2" ]; then        
            config_file="$(realpath "$2" )"
            
            if [ ! -f "$config_file" ] ; then
                err "config file is not found : $config_file" $__ERROR $__EXIT 16
            fi
            shift 2
            cat "$config_file" >> "$configs"
        else
            err "-c|--config-file option requires argument." $__ERROR $__EXIT  17
        fi
    ;;

    *)
        show_help;exit 1
    ;;
    esac
done

dos2unix "$inputs" 1>/dev/null 2>/dev/null || err "dos2unix Error!" $__ERROR $__EXIT  18
dos2unix "$configs" 1>/dev/null 2>/dev/null || err "dos2unix Error!" $__ERROR $__EXIT  19

prepare_configs  2>/dev/null || err "configs file preperation error!" $__ERROR $__EXIT  20 

if [ -n "$output_file" ] || [ -z "$output_file" ]; then
    output_file=`mktemp --suffix=.csv`  
fi


while read -r line || [ -n "$line" ]; do
    field=$(get_field "$line")
    capture_group=$(get_capture_group "$line")
    regex=$(get_regex "$line")
    echo "$field" > "$output_file"
    extract "$inputs"  "$regex" "$capture_group" >> "$output_file"
    handle_output "$tmp_output" "$tmp_output2"  "$output_file"   
done <"$configs"
mv "$tmp_output" "$output_file" 

remove_tmp_files || err "error while removing temp files $configs $inputs  $tmp_output2 " $__ERROR $__NOTHING  0
echo "$output_file"
