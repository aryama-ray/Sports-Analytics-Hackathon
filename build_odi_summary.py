#!/usr/bin/python

import yaml
import os
import csv
import argparse


#DATASRC = "/home/tanmoy/work/src/self.codes/upgrad_cric/datasrc/"
#OPFILE = "/home/tanmoy/work/src/self.codes/upgrad_cric/odi_summary.csv"


curfile = None

def fetch_val(idict, key, tostr=True):
    val = None
    try:
        temp = idict[key]
        if tostr and isinstance(temp, list):
            val = '|'.join(temp)
        else:
            val = temp
    except KeyError:
        #print "KeyError in file %s key %s" %(curfile, key)
        pass
    except Exception:
        #print "GenException in file %s key %s" %(curfile, key)
        pass
    return val

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--datadir", dest="datasrc", \
            help="Data source directory")
    parser.add_argument("-o", "--outfile", dest="outfile", \
            help="Data source directory")

    options, args = parser.parse_known_args()

    if not options.datasrc:
        print "No data source directory specified"
        exit(1)
    if not options.outfile:
        print "No output file specified"
        exit(1)

    datasrc = os.path.abspath(options.datasrc)
    opfile = os.path.abspath(options.outfile)

    try:
        file_list = os.listdir(datasrc)
    except Exception as e:
        print "Unable to list files in folder %s" %datasrc
        exit(1)

    csv_w = None
    print "Creating output file: %s" %opfile
    try:
        op = open(opfile, 'w')
        csv_w = csv.writer(op)
    except Exception as oe:
        print "Unable to open outputfile %s" %opfile
        exit(1)

    print "Writing column header to output"
    header = [
        'Match City', 'Venue/Ground', 'Date', 'Match Type', 'Gender',\
        'Team1', 'Team2', 'Winner' ,'Overs Played', 'MoM',\
        'Toss Decision', 'Toss Winner', 'Innings',\
        'Batting Team', 'Total Runs', 'Total 6s', 'Total 4s', 'Total Wickets',\
        'Total Balls', 'fid'
    ]
    csv_w.writerow(header)

    print "Processing #%s input files" %len(file_list)

    for fname in file_list:
        try:
            file_str = open("%s/%s" %(datasrc, fname), 'r').read()
        except Exception as e:
            print "Failed to open file %s err: %s" %(fname, str(e))
            continue
        curfile = fname

        try:
            ydata = yaml.load(file_str)
        except Exception as ye:
            print "Failed to parse yaml in file: %s err: %s" %(fname, str(ye))
            continue

        try:
            row = []
            info = ydata['info']
            innings = ydata['innings']

            row.append(fetch_val(info, 'city'))
            row.append(fetch_val(info, 'venue'))
            dates = fetch_val(info, 'dates', tostr=False)
            date_str = None
            if dates:
                date_str = dates[0].__str__()
            row.append(date_str)
            row.append(fetch_val(info, 'match_type'))
            row.append(fetch_val(info, 'gender'))

            teams = fetch_val(info, 'teams', tostr=False)
            row.append(teams[0])
            row.append(teams[1])

            outcome = fetch_val(info, 'outcome')
            if not outcome or not isinstance(outcome, dict):
                outcome = {}
            row.append(outcome.get('winner', None))

            row.append(fetch_val(info, 'overs'))
            row.append(fetch_val(info, 'player_of_match'))

            toss_dict = fetch_val(info, 'toss')
            if not toss_dict or not isinstance(toss_dict, dict):
                toss_dict = {}
            toss_d = toss_dict.get('decision', None)
            row.append(toss_d)
            toss_w = toss_dict.get('winner', None)
            row.append(toss_w)

            if not len(innings):
                print "No innings found in %s" %fname
                continue

            for inn in innings:
                irow = []
                try:
                    inn_key = inn.keys()[0]
                    irow.append(inn_key)
                    inn_val = inn[inn_key]
                    irow.append(fetch_val(inn_val, 'team')) #Batting Team
                    deliveries = fetch_val(inn_val, 'deliveries', tostr=False)
                    totalruns = 0
                    total6s = 0
                    total4s = 0
                    totalballs = 0
                    totalwickets = 0
                    for delivery in deliveries:
                        ball_info = delivery.values()[0]
                        totalballs += 1
                        runs = fetch_val(ball_info, 'runs')
                        if runs:
                            r = runs['total']
                            totalruns += r
                            if r == 4:
                                total4s += 1
                            elif  r == 6:
                                total6s += 1
                        wicket = fetch_val(ball_info, 'wicket')
                        if wicket:
                            totalwickets += 1
                    irow.append(totalruns)
                    irow.append(total6s)
                    irow.append(total4s)
                    irow.append(totalwickets)
                    irow.append(totalballs)
                except Exception as ie:
                    print "Malformed innings data in file %s err: %s"\
                        %(fname, str(ie))
                    pass
                irow.append(fname)
                wrow = row + irow
                csv_w.writerow(wrow)
        except Exception as pe:
            print "Data parse failed on file %s err: %s" %(fname, str(pe))
            continue

    op.close()
    exit(0)
