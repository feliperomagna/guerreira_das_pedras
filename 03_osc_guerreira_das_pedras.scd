
(
OSCdef.new(
	\aziosc,
	{
		arg msg, time, addr, recvPort;
		~ambiGrain.synth.set(\aziangle, msg[1]);
		msg[1].postln;


	},
	"/xright", recvPort: 8000;
);


OSCdef.new(\slider1,
	{
		arg msg, time, addr, recvPort;
		defer{

			~slider[0].valueAction_(msg[1].postln).action_({arg v; ~mic_dry.set( \amp, v.value.postln); });

		};
	},
	"/fader1", recvPort: 474747;
);

OSCdef.new(\slider2,
	{
		arg msg, time, addr, recvPort;
		defer{
			~slider[1].valueAction_(msg[1].postln).action_({arg v; ~flucomalive.set( \amp, v.value.postln); });
		};
	},
	"/fader4", recvPort: 474747;
);

OSCdef.new(\slider3,
	{
		arg msg, time, addr, recvPort;
		defer{
			~slider[2].valueAction_(msg[1].postln).action_({arg v; ~backsound.set( \mul, v.value.postln); });
		};
	},
	"/fader3", recvPort: 474747;
);

OSCdef.new(\slider4,
	{
		arg msg, time, addr, recvPort;
		defer{
			~slider[3].valueAction_(msg[1].postln).action_({arg v; ~ambiGrain.set( \amp, v.value.postln); });
		};
	},
	"/fader5", recvPort: 474747;
);

OSCdef.new(\slider5,
	{
		arg msg, time, addr, recvPort;
		defer{
			~slider[4].valueAction_(msg[1].postln).action_({arg v; ~decoder.synth.set( \amp, v.value.postln);});
		};
	},
	"/fader2", recvPort: 474747;
);

OSCdef.new(\buttonBackdark,
	{
		arg msg, time, addr, recvPort;
		defer{
			~button[5].valueAction_(msg[1].postln).action_({arg v; if( msg[1] == 1, {
				~backdark= Synth(\backsound, [\i_freq, 80, \gate, 1, \amp, 0.2, \harm,Array.geom(1, 11, 1.61)])});
			});
	};
	},
	"/button6", recvPort: 474747;
);

OSCdef.new(\buttonGrain,
	{
		arg msg, time, addr, recvPort;
		defer{
			~button[1].valueAction_(msg[1].postln).action_({arg v; if( msg[1] == 1, {
				~ambiGrain = VSTPluginController(Synth(\ambiGrain, [\inbus, ~delay_bus, \outbus, ~ambiMasterBus, \freeze, 0, \gate, 1, \amp, 8], target: ~ambiMasterFXGroup)).open("GranularEncoder")});
			});
		};
	},
	"/button2", recvPort: 474747;
);

OSCdef.new(\buttonFim,
	{
		arg msg, time, addr, recvPort;
		defer{
			~button[2].valueAction_(msg[1].postln).action_({arg v; if( msg[1] == 1,  Routine({~decoder.synth.set(\gate, 0);~ambigrain.set(\gate, 0);2.wait;~backsound.set(\gate, 0); ~backdark.set(\gate, 0);}).play;);

			});
			};
	},
	"/button5", recvPort: 474747;
);

OSCdef.new(\buttonPanico,
	{
		arg msg, time, addr, recvPort;
		defer{
			if (msg[1] == 1, {
			Server.killAll;
			});
		};
	},
	"/button3", recvPort: 474747;
);

OSCdef.new(\poemaOSC,
	{
		arg msg, time, addr, recvPort;
		defer{
			~button[3].valueAction_(msg[1].postln).action_({arg v; if( msg[1] == 1, {
				~poemaplay = Synth(\poema, [\outbus, ~dualdelay_bus, \amp, 6]);
				~ampGrain = 0;
				~dualDelay.editor;
			});
			});
		};

	},
	"/button1", recvPort: 474747;
);

w = Window.new("Guerreira das Pedras", Rect(100, 100, 800, 800)).front;
w.alwaysOnTop;
b = CompositeView(w, Rect(50, 400, 525, 110));
c = CompositeView(w, Rect(50, 50, 525, 310));
c.background = Color.white;
b.background = Color.gray;
c.decorator = FlowLayout(c.bounds);
b.decorator = FlowLayout(b.bounds);
~button = 6.collect({Button.new(b, Rect(0, 0, 100, 100))});
~slider = 5.collect({Slider.new(c, Rect(0, 0, 100, 300))});
~button[0].states_([[0], [1]]).action_({ arg butt;
	if (butt.value == 1,
		{
			~ambiGrain.synth.set(\freeze, 1);
	});
	if (butt.value == 0,
		{
			~ambiGrain.synth.set(\freeze, 0);
	});
});
StaticText(w, Rect(80, 10, 50, 50)).string_("MicDry");
StaticText(w, Rect(180, 10, 50, 50)).string_("Flucoma");
StaticText(w, Rect(280, 10, 70, 50)).string_("BackSound");
StaticText(w, Rect(400, 10, 50, 50)).string_("Grain");
StaticText(w, Rect(500, 10, 50, 50)).string_("Master");
~button[0].string = "Freeze";
~button[1].string = "Grain";
~button[2].string = "Fim";
~button[3].string = "DarkBack";
~button[4].string = "Panico";
~button[5].string = "BackDark";
//w.layout_(HLayout(~button, ~slider));

)



// OSCdef.new(
// 	\backsoundosc,
// 	{
// 		arg msg, time, addr, recvPort;
// 		if(
// 			msg[1] == 1,
// 			/*{
// 			Synth(\backsound, [\i_freq, 80, \harm,Array.geom(1, 11, 1.61)]);
// 			});*/
//
// 		},
// 		"/button1", recvPort: 12345
// 	);

// OSCdef.new(
// 	\fingers,
// 	{
// 		arg msg, time, addr, recvPort;
// 		if(
// 			msg[1] == 0,
// 			{
// 				Synth(\backsound, [\i_freq, 80, \harm,Array.geom(1, 9, 1.61)]);
// 			};
//
// 		);
// 		if(
// 			msg[1] == 1,
// 			{
// 				Synth(\backsound, [\i_freq, 230, \harm,Array.geom(1, 11, 1.61)]);
// 			};
//
// 		);
//
//
// 	},
// 	"/fingers1", recvPort: 12345
//);
