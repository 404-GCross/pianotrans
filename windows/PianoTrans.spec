# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

from PyInstaller.utils.hooks import collect_data_files, collect_dynamic_libs

# Collect librosa data files (audio examples, etc.)
datas = collect_data_files('librosa')

# Collect torch CUDA DLLs — critical for GPU support
torch_datas = collect_data_files('torch')
for (src, dst) in torch_datas:
    # Only include shared libraries — reduce bundle size
    if src.endswith(('.dll', '.pyd')):
        datas.append((src, dst))

# Hidden imports — PyInstaller may miss these at analysis time
# NOTE: Some sklearn internal modules are imported dynamically and
# PyInstaller can't trace them. Add only the ones that actually exist
# in your installed sklearn version.
hiddenimports = [
    # sklearn internals (used by librosa via numba)
    'sklearn.neighbors._partition_nodes',
    'sklearn.utils._weight_vector',
    # torch C++ extensions
    'torch',
    'torch._C',
    # misc
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
                 # Exclude unnecessary torch components to reduce size
                 'torchvision',
                 'torchaudio',
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
