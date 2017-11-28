if exist('purge') > 0
    purge
end

[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));
cDirSrc = fullfile(cDirThis, '..', 'src');
cDirVendor = fullfile(cDirThis, '..', 'vendor');

% Add src
addpath(genpath(cDirSrc));

% Add dependencies (assumed one dir above)
% github/cnanders/mic
% github/cnanders/matlab-npoint-lc400
% github/cnanders/matlab-ieee
% github/cnanders/matlab-hex

addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-quasar', 'src')));
addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-instrument-control', 'src')));
addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-npoint-lc400', 'src')));
addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-ieee', 'src')));
addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-hex', 'src')));


% Known bug in MATLAB that you cannot add a class to a path and then import
% it later in th same script.  Wrapping the import with eval() works.

% eval('import hex.HexUtils');
% eval('import npoint.lc400.LC400');

% Optionally configure with the directory where waveforms are saved
% The default is to use pwd

cDir = fullfile( ...
    cDirThis, ...
    'save' ...
);

clock = mic.Clock('test');
sc = ScannerControl(...
    'cLC400TcpipHost', '192.168.0.2', ...
    'clock', clock, ...
    'cDirWaveforms', cDir ...
);
sc.build();
