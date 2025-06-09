from pyo import *

s = Server(winhost='asio').boot()

# The sound table to granulate.
# snd = Input().out()
snd = SfPlayer("voice.wav", loop=True, mul=0.5).out()

# Listen addresses '/density', '/position', '/pitch_rand' and '/duration' on port 9000.
rec = OscReceive(port=9000, address=["/yright", "/xright", "/yleft", "/xleft"])

# Sets initial values for the OSC streams. This allow the program to run with
# minimal behaviour even if no message have been sent on these addresses.
rec.setValue("/yright", 0)
rec.setValue("/yleft", 0)

### yleft = volume // yright = transposition
fb = SigTo(rec["/yleft"], time=0.05, add=-0.2)
time = SigTo(rec["/yright"], time=0.05, mul=1, add=-0.18)

# pr = Print(rec["/yleft"], method=1)
# pr2 = Print(rec["/yright"], method=1)

delay = SmoothDelay(snd, delay=time, maxdelay=2, feedback=fb, mul=0.6).out()

s.gui(locals())