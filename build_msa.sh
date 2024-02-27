#!/bin/bash
#

CWD=`readlink -f $0`
CWD=`dirname ${CWD}`


######## set your variables here
db_dir=${HOME}/data

msa_hhblitsdb="${db_dir}/af2_db/uniclust30/uniclust30_2018_08/uniclust30_2018_08"
msa_jackhmmerdb="${db_dir}/fupred_db/uniref90_db/uniref90.fasta ${db_dir}/deepmsa_db/tartaDB/tara.fasta"
msa_hmmsearchdb="${db_dir}/fupred_db/metaclust_db/metaclust_2017_05.fasta"

export HHLIB=${CWD}

##############################################
# NOTE: Required by scripts/hhsuitedb.sh
export uniclust30_db=${db_dir}/af2_db/uniclust30/uniclust30_2018_08/uniclust30_2018_08


help() {
  echo -e "usage: `basename $0` [options]\n" \
          "options:\n" \
          "  -i, --input_fasta <input_fasta> *\n" \
          "  -o, --output_dir <output_dir> *\n" \
          "  -d, --work_dir <work_dir> *\n" \
          "  --cpu <cpu_num>\n" \
          "  -v, --verbose\n" \
          "  -h, --help\n"
  exit $1
}

output_dir="."
work_dir=tmp
cpu=96;
verbose=""

ARGS=$(getopt --options "i:o:d:vh" --longoptions "input_fasta:,output_dir:,work_dir:,cpu:,verbose,help" -- "$@") || exit
eval "set -- ${ARGS}"
while true; do
  case "$1" in
    (-i | --input_fasta) input_fasta="$2"; shift 2;;
    (-o | --output_dir) output_dir="$2"; shift 2;;
    (-d | --work_dir) work_dir="$2"; shift 2;;
    (--cpu) cpu="$2"; shift 2;;
    (-v | --verbose) verbose="-v"; shift 1;;
    (-h | --help) help 0 ;;
    (--) shift 1; break;;
    (*) help 1;
  esac
done

# Check arguments
if [ -z ${input_fasta} ]; then
  help 1
fi

python build_msa.py \
  --ncpu=${cpu} \
  --hhblitsdb=${msa_hhblitsdb} \
  --jackhmmerdb ${msa_jackhmmerdb}  \
  --hmmsearchdb ${msa_hmmsearchdb} \
  --tmpdir=${work_dir}/deepMSA \
  --outdir=${output_dir} \
  ${verbose} \
  ${input_fasta}
