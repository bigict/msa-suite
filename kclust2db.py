"""
kclust2db.py db.fasta
    cluster sequences in FASTA file db.fasta using kClust

Options:
    -tmpdir=/tmp/$USER/kClust_`date +%N`
        use -tmpdir as temperary folder

    -id=30
        kClust sequence identity cutoff 30%. legal values are:
        20, 30, 40, 50, 60, 70, 80, 90, 99

    -ncpu=1
        number of CPU threads
"""
import os
import sys
import subprocess
import shutil
from string import Template

from hhpaths import bin_dict
from utils import make_tmpdir, mkdir_if_not_exist

import logging

logger = logging.getLogger(__file__)

id2s_dict = {
    20: 0.52,
    30: 1.12,
    40: 1.73,
    50: 2.33,
    60: 2.93,
    70: 3.53,
    80: 4.14,
    90: 4.74,
    99: 5.28
}

kclust_threshold_n2s_list = [99, 90, 80, 70, 60, 50, 40, 30]

kclust_template = Template(
    "$kClust -i $infile -s $threshold -d $tmpdir -M 5000MB")
kClust_mkAln_template = Template(
    "$kClust_mkAln -c '$clustalo --threads=$ncpu -i $$infile -o $$outfile' -d $tmpdir --no-pseudo-headers|grep -P '^Filename:'|cut -d' ' -f2"  # pylint: disable=line-too-long
)
reformat_template = Template(
    "$reformat fas a3m $filename $tmpdir/$basename.a3m")
# hhblitsdb_template = Template(
#     "$hhblitsdb --cpu $ncpu -o $outdb --input_a3m $tmpdir/a3m")
cdhit_template = Template(
    "$cdhit -i $infile -o $outfile -c $c -n $n -T $ncpu -M 8000")


def write_fseqs(txt, outfile, max_name_len=32):  # pylint: disable=redefined-outer-name
  with open(outfile, "w") as f:
    for line in txt.splitlines():
      if line.startswith(">"):
        name, *_ = line.split(" ")
        if len(name) > max_name_len:
          line = f"{line[:max_name_len]} {line[max_name_len:]}"
      f.write(f"{line}\n")


def remove_a3m_gap(infile, outfile, seqname_prefix=""):  # pylint: disable=redefined-outer-name
  ''' read a3m/fasta format infile, remove gaps and output to outfile.
  return the number of sequences '''
  with open(infile, "r") as fp:
    lines = fp.read().splitlines()

  txt = ""
  nseq = 0

  for line in lines:
    if line.startswith(">"):
      nseq += 1
      line = f">{seqname_prefix}{line[1:]}"
    else:
      line = line.upper().replace("-", "").replace(".", "")
    txt += line + "\n"

  with open(outfile, "w") as fp:
    fp.write(txt)

  return nseq


def remove_redundant_cdhit(infile, outfile, cdhit_c, ncpu):  # pylint: disable=redefined-outer-name
  ''' read fasta format infile, perform redundancy removal, and
    output to outfile.  return the number of sequences '''
  n = 5
  if cdhit_c < 0.5:
    n = 2
  elif cdhit_c < 0.6:
    n = 3
  elif cdhit_c < 0.7:
    n = 4

  logger.info("#### remove redundancies with cd-hit ####")
  cmd = cdhit_template.substitute(
      cdhit=bin_dict["cdhit"],
      infile=infile,
      outfile=outfile,
      c=cdhit_c,
      n=n,
      ncpu=ncpu,
  )
  logger.info(cmd)
  os.system(cmd)

  if os.path.isfile(outfile):
    infile = outfile.strip()
  with open(outfile, "r") as fp:
    nseq = ("\n" + fp.read()).count("\n>")
  return nseq, infile


def kclust_threshold(infile):  # pylint: disable=redefined-outer-name
  with open(infile, "r") as fp:
    nseq = ("\n" + fp.read()).count("\n>")
  for i, t in enumerate(kclust_threshold_n2s_list):
    if nseq < (i + 1) * 500:
      return t
  return kclust_threshold_n2s_list[-1]


def kclust2db(infile, tmpdir=".", s=1.12, ncpu=1):  # pylint: disable=redefined-outer-name
  """Cluster sequences in FASTA file \"infile\", and generate hhblits
    style database at outdb"""
  logger.info("#### cluster input fasta ####")
  kclustdir = os.path.join(tmpdir, "kClust")
  mkdir_if_not_exist(kclustdir)
  cmd = kclust_template.substitute(
      kClust=bin_dict["kClust"],
      infile=infile,
      threshold=s,
      tmpdir=kclustdir,
  )
  logger.info(cmd)
  os.system(cmd)

  logger.info("#### alignment within each cluster ####")
  cmd = kClust_mkAln_template.substitute(
      kClust_mkAln=bin_dict["kClust_mkAln"],
      clustalo=bin_dict["clustalo"],
      ncpu=ncpu,
      tmpdir=kclustdir,
  )
  logger.info(cmd)
  with subprocess.Popen(cmd, shell=True, text=True,
                        stdout=subprocess.PIPE) as p:
    stdout, _ = p.communicate()

  logger.info("#### reformat fas into a3m ####")
  a3mdir = os.path.join(tmpdir, "a3m")
  mkdir_if_not_exist(a3mdir)
  for filename in map(lambda x: x.strip(), stdout.splitlines()):
    cmd = reformat_template.substitute(
              reformat=bin_dict["reformat"],
              filename=filename,
              tmpdir=a3mdir,
              basename=os.path.basename(os.path.splitext(filename)[0]),
          )
    logger.debug(cmd)
    os.system(cmd)

  # logger.info("#### build hhblitsdb ####")
  # mkdir_if_not_exist(os.path.dirname(outdb))
  # cmd = hhblitsdb_template.substitute(
  #     hhblitsdb=bin_dict["hhblitsdb"],
  #     ncpu=ncpu,
  #     outdb=outdb,
  #     tmpdir=tmpdir,
  # )
  # logger.info(cmd)
  # os.system(cmd)
  return a3mdir


if __name__ == "__main__":
  seq_id = 30
  ncpu = 1
  tmpdir = ""

  argv = []
  for arg in sys.argv[1:]:
    if arg.startswith("-id="):
      seq_id = float(arg[len("-id="):])
      if seq_id < 1:
        seq_id = 100 * seq_id
      seq_id = int(seq_id)
    elif arg.startswith("-ncpu="):
      ncpu = int(arg[len("-ncpu="):])
    elif arg.startswith("-tmpdir="):
      tmpdir = os.path.abspath(arg[len("-tmpdir="):])
    elif arg.startswith("-"):
      print(f"ERROR! No such option {arg}\n")
      sys.exit()
    else:
      argv.append(arg)

  if not seq_id in id2s_dict:
    print(f"ERROR! Illegal sequence identity cutoff {seq_id}\n")
    sys.exit()
  s = id2s_dict[seq_id]

  if len(argv) != 1:
    print(__doc__)
    sys.exit()

  infile = os.path.abspath(argv[0])
  tmpdir = make_tmpdir(tmpdir, prefix="kClust_")

  kclust2db(infile, tmpdir, s, ncpu)
  if os.path.isdir(tmpdir):
    shutil.rmtree(tmpdir)
