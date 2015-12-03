#!/usr/bin/env python
#
# Wrapper script to find the status of a submitted job for PBS
#

import sys
import os
import re
import subprocess as sp

import logging as log
logger = log.getLogger('MOAB status')
logger.setLevel(log.WARNING)
handler = log.StreamHandler(sys.stdout)
logger.addHandler(handler)

queue_dir = os.path.dirname(os.path.abspath(__file__))
queues_dir = os.path.dirname(queue_dir)
common_dir = os.path.join(queues_dir, "common")
sys.path.insert(0, common_dir)
import queueinit

usage_str = "Usage: status.py <batchid(s)>"

status_re = r'State: (\w*)'

def jobcontrol_status(pbs_status):
    jc_status = {
        'Idle' : 'submitted',
        'Starting' : 'submitted',
        'Running' : 'running'
        }
    return jc_status.get(pbs_status, "unknown")

def form_command(keywords, batchid):
    cmd = ""
    cmd += "%s " % keywords["MSTAT"]
    cmd += "%s " % str(batchid)
    return cmd

def process_output(qstat_output):
    m = re.search(status_re, qstat_output, re.M)
    match = "unknown"
    if m:
       match = m.group(1) 
    return jobcontrol_status(match)

def run(batchids):
    """
    Run the QSTAT command to get the status of given batchids.

    Sample output of command (note the batch id can be truncated):

    $ qstat
    Job id            Name             User              Time Use S Queue
    ----------------  ---------------- ----------------  -------- - -----
    97.pdx-pbspro-lv0 job300-muriel-4  mashkevi          00:00:00 R workq

    """

    keywords = queueinit.readConfig(queue_dir=queue_dir)

    for batchid in batchids:
        cmd = form_command(keywords, batchid)
        logger.debug("Executing cmd: %s"% cmd)
        qstat = sp.Popen(cmd, shell=True, stdout = sp.PIPE)
        outp = qstat.stdout.read()
        pbs_status = process_output(outp)
        exit_code = qstat.wait()
        print batchid, pbs_status

    return exit_code

#########################################################################
def main(argv):
    """
    Main routine for the commandline application
    """
    optParser = queueinit.setupOptions(usage_str)
    opts, batchids = optParser.parse_args()

    if not batchids:
        raise Exception("No batchids were specified")

    if opts.debug:
        logger.setLevel(log.DEBUG)

    exit_code = run(batchids)
    return exit_code

if __name__ == '__main__':
    try:
        exit_code = main(sys.argv)
    except Exception, err:
        print err
        print usage_str
        sys.exit(1)
    sys.exit(exit_code)
