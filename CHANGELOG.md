ToDo:

- Add AOI fields for the x and y directinos and use these in the code (these can be passed in during construction)


## 1.1.4

- Adding support for quasar illumination patterns which use [https://github.com/cnanders/matlab-quasar](https://github.com/cnanders/matlab-quasar)

## 1.1.3 

- The code and UI to send waveforms to the LC400 is better separated from the rest of the code
- Got rid of volts scale (set to 1 everywhere)

## 1.1.2

- Refactoring the code to generate the signed 20-bit values for the waveform that are used to write it to the LC400

## 1.1.1

- Updated dependencies in README.md

## 1.1.0

- Now uses [github/cnanders/matlab-instrument-control](https://github.com/cnanders/matlab-instrument-control) (v1.0.0-beta.*)


## 1.0.0

Build using [github/cnanders/mic](https://github.com/cnanders/mic) (v1.0.0-alpha.*)