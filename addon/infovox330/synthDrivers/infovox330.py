# Infovox 330 - 64-bit proxy. Launches NVDA's bundled 32-bit synth host and
# points it at this add-on's own reg-free driver in synthDrivers32/.
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
