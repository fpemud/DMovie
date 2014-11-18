#!/usr/bin/env python3
# -*- coding: utf-8; tab-width: 4; indent-tabs-mode: t -*-

import os
import sys
import shutil
import unittest

curDir = os.path.dirname(os.path.abspath(__file__))
if sys.version_info >= (3, 0):
    sys.path.insert(0, os.path.join(curDir, "../python3"))
else:
    sys.path.insert(0, os.path.join(curDir, "../python2"))
import pylkc


class Test_Linux_3_17(unittest.TestCase):

    def setUp(self):
        self.rootDir = os.path.join(curDir, "linux-3.17")

    def runTest(self):
        pylkc.init(self.rootDir)
        try:
            pylkc.conf_parse(self.rootDir)
            pylkc.conf_read(None)
            pylkc.conf_write(None)
        finally:
            pylkc.release()

    def tearDown(self):
        pass


class Test_Linux_3_16(unittest.TestCase):

    def setUp(self):
        self.rootDir = os.path.join(curDir, "linux-3.16")

    def runTest(self):
        pylkc.init(self.rootDir)
        try:
            pylkc.conf_parse(self.rootDir)
            pylkc.conf_read(None)
        finally:
            pylkc.release()

    def tearDown(self):
        pass


def suite():
    suite = unittest.TestSuite()
    suite.addTest(Test_Linux_3_17())
    suite.addTest(Test_Linux_3_16())
    return suite

if __name__ == "__main__":
    unittest.main(defaultTest='suite')
