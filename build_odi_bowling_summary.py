#!/usr/bin/python

import yaml
import os
import csv
import argparse


#DATASRC = "/home/tanmoy/work/src/self.codes/upgrad_cric/datasrc/"
#OPFILE = "/home/tanmoy/work/src/self.codes/upgrad_cric/odi_summary.csv"


def fetch_val(idict, key, tostr=True):
    val = None
    try:
        temp = idict[key]
        if tostr and isinstance(temp, list):
            val = '|'.join(temp)
        else:
            val = temp
    except KeyError:
        pass
    except Exception:
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
    headers = [
        'fid', 'Country', 'Bowler', 'Opponent', 'Innings',\
        'Total Balls', 'Runs Conceded', 'Wickets', 'Maiden',\
        'Total 4s', 'Total 6s',
    ]

    csv_w.writerow(headers)

    print "Processing #%s input files" %len(file_list)

    for fname in file_list:
        try:
            file_str = open("%s/%s" %(datasrc, fname), 'r').read()
        except Exception as e:
            print "Failed to open file %s err: %s" %(fname, str(e))
            continue

        try:
            ydata = yaml.load(file_str)
        except Exception as ye:
            print "Failed to parse yaml in file: %s err: %s" %(fname, str(ye))
            continue

        try:
            bowlers = {}
            innings = ydata['innings']
            for inn in innings:
                inn_key = inn.keys()[0]
                inn_val = inn[inn_key]
                team = fetch_val(inn_val, 'team') #Batting Team
                deliveries = fetch_val(inn_val, 'deliveries', tostr=False)
                over_idx = '0'
                bc = 0
                for delivery in deliveries:
                    dnum = str(delivery.keys()[0])
                    curr_ovr = dnum.split('.')[0]
                    if curr_ovr != over_idx: #Over changed
                        over_idx = curr_ovr
                        bc = 0
                    bc += 1
                    ball_info = delivery.values()[0]
                    name = ball_info['bowler']
                    if name not in bowlers:
                        bowlers[name] = {\
                            'fid' : fname,\
                            'Country': team,\
                            'Opponent': None, #TODO
                            'Innings' : inn_key,\
                            'Balls': 0,\
                            'Runs' : 0,\
                            'Wicket' : 0,\
                            'Maiden' : 0,\
                            't4' : 0,\
                            't6' : 0
                        }
                    bowler = bowlers[name]
                    total_balls = bowler['Balls']
                    bowler.update({'Balls' : total_balls + 1})
                    runs = fetch_val(ball_info, 'runs')
                    if runs:
                        r = runs['total']
                        run_now = bowler['Runs']
                        truns = run_now + r
                        bowler.update({'Runs' : truns})
                        if r == 4:
                            t4_now = bowler['t4']
                            bowler.update({'t4' : t4_now + 1})
                        elif r == 6:
                            t6_now = bowler['t6']
                            bowler.update({'t6' : t6_now + 1})

                        if bc % 6 == 0 and truns == 0: #Maiden over
                            m_now = bowler['Maiden']
                            bowler.update({'Maiden' : m_now + 1})

                    wicket = fetch_val(ball_info, 'wicket')
                    if wicket and wicket['kind'] != "run out":
                        wick_now = bowler['Wicket']
                        bowler.update({'Wicket' : wick_now + 1})


            for k, v in bowlers.iteritems():
                wrow = []
                wrow.append(v['fid'])
                wrow.append(v['Country'])
                wrow.append(k)
                wrow.append(v['Opponent'])
                wrow.append(v['Innings'])
                wrow.append(v['Balls'])
                wrow.append(v['Runs'])
                wrow.append(v['Wicket'])
                wrow.append(v['Maiden'])
                wrow.append(v['t4'])
                wrow.append(v['t6'])
                csv_w.writerow(wrow)
        except Exception as pe:
            print "Data parse failed on file %s err: %s" %(fname, str(pe))
            continue

    op.close()
    exit(0)

