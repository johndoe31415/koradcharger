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
parser.add_argument("-m", "--mah", action = "store_true", help = "Instead of voltage, plot the mAh that have been charged by integrating the charging current.")
parser.add_argument("-o", "--output", metavar = "pngfile", default = "charging_graph.png", help = "Output file to write to. Defaults to %(default)s.")
parser.add_argument("logfile", metavar = "logfile", help = "A charging log.")
args = parser.parse_args(sys.argv[1:])

gpd = GnuPlotDiagram(title = "Charging Diagram", xtitle = "Time", ytitle = "Current / A", ytitle2 = "Voltage / V" if (not args.mah) else "Charge / mAh")
data_v = [ ]
data_i = [ ]
data_mah = [ ]
with open(args.logfile) as f:
	t0 = None
	tlast = None
	mah = 0
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
		tlast = data["t"]

	gpd.add_dataset(GnuPlotDataset(data_i, title = "Current", line_width = 2))
	if not args.mah:
		gpd.add_dataset(GnuPlotDataset(data_v, title = "Voltage", line_width = 2, axis = 2))
	else:
		gpd.add_dataset(GnuPlotDataset(data_mah, title = "Charge in mAh", line_width = 2, axis = 2))

gpd.write_rendered(args.output)
