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


class MovieInfo(QObject):

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

	@property
	def standard_full(self):
		return "%s/%d" % (self.standard, self.frame_rate)

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


class MovieElem(QObject):
	"""Contains static information"""

	DEFECT_INCONSISTENT = 1				# global defect: movie data are not consistent
	DEFECT_NO_ORIGINAL = 2				# global defect: no any original movie data
	DEFECT_WATERMARK = 10				# per-data defect: movie has watermark
	DEFECT_EMBED_SUBTITLES = 11			# per-data defect: movie file has embeded subtitles, the subtitles should be contained in seperate file, in text format
	DEFECT_SHOT_VERSION = 12			# per-data defect: movie file is shot version, not clear
	DEFECT_INCOMPLETE = 13				# per-data defect: movie file is clipped, not the full version
	DEFECT_TRIM_NEEDED = 14				# per-data defect: movie file contains uneccessary header or footer, mostly ads
	DEFECT_TS_WITHOUT_PAR2 = 15			# per-data defect: *.ts file should have corresponding .par2 files as its checksum

    def __init__(self, element_path):
        QObject.__init__(self)

        self._elem_obj = elemlib.open_element(element_path, "ro")

		self._info = MovieInfo()
		self._movie_data_list = []
		self._subtitles = dict()

		self._ori_movie_data_index_list = []
		self._cur_movie_data_index = -1
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
			self._movie_data_list.append(MovieData(fname))

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
        # set default value
        self.moduleDict = dict()

        # parse file
        h = _MovieInfoFileXmlHandler(self. moduleDict)
        xml.sax.parse(self.param.modulesFile, h)

        # post process
        for m in self.moduleDict:
            # check parse result
            strList = m.split("-")
            if len(strList) < 3:
                raise Exception("Invalid module name \"%s\"" % (m))

            moduleScope = strList[0]
            moduleType = strList[1]
            moduleId = "-".join(strList[2:])
            if moduleScope not in ["sys", "usr"]:
                raise Exception("Invalid module scope for module name \"%s\"" % (m))
            if moduleType not in ["server", "client", "peer"]:
                raise Exception("Invalid module type for module name \"%s\"" % (m))
            if len(moduleId) > 32:
                raise Exception("Module id is too long for module name \"%s\"" % (m))
            if re.match("[A-Za-z0-9_]+", moduleId) is None:
                raise Exception("Invalid module id for module name \"%s\"" % (m))

            moduleObj = None
            exec("import %s" % (m.replace("-", "_")))
            exec("moduleObj = %s.ModuleObject()" % (m.replace("-", "_")))

            if m != moduleObj.getModuleName():
                raise Exception("Module \"%s\" does not exists" % (m))
            if True:
                propDict = moduleObj.getPropDict()
                if "allow-local-peer" not in propDict:
                    raise Exception("Property \"allow-local-peer\" not provided by module \"%s\"" % (m))
                if "suid" not in propDict:
                    raise Exception("Property \"suid\" not provided by module \"%s\"" % (m))
                if "standalone" not in propDict:
                    raise Exception("Property \"standalone\" not provided by module \"%s\"" % (m))
                if not isinstance(propDict["allow-local-peer"], bool):
                    raise Exception("Property \"allow-local-peer\" in module \"%s\" should be of type bool" % (m))
                if not isinstance(propDict["suid"], bool):
                    raise Exception("Property \"suid\" in module \"%s\" should be of type bool" % (m))
                if not isinstance(propDict["standalone"], bool):
                    raise Exception("Property \"standalone\" in module \"%s\" should be of type bool" % (m))
                if moduleScope == "sys" and propDict["suid"]:
                    raise Exception("Property \"suid\" in module \"%s\" must be equal to False" % (m))

            # fill SnCfgModuleInfo object
            self.moduleDict[m].moduleScope = moduleScope
            self.moduleDict[m].moduleType = moduleType
            self.moduleDict[m].moduleId = moduleId
            self.moduleDict[m].moduleObj = moduleObj


class MovieModule(QObject):
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
	        self._elem = MovieElem(element_path)
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

class MovieInfoXmlSyntaxError(Exception):

    def __init__(self, message):
        super(MovieInfoParseError, self).__init__(message)


class _MovieInfoXmlHandler(xml.sax.handler.ContentHandler):
    INIT = 0
    IN_ROOT = 1
    IN_RUNTIME = 2
    IN_ASPECT_RATIO = 3
    IN_LINKS = 4
    IN_LINES_WIKI = 5
    IN_LINKS_IMDB = 6
    IN_DATA = 7
    IN_DATA_ORIGINAL = 8
    IN_DATA_DEFECTS = 9
    IN_DATA_DEFECTS_DEFECT = 10

    def __init__(self):
        xml.sax.handler.ContentHandler.__init__(self)
        self.state = self.INIT

		self.runtime = -1
		self.aspect_ratio = (-1, -1)
		self.wiki_links = dict()			# dict<lang:str, url:str>
		self.imdb_link = ""
		self.data_dict = dict()				# dict<dir:str, (is_original:bool, defects:list<int>)>

		self.cur_wiki_lang = None
		self.cur_data_dir = None
		self.cur_data_original = None
		self.cur_data_defects = None

    def startElement(self, name, attrs):
        if name == "movie-info" and self.state == self.INIT:
            self.state = self.IN_ROOT
		elif name == "runtime" and self.state == self.IN_ROOT:
			self.state = self.IN_RUNTIME
		elif name == "aspect-ratio" and self.state == self.IN_ROOT:
			self.state = self.IN_ASPECT_RATIO
        elif name == "links" and self.state == self.IN_ROOT:
            self.state = self.IN_LINKS
		elif name == "wikipedia" and self.state == self.IN_LINKS:
            self.state = self.IN_LINES_WIKI
            self.cur_wiki_lang = attrs.get("lang", "")
            if self.cur_wiki_lang in self.wiki_links:
				raise MovieInfoXmlSyntaxError("duplicate wikipedia link language %s" % (self.cur_wiki_lang))
		elif name == "imdb" and self.state == self.IN_LINKS:
            self.state = self.IN_LINES_IMDB
        elif name == "data" and self.state == self.IN_ROOT:
            self.state = self.IN_DATA
            self.cur_data_dir = attrs.get("directory", "")
			if self.cur_data_dir in self.data_dict:
				raise MovieInfoXmlSyntaxError("duplicate data directory %s" % (self.cur_data_dir))
            self.cur_data_original = False
            self.cur_data_defects = []
		elif name == "original" and self.state == self.IN_DATA:
			self.state = self.IN_DATA_ORIGINAL
            self.cur_data_original = True
        elif name == "defects" and self.state == self.IN_DATA:
			self.state = self.IN_DATA_DEFECTS
		elif name == "watermark" and self.state == self.IN_DATA_DEFECTS:
			self.state = self.IN_DATA_DEFECTS_DEFECT
			self.cur_data_defects.append(MovieElem.DEFECT_WATERMARK
		elif name == "embed-subtitles" and self.state == self.IN_DATA_DEFECTS:
			self.state = self.IN_DATA_DEFECTS_DEFECT
			self.cur_data_defects.append(MovieElem.DEFECT_EMBED_SUBTITLES
		elif name == "shot-version" and self.state == self.IN_DATA_DEFECTS:
			self.state = self.IN_DATA_DEFECTS_DEFECT
			self.cur_data_defects.append(MovieElem.DEFECT_SHOT_VERSION
		elif name == "incomplete" and self.state == self.IN_DATA_DEFECTS:
			self.state = self.IN_DATA_DEFECTS_DEFECT
			self.cur_data_defects.append(MovieElem.DEFECT_INCOMPLETE
		elif name == "trim-needed" and self.state == self.IN_DATA_DEFECTS:
			self.state = self.IN_DATA_DEFECTS_DEFECT
			self.cur_data_defects.append(MovieElem.DEFECT_TRIM_NEEDED
		elif name == "ts-without-par2" and self.state == self.IN_DATA_DEFECTS:
			self.state = self.IN_DATA_DEFECTS_DEFECT
			self.cur_data_defects.append(MovieElem.DEFECT_TS_WITHOUT_PAR2
        else:
            raise Exception("Failed to parse modules file")

    def endElement(self, name):
        if name == "movie-info" and self.state == self.IN_ROOT:
            self.state = self.INIT
		elif name == "runtime" and self.state == self.IN_RUNTIME:
			self.state = self.IN_ROOT
		elif name == "aspect-ratio" and self.state == self.IN_ASPECT_RATIO:
			self.state = self.IN_ROOT
        elif name == "links" and self.state == self.IN_LINKS:
            self.state = self.IN_ROOT
		elif name == "wikipedia" and self.state == self.IN_LINKS_WIKI:
			self.cur_wiki_lang = None
            self.state = self.IN_LINKS
		elif name == "imdb" and self.state == self.IN_LINKS_IMDB:
            self.state = self.IN_LINES
        elif name == "data" and self.state == self.IN_DATA:
			self.data_dict[self.cur_data_dir] = (self.cur_data_original, self.cur_data_defects)
			self.cur_data_defects = None
			self.cur_data_original = None
			self.cur_data_dir = None
            self.state = self.IN_ROOT
		elif name == "original" and self.state == self.IN_DATA_ORIGINAL:
			self.state = self.IN_DATA
		elif name == "defects" and self.state == self.IN_DATA_DEFECTS:
			self.state = self.IN_DATA
		elif name == "watermark" and self.state == self.IN_DATA_DEFECTS_DEFECT:
			self.state = self.IN_DATA_DEFECTS
		elif name == "embed-subtitles" and self.state == self.IN_DATA_DEFECTS_DEFECT:
			self.state = self.IN_DATA_DEFECTS
		elif name == "shot-version" and self.state == self.IN_DATA_DEFECTS_DEFECT:
			self.state = self.IN_DATA_DEFECTS
		elif name == "incomplete" and self.state == self.IN_DATA_DEFECTS_DEFECT:
			self.state = self.IN_DATA_DEFECTS
		elif name == "trim-needed" and self.state == self.IN_DATA_DEFECTS_DEFECT:
			self.state = self.IN_DATA_DEFECTS
		elif name == "ts-without-par2" and self.state == self.IN_DATA_DEFECTS_DEFECT:
			self.state = self.IN_DATA_DEFECTS
        else:
            raise Exception("Failed to parse modules file")

    def characters(self, content):
        if self.state == self.IN_RUNTIME:
            self.runtime = int(content)
        elif self.state == self.IN_ASPECT_RATIO:
			r = content.split(":")
            self.aspect_ratio = (float(r[0]), float(r[1]))
		elif self.state == self.IN_LINKS_WIKI:
			self.wiki_links[self.cur_wiki_lang] = content
		elif self.state == self.IN_LINKS_IMDB:
			self.imdb_link = content
        else:
            pass

