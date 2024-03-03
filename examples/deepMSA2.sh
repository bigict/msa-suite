#!/bin/bash
#

set -e

CWD=`readlink -f $0`
CWD=`dirname ${CWD}`

CWD=`dirname ${CWD}` # Parent


######## set your variables here
db_dir=${CWD}/db

dmsa_hhblitsdb="${db_dir}/uniclust30_2018_08/uniclust30_2018_08"
dmsa_jackhmmerdb="${db_dir}/uniref90/uniref90.fasta"
dmsa_hmmsearchdb="${db_dir}/metaclust_db/metaclust_2017_05.fasta"

qmsa_hhblitsdb="${db_dir}/uniclust30_2018_08/uniclust30_2018_08"
qmsa_jackhmmerdb="${db_dir}/uniref90/uniref90.fasta"
qmsa_bfddb="${db_dir}/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"
qmsa_hmmsearchdb="${db_dir}/metaclust_db/metaclust_2017_05.fasta"

mmsa_hmmsearchdb=""
jgi_db=${db_dir}/JGIclust
for db in $(cat ${jgi_db}/list); do
  mmsa_hmmsearchdb="${mmsa_hmmsearchdb} ${jgi_db}/${db}"
done

export HHLIB=${CWD}

##############################################
# NOTE: Required by scripts/hhsuitedb.sh
export uniclust30_db=${db_dir}/uniclust30_2018_08/uniclust30_2018_08


help() {
  echo -e "usage: `basename $0` [options]\n" \
          "options:\n" \
          "  -i, --input_fasta <input_fasta> *\n" \
          "  -o, --output_dir <output_dir> *\n" \
          "  --cpu <cpu_num>\n" \
          "  -v, --verbose\n" \
          "  -h, --help\n"
  exit $1
}

output_dir="."
cpu=16;
verbose=""

ARGS=$(getopt --options "i:o:vh" --longoptions "input_fasta:,output_dir:,cpu:,verbose,help" -- "$@") || exit
eval "set -- ${ARGS}"
while true; do
  case "$1" in
    (-i | --input_fasta) input_fasta="$2"; shift 2;;
    (-o | --output_dir) output_dir="$2"; shift 2;;
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
work_dir="${output_dir}/deepMSA2"

#####################################
# Build dMSA
python msa_build.py \
  --ncpu=${cpu} \
  --hhblitsdb=${dmsa_hhblitsdb} \
  --jackhmmerdb ${dmsa_jackhmmerdb}  \
  --hmmsearchdb ${dmsa_hmmsearchdb} \
  --tmpdir=${work_dir}/dMSA \
  --outdir=${output_dir}/dMSA \
  ${verbose} \
  ${input_fasta}

#####################################
# Build qMSA
python msa_build.py \
  --ncpu=${cpu} \
  --hhblitsdb=${qmsa_hhblitsdb} \
  --jackhmmerdb ${qmsa_jackhmmerdb}  \
  --bfddb ${qmsa_bfddb}  \
  --hmmsearchdb ${qmsa_hmmsearchdb} \
  --tmpdir=${work_dir}/qMSA \
  --outdir=${output_dir}/qMSA \
  ${verbose} \
  ${input_fasta}

pid=`basename ${input_fasta} | awk -F '.' '{if (NF == 1){print $1;} else {printf("%s", $1); for(i=2;i<NF;++i){printf(".%s", $i);}}}'`

#####################################
# Build mMSA^a (qMSA stage3)
mkdir -p ${work_dir}/mMSA/a
mkdir -p ${output_dir}/mMSA/a
if [ -f ${output_dir}/qMSA/${pid}.bfdaln ]; then
  cp ${output_dir}/qMSA/${pid}.bfd{aln,a3m} ${output_dir}/mMSA/a
fi

python msa_build.py \
  --ncpu=${cpu} \
  --bfddb ${qmsa_bfddb}  \
  --hmmsearchdb ${mmsa_hmmsearchdb} \
  --tmpdir=${work_dir}/mMSA/a \
  --outdir=${output_dir}/mMSA/a \
  --keep \
  ${verbose} \
  ${input_fasta}

# Create ssi index
${HHLIB}/bin/esl-sfetch --index ${work_dir}/mMSA/a/hmmsearch.fseqs

#####################################
# Build mMSA^b (qMSA stage2)
mkdir -p ${work_dir}/mMSA/b
mkdir -p ${output_dir}/mMSA/b
if [ -f ${output_dir}/qMSA/${pid}.jacaln ]; then
  cp ${output_dir}/qMSA/${pid}.jac{aln,a3m} ${output_dir}/mMSA/a
fi

python msa_build.py \
  --ncpu=${cpu} \
  --jackhmmerdb ${qmsa_jackhmmerdb}  \
  --hmmsearchdb ${work_dir}/mMSA/a/hmmsearch.fseqs \
  --tmpdir=${work_dir}/mMSA/b \
  --outdir=${output_dir}/mMSA/b \
  ${verbose} \
  ${input_fasta}

#####################################
# Build mMSA^c (dMSA stage2)
mkdir -p ${work_dir}/mMSA/c
mkdir -p ${output_dir}/mMSA/c
if [ -f ${output_dir}/dMSA/${pid}.jacaln ]; then
  cp ${output_dir}/dMSA/${pid}.jac{aln,a3m} ${output_dir}/mMSA/a
fi

python msa_build.py \
  --ncpu=${cpu} \
  --jackhmmerdb ${dmsa_jackhmmerdb}  \
  --hmmsearchdb ${work_dir}/mMSA/a/hmmsearch.fseqs \
  --tmpdir=${work_dir}/mMSA/c \
  --outdir=${output_dir}/mMSA/c \
  ${verbose} \
  ${input_fasta}

# Cleanup
rm -rf ${work_dir}/mMSA/a
