# Infovox 330 for NVDA - 64-bit proxy driver.
# Copyright (C) 2026 Josh <joshknnd1982@gmail.com>
# This file is covered by the GNU General Public License, version 2 or later.
# See the COPYING file in the project root, and NOTICE.md for third-party rights.
#
# NVDA runs as a 64-bit process and cannot load the 32-bit Infovox COM engine
# directly. This proxy launches NVDA's bundled 32-bit synth host and points it
# at this add-on's own registry-free driver in synthDrivers32/.
import os
from _bridge.clients.synthDriverHost32.synthDriver import SynthDriverProxy32


class SynthDriver(SynthDriverProxy32):
	name = "infovox330"
	description = "Infovox 330"
	# <addon>/synthDrivers/infovox330.py -> <addon>/synthDrivers32
	synthDriver32Path = os.path.join(
		os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
		"synthDrivers32",
	)
	synthDriver32Name = "infovox330"

	@classmethod
	def check(cls):
		if not super().check():
			return False
		return os.path.isfile(os.path.join(cls.synthDriver32Path, "infovox_host.dll"))
