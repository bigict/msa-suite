""""This is the python equivalent of HHPath.pm
"""
import os
import logging


logger = logging.getLogger(__file__)


if "HHLIB" not in os.environ:
  os.environ["HHLIB"] = os.path.dirname(os.path.abspath(__file__))
HHLIB = os.environ["HHLIB"]


bin_dict = dict(
    #### upstream hhsuite executables ####
    hhblits=os.path.join(HHLIB, "bin/hhblits"),
    cstranslate=os.path.join(HHLIB, "bin/cstranslate"),
    hhfilter=os.path.join(HHLIB, "bin/hhfilter"),
    reformat=os.path.join(HHLIB, "scripts/reformat.pl"),
    hhblitsdb=os.path.join(HHLIB, "scripts/hhsuitedb.sh"),

    #### qhmmer ####
    qhmmsearch=os.path.join(HHLIB, "bin/qhmmsearch"),
    qhmmbuild=os.path.join(HHLIB, "bin/qhmmbuild"),
    qjackhmmer=os.path.join(HHLIB, "bin/qjackhmmer"),
    eslsfetch=os.path.join(HHLIB, "bin/esl-sfetch"),

    #### MSAParser ####
    fasta2aln=os.path.join(HHLIB, "bin/fasta2aln"),
    fastaCov=os.path.join(HHLIB, "bin/fastaCov"),
    realignMSA=os.path.join(HHLIB, "bin/realignMSA"),
    rmRedundantSeq=os.path.join(HHLIB, "bin/rmRedundantSeq"),
    calNf=os.path.join(HHLIB, "bin/fastNf"),

    ### sequence clustering by kClust ####
    kClust=os.path.join(HHLIB, "bin/kClust"),
    kClust_mkAln=os.path.join(HHLIB, "bin/kClust_mkAln"),
    clustalo=os.path.join(HHLIB, "bin/clustalo"),
)


def check_hhsuite_binaries():
  ''' check if all binaries listed in bin_dict are present '''
  for name, path in bin_dict.items():
    if not os.path.isfile(path):
      logger.error("Cannot locate %s at %s", name, path)


if __name__ == "__main__":
  check_hhsuite_binaries()
