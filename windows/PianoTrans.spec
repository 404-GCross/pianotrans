# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

from PyInstaller.utils.hooks import collect_data_files

# Minimal: only collect librosa data files that are actually needed
datas = []

# Hidden imports — PyInstaller may miss these at analysis time
hiddenimports = [
    'sklearn.neighbors._partition_nodes',
    'sklearn.utils._weight_vector',
    'numba',
    'resampy',
    'soundfile',
    'audioread',
]

a = Analysis(['PianoTrans.py'],
             pathex=[],
             binaries=[],
             datas=datas,
             hiddenimports=hiddenimports,
             hookspath=[],
             runtime_hooks=[],
             excludes=[
                 # matplotlib — dependency of piano_transcription_inference
                 # but never used at inference time
                 'matplotlib',
                 # Unnecessary torch subpackages
                 'torchvision',
                 'torchaudio',
                 'torch.distributed',
                 'torch.utils.tensorboard',
                 # Test / dev tools
                 'pytest',
                 'unittest',
                 'setuptools',
                 'pip',
                 'wheel',
                 'pkg_resources',
                 # Jupyter ecosystem (pulled by some packages but unused)
                 'IPython',
                 'jupyter',
                 'jupyter_client',
                 'jupyter_core',
                 'notebook',
                 'nbconvert',
                 'nbformat',
                 'ipykernel',
             ],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          [],
          exclude_binaries=True,
          name='PianoTrans',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=False,
          console=False)
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=False,
               upx=True,
               upx_exclude=[],
               name='PianoTrans')
