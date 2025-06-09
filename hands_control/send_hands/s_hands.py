from cvzone.HandTrackingModule import HandDetector 
import cv2
from osc4py3.as_eventloop import *
from osc4py3 import oscbuildparse
from pythonosc import osc_message_builder
from pythonosc import udp_client


# Start the system.
osc_startup()                                             

# Make client channels to send packets.
osc_udp_client("127.0.0.1", 8000, "supercollider")
osc_udp_client("10.10.10.105", 8000, "openframeworks")

# parâmetros para enviar por osc
width = 640
height = 480

cap = cv2.VideoCapture(1)

detector = HandDetector(staticMode=False, maxHands=2, modelComplexity=1, detectionCon=0.5, minTrackCon=0.5)

while True:
    success, img = cap.read()

    hands, img = detector.findHands(img, draw=True, flipType=True)

    if hands:
        hand1 = hands[0]
        lmList1 = hand1["lmList"] # 21 landmarks for the first hand
        bbox1 = hand1["bbox"]
        center1 = hand1["center"]
        handType1 = hand1["type"] 
       
        
        fingers1 = detector.fingersUp(hand1) # detecção dos dedos
        fingers_status1 = 0 if all(fingers1) else 1 if not any(fingers1) else -1
        # left or right
        # print(f'handType = {handType1}', end = " ")
        # print(f'lmlist = {lmList1}', end = " ")
        # print(f'bbox = {bbox1}, center = {center1}', end = " ")
     

        if handType1 == 'Right':
            posX1 = lmList1[8][0]
            posY1 = lmList1[8][1]
            # print(f'Xr = {posX1/width} Yr = {posY1/height}', end = " ")
            # Build a message and send it.
            msg_xr = oscbuildparse.OSCMessage("/xright", ",f", [1 - (posX1/width)])
            msg_yr = oscbuildparse.OSCMessage("/yright", ",f", [1 - (posY1/height)])
            #msg_fingers1 = oscbuildparse.OSCMessage("/fingers1", ",i", [all_fingers_up1 if all_fingers_up1 else all_fingers_down1])
            if fingers_status1 != -1:
                msg_fingers1 = oscbuildparse.OSCMessage("/fingers1", ",i", [fingers_status1])
                osc_send(msg_fingers1, "openframeworks")
                osc_process()
                osc_send(msg_fingers1, "supercollider")
                osc_process()
            osc_send(msg_xr, "openframeworks")
            osc_process()
            osc_send(msg_yr, "openframeworks")
            osc_process()
            osc_send(msg_xr, "supercollider")
            osc_process()
            osc_send(msg_yr, "supercollider")
            osc_process()
        print(f'posx = {posX1} posy = {posY1}', end = " ")
        # count the number of fingers up for the first hand if it is Left
        if handType1 == 'Left':
            posX2 = lmList1[8][0]
            posY2 = lmList1[8][1]
            print(f'Xl = {posX2/width} Yl = {posY2/height}', end = " ")
            msg_xl = oscbuildparse.OSCMessage("/xleft", ",f", [1 - (posX2/width)])
            msg_yl = oscbuildparse.OSCMessage("/yleft", ",f", [1 - (posY2/height)])
            osc_send(msg_xl, "openframeworks")
            osc_process()
            osc_send(msg_yl, "openframeworks")
            osc_process()
            osc_send(msg_xl, "supercollider")
            osc_process()
            osc_send(msg_yl, "supercollider")
            osc_process()


        # check if a second hand is detected
        if len(hands) == 2:
            hand2 = hands[1]
            lmList2 = hand2["lmList"] # 21 landmarks for the second hand (x,y,z)
            bbox2 = hand2["bbox"]
            center2 = hand2["center"]
            handType2 = hand2["type"]

            if handType2 == 'Right':
                posX3 = lmList2[8][0]
                posY3 = lmList2[8][1]
                print(f'Xr = {posX3/width} Yr = {posY3/height}', end = " ")
                msg_xr = oscbuildparse.OSCMessage("/xright", ",f", [1 - (posX3/width)])
                msg_yr = oscbuildparse.OSCMessage("/yright", ",f", [1 - (posY3/height)])
                osc_send(msg_xr, "openframeworks")
                osc_process()
                osc_send(msg_yr, "openframeworks")
                osc_process()
                osc_send(msg_xr, "supercollider")
                osc_process()
                osc_send(msg_yr, "supercollider")
                osc_process()
            
            if handType2 == 'Left':
                posX4 = lmList2[8][0]
                posY4 = lmList2[8][1]
                print(f'Xl = {posX4/width} Yl = {posY4/height}', end = " ")
                msg_xl = oscbuildparse.OSCMessage("/xleft", ",f", [1 - (posX4/width)])
                msg_yl = oscbuildparse.OSCMessage("/yleft", ",f", [1 - (posY4/height)])
                osc_send(msg_xl, "openframeworks")
                osc_process()
                osc_send(msg_yl, "openframeworks")
                osc_process()
                osc_send(msg_xl, "supercollider")
                osc_process()
                osc_send(msg_yl, "supercollider")
                osc_process()
                  


        print(" ") # new line for better readability

    cv2.imshow("Image", img)
    # cv2.imshow("Image", cv2.flip(img,1))
    cv2.waitKey(1)
