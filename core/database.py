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
import json
import sqlite3
from utils import touch_file
from constant import CONFIG_DIR
from PyQt5.QtCore import pyqtSlot, pyqtSignal, pyqtProperty, QObject, QTimer


class Database(QObject):
    lastOpenedPathChanged = pyqtSignal(str)
    lastWindowWidthChanged = pyqtSignal(int)

    def __init__(self):
        QObject.__init__(self)
        self.video_db_path = os.path.join(CONFIG_DIR, "video_db")
        touch_file(self.video_db_path)
        self.video_db_connect = sqlite3.connect(self.video_db_path)
        self.video_db_cursor = self.video_db_connect.cursor()

        self.video_db_cursor.execute(
            "CREATE TABLE IF NOT EXISTS settings(key PRIMARY KEY NOT NULL, value)"
        )

        self._commit_timer = QTimer()
        self._commit_timer.setInterval(500)
        self._commit_timer.setSingleShot(True)
        self._commit_timer.timeout.connect(lambda: self.video_db_connect.commit())

    @pyqtSlot()
    def forceCommit(self):
        self.video_db_connect.commit()

    @pyqtSlot(str, int)
    def record_video_position(self, video_path, video_position):
        movieInfo = json.loads(self.getMovieInfo(video_path))
        movieInfo["position"] = video_position
        self.updateMovieInfo(video_path, json.dumps(movieInfo))

    @pyqtSlot(str, result=int)
    def fetch_video_position(self, video_path):
        movieInfo = json.loads(self.getMovieInfo(video_path))
        return int(movieInfo.get("position", 0))

    def getValue(self, key):
        self.video_db_cursor.execute(
            "SELECT value FROM settings WHERE key=?", (key,)
        )
        result = self.video_db_cursor.fetchone()

        return result[0] if result else ""

    def setValue(self, key, value):
        self.video_db_cursor.execute(
            "INSERT OR REPLACE INTO settings VALUES(?, ?)", (key, value)
        )
        self._commit_timer.start()

    @pyqtSlot(str, result=str)
    def getMovieInfo(self, video_path):
        value = self.getValue(video_path)
        return value if (value.startswith("{") and value.endswith("}")) else "{}"

    @pyqtSlot(str, str, result=str)
    def updateMovieInfo(self, video_path, info):
        self.setValue(video_path, info)

    @pyqtProperty(str, notify=lastOpenedPathChanged)
    def lastOpenedPath(self):
        return self.getValue("last_opened_path") or ""

    @lastOpenedPath.setter
    def lastOpenedPath(self, value):
        value = value[7:] if value.startswith("file://") else value
        value = os.path.dirname(value) if os.path.isfile(value) else value
        self.setValue("last_opened_path", value)
        self.lastOpenedPathChanged.emit(value)

    @pyqtProperty(int, notify=lastWindowWidthChanged)
    def lastWindowWidth(self):
        return int(self.getValue("last_window_width") or 0)

    @lastWindowWidth.setter
    def lastWindowWidth(self, value):
        self.setValue("last_window_width", value)
        self.lastWindowWidthChanged.emit(value)
