// SETUP ANTES DE COMECAR A PECA
ServerOptions.devices;
(

~placa = "M-Track Eight";
//~placa = "Scarlett 18i20 USB";
//~placa = "M-Track Eight"
//~placa = "H5";

//s.makeGui;
//s = Server.local;
//o = s.options;
o.device = ~placa;
// s.options.numInputBusChannels = 16;
// s.options.numOutputBusChannels = 16;
// s.options.blockSize = 64;
// s.options.sampleRate = 44100;
// s.options.maxNodes = 4096;
// s.options.numAudioBusChannels = 300;
// s.options.numWireBufs = 4096;
//
s.newAllocators; //reseta buffers e buses
)

//////HABILITAR GRAVACAO ********************************************************************

(
~trainroutine = Routine({

	s.boot;

	//espera o servidor iniciar antes de começar a rotina principal

	s.waitForBoot({

		//s.record;
		s.sync;

		this.executeFile(Document.current.dir +/+ "01_treinamento_flucoma_performance.scd");
		s.sync;
	});
}).play;
)


~ampGrain = 1;
///////// COMECOU!!

(
~mainroutine = Routine({


	////////////// Definições gerais que independem do servidor
	s.record;
	s.sync;

	//s.boot;

	//espera o servidor iniciar antes de começar a rotina principal

	s.waitForBoot({

		//s.record;
		s.sync;

		this.executeFile(Document.current.dir +/+ "02_synthdefs_guerreira_das_pedras.scd");
		s.sync;

		this.executeFile(Document.current.dir +/+ "03_osc_guerreira_das_pedras.scd");
		s.sync;





	// BUS + GROUP

	//s.plotTree;
	~delay_bus = Bus.audio(s, 1);
	s.sync;
	~dualdelay_bus = Bus.audio(s, 1);
	s.sync;
	~ambiMasterBus = Bus.audio(s, ~numChannels);
	s.sync;
	~ambiMasterGroup = Group.new;
/*	s.sync;*/
	// binaural decoder (writes to master output)
	/*~decoder = VSTPluginController(Synth(\binauralDecoder, [\inbus, ~ambiMasterBus, \outbus, 0],
		target: ~ambiMasterGroup, addAction: \addToTail)).open("BinauralDecoder");*/
	s.sync;
	// AllRADDecoder option
	~decoder = VSTPluginController(Synth(\allradDecoder, [\inbus, ~ambiMasterBus, \outbus, 0, \gate, 1, \amp, 0.6],
	target: ~ambiMasterGroup, addAction: \addToTail)).open("AllRADecoder");
	s.sync;
	// a group for ambisonic master effects*/
	~ambiMasterFXGroup = Group.before(~decoder.synth);
	s.sync;


	~decoder.readProgram("/Users/feliperomagna/Library/Mobile Documents/com~apple~CloudDocs/Documents/Pessoais/Doutorado/Doutorado UFMG/Disciplinas/2024/guerreira_das_pedras/ambi_presets/ecris_octa-setup_28jun.fxp");
	s.sync;

/// PLAY

// N ambisonic busses (3rd order) with stereo encoder. add ambi groups *before* master group!
	~numBus = 4; // change this if you want
	s.sync;
	~ambiBus = Array.newClear(~numBus);
	s.sync;
	~ambiGroup = Array.newClear(~numBus);
	s.sync;
	~encoder = Array.newClear(~numBus);
	s.sync;
	~numBus.do { |i|
		~ambiBus[i] = Bus.audio(s, ~numChannels);
		~ambiGroup[i] = Group.before(~ambiMasterGroup);
		// sound source (head)
		~delayping = Synth(\delayping, [\inbus, ~delay_bus, \outbus, ~ambiBus[i], \decaytime, 3, \amp, 5 / ~numBus], target: ~ambiGroup[i]);
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


	};

s.sync;
~flucomalive = Synth(\flucomalive, [\outbus, ~delay_bus, \amop, 2]);
~mic_dry = Synth(\micdry, [\outbus, 0, \amp, 0.7, \gate, 1]);
~backsound = Synth(\backsound, [\i_freq, 130, \gate, 1, \amp, 0.3, \harm,Array.geom(1, 9, 1.61)]);
s.sync;
~encoder.do(_.set(6, rand(1.0))); // 6 -> azimuth
s.sync;
~dualDelay = VSTPluginController(Synth(\dualDelay, [\gate, 1, \inbus, ~dualdelay_bus, \outbus, ~ambiMasterBus, \amp, 1], target: ~ambiMasterFXGroup)).open("DualDelay");
s.sync;


~ambiReverb = VSTPluginController(Synth(\ambiFX, [\inbus, ~ambiMasterBus, \outbus, 0, \drywet, 0.98, \roomsize, 1, \revtime, 1, \lowcut, 0.4, \lowgain, 4, \fdnsize, 0.5],
		target:~ambiMasterFXGroup)).open("FdnReverb");
	s.sync;

~lfoGroup = Group.new;
s.sync;
~lfoBus = ~numBus.collect { Bus.control };
s.sync;
~lfo = ~numBus.collect { |i| { | rate = 0.2 | LFNoise1.kr(rate, 0.5, 0.5) }.play(~lfoGroup, ~lfoBus[i]) };
s.sync;
~encoder.do { | enc, i | enc.map(6, ~lfoBus[i]) }; // map azimuth parameter (nr. 6) to control bus


		});
}).play;
)



~ambiGrain = VSTPluginController(Synth(\ambiGrain, [\inbus, ~delay_bus, \outbus, ~ambiMasterBus, \amp, 7, \freeze, 0, \gate, 1],target: ~ambiMasterFXGroup)).open("GranularEncoder");


~ambiGrain.synth.set(\freeze, 1);
~ambiGrain.synth.set(\gate, 0);
~ambiReverb.gui;
~ambiReverb.editor;
~ambiGrain.editor;
~decoder.editor;
~dualDelay.editor;
~dualDelay.gui;

~ampGrain = 1;















/*

~backsound.set(\i_freq, 80, \harm,Array.geom(1, 11, 1.61));
~backsound.set(\gate, 0);

~fx.set(\drywet, 0.5);
~ambiReverb.get(2, {arg f; f.postln;});
~ambiReverb.gui;


~poemaplay = Synth(\poema, [\outbus, ~dualdelay_bus, \amp, 6]);
~poemaplay.set(\amp, 6);
~dualDelay.set(\amp, 2);

(
~endRoutine = Routine({// clean up when finished

	~mic_dry.set(\gate, 0);
	~decoder.synth.set(\gate, 0);
	~ambigrain.set(\gate, 0);
	2.wait;
	~backsound.set(\gate, 0);

}).play;
)




~ambiGrain = VSTPluginController(Synth(\ambiGrain, [\inbus, ~delay_bus, \outbus, ~ambiMasterBus, \amp, 1, \freeze, 0, \gate, 1],
	target: ~ambiMasterFXGroup)).open("GranularEncoder");*/
