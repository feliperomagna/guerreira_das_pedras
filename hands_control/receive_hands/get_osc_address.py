from pyo import *

# Set the port number.
port = 9000

s = Server().boot().start()

print("Play with your OSC interface...")

# Function called whenever OscDataReceive receives an input.
def printInputMessage(address, *args):
    print("Address =", address)
    print("Values =", args)
    print("---------------")


# OscDataReceive accepts any kind of OSC message.
# The wildcard alone ("*") to the address argument means that
# the object will monitor any address on the port.
scan = OscDataReceive(port=port, address="*", function=printInputMessage)

s.gui(locals())