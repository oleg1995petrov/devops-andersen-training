# Project overview

* Write a script that checks if there are open pull requests for a repository.
  A URL like "https://github.com/$user/$repo" will be passed to the script.
* Print the list of the most productive contributors (authors of more than 1 open PR).
* Print the number of PRs each contributor has created with the labels.
* Implement my own feature that I find the most attractive: anything from sorting
  to comment count or even fancy output format.
* Ask my chat mate to review my code and create a meaningful pull request.
* Do the same for him.
* Merge my fellow PR.

## Solution

The script (`script.sh`) accepts:  
  * positional argument - Github repository address 
  * optional arguments:
    * `-t` or `--access-token` - your Github access token. 
    * `-p` or `--pages-number` - the number of data pages to parse 
      (one page contents up to 100 opened pull requests).
      Default value is 1 - up to 100 PRs.

## Requirements 

  * Python 3

## The User Guide

1. Clone the repo:

    ```bash
    git clone https://github.com/oleg1995petrov/devops-andersen-training.git && cd 'devops-andersen-training/HW 5'
    ```

2. Start the script:
    
    ```bash
    ./script.sh https://www.github.com/{owner}/{repository}

    # or 
    ./script.sh github.com/{owner}/{repository}

    # or 
    ./script.sh {owner}/{repository}

    ```
