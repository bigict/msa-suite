"""Utils for msa-suite
"""
import os
from inspect import isfunction
import random
import logging


logger = logging.getLogger(__file__)


# helpers
def exists(val):
  return val is not None


def default(val, d):
  if exists(val):
    return val
  return d() if isfunction(d) else d


def mkdir_if_not_exist(dirname):
  os.makedirs(dirname, exist_ok=True)


def make_tmpdir(tmpdir, prefix=""):
  if not tmpdir:
    while True:
      tmpdir = f"/tmp/{os.getenv('USER')}/{prefix}{random.randint(0, 10**10)}"
      if not os.path.isdir(tmpdir):
        break
  mkdir_if_not_exist(tmpdir)
  logger.info("created folder %s", tmpdir)
  return tmpdir
