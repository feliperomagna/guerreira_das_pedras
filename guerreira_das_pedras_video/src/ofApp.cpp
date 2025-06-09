#include "ofApp.h"


//--------------------------------------------------------------
void ofApp::setup(){
    //just set up the openFrameworks stuff
    ofSetFrameRate(60);
    ofSetVerticalSync(true);
    ofBackground(0);
    
    // open an outgoing connection to HOST:PORT
    // sender.setup(HOST, PORT);

    // listen on the given port
	ofLog() << "listening for osc messages on port " << PORT;
	receiver.setup(PORT);

    //initialize the variable so it's off at the beginning
    usecamera = false;
    //**ALTERACAO */
    lastOscMessageTime = 0; // Initialize last OSC message time
    fadeOutDuration = 100.0f; // Duration in seconds for points to fade out
}

//--------------------------------------------------------------
void ofApp::update(){

    //**ALTERACAO */
    float currentTime = ofGetElapsedTimef();
    // hide old messages
	for(int i = 0; i < NUM_MSG_STRINGS; i++){
		if(timers[i] < ofGetElapsedTimef()){
			msgStrings[i] = "";
		}
	}

   //**ALTERACAO */
    bool receivedMessage = false;

    while (receiver.hasWaitingMessages()) {
        ofxOscMessage msg;
        receiver.getNextMessage(msg);
        if (msg.getAddress() == "/xright") {
            oscRightX = msg.getArgAsFloat(0);
        } else if (msg.getAddress() == "/yright") {
            oscRightY = msg.getArgAsFloat(0);
        } else if (msg.getAddress() == "/xleft") {
            oscLeftX = msg.getArgAsFloat(0);
        } else if (msg.getAddress() == "/yleft") {
            oscLeftY = msg.getArgAsFloat(0);
        }
        receivedMessage = true;
    }
    //**ALTERACAO */
    if (receivedMessage) {
        lastOscMessageTime = currentTime;

        glm::vec3 handRightPoint(oscRightX*ofGetWidth(), oscRightY*ofGetHeight(), 0);
        points.push_back(handRightPoint);

        // glm::vec3 handLeftPoint(oscLeftX*ofGetWidth(), oscLeftY*ofGetHeight(), 0);
        // points.push_back(handLeftPoint);

        if( points.size() > 25 ) {
            points.erase(points.begin());
        }
    }

    // Fade out points when no OSC messages are received
    for (auto& point : points) {
        point.z -= 3; // Move points
    }

    if (currentTime - lastOscMessageTime > fadeOutDuration) {
        float fadeFactor = 1.0f - (currentTime - lastOscMessageTime - fadeOutDuration);
        fadeFactor = ofClamp(fadeFactor, 0.0f, 1.0f);

        for (auto& point : points) {
            point.z *= fadeFactor;
        }

        points.erase(std::remove_if(points.begin(), points.end(), [](const glm::vec3& point) {
            return point.z <= 0.0f;
        }), points.end());
    }

    polyline.clear();
    polyline.addVertices(points);
    if(polyline.getPerimeter() > 5) {
        // polyline = polyline.getResampledBySpacing(2);
        polyline = polyline.getSmoothed(smoothingSize);
    }
}
    // while (receiver.hasWaitingMessages()) {
    //     ofxOscMessage msg;
    //     receiver.getNextMessage(msg);
    //     if (msg.getAddress() == "/xleft") {
    //         oscLeftX = msg.getArgAsFloat(0);
    //     } else if (msg.getAddress() == "/yleft") {
    //         oscLeftY = msg.getArgAsFloat(0);
    //     }
   
        
        
    // ofxOscMessage mx;
    // ofxOscMessage my;
    // ofxOscMessage mz;
    // receiver.getNextMessage(mx);
    // receiver.getNextMessage(my);
    // receiver.getNextMessage(mz);
    
    // glm::vec3 handRightPoint(oscRightX*ofGetWidth(), oscRightY*ofGetHeight(), 0);
    //     points.push_back(handRightPoint);

    // glm::vec3 handLeftPoint(oscLeftX*ofGetWidth(), oscLeftY*ofGetHeight(), 0);
    //     points.push_back(handLeftPoint);

    //  // Remover pontos antigos se exceder 25
    // if (rightHandPoints.size() > 25) {
    //     rightHandPoints.erase(rightHandPoints.begin());
    // }
    // if (leftHandPoints.size() > 25) {
    //     leftHandPoints.erase(leftHandPoints.begin());
    // }

   


    //don't move the points if we are using the camera
//     if(!usecamera){
//         glm::vec3 sumOfAllPoints(0,0,0);
//         for(unsigned int i = 0; i < points.size(); i++){
//             points[i].z -= 3;
//             sumOfAllPoints += points[i];
//         }
//         center = sumOfAllPoints / points.size();
//     }
//     if( points.size() > 25 ) {
//         points.erase(points.begin());
//     }
    
//     polyline.clear();
//     polyline.addVertices( points );
//     if( polyline.getPerimeter() > 5 ) {
//         // this will provide an even distance between points on the line
//               polyline = polyline.getResampledBySpacing(2);
        
//         polyline = polyline.getSmoothed(smoothingSize);
//     }

	
    
// }

// }




//--------------------------------------------------------------
void ofApp::draw(){


    auto verts = points;
    if(usePolyline) {
        verts = polyline.getVertices();
        
    }
    
    ofEnableAlphaBlending();
    ofSetColor(255, 255, 255, 100); 
    glPointSize(4);


    //do the same thing from the first example...
    ofMesh mesh;
    mesh.setMode(OF_PRIMITIVE_POINTS);


    // Keep track of creation time for each point
    // vector<float> pointCreationTimes;
    // pointCreationTimes.resize(verts.size());

    for(unsigned int i = 1; i < (int)verts.size(); i++){


        //find this point and the next point
        glm::vec3 thisPoint = verts[i-1];
        glm::vec3 nextPoint = verts[i];
        if( i < verts.size()-10 ) {
            nextPoint = verts[i+1];
        }

        //get the direction from one to the next.
        //the ribbon should fan out from this direction
        glm::vec3 direction = (thisPoint - nextPoint);

        //get the distance from one point to the next
        float distance = glm::length(direction);

        //get the normalized direction. normalized vectors always have a length of one
        //and are really useful for representing directions as opposed to something with length
        glm::vec3 unitDirection = glm::normalize(direction);

        //find both directions to the left and to the right
        glm::vec3 toTheLeft =  glm::rotate(unitDirection, -90.f, glm::vec3(0,0,1));
        glm::vec3 toTheRight = glm::rotate(unitDirection, 90.f, glm::vec3(0,0,1));


        //use the map function to determine the distance.
        //the longer the distance, the narrower the line.
        //this makes it look a bit like brush strokes
        float thickness = ofMap(distance, 0, 500, 400, 4000, true);
        
        // calculate a taper based on the index
        float indexPct = 1.0f;
        if( i < 25 ) {
            indexPct = ofMap( i, 0, 250, 0.5, 0.0, true );
        }
        thickness *= indexPct;

        
        //calculate the points to the left and to the right
        //by extending the current point in the direction of left/right by the length
        glm::vec3 leftPoint = thisPoint+toTheLeft*thickness;
        glm::vec3 rightPoint = thisPoint+toTheRight*thickness;

        

        //add these points to the triangle strip
        mesh.addVertex(glm::vec3(leftPoint.x, leftPoint.y, leftPoint.z));
        mesh.addVertex(glm::vec3(rightPoint.x, rightPoint.y, rightPoint.z));
    }
    
    //end the shape
    mesh.draw();


   
    mesh.setMode(OF_PRIMITIVE_POINTS);
    for(unsigned int i = 1; i < (int)verts.size(); i++){


        //find this point and the next point
        glm::vec3 thisPoint = verts[i-1];
        glm::vec3 nextPoint = verts[i];
        if( i < verts.size()-10 ) {
            nextPoint = verts[i+1];
        }

        //get the direction from one to the next.
        //the ribbon should fan out from this direction
        glm::vec3 direction = (thisPoint - nextPoint);

        //get the distance from one point to the next
        float distance = glm::length(direction);

        //get the normalized direction. normalized vectors always have a length of one
        //and are really useful for representing directions as opposed to something with length
        glm::vec3 unitDirection = glm::normalize(direction);

        //find both directions to the left and to the right
        glm::vec3 toTheLeft =  glm::rotate(unitDirection, -45.f, glm::vec3(0,0,1));
        glm::vec3 toTheRight = glm::rotate(unitDirection, 45.f, glm::vec3(0,0,1));


        //use the map function to determine the distance.
        //the longer the distance, the narrower the line.
        //this makes it look a bit like brush strokes
        float thickness = ofMap(distance, 0, 500, 400, 4000, true);
        
        // calculate a taper based on the index
        float indexPct = 1.0f;
        if( i < 25 ) {
            indexPct = ofMap( i, 0, 250, 0.5, 0.0, true );
        }
        thickness *= indexPct;

        //calculate the points to the left and to the right
        //by extending the current point in the direction of left/right by the length
        glm::vec3 leftPoint = thisPoint+toTheLeft*thickness;
        glm::vec3 rightPoint = thisPoint+toTheRight*thickness;

        //add these points to the triangle strip
        mesh.addVertex(glm::vec3(leftPoint.x, leftPoint.y, leftPoint.z));
        mesh.addVertex(glm::vec3(rightPoint.x, rightPoint.y, rightPoint.z));

        
    }

    //end the shape
    mesh.draw();

    

    //if we're using the camera, take it away
    // if(usecamera){
    //     camera.end();
    // }
    /*
    ofSetColor( 40 );
    string outString = "Move the mouse to add points to the line";
    outString += "\nUse camera view(spacebar): "+ofToString(usecamera);
    outString += "\nUse polyline for smoothing(p): "+ofToString(usePolyline);
    outString += "\nPolyline smoothing size(up/down): "+ofToString(smoothingSize);
    ofDrawBitmapString( outString, 20, 20 );
     */

     ofDisableAlphaBlending(); 
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    // if( key == ' ' ) {
    //     //hitting spacebar swaps the camera view
    //     usecamera = !usecamera;
    // }
    // if( key == 'p' ) {
    //     usePolyline = !usePolyline;
    // }
    
    // if( key == OF_KEY_UP ) {
    //     smoothingSize++;
    // }
    // if( key == OF_KEY_DOWN ){
    //     smoothingSize--;
    //     if( smoothingSize < 1 ){
    //         smoothingSize=1;
    //     }
    // }
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){
    //if we are using the camera, the mouse moving should rotate it around the whole sculpture
    // if(usecamera){
    //     float rotateAmount = ofMap(ofGetMouseX(), 0, ofGetWidth(), 0, 360);
    //     glm::vec3 furthestPoint;
    //     if (points.size() > 0) {
    //         furthestPoint = points[0];
    //     }
    //     else
    //     {
    //         furthestPoint = glm::vec3(x, y, 0);
    //     }

    //     glm::vec3 directionToFurthestPoint = (furthestPoint - center);
    //     glm::vec3 directionToFurthestPointRotated = glm::rotate(directionToFurthestPoint, ofDegToRad(rotateAmount), glm::vec3(0,1,0));
    //     camera.setPosition(center + directionToFurthestPointRotated);
    //     camera.lookAt(center);
    // }
    // //otherwise add points like before
    // else{
    //     glm::vec3 mousePoint(x, y, 0);
    //     points.push_back(mousePoint);
        
    // }
}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){

}

