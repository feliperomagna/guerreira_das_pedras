(
~order = 3; // set this to the order you want
~numChannels = ((~order + 1)**2).asInteger;

// SRC + DELAY
SynthDef(\micdry, {
	arg amp = 0.3, outbus, soundinbus=0, gate=0;
	var mic, env;
	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.1, sustainLevel: 0.3, releaseTime: 7), gate);
	mic = SoundIn.ar(soundinbus, amp);
	mic = Splay.ar(mic, spread: 1, level: amp);
	mic = mic * env * amp;
	//Out.ar(outbus, LPF.ar(FreeVerb.ar(mic, mix: 0.7, room: 0.6, damp: 0.3, mul: 0.8),8000));
	Out.ar(outbus, LPF.ar(NHHall.ar((mic[0])!2),8000)[0]);

}).add;

SynthDef(\flucomalive, {
	arg maxdelaytime = 0.4, delaytime = 0.2, amp = 1, gate = 1, ptrdelay = 0.4, outbus = 0, soundinbus=0;
	var src, sig, mix, env, ptr, fluc;
	//env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.1, sustainLevel: 0.5, releaseTime: 3), gate);
	src = SoundIn.ar([soundinbus]);//PlayBuf.ar(1,~mic,BufRateScale.ir(~mic),doneAction:2);
	//var src = PlayBuf.ar(1,~songsax,BufRateScale.ir(~songsax), doneAction: 2); //audio para teste
	sig = FluidNMFFilter.ar(src,~bases, 3);
	fluc = sig[0] * amp;
	/*mix = mix + CombL.ar(in: mix, maxdelaytime: maxdelaytime, delaytime: delaytime, decaytime: 2, mul: 0.8);
	mix = mix + GVerb.ar(sig[0, 2], 100,7,0.9,drylevel:0, mul: 0.5);*/
	Out.ar(outbus, fluc);
}).add;

SynthDef(\delayping, {
	arg maxdelay = 0.4, delaytime = 0.2, decaytime = 3, amp=1, inbus, outbus;
	var delayint, in;
	in = In.ar(inbus, 1);
	delayint = CombL.ar(in, maxdelaytime: maxdelay, delaytime: delaytime, decaytime: decaytime, mul: amp);
	Out.ar(outbus, delayint);
}).add;


SynthDef(\backsound, {
	arg i_freq, outbus, size, gate = 0, mul = 0.5;
    var klank, n, harm, amp, ring, sig, env;
	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.1, sustainLevel: 0.5, releaseTime: 7), gate);
    harm = \harm.ir(Array.series(4, 1, 1)); // harmonics
    amp = \amp.ir(Array.fill(4, 0.40)); // amplitudes
	ring = \ring.ir(Array.fill(4, 1)); // ring times
    klank = Klank.ar(`[harm, amp, ring], {BrownNoise.ar(0.003)}.dup, i_freq);
	sig = Splay.ar(klank, level: Line.kr(0, amp, 7));
	sig = sig * env * mul;
    Out.ar(outbus, sig);
}).add;


~poemabuf = Buffer.read(s, "/Users/feliperomagna/Library/Mobile Documents/com~apple~CloudDocs/Documents/Pessoais/Doutorado/Doutorado UFMG/Disciplinas/2024/guerreira_das_pedras/poema_serena_master.wav");

SynthDef(\poema, { | outbus, amp = 1.0, gate = 1 |
	var env, sig;
	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.1, sustainLevel: 0.5, releaseTime: 3), gate);
	sig = PlayBuf.ar(numChannels: 2, bufnum: ~poemabuf);
	sig = sig * amp * env;
	Out.ar(outbus, sig);
}).add;



///////////AMBISONICS

// binaural decoder (~numChannels -> 2) - reads from 'bus' and sums into 'out'
SynthDef.new(\binauralDecoder, { | inbus, outbus = 0 |
    Out.ar(outbus, VSTPlugin.ar(In.ar(inbus, ~numChannels), 2));
}).add;

SynthDef.new(\allradDecoder, { | inbus, outbus = 0, gate = 0, amp = 0.4|
	var env;
	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.1, sustainLevel: 0.5, releaseTime: 7), gate);
    Out.ar(outbus, VSTPlugin.ar(In.ar(inbus, ~numChannels), 8)*env*amp);
}).add;

// stereo encoder (2 -> ~numChannels) - replaces stereo signal with ambisonics signal
SynthDef.new(\stereoEncoder, { | inbus = 0, order, aziangle, width  |
	ReplaceOut.ar(inbus, VSTPlugin.ar(In.ar(inbus, 2), ~numChannels, params: [0, order, 6, aziangle, 9, width]));
}).add;

// ambisonics insert FX (replaces input with output)
SynthDef.new(\ambiFX, { | inbus = 0, bypass, roomsize, revtime, lowcut, lowq, lowgain, hicut, hiq, higain, drywet, fadein, fdnsize |
	ReplaceOut.ar(inbus, VSTPlugin.ar(In.ar(inbus, 2), numOut:  ~numChannels, bypass: bypass, params: [0, roomsize, 1, revtime, 2, lowcut, 3, lowq, 4, lowgain, 8, hicut, 6, hiq, 7, higain, 8, drywet, 9, fadein, 10, fdnsize]));
}).add;

// ambisonics insert Grain
SynthDef.new(\ambiGrain, {
	| inbus = 0, bypass, order = 0, norm, deltat = 0.222, lenght = 0.170, deltamod = 0.109, lenghtmod = 0.09, pos = 0, posmod = 0, pitch = 0.254, pitchmod = 0, attack = 0.08, attackmod = 0.08, decay = 0.5, decaymod = 0.2, mix = 0.7, freeze  = 0, aziangle, gate = 0, amp = 3, outbus|
	var env;
	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.1, sustainLevel: 0.3, releaseTime: 2), gate);
	Out.ar(outbus, VSTPlugin.ar(In.ar(inbus, 2)*~ampGrain, numOut: ~numChannels, bypass: bypass, params: [0,order,1, norm, 6, aziangle, 12, deltat, 13, deltamod, 14, lenght, 15, lenghtmod, 16, pos, 17, posmod, 18, pitch, 19, pitchmod, 20, attack, 21, attackmod, 22, decay, 23, decaymod, 24, mix, 26, freeze]) * env * amp);
}).add;

SynthDef.new(\dualDelay, {
	arg gate = 1, amp = 1, outbus, inbus, bypass, lowpassright = 8000, lowpassleft = 1200;
	var env, sig;
	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.1, sustainLevel: 0.3, releaseTime: 7), gate);
	sig = VSTPlugin.ar(In.ar(inbus, 2), ~numChannels, bypass: bypass, params: [9, lowpassright, 10, lowpassleft]);
	sig = sig * amp * env;
	Out.ar(outbus, sig);
}).add;
// helper Synth (throws audio from ambi bus to ambi master bus)
SynthDef.new(\ambiThrow, { | from, to |
    Out.ar(to, In.ar(from, ~numChannels));
}).add;

)