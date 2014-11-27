#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2011 ~ 2012 Deepin, Inc.
#               2011 ~ 2012 Wang Yong
#
# Author:     Wang Yong <lazycat.manatee@gmail.com>
# Maintainer: Wang Yong <lazycat.manatee@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import glob
import elemlib

from PyQt5.QtCore import QObject
from PyQt5.QtCore import pyqtProperty, pyqtSignal, pyqtSlot

from subtitles import Parser, SUPPORTED_FILE_TYPES
from constant import DEFAULT_WIDTH, DEFAULT_HEIGHT, WINDOW_GLOW_RADIUS
from media_info import parse_info
from i18n import _
from utils import utils


class MovieInfo2(QObject):

	def __init__(self):
		self.runtime = -1
		self.aspect_ratio = (-1, -1)
		self.wiki_links = dict()
		self.imdb_link = ""
		self.defects = set()


class MovieAvLevel(QObject):

	def __init__(self):
		self.video_format = ""
		self.audio_format = ""
		self.frame_rate = -1
		self.scanning_method = ""				# "interlaced" "progressive"
		self.width = -1
		self.height = -1
		self.aspect_ratio = (-1, -1)			# inaccurate if calculated by self.width and self.height
		self.audio_languages = []				# list<str>
		self.subtitle_languages = []			# list<str>

	@property
	def standard(self):
		t = (self.width, self.height)
		if t == (320, 240) or t == (352, 240) or t == (427, 240):
			ret = "240"
		elif t == (352, 288) or t == (482, 272):
			ret = "288"
		elif t == (480, 360) or t == (640, 360):
			ret = "360"
		elif t == (640, 480) or t == (720, 480) or t == (800, 480) or t == (854, 480):
			ret = "480"
		elif t == (720, 576) or t == (704, 576):
			ret = "576"
		elif t == (1280, 720):
			ret = "720"
		elif t == (1920, 1080):
			ret = "1080"
		elif t == (3840, 2160):
			ret = "2160"
		elif t == (7680, 4320):
			ret = "4320"
		else:
			ret = ""

		if ret != "":
			ret += self.scanning_method[0]

		return ret


class MovieData(QObject):

	def __init__(self, directory_path):
		self.directory_path = ""
		self.file_list = []
		self.movie_type = None
		self.movie_width = None
		self.movie_height = None
		self.movie_size = None
		self.movie_duration = None
		self.video_format = None
		self.audio_format = None

		# get all the video files
        for fbasename in sorted(os.listdir(directory_path)):
            fname = os.path.join(element_path, fbasename)
            if utils.fileIsValidVideo(fname):
                self.file_list.append(fname)
        if len(self.file_list) == 0:
            raise Exception("No video file in movie data directory %s" % (directory_path))

		# get media information for every video file
        media_info_list = []
		for f in self.file_list:
			media_info_list.append(parse_info(filepath))

		# check media information
		for m in media_info_list[1:]:
			if media_info_list[0].get("general_extension") != m.get("general_extension"):
				raise Exception("")
			if media_info_list[0].get("video_width") != m.get("video_width"):
				raise Exception("")
			if media_info_list[0].get("video_height") != m.get("video_height"):
				raise Exception("")

		# get final media information
		self.movie_type = media_info_list[0].get("general_extension") or _("Unknown")
		self.movie_width = media_info_list[0].get("video_width") or DEFAULT_WIDTH
		self.movie_height = media_info_list[0].get("video_height") or DEFAULT_HEIGHT
		self.movie_size = int(media_info_list[0].get("general_size") or 0)
		self.movie_duration = media_info_list[0].get("general_duration") or 0
		self.video_format = None
		self.audio_format = None


class MovieElement(QObject):
	"""Contains static information"""

	DEFECT_SPLIT_FILE = 1				# movie should be in a single file, not seperate files
	DEFECT_WATERMARK = 2				# movie has watermark
	DEFECT_EMBED_SUBTITLES = 3			# movie file has embeded subtitles, the subtitles should be contained in seperate file, in text format
	DEFECT_SHOT_VERSION = 4				# movie file is shot version, not clear
	DEFECT_INCOMPLETE = 5				# movie file is clipped, not the full version
	DEFECT_TRIM_NEEDED = 6				# movie file contains uneccessary header or footer, mostly ads
	DEFECT_NO_TS_PAR2 = 7				# *.ts file should have corresponding .par2 files as its checksum
	DEFECT_INCONSISTENT = 8				# movie data are not consistent
	DEFECT_NO_ORIGINAL = 9				# no original movie data

    def __init__(self, element_path):
        QObject.__init__(self)

        self._elem_obj = elemlib.open_element(element_path, "ro")

		self._info = MovieInfo2()
		self._original_data_dir = ""
		self._movie_data_set = set()
		self._subtitles = dict()

		self._cur_movie_data = None
		self._cur_av_level = None
		self._max_av_level = None

		# parse movie_info.xml
        self._parseMovieInfoXml(os.path.join(element_path, "movie_info.xml"))

		# get movie data set
        for fbasename in sorted(os.listdir(element_path)):
            fname = os.path.join(element_path, fbasename)
			if not (os.path.isdir(fname) or re.match("^data[0-9]+$", fbasename)):
				continue
			self._movie_data_set.add(MovieData(fname))

		# get subtitle dict
	    result = []
	    for ext in SUPPORTED_FILE_TYPES:
	        result += glob.glob("%s/*.%s" % (element_path, ext))

		# get maximum audio video level
		pass

		# select current movie data
		pass

		# get current audio video level
		pass

    def close(self):
        if self._elem_obj is not None:
            self._elem_obj.close()
        self._elem_obj = None

    def _parseMovieInfoXml(self, filepath):
    	pass


class MovieInfo(QObject):
	"""Contains static information and playing information"""

    fileChanged = pyqtSignal(str, int, arguments=["cur_file", "cur_position"])

	### initialization ###

    def __init__(self):
        QObject.__init__(self)
        self._elem = None
        self._audio_lang = ""
        self._subtitle_lang = ""
        self._subtitle_parser = None
        self._position = -1

    @pyqtSlot()
    def close(self):
        self._position = -1
        self._subtitle_parser = None
        self._subtitle_lang = ""
        self._audio_lang = ""
        if self._elem is not None:
            self._elem.close()
        self._elem = None

    @pyqtSlot(str)
    def set_element_dmovie(self, element_path):
        self.close()
        try:
	        self._elem = MovieElement(element_path)
	        if len(self._elem.cur_av_level.audio_languages) > 0:
		        self._audio_lang = self._elem.cur_av_level.audio_languages[0]
			if len(self._elem.cur_av_level.subtitle_languages) > 0:
				lang = self._elem.cur_av_level.subtitle_languages[0]
		        self._subtitle_lang = lang
		        self._subtitle_parser = Parser(self._elem._subtitles[lang])
	        self._position = 0
		except:
			self.close()
			raise

	### movie play settings ###

    @pyqtSlot(str)
    def set_audio_language(self, lang):
		if lang not in self._elem.cur_av_level.audio_languages:
			raise Exception("invalid audio language")
		self._audio_lang = lang
		# fixme

    @pyqtSlot(str)
    def set_subtitle_language(self, lang):
		if lang not in self._elem.cur_av_level.subtitle_languages:
			raise Exception("invalid subtitle language")

		old_lang = self._subtitle_lang
		old_parser = self._subtitle_parser
        try:
			self._subtitle_lang = lang
	        self._subtitle_parser = Parser(self._elem._subtitles[lang])
		except:
			self._subtitle_lang = old_lang
	        self._subtitle_parser = old_parser
			raise

    @pyqtSlot(int)
    def set_position(self, new_position):
		self._position = new_position
    	self.fileChanged.emit("", -1)

	### basic information ###

    @pyqtProperty(str)
    def movie_title(self):
        return self._elem._elem_obj.get_info().get_name()

    @pyqtProperty(int)
    def movie_width(self):
        return self._elem._cur_movie_data.movie_width

    @pyqtProperty(int)
    def movie_height(self):
        return self._elem._cur_movie_data.movie_height

    @pyqtProperty(QObject)
	def movie_info(self):
		return self._elem._info

    @pyqtProperty(QObject)
	def max_av_level(self):
		return self._elem._max_av_level

    @pyqtProperty(QObject)
	def cur_av_level(self):
		return self._elem._cur_av_level

    @pyqtProperty(QArray)
	def subtitle_languages(self):
		return self._elem._subtitles.keys()

	### dynamic information ###

    @pyqtProperty(int)
    def movie_duration(self):
        return self._elem._cur_movie_data.movie_duration

    @pyqtProperty(str)
    def audio_language(self):
        return self._audio_lang

    @pyqtProperty(str)
    def subtitle_language(self):
        return self._subtitle_lang

    @pyqtProperty(int)
    def cur_position(self):
        return self._position

    @pyqtProperty(str)
    def cur_file(self):
        return ""

    @pyqtProperty(int)
    def cur_file_position(self):
        return -1

    @pyqtProperty(str)
    def subtitle_now(self):
    	if self._subtitle_parser is not None:
	    	return self._subtitle_parser.get_subtitle_at(self._position)
	    else:
       		return ""
