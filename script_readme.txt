Capturing the steps on how the individual stats were fetched from the raw datasource. 


1. Datasources:i (Input)
    a. Download from cricksheet.com 
    b. Bunch of YAML files where each yaml object represents an entire match with ball-by-ball details. 

2. Stats derived: (Output)
    a. ODI Match Summary
    b. Batting Summary for per player per match
    c. Bowling Summary for per player per match. 

3. Scripts:
    Following three python scripts used to derive the data from the raw datafiles. 
    a. build_odi_summary.py
    b. build_odi_batting_summary.py
    c. build_odi_summary.py 

    Each of the scripts are self explanatory and has adequte comments. 

    Brief script spec:
        a. Takes as input two command line parameters
            -d : The source directory where the yaml files are located
            -o : The output CSV filename
            Example usage:
            $> ./build_odi_summary.py -d datasource/ -o odi_summary.csv
            $> ./build_odi_batting_summary.py -d datasource/ -o batting_summary2.csv
            $> ./build_odi_bowling_summary.py -d datasource/ -o bowling_summary.csv

        b. The script lists all the .yaml files into a list and then iterates over each of them.
           The yaml python package easily helps us load the entire yaml file into a yaml object
           which is essentially a dictioary. 
           We iterate over each field in the dictionary, to fetch match date, like venue, place,
           toss results etc. 
           Then we iterate over each delivery (which is essentially again a list) to derive the
           batting, bowling and total tuns and other necessary stats.
