[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

addpath(genpath(cDirThis));

% Dir of application
cDirApp = fullfile(cDirThis, '..');

% Add github/cnanders/matlab-npoint-lc400 and its dependencies
addpath(fullfile(cDirApp, 'vendor', 'github', 'cnanders', 'matlab-npoint-lc400', 'pkg'));
addpath(fullfile(cDirApp, 'vendor', 'github', 'cnanders', 'matlab-hex', 'pkg'));
addpath(fullfile(cDirApp, 'vendor', 'github', 'cnanders', 'matlab-ieee', 'pkg'));

% Add github/cnanders/mic lib 
addpath(genpath(fullfile(cDirApp, 'libs', 'mic')));

% Add functions
addpath(genpath(fullfile(cDirApp, 'functions')));

% Known bug in MATLAB that you cannot add a class to a path and then import
% it later in th same script.  Wrapping the import with eval() works.

% eval('import npoint.hex.HexUtils');
% eval('import npoint.lc400.LC400');

purge

cl = Clock('Master');
sc = ScannerControl(...
    'cl', cl ...
);
sc.build();
