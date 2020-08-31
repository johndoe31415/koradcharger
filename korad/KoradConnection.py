#	koradcharger - Korad KA3005-based Li-Ion CC/CV charger
#	Copyright (C) 2020-2020 Johannes Bauer
#
#	This file is part of koradcharger.
#
#	koradcharger is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; this program is ONLY licensed under
#	version 3 of the License, later versions are explicitly excluded.
#
#	koradcharger is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with koradcharger; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#	Johannes Bauer <JohannesBauer@gmx.de>

import serial
import time

class KoradConnectionException(Exception): pass

class KoradConnection():
	def __init__(self, device):
		self._conn = serial.Serial(device, baudrate = 9600, timeout = 0.1)
		self._channels = 1

	def _rx(self):
		data = self._conn.read(128)
		data = data.rstrip(b"\x00")
		return data.decode("ascii")

	def _tx(self, text):
		data = text.encode("ascii")
		self._conn.write(data)
		time.sleep(0.15)

	def _txrx(self, text):
		for try_no in range(3):
			self._tx(text)
			response = self._rx()
			if response != "":
				return response
			time.sleep(0.5)
		raise KoradConnectionException("Could not get a response to the '%s' command." % (text))

	def _get_float(self, value, char_count = None):
		str_value = self._txrx(value + "?")
		if char_count is not None:
			str_value = str_value[:char_count]
		print("FLOAT", str_value)
		return float(str_value)

	def identify(self):
		return self._txrx("*IDN?")

	def set_v(self, value, channel = 1):
		self._tx("VSET%d:%.2f" % (channel, value))

	def set_i(self, value, channel = 1):
		self._tx("ISET%d:%.3f" % (channel, value))

	def _status(self):
		self._tx("STATUS?")
		status_byte = self._conn.read(1)
		if len(status_byte) != 1:
			return None
		status_byte = status_byte[0]
		status = {
			"ch1":		{
				"mode": "CC" if ((status_byte >> 0) & 1) else "CV",
			},
			"track":	{
				0:	"ind",
				1:	"ser",
				2:	"?",
				3:	"par",
			}[(status_byte >> 2) & 3],
			"beep":		bool((status_byte >> 4) & 1),
			"lock":		bool((status_byte >> 5) & 1),
			"out":		bool((status_byte >> 6) & 1),
		}
		if self._channels >= 2:
			status.update({
				"ch2": {
					"mode":	"CC" if ((status_byte >> 1) & 1) else "CV",
				},
			})
		for channel in range(self._channels):
			dictkey = "ch%d" % (channel + 1)
			status[dictkey].update({
				"vset":		self._get_float("VSET%d" % (channel + 1)),
				"iset":		self._get_float("ISET%d" % (channel + 1), 5),
				"vout":		self._get_float("VOUT%d" % (channel + 1)),
				"iout":		self._get_float("IOUT%d" % (channel + 1), 5),
			})
		return status

	def status(self):
		for try_no in range(3):
			status = self._status()
			if status is not None:
				return status
			time.sleep(0.5)
		raise KoradConnectionException("Could not get a response to the 'status' command.")

	def output(self, state):
		self._tx("OUT%d" % (int(bool(state))))

	def close(self):
		self._conn.close()

	def __enter__(self):
		return self

	def __exit__(self, *args):
		self.close()
