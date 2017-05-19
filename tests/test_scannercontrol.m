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
addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-instrument-control')));
%addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-npoint-lc400', 'pkg')));
%addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-ieee', 'pkg')));
%addpath(genpath(fullfile(cDirVendor, 'github', 'cnanders', 'matlab-hex', 'pkg')));



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
sc = ScannerControl('cDirWaveforms', cDir);
sc.build();
