# About

MATLAB UI for generating waveforms suitable for use in active illumination systems of photolithography instruments with coherent sources.   This software is used by the Berkeley Extreme Ultraviolet (EUV) Microfield Exposure Tool (MET) at Lawrenece Berkeley National Lab.

# Installation

1. Clone this repo and the repos of all [dependencies](#dependencies) into your MATLAB project, preferably in a “vendor” directory.  See [Recommended Project Structure](#project-structure)

2. Add this library and all dependencies to the MATLAB path, e.g., 

```matlab
addpath(genpath('vendor/github/cnanders/matlab-scanner-control-npoint'));
addpath(genpath('vendor/github/cnanders/mic'));
addpath(genpath('vendor/github/cnanders/matlab-npoint-lc400/pkg'));
addpath(genpath('vendor/github/cnanders/matlab-ieee/pkg'));
addpath(genpath('vendor/github/cnanders/matlab-hex/pkg'));

```
3. Make sure the nPoint LC400 is recognized.  See [github/cnanders/matlab-npoint-lc400](https://github.com/cnanders/matlab-npoint-lc400)
3. Instantiate a `ScannerControl` and call its `build()` method

```matlab
sc = ScannerControl();
sc.build();
```

<a name="dependencies"></a>
## Dependencies

- [github/cnanders/mic](https://github.com/cnanders/mic) (for the UI)
- [github/cnanders/matlab-npoint-lc400](https://github.com/cnanders/matlab-npoint-lc400) (for MATLAB USB serial communication with nPoint LC.400 controller)

<a name="project-structure"></a>
# Recommended Project Structure

- project
	- vendor
		- github
			- cnanders
                - matlab-scanner-control-npoint **(this repo)**
                - mic **(direct dependency)**
                - matlab-npoint-lc400 **(direct dependency)**	
				- matlab-ieee **(dependency of matlab-npoint-lc400)**
				- matlab-hex **(dependency of matlab-ieee)**
	- file1.m
	- file2.m