#!/bin/bash
#

CWD=`readlink -f $0`
CWD=`dirname ${CWD}`

help() {
  echo -e "usage: `basename $0` [options]\n" \
          "options:\n" \
          "  -i, --input_a3m <input_a3m> *\n" \
          "  -o, --output_db <output_db> *\n" \
          "  -d, --uniclust30_db <uniclust30_db> *\n" \
          "  -e, --hhlib <hhlib env>\n" \
          "  --cpu <cpu_num>\n" \
          "  -v, --verbose\n" \
          "  -h, --help\n"
  exit $1
}

HHLIB=${HHLIB:-$(dirname ${CWD})}
uniclust30_db=${hhsuite_uniclust30_db}
cpu=16
verbose=0

ARGS=$(getopt --options "i:o:d:e:vh" --longoptions "input_a3m:,output_db:,uniclust30_db:,hhlib:,cpu:,verbose,help" -- "$@") || exit
eval "set -- ${ARGS}"
while true; do
  case "$1" in
    (-i | --input_a3m) input_a3m="$2"; shift 2;;
    (-o | --output_db) output_db="$2"; shift 2;;
    (-d | --uniclust30_db) uniclust30_db="$2"; shift 2;;
    (-e | --hhlib) HHLIB="$2"; shift 2;;
    (--cpu) cpu="$2"; shift 2;;
    (-v | --verbose) verbose=1; shift 1;;
    (-h | --help) help 0 ;;
    (--) shift 1; break;;
    (*) help 1;
  esac
done

error_alarm() {
  echo $*
  exit 1
}

exec_with_error_check() {
  cmd=$*
  if [ ${verbose} -ne 0 ]; then
    echo "${cmd}"
  fi
  ${cmd} || error_alarm ${cmd}
}

# Check arguments
if [ -z ${input_a3m} ]; then
  help 1
fi
if [ -z ${output_db} ]; then
  help 1
fi
if [ -z ${uniclust30_db} ]; then
  help 1
fi

mkdir -p `dirname ${output_db}`
if [ -d ${input_a3m} ]; then
  cat ${input_a3m}/*.a3m > ${output_db}.fa
  input_a3m=${output_db}.fa
fi

# 1. Creating a database of HHblits compatible MSAs
exec_with_error_check ${HHLIB}/bin/ffindex_from_fasta -s ${output_db}_fa.ff{data,index} ${input_a3m}

exec_with_error_check ${HHLIB}/bin/hhblits_omp -i ${output_db}_fa -d ${uniclust30_db} -oa3m ${output_db}_a3m -n 2 -cpu ${cpu} -v 0

# 2. Computing hidden markov models
exec_with_error_check ${HHLIB}/bin/ffindex_apply ${output_db}_a3m.ff{data,index} \
    -i ${output_db}_hhm.ffindex -d ${output_db}_hhm.ffdata -- ${HHLIB}/bin/hhmake -i stdin -o stdout -v 0

# 3. Computing context states for prefiltering
exec_with_error_check ${HHLIB}/bin/cstranslate -f -x 0.3 -c 4 -I a3m -i ${output_db}_a3m -o ${output_db}_cs219

# 4. Putting everything together
sort -k3 -n -r ${output_db}_cs219.ffindex | cut -f1 > ${output_db}_sorting.dat

exec_with_error_check ${HHLIB}/bin/ffindex_order ${output_db}_sorting.dat ${output_db}_hhm.ff{data,index} ${output_db}_hhm_ordered.ff{data,index}
exec_with_error_check mv ${output_db}_hhm_ordered.ffindex ${output_db}_hhm.ffindex
exec_with_error_check mv ${output_db}_hhm_ordered.ffdata ${output_db}_hhm.ffdata

exec_with_error_check ${HHLIB}/bin/ffindex_order ${output_db}_sorting.dat ${output_db}_a3m.ff{data,index} ${output_db}_a3m_ordered.ff{data,index}
exec_with_error_check mv ${output_db}_a3m_ordered.ffindex ${output_db}_a3m.ffindex
exec_with_error_check mv ${output_db}_a3m_ordered.ffdata ${output_db}_a3m.ffdata
