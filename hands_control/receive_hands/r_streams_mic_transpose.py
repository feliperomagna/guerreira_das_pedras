from pyo import *

s = Server(winhost='asio').boot()

# The sound table to granulate.
# snd = Input().out()
snd = SfPlayer("voice.wav", loop=True, mul=0.75).out()

# Listen addresses '/density', '/position', '/pitch_rand' and '/duration' on port 9000.
rec = OscReceive(port=9000, address=["/yright", "/xright", "/yleft", "/xleft"])

# Sets initial values for the OSC streams. This allow the program to run with
# minimal behaviour even if no message have been sent on these addresses.
rec.setValue("/yright", 0)
rec.setValue("/yleft", 0)

### yleft = volume // yright = transposition
vol = SigTo(rec["/yleft"], time=0.05, mul=0.5)
transp = SigTo(rec["/yright"], time=0.05, mul=-2, add=0.4)
# transp2 = transp + 2

# pr = Print(transp, method=1)
harm = Harmonizer(snd, transpo=[transp, transp+1, transp-2], mul=vol).mix(2).out()

s.gui(locals())