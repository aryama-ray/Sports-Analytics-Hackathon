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
        'fid', 'Country', 'Batsman', 'Opponent', 'Innings',\
        'Runs', 'Balls', 'Out', 'Total 4s', 'Total 6s'
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
            batters = {}
            innings = ydata['innings']
            for inn in innings:
                inn_key = inn.keys()[0]
                inn_val = inn[inn_key]
                team = fetch_val(inn_val, 'team') #Batting Team
                deliveries = fetch_val(inn_val, 'deliveries', tostr=False)
                for delivery in deliveries:
                    ball_info = delivery.values()[0]
                    name = ball_info['batsman']
                    if name not in batters:
                        batters[name] = {\
                            'fid' : fname,\
                            'Country': team,\
                            'Opponent': None, #TODO
                            'Innings' : inn_key,\
                            'Runs' : 0,\
                            'Balls': 0,\
                            'Out' : None,
                            't4' : 0,\
                            't6' : 0
                        }
                    batter = batters[name]
                    balls_faced = batter['Balls']
                    batter.update({'Balls' : balls_faced + 1})
                    runs = fetch_val(ball_info, 'runs')
                    if runs:
                        r = runs['batsman']
                        run_now = batter['Runs']
                        batter.update({'Runs' : run_now  + r})
                        if r == 4:
                            t4_now = batter['t4']
                            batter.update({'t4' : t4_now + 1})
                        elif r == 6:
                            t6_now = batter['t6']
                            batter.update({'t6' : t6_now + 1})

                    wicket = fetch_val(ball_info, 'wicket')
                    if wicket and wicket['player_out'] == name:
                        batter.update({'Out' : wicket['kind']})


            for k, v in batters.iteritems():
                wrow = []
                wrow.append(v['fid'])
                wrow.append(v['Country'])
                wrow.append(k)
                wrow.append(v['Opponent'])
                wrow.append(v['Innings'])
                wrow.append(v['Runs'])
                wrow.append(v['Balls'])
                wrow.append(v['Out'])
                wrow.append(v['t4'])
                wrow.append(v['t6'])
                csv_w.writerow(wrow)
        except Exception as pe:
            print "Data parse failed on file %s err: %s" %(fname, str(pe))
            continue

    op.close()
    exit(0)

