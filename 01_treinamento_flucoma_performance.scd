
//FLUCOMA
(

~mainRoutine = Routine({

	~currentDir = Document.current.dir;

	s.boot;

	s.waitForBoot({

		//buffers de treinamento
		~sax = Buffer.read(s, "/Users/feliperomagna/Library/Mobile Documents/com~apple~CloudDocs/Documents/Pessoais/Doutorado/Doutorado UFMG/Disciplinas/2024/guerreira_das_pedras/5yEo_gS5Eds.wav");

		s.sync;
	/*	~songsax = Buffer.read(s, "/Users/feliperomagna/Library/Mobile Documents/com~apple~CloudDocs/Documents/Pessoais/Doutorado/Doutorado UFMG/Disciplinas/2024/python24/sax_soprano_duet/w6Vraxq69Wo.wav");*/

		//~songsax.play;

		//carrega os buffers limpos
		~resynth = Buffer(s);
		s.sync;
		~bases = Buffer(s);
		s.sync;
		~activations = Buffer(s);
		s.sync;

		//define numero de componentes da decomposicao
		~n_components = 3;
		s.sync;

		//treinamento
		"treinando...".postln;	FluidBufNMF.processBlocking(s,~sax,bases:~bases,activations:~activations,resynth:~resynth,resynthMode:1,components:~n_components, action:{"done".postln;});
		s.sync;

		/*"salvando buffers...".postln;
		~bases.write(path: ~currentDir +/+ "flucoma_buffers_files" +/+ "bases_sax.aiff");
		~activations.write(path: ~currentDir +/+ "flucoma_buffers_files" +/+ "activations_sax.aiff");
		"done".postln;*/

	})
}).play;
)

