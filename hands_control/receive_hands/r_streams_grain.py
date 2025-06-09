from pyo import *

s = Server(winhost='asio').boot()

# The sound table to granulate.
table = SndTable("frag.wav")
# table = SndTable("voice.wav")

# Listen addresses '/density', '/position', '/pitch_rand' and '/duration' on port 9000.
rec = OscReceive(port=9000, address=["/yright", "/xright", "/yleft", "/xleft"])

# Sets initial values for the OSC streams. This allow the program to run with
# minimal behaviour even if no message have been sent on these addresses.
rec.setValue("/yright", 0.5)
rec.setValue("/xright", 0.5)
rec.setValue("/yleft", 0.0)
rec.setValue("/xleft", 0.5)

# Density of grains, between 1 and 250 grains per second.
dens = SigTo(rec["/yright"], time=0.05, mul=249, add=1)

# Reading position, in samples, in the table + little jitter noise.
pos = SigTo(rec["/xright"], time=0.05, mul=table.getSize(), add=Noise(100))

# Amplitude of a jitter noise around 1.0 to control the pitch of individual grains.
rpit = SigTo(rec["/yleft"], time=0.05, mul=0.2, add=0.001)
pit = Noise(mul=rpit, add=1)

# Grain duration, between 0.025 and 0.5 second.
dur = SigTo(rec["/xleft"], time=0.05, mul=0.475, add=0.025)

grain = Particle(
    table=table,  # table to read samples from.
    env=HannTable(),  # grain envelope.
    dens=dens,  # density of grains per second.
    pitch=pit,  # pitch of grains.
    pos=pos,  # position in the table where to start the grain.
    dur=dur,  # grain duration.
    dev=0.01,  # Maximum deviation of the starting time of the grain.
    pan=Noise(0.5, 0.5),  # Panning factor of the grain.
    chnls=2,  # Number of channels to output.
    mul=0.15,
).out()

s.gui(locals())