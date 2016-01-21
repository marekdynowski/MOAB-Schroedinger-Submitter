#!/bin/bash
#MSUB -N %PBSNAME%
#MSUB -j oe
#MSUB -r n
#MSUB -l nodes=%NPROC%
#
# Batch-submission script for the MOAB system
#

PATH=/usr/bin:/bin:/usr/bsd:/usr/sbin:/sbin:/usr/local/bin:$PATH

MPATH=/opt/moab/bin
curdir=`echo $0 | sed -e 's#/[^/]*$##'`
if [ -f "$curdir/config" ]; then
  . $curdir/config
fi

PATH=$MPATH:$PATH

SCHRODINGER_BATCHID="`cat $SCHRODINGER_TMPJOBIDFILE`"
export SCHRODINGER_BATCHID

%ENVIRONMENT%

NODEFILE_DIR=~/.schrodinger/tmp
if [ ! -d "$NODEFILE_DIR" ]; then
  mkdir -p "$NODEFILE_DIR"
fi

if [ "%NPROC%" -gt 1 -a -n "$PBS_NODEFILE" ]; then
  SCHRODINGER_NODEFILE="$PBS_NODEFILE"
  SCHRODINGER_MPI_NODEFILE="$PBS_NODEFILE"
  export SCHRODINGER_NODEFILE SCHRODINGER_MPI_NODEFILE
  if [ -n "%GPGPU%" ]; then
    #SCHRODINGER_GPGPU=`awk -v ORS=' ' -v OFS=':' '{print $1, "%GPGPU%"}' $PBS_NODEFILE`

    # hack
    NODES=`checkjob $SCHRODINGER_BATCHID | awk '/Allocated Nodes:/{getline; print}' | sed 's/\]/\]\n/' | sed 's/[][]//g'`
    SCHRODINGER_GPGPU=""
    for line in $NODES; do
      NODE=`echo $line | sed -r 's/([^\:]+)\:.*/\1/'`
      PPN=`echo $line | sed -r 's/[^\:]+\:(.*)/\1/'`
      for i in `seq $PPN`; do
        SCHRODINGER_GPGPU="$SCHRODINGER_GPGPU $NODE:%GPGPU%"
      done
    done
    # hack - end

    export SCHRODINGER_GPGPU
  fi
else
  SCHRODINGER_MPI_NODEFILE="$NODEFILE_DIR/$MOAB_JOBID.mpinodes"
  SCHRODINGER_TMP_NODEFILE="$SCHRODINGER_MPI_NODEFILE"
  export SCHRODINGER_MPI_NODEFILE SCHRODINGER_TMP_NODEFILE
  hostname > "$SCHRODINGER_MPI_NODEFILE"
  if [ -n "%GPGPU%" ]; then
    HOST=`hostname`
    SCHRODINGER_GPGPU="$HOST:%GPGPU%"
    export SCHRODINGER_GPGPU
  fi
fi

%COMMAND%

