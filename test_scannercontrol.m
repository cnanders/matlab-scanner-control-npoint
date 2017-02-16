[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add npoint package
addpath(fullfile(cDirThis, 'pkgs', 'matlab-npoint-lc400'));

% Add mic lib (for purge)
addpath(genpath(fullfile(cDirThis, 'libs', 'mic')));

% Add functions
addpath(genpath(fullfile(cDirThis, 'functions')));

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
