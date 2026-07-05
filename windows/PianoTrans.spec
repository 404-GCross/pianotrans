# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

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
                 # torch subpackages not needed for inference
                 # NOTE: do NOT exclude torch.distributed — it is imported
                 #       by torch.utils.data.dataloader even in single-GPU mode
                 'torchvision',
                 'torchaudio',
                 'torch.utils.tensorboard',
                 # Test / dev tools (not needed at runtime)
                 'pytest',
                 'unittest',
                 'pip',
                 'setuptools',
                 'wheel',
                 'pkg_resources',
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
