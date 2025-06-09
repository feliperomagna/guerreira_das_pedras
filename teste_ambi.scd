// SynthDefs
(
~order = 3; // set this to the order you want
~numChannels = ((~order + 1)**2).asInteger;
// binaural decoder (~numChannels -> 2) - reads from 'bus' and sums into 'out'
SynthDef.new(\binauralDecoder, { | bus, out = 0 |
    Out.ar(out, VSTPlugin.ar(In.ar(bus, ~numChannels), 2));
}).add;

// stereo encoder (2 -> ~numChannels) - replaces stereo signal with ambisonics signal
SynthDef.new(\stereoEncoder, { | bus = 0 |
    ReplaceOut.ar(bus, VSTPlugin.ar(In.ar(bus, 2), ~numChannels));
}).add;

// ambisonics insert FX (replaces input with output)
SynthDef.new(\ambiFX, { | bus = 0, bypass |
    ReplaceOut.ar(bus, VSTPlugin.ar(In.ar(bus, 2), ~numChannels, bypass));
}).add;

// helper Synth (throws audio from ambi bus to ambi master bus)
SynthDef.new(\ambiThrow, { | from, to |
    Out.ar(to, In.ar(from, ~numChannels));
}).add;

SynthDef(\test, {
	arg freq=440,dur=1,amp=1,outbus=0;
	var fonte, filtro, decay;
	fonte = PinkNoise.ar*EnvGen.ar(Env.perc(0.01,0.04));
	filtro = Resonz.ar(fonte,freq,0.02);
	decay = Decay2.ar(filtro,0.01,dur-0.01)*amp;
	DetectSilence.ar(decay,doneAction: 2);
	Out.ar(outbus,decay)
}).add;

SynthDef(\reverb, {arg inbus,outbus,revtime=5, dry=1,early=0.7,wettail=0.5,amp=1;
	var in,rev;
	in = In.ar(inbus,1);
	rev = GVerb.ar(in,revtime: revtime,drylevel: dry,earlyreflevel: early,taillevel: wettail)*amp;
	Out.ar(outbus, rev);
}).add;

)


(
~ambi_bus = Bus.audio(s, 4);
~src_group = Group.new;
~fx_group = Group.after(~src_group);
~ambi_group = Group.after(~fx_group);
~decoder = VSTPluginController(Synth(\binauralDecoder, [\bus, ~ambi_bus, \out, 0], target: ~ambi_group, addAction: \addToTail));
~decoder.open("BinauralDecoder");
)

(
~src_synth = Routine({
	inf.do({var nota, dur,amp;
		nota = midicps(rrand(60,84));
		dur = rrand(1,10)/4;
		amp = dbamp(rrand(-5,0.0));
		Synth(\test, [\freq, 440, \amp, 1, \dur, 1, \outbus, ~src_group], target: ~src_group);
		(dur/4).wait
	});
}).play();
)
~fx_synth = Synth(\reverb, [\inbus, ~src_group, \outbus, ~decoder], target: ~fx_group);
~encoder = VSTPluginController(Synth(\stereoEncoder, [\bus, ~ambi_bus], target: ~ambi_group, addAction: 'addtoTail'));
~enconder.open("StereoEncoder", action: { |self| self.set(6, rand(1.0)) });




// create ambisonic master section
