# About

MATLAB UI for generating waveforms suitable for use in active illumination systems of photolithography instruments with coherent sources.   This software is used by the Berkeley Extreme Ultraviolet (EUV) Microfield Exposure Tool (MET) at Lawrenece Berkeley National Lab.

# Installation

1. Clone this git repo into your MATLAB project, 
2. Clone the git repos of all [dependencies](#dependencies) into your project, preferably in a “vendor” directory.  If any dependencies have dependencies, be sure to bring those in too.  See [Recommended MATLAB App Structure](https://github.com/cnanders/matlab-app-structure)
3. Add the src code of this library and all dependencies to the MATLAB path, e.g., 
```matlab
addpath(genpath('vendor/github/cnanders/matlab-scanner-control-npoint/src'));
addpath(genpath('vendor/github/cnanders/matlab-instrument-control/src'));
addpath(genpath('vendor/github/cnanders/matlab-npoint-lc400/src'));
addpath(genpath('vendor/github/cnanders/matlab-ieee/src'));
addpath(genpath('vendor/github/cnanders/matlab-hex/src'));
```
4. Make sure the nPoint LC400 is recognized.  See [github/cnanders/matlab-npoint-lc400](https://github.com/cnanders/matlab-npoint-lc400)
5. Instantiate a `ScannerControl` and call its `build()` method

```matlab
sc = ScannerControl();
sc.build();
```

<a name="dependencies"></a>
## Dependencies

- [https://github.com/cnanders/matlab-quasar](https://github.com/cnanders/matlab-quasar)
- [https://github.com/cnanders/matlab-instrument-control](https://github.com/cnanders/matlab-instrument-control) for the UI (v1.1.0)
- [https://github.com/cnanders/matlab-npoint-lc400](https://github.com/cnanders/matlab-npoint-lc400) for MATLAB communication with nPoint LC.400 controller

