# regex_parser

## Overview
`regex_parser` is a bash script designed to extract and parse data using regex from input files and output the results in a CSV format. It is a lightweight and efficient tool tailored for parsing fields defined by configuration files.

---

## Features
- Parse input data using regex patterns.
- Supports multiple input files and configuration files.
- Outputs data in CSV format.
- Per line parsing (match the provided regexs for each line, and consider the output for line a row in the output csv file)
---

## Requirements
- **Dependencies:**
  - Perl
  - dos2unix
  - gawk
### Installing Dependencies
To install the required dependencies on Debian-based systems, run:
```bash
sudo apt update && sudo apt install perl dos2unix gawk -y
```

---

## Usage

### Syntax
```bash
./regex_parser [OPTIONS]
```

### Options
- `-h`, `--help` : Show help and exit.
- `-i`, `--input-file <file>` : Specify input data file(s). Multiple files can be specified.
- `-o`, `--output-file <file>` : Specify the output CSV file.
- `-c`, `--config-file <file>` : Specify configuration file(s) with parsing instructions.

### Example
```bash
./regex_parser -i input1.txt -i input2.csv -o output.csv -c config1.txt -c config2.conf
```

---

## Configuration File Format
The configuration file defines the fields to extract, along with their regex and capture groups. Each line should follow this format:
```plaintext
<field_name>:<capture_group>:<regex>
```
- **field_name**: The name of the field to extract.
- **capture_group**: (Optional) The capture group number to extract.
- **regex**: The regex pattern to use for parsing.
- **comments**: Use `#` at the start of the line, to make it a comment.
### Example Configuration
```plaintext
email::[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}
phone:1:(\d{3}-\d{3}-\d{4})
```

---


## How It Works
- Uses `perl` with regex to extract fields from input files, it match regex per line,
  Writes parsed data to the specified output file (csv file).

---



## Where To Use
- It could be used for log parsing, data extraction, and many more use cases.

---


## Simple Benchmark
- Tested on a 2GB Fortigate Logs file. The file contained raw logs and additional data (log source name, time, etc.).
- With 28 regex patterns for extraction, it took nearly 1 minute and 30 seconds to process.

---

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Author
**Amro Alasmar**

## Idea By
**Mohammad Khaled**
