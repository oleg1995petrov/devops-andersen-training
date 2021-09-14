# Homework 3 overview

Transform the next one line command to nice script:

```bash
netstat -tunapl | awk '/firefox/ {print $5}' | cut -d: -f1 | sort | uniq -c | sort | tail -n5 | grep -oP '(\d+\.){3}\d+' | while read IP; do whois $IP | awk -F':' '/^Organization/ {print $2}'; done
```

* Create README.md and describe what will be doing that script
* The script has to accept PID or a process name as an argument 
* An user has to manage number of output lines
* There must be an opportunity to see other connections states
* The script has to output understandable error messages
* The script shouldn't depend on start up privileges and output any warnings
* The script outputs number of connections to each organizations
* The script allows to receive other data form `whois` output
* The script is able to work with `ss`

## Solution

The script `script.sh` accepts:  
  * positional argument - PID or process name  
  * optional arguments:  
    * `-n` or `--num-lines` - maximum number of lines that will be outputted  
    * `-e` or `--extend` - displays additional information about organizations. Accepts one or more followings fields separated by space: "updated", "country", "city", "address".

## Usage

1. Clone the repo
    ```bash
    git clone https://github.com/oleg1995petrov/devops-andersen-training.git
    cd 'devops-andersen-training/HW 3'
    ```
3. Start the script
    
    ```bash
    ./script.sh firefox -n 3 -e updated country city address	

    # or
    ./script.sh 654321 -n 3 -e country updated

    # or
    ./script.sh firefox
    ```
