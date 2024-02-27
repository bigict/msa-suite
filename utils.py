"""Utils for msa-suite
"""
import os
import sys
import random
import logging


logger = logging.getLogger(__file__)


def mkdir_if_not_exist(dirname):
  os.makedirs(dirname, exist_ok=True)


def make_tmpdir(tmpdir, prefix=""):  # pylint:disable=redefined-outer-name
  if not tmpdir:
    while True:
      tmpdir = f"/tmp/{os.getenv('USER')}/{prefix}{random.randint(0, 10**10)}"
      if not os.path.isdir(tmpdir):
        break
  mkdir_if_not_exist(tmpdir)
  logger.info(f"created folder {tmpdir}\n")
  return tmpdir
