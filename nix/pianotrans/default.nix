{
  lib,
  python3Packages,
  ffmpeg,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "pianotrans";
  version = "1.0.1";
  pyproject = true;
  __structuredAttrs = true;

  src =
    with lib.fileset;
    toSource {
      root = ../../.;
      fileset = unions [
        ../../PianoTrans.py
        ../../setup.py
      ];
    };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    piano-transcription-inference
    resampy
    tkinter
    torch
  ];

  # Project has no tests
  doCheck = false;

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ ffmpeg ])
  ];

  meta = {
    description = "Simple GUI for ByteDance's Piano Transcription with Pedals";
    mainProgram = "pianotrans";
    homepage = "https://github.com/azuwis/pianotrans";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ azuwis ];
  };
})
