
#pragma once

#include "ofMain.h"
#include "ofxOsc.h"

#define HOST "localhost"

#define PORT 8000

// max number of strings to display
#define NUM_MSG_STRINGS 20



class ofApp : public ofBaseApp{
    public:
        void setup();
        void update();
        void draw();

        void keyPressed  (int key);
        void keyReleased(int key);
        void mouseMoved(int x, int y);
        void mouseDragged(int x, int y, int button);
        void mousePressed(int x, int y, int button);
        void mouseReleased(int x, int y, int button);
        void mouseEntered(int x, int y);
        void mouseExited(int x, int y);
        void windowResized(int w, int h);
        void dragEvent(ofDragInfo dragInfo);
        void gotMessage(ofMessage msg);
    
        ofTrueTypeFont font;
        ofxOscSender sender;
        ofBuffer imgAsBuffer;
        ofImage img;

        
		ofxOscReceiver receiver;

        int currentMsgString;
		string msgStrings[NUM_MSG_STRINGS];
		float timers[NUM_MSG_STRINGS];

		int mouseButtonInt = 0;
		string mouseButtonState = "";
        float oscRightX = 0;
        float oscRightY = 0;
        float oscLeftX = 0;
        float oscLeftY = 0;


		ofImage receivedImage;

        //this holds all of our points
        vector<glm::vec3> points;
        //this keeps track of the center of all the points
        glm::vec3 center;

        //our camera objects for looking at the scene from multiple perspectives
        ofCamera camera;

        //if usecamera is true, we'll turn on the camera view
        bool usecamera;
        // use the polyline for smoothing
        ofPolyline polyline;

        bool usePolyline = true;
        int smoothingSize = 1;

        float lastOscMessageTime;
        float fadeOutDuration;
    
        
};

