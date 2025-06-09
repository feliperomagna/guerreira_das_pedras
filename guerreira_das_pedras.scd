// inicio
// fico imaginando o som que pode uma borboleta escutar ou emitir
// borboletas e almas

// inicio da danca com esse som de back, simbolizando a transformacao de uma borboleta
(
~noise = {
	var freq, sig;
	freq = {exprand(260,390)} ! 50;
	sig = SinOsc.ar(freq) * 0.1;
	sig = Splay.ar(sig, level:Line.kr(0, 0.5, 2));
};
)
~noise.play;



//FLUCOMA
(
//buffers de treinamento
~sax = Buffer.read(s, "/Users/feliperomagna/Library/Mobile Documents/com~apple~CloudDocs/Documents/Pessoais/Doutorado/Doutorado UFMG/Disciplinas/2024/estudos_sc/5yEo_gS5Eds.wav");
~songsax = Buffer.read(s, "/Users/feliperomagna/Library/Mobile Documents/com~apple~CloudDocs/Documents/Pessoais/Doutorado/Doutorado UFMG/Disciplinas/2024/python24/sax_soprano_duet/w6Vraxq69Wo.wav");

//~songsax.play;

//carrega os buffers limpos
~resynth = Buffer(s);
~bases = Buffer(s);
~activations = Buffer(s);

//define numero de componentes da decomposicao
~n_components = 3;

//treinamento
FluidBufNMF.processBlocking(s,~sax,bases:~bases,activations:~activations,resynth:~resynth,resynthMode:1,components:~n_components,action:{"done".postln;});
)
//teste
// ~resynth.play;

// 0 = chaves
// 1 = médios
// 2 = harmonicos graves

//SYNTHDEF
(
// SRC + DELAY
SynthDef(\micdry, {
	arg amp = 0.5, outbus, inbus;
	var mic;
	mic = SoundIn.ar(0, amp);
	mic = Splay.ar(mic, spread: 1, level: amp);
	Out.ar(outbus, mic);
}).add;

SynthDef(\flucomalive, {
	arg maxdelaytime = 0.4, delaytime = 0.2, amp = 1, gate = 1, ptrdelay = 0.4, outbus = 0;
	var src, sig, mix, env, ptr, fluc;
	src = SoundIn.ar(0);//PlayBuf.ar(1,~mic,BufRateScale.ir(~mic),doneAction:2);
	//var src = PlayBuf.ar(1,~songsax,BufRateScale.ir(~songsax), doneAction: 2); //audio para teste
	sig = FluidNMFFilter.ar(src,~bases, 3);
	fluc = sig[0];
	/*mix = mix + CombL.ar(in: mix, maxdelaytime: maxdelaytime, delaytime: delaytime, decaytime: 2, mul: 0.8);
	mix = mix + GVerb.ar(sig[0, 2], 100,7,0.9,drylevel:0, mul: 0.5);*/
	Out.ar(outbus, fluc);
}).add;

SynthDef(\delayping, {
	arg maxdelay = 0.4, delaytime = 0.2, decaytime = 2, amp=1, inbus, outbus;
	var delayint, in;
	in = In.ar(inbus, 1);
	delayint = CombL.ar(in, maxdelaytime: maxdelay, delaytime: delaytime, decaytime: decaytime, mul: amp);
	Out.ar(outbus, delayint);
}).add;

SynthDef(\backnoise, {
	arg freqmin = 260, freqmax = 390, outbus, amp = 0.4;
	var freq, sig;
	freq = {exprand(freqmin, freqmax)} ! 50;
	sig = SinOsc.ar(freq) * 0.1;
	sig = Splay.ar(sig, level:Line.kr(0, amp, 2));
	Out.ar(outbus, sig);
}).add;




////////////AMBISONICS


~order = 3; // set this to the order you want
~numChannels = ((~order + 1)**2).asInteger;
// binaural decoder (~numChannels -> 2) - reads from 'bus' and sums into 'out'
SynthDef.new(\binauralDecoder, { | inbus, outbus = 0 |
	Out.ar(outbus, VSTPlugin.ar(In.ar(inbus, ~numChannels), 2));
}).add;

SynthDef.new(\allradDecoder, { | inbus, outbus = 0 |
	Out.ar(outbus, VSTPlugin.ar(In.ar(inbus, ~numChannels), 2));
}).add;

// stereo encoder (2 -> ~numChannels) - replaces stereo signal with ambisonics signal
SynthDef.new(\stereoEncoder, { | inbus = 0, order, aziangle, width  |
	ReplaceOut.ar(inbus, VSTPlugin.ar(In.ar(inbus, 2), ~numChannels, params: [0, order, 6, aziangle, 9, width]));
}).add;

// ambisonics insert FX (replaces input with output)
SynthDef.new(\ambiFX, { | inbus = 0, bypass, roomsize, revtime, lowcut, lowq, lowgain, hicut, hiq, higain, drywet, fadein, fdnsize |
	ReplaceOut.ar(inbus, VSTPlugin.ar(In.ar(inbus, 2), numOut:  ~numChannels, bypass: bypass, params: [0, roomsize, 1, revtime, 2, lowcut, 3, lowq, 4, lowgain, 5, hicut, 6, hiq, 7, higain, 8, drywet, 9, fadein, 10, fdnsize]));
}).add;

// ambisonics insert Grain
SynthDef.new(\ambiGrain, { | inbus = 0, bypass, order = 0, norm, deltat = 0.222, lenght = 0.230, deltamod = 0.109, lenghtmod = 0.09, pos = 0, posmod = 0, pitch = 0.254, pitchmod = 0, attack = 0, attackmod = 0, decay = 0, decaymod = 0, mix = 0.5, freeze  = 0, aziangle|
	ReplaceOut.ar(inbus, VSTPlugin.ar(In.ar(inbus, 2), numOut: ~numChannels, bypass: bypass, params: [0,order,1, norm, 6, aziangle, 12, deltat, 13, deltamod, 14, lenght, 15, lenghtmod, 16, pos, 17, posmod, 18, pitch, 19, pitchmod, 20, attack, 21, attackmod, 22, decay, 23, decaymod, 24, mix, 26, freeze]));
}).add;

// helper Synth (throws audio from ambi bus to ambi master bus)
SynthDef.new(\ambiThrow, { | from, to |
	Out.ar(to, In.ar(from, ~numChannels));
}).add;

)




(
// BUS + GROUP

//s.plotTree;
~delay_bus = Bus.audio(s, 1);
~ambiMasterBus = Bus.audio(s, ~numChannels);
~mixFinalBus = Bus.audio(s, 1);
~ambiMasterGroup = Group.new;
// binaural decoder (writes to master output)
~decoder = VSTPluginController(Synth(\binauralDecoder, [\inbus, ~ambiMasterBus, \outbus, 0],
    target: ~ambiMasterGroup, addAction: \addToTail)).open("BinauralDecoder");
// AllRADDecoder option
/*~decoder = VSTPluginController(Synth(\allradDecoder, [\inbus, ~ambiMasterBus, \outbus, 0],
    target: ~ambiMasterGroup, addAction: \addToTail)).open("AllRADecoder");*/
// a group for ambisonic master effects
~ambiMasterFXGroup = Group.before(~decoder.synth);
)



/// PLAY
(
// N ambisonic busses (3rd order) with stereo encoder. add ambi groups *before* master group!
~numBus = 4; // change this if you want
~ambiBus = Array.newClear(~numBus);
~ambiGroup = Array.newClear(~numBus);
~encoder = Array.newClear(~numBus);
~numBus.do { |i|
    ~ambiBus[i] = Bus.audio(s, ~numChannels);
    ~ambiGroup[i] = Group.before(~ambiMasterGroup);
    // sound source (head)
	~delayping = Synth(\delayping, [\inbus, ~delay_bus, \outbus, ~ambiBus[i], \amp, 1 / ~numBus], target: ~ambiGroup[i]);
    //Synth.new(\test, [\out, ~ambiBus[i], \vol, 1.0 / ~numBus], ~ambiGroup[i], addAction: \addToHead);
    // encoder (after sound source)
    ~encoder[i] = VSTPluginController(Synth(\stereoEncoder, [\inbus, ~ambiBus[i]],
		target: ~ambiGroup[i], addAction: \addToTail));
    // open plugin and randomize azimuth
    ~encoder[i].open("StereoEncoder", action: { |self| self.set(6, rand(1.0)) }); // 6 -> azimuth
    // throw to master section (after encoder)
    Synth(\ambiThrow, [\from, ~ambiBus[i], \to, ~ambiMasterBus], target: ~ambiGroup[i], addAction: \addToTail);

    // you can add more sound sources to the head of the group, stereo FX *before* the encoder and ambi FX *after* the encoder:
    // sound source, [sound source] ..., [stereo FX], [stereo FX], ..., ENCODER, [ambi FX], [ambi FX], ..., THROW
~flucomalive = Synth(\flucomalive, [\outbus, ~delay_bus]);
~mic_dry = Synth(\micdry, [\outbus, 0, \amp, 0.7]);

}
)

~mic_dry = Synth(\micdry, [\outbus, 0, \amp, 0.9]);
~noise = Synth(\backnoise, [\outbus, 0, \amp, 0.3]);

~encoder.do(_.set(6, rand(1.0))); // 6 -> azimuth

~ambiReverb = VSTPluginController(Synth(\ambiFX, [\inbus, ~ambiMasterBus, \outbus, 0, \drywet, 0.5, \roomsize, 0.3, \revtime, 0.3, \lowcut, 0.4, \fdnsize, 0.5],
	target:~ambiMasterFXGroup)).open("FdnReverb");

~ambiGrain = VSTPluginController(Synth(\ambiGrain, [\inbus, ~delay_bus, \outbus, ~ambiMasterBus, \freeze, 0],
	target: ~ambiMasterFXGroup)).open("GranularEncoder");



~fx.set(\drywet, 0.5);
~ambiReverb.get(2, {arg f; f.postln;});
~ambiReverb.gui;



(
~lfoGroup = Group.new;
~lfoBus = ~numBus.collect { Bus.control };
~lfo = ~numBus.collect { |i| { | rate = 0.2 | LFNoise1.kr(rate, 0.5, 0.5) }.play(~lfoGroup, ~lfoBus[i]) };
~encoder.do { | enc, i | enc.map(6, ~lfoBus[i]) }; // map azimuth parameter (nr. 6) to control bus
)

~encoder[0].editor;


~lfoGroup.set(\rate, exprand(0.1, 4.0));
~ambiReverb.gui;
~ambiGrain.editor;
~ambiGrain.gui;


// OSC
(
OSCdef.new(
	\pointsx,
	{
		arg msg, time, addr, recvPort;
		~ambiGrain.synth.set(\aziangle, msg[1]);
		msg[1].postln;


	},
	"/xright", recvPort: 12345
);

OSCdef.new(
	\fingers,
	{
		arg msg, time, addr, recvPort;
		~ambiGrain.synth.set(\freeze, msg[1]);
		msg[1].postln;


	},
	"/fingers1", recvPort: 12345
);
)






