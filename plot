#!/usr/bin/python3
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

import sys
import json
from FriendlyArgumentParser import FriendlyArgumentParser
from GnuPlot import GnuPlotDiagram, GnuPlotDataset

parser = FriendlyArgumentParser(description = "Li-Ion charging log plotter.")
parser.add_argument("-a", "--axis1", choices = [ "voltage", "current", "mah", "wh" ], default = "current", help = "First axis content. Can be one of %(choices)s, defaults to %(default)s.")
parser.add_argument("-b", "--axis2", choices = [ "voltage", "current", "mah", "wh", "none" ], default = "mah", help = "Second axis content. Can be one of %(choices)s, defaults to %(default)s.")
parser.add_argument("-o", "--output", metavar = "pngfile", default = "charging_graph.png", help = "Output file to write to. Defaults to %(default)s.")
parser.add_argument("logfile", nargs = "+", metavar = "logfile", help = "A charging log or logs that should be plotted.")
args = parser.parse_args(sys.argv[1:])

class Plotter():
	def __init__(self, args):
		self._args = args
		self._gpd = None

	def _plot(self, filename, include_filename = False):
		data_v = [ ]
		data_i = [ ]
		data_mah = [ ]
		data_wh = [ ]
		with open(filename) as f:
			t0 = None
			tlast = None
			mah = 0
			wh = 0
			for line in f:
				data = json.loads(line)
				if t0 is None:
					t0 = data["t"]
				tdiff = data["t"] - t0
				data_v.append((tdiff, data["data"]["ch1"]["vout"]))
				data_i.append((tdiff, data["data"]["ch1"]["iout"]))
				if (tlast is not None) and (data["t"] - tlast) < 5:
					delta_t = data["t"] - tlast
					mah += 1000 * data["data"]["ch1"]["iout"] * delta_t / 3600
					data_mah.append((tdiff, mah))
					wh += data["data"]["ch1"]["vout"] * data["data"]["ch1"]["iout"] * delta_t / 3600
					data_wh.append((tdiff, wh))
				tlast = data["t"]

			suffix = "" if (not include_filename) else (" / %s" % (filename))
			for axis in range(2):
				content = self._args.axis1 if (axis == 0) else self._args.axis2
				if content == "current":
					self._gpd.add_dataset(GnuPlotDataset(data_i, title = "Current%s" % (suffix), line_width = 2, axis = axis + 1))
				elif content == "voltage":
					self._gpd.add_dataset(GnuPlotDataset(data_v, title = "Voltage%s" % (suffix), line_width = 2, axis = axis + 1))
				elif content == "mah":
					self._gpd.add_dataset(GnuPlotDataset(data_mah, title = "Charge in mAh%s" % (suffix), line_width = 2, axis = axis + 1))
				elif content == "wh":
					self._gpd.add_dataset(GnuPlotDataset(data_wh, title = "Charge in Wh%s" % (suffix), line_width = 2, axis = axis + 1))
				elif content == "none":
					pass
				else:
					raise NotImplementedError(content)

	def run(self):
		data = {
			"title": "Charging Diagram",
			"xtitle": "Time / hh:mm",
		}
		axis_descriptions = {
			"voltage":	"Voltage / V",
			"current":	"Current / A",
			"mah":		"Charge / mAh",
			"wh":		"Charge / Wh",
		}
		data["ytitle"] = axis_descriptions[self._args.axis1]
		if self._args.axis2 != "none":
			data["ytitle2"] = axis_descriptions[self._args.axis2]
		self._gpd = GnuPlotDiagram(**data)

		for filename in self._args.logfile:
			self._plot(filename, include_filename = len(self._args.logfile) > 1)

		self._gpd.make_timeplot("%H:%M")
		self._gpd.write_rendered(self._args.output)

plotter = Plotter(args)
plotter.run()
