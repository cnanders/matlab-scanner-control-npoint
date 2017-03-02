if exist('purge') > 0
    purge
end

[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

addpath(genpath(cDirThis));

% Add this pkg
addpath(genpath(fullfile(cDirThis, '..', 'pkg')));

% Add dependencies (assumed one dir above)
% github/cnanders/mic
% github/cnanders/matlab-npoint-lc400
% github/cnanders/matlab-ieee
% github/cnanders/matlab-hex
addpath(genpath(fullfile(cDirThis, '..', '..', 'mic')));
addpath(genpath(fullfile(cDirThis, '..', '..', 'matlab-npoint-lc400', 'pkg')));
addpath(genpath(fullfile(cDirThis, '..', '..', 'matlab-ieee', 'pkg')));
addpath(genpath(fullfile(cDirThis, '..', '..', 'matlab-hex', 'pkg')));

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
