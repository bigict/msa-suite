"""
kclust2db.py db.fasta mydb/mydb
    cluster sequences in FASTA file db.fasta using kClust,
    and generate hhblits style database at mydb/mydb

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

kClust_template = Template("$kClust -i $infile -s $threshold -d $tmpdir/kClust")
kClust_mkAln_template = Template(
    "$kClust_mkAln -c '$clustalo --threads=$ncpu -i $$infile -o $$outfile' -d $tmpdir/kClust --no-pseudo-headers|grep -P '^Filename:'|cut -d' ' -f2"  # pylint: disable=line-too-long
)
reformat_template = Template(
    "$reformat fas a3m $filename $tmpdir/a3m/$basename.a3m")
hhblitsdb_template = Template(
    "$hhblitsdb --cpu $ncpu -o $outdb --input_a3m $tmpdir/a3m")


def kclust2db(infile, outdb, tmpdir=".", s=1.12, ncpu=1):  # pylint: disable=redefined-outer-name
  """Cluster sequences in FASTA file \"infile\", and generate hhblits
    style database at outdb"""
  logger.info("#### cluster input fasta ####")
  cmd = kClust_template.substitute(
      dict(
          kClust=bin_dict["kClust"],
          infile=infile,
          threshold=s,
          tmpdir=tmpdir,
      ))
  logger.info(cmd)
  os.system(cmd)

  logger.info("#### alignment within each cluster ####")
  cmd = kClust_mkAln_template.substitute(
      dict(
          kClust_mkAln=bin_dict["kClust_mkAln"],
          clustalo=bin_dict["clustalo"],
          ncpu=ncpu,
          tmpdir=tmpdir,
      ))
  logger.info(cmd)
  with subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE) as p:
    stdout, _ = p.communicate()

  logger.info("#### reformat fas into a3m ####")
  a3mdir = os.path.join(tmpdir, "a3m")
  mkdir_if_not_exist(a3mdir)
  for filename in stdout.splitlines():
    os.system(
        reformat_template.substitute(
            dict(
                reformat=bin_dict["reformat"],
                filename=filename,
                tmpdir=tmpdir,
                basename=os.path.basename(os.path.splitext(filename)[0]),
            )))

  logger.info("#### build hhblitsdb ####")
  mkdir_if_not_exist(os.path.dirname(outdb))
  cmd = hhblitsdb_template.substitute(
      dict(
          hhblitsdb=bin_dict["hhblitsdb"],
          ncpu=ncpu,
          outdb=outdb,
          tmpdir=tmpdir,
      ))
  logger.info(cmd)
  os.system(cmd)


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

  if len(argv) != 2:
    print(__doc__)
    sys.exit()

  infile = os.path.abspath(argv[0])
  outdb = os.path.abspath(argv[1])
  tmpdir = make_tmpdir(tmpdir, prefix="kClust_")

  kclust2db(infile, outdb, tmpdir, s, ncpu)
  if os.path.isdir(tmpdir):
    shutil.rmtree(tmpdir)
