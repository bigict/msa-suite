#!/bin/bash
#

CWD=`readlink -f $0`
CWD=`dirname ${CWD}`


######## set your variables here
db_dir=${CWD}/db

msa_hhblitsdb=${qmsa_hhblitsdb:-"${db_dir}/uniclust30_2018_08/uniclust30_2018_08"}
msa_jackhmmerdb=${qmsa_jackhmmerdb:-"${db_dir}/uniref90/uniref90.fasta"}
msa_bfddb=${qmsa_bfddb:-"${db_dir}/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"}
msa_hmmsearchdb=${qmsa_hmmsearchdb:-"${db_dir}/metaclust_db/metaclust_2017_05.fasta"}

HHLIB=${HHLIB:-${CWD}}
export HHLIB

##############################################
# NOTE: Required by scripts/hhsuitedb.sh
hhsuite_uniclust30_db=${hhsuite_uniclust30_db:-"${db_dir}/uniclust30_2018_08/uniclust30_2018_08"}
export hhsuite_uniclust30_db


help() {
  echo -e "usage: `basename $0` [options]\n" \
          "options:\n" \
          "  -i, --input_fasta <input_fasta> *\n" \
          "  -o, --output_dir <output_dir> *\n" \
          "  --cpu <cpu_num>\n" \
          "  -k, --keep\n" \
          "  -v, --verbose\n" \
          "  -h, --help\n"
  exit $1
}

output_dir="."
cpu=96;
keep=""
verbose=""

ARGS=$(getopt --options "i:o:d:vh" --longoptions "input_fasta:,output_dir:,cpu:,verbose,help" -- "$@") || exit
eval "set -- ${ARGS}"
while true; do
  case "$1" in
    (-i | --input_fasta) input_fasta="$2"; shift 2;;
    (-o | --output_dir) output_dir="$2"; shift 2;;
    (--cpu) cpu="$2"; shift 2;;
    (-k | --keep) keep="-k"; shift 1;;
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

python ${CWD}/msa_build.py \
  --ncpu=${cpu} \
  --hhblitsdb=${msa_hhblitsdb} \
  --jackhmmerdb ${msa_jackhmmerdb}  \
  --bfddb ${msa_bfddb}  \
  --hmmsearchdb ${msa_hmmsearchdb} \
  --tmpdir=${output_dir}/deepMSA \
  --outdir=${output_dir} \
  ${keep} \
  ${verbose} \
  ${input_fasta}
