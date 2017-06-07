classdef ScannerControl < mic.Base
%PUPILFILL Class that allows to monitor and the control of the Pupil fill
%
%   See also ScannerCore, RETICLEPICK, HEIGHTSENSOR
    
    properties (Constant)
        
        dPupilScale     = 1.1;
        dPupilPixels    = 220;
        
        dWidth          = 1230
        dHeight         = 720
        
        dWidthPlotPanel = 990;
        dWidthSavedWaveformsPanel = 990;

    end
    
    properties
                
        
    end
    
    properties (SetAccess = private)
        
        % {npoint.lc400.LC400 1x1}
        np
        
        dThetaX = 45; % deg
        dThetaY = 0;
        
        dHeightEdit = 24;
    end
    
    properties (Access = private)
        
        cPortNPoint = 'COM3';
                
        % {char 1xm} full path to the dir this file is in
        cDirThis
        % {char 1xm} full path to dir of the project
        cDirApp
        % { char 1xm} full path to dir of saved pupilfills
        cDirWaveforms
        
        cSaveDir
        
        cDevice = 'test'       % Name of nPoint device 'm142' (field), 'm143' (pupil)
        
        dYOffset = 360;
               
        lConnected = false;
        hFigure
        hWaveformPanel
        hWaveformMultiPanel
        hWaveformDCPanel
        hWaveformRastorPanel
        hWaveformSawPanel
        hWaveformSerpPanel
        hWaveformGeneralPanel
        hSavedWaveformsPanel
        
        hPlotPanel              % main plot panel
        hPlotPreviewPanel       % panel with the plots for the preview data
        hPlotMonitorPanel       % panel with all of the plots for the record data
        hPlotRecordPanel        % panel with the uie time and record button
        
        hPreviewAxis2D
        hPreviewAxis2DSim
        hPreviewAxis1D
        
        hLinesVxSensor1D
        hLinesVySensor1D
        hLinesVxCommand1D
        hLinesVyCommand1D
        
        hLinesSensorVxVsVy
        hLinesCommandVxVsVy
        
        hMonitorAxis2D
        hMonitorAxis2DSim
        hMonitorAxis1D
        
        hCameraPanel
        hDevicePanel
        
        lSerpentineDebug = false;
        hSerpentineKernelAxes
        hSerpentineWaveformAxes
        hSerpentineConvAxes
        hSerpentineConvOutputAxes
        hSerpentineCurrentAxes
        
        dPreviewPixels = 220;
        dPreviewScale = 1.1;
        
        lUseNPoint = false
        
        dFreqMin        % minimum frequency
        dFreqMax        % maximum frequency
        
        dVx
        dVy
        dVxCorrected
        dVyCorrected
        dTime

        
        % Storage for record plot
        dRVxCommand
        dRVyCommand
        dRVxSensor
        dRVySensor
        dRTime
        
        uipType
        uipPlotType
        
        uieMultiPoleNum
        uieMultiSigMin
        uieMultiSigMax
        uieMultiCirclesPerPole
        uieMultiDwell
        uieMultiOffset
        uieMultiRot
        uieMultiXOffset
        uieMultiYOffset
        uieMultiTransitTime
        uieTimeStep
        uipMultiTimeType
        uieMultiHz
        uieMultiPeriod
        uitMultiFreqRange

        uieSawSigX
        uieSawPhaseX
        uieSawOffsetX
        uieSawSigY
        uieSawPhaseY
        uieSawOffsetY
        uipSawTimeType
        uieSawHz
        uieSawPeriod
        
        uieSerpSigX
        uieSerpSigY
        uieSerpNumX
        uieSerpNumY
        uieSerpOffsetX
        uieSerpOffsetY
        uieSerpPeriod
        
        uieDCx
        uieDCy
        
        uieRastorData
        uieRastorTransitTime
        uilSaved
        
        uieFilterHz
        uieVoltsScale
        uieConvKernelSig
        
        uibPreview
        uibSave
        uibRecord
        uieRecordTime
        
        uibWriteWaveform
        uibStartWaveform
        uibStopWaveform
        
    end
    
    events
        
        eNew
        eDelete
        
    end
    
    
    methods
        
        function this = ScannerControl(varargin)
          
            [this.cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));
            
            this.cDirApp = this.cDirThis;
        
            this.cDirWaveforms = fullfile(...
                this.cDirApp, ...
                'save', ...
                sprintf('scanner-%s', this.cDevice) ...
            );
        
            % Apply varargin
            
            for k = 1 : 2: length(varargin)
                % this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}), 3);
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
            mic.Utils.checkDir(this.cDirWaveforms);
            
            this.init();
        end
         
        % Write dTime, i32X, and i32Y to a CSV
        function csv(this)
            m = [this.dTime' this.i32X' this.i32Y'];
            csvwrite('data.csv', m);
        end
        
        % Write x, y values (mrad) to text file
        % @param {char 1xm} c - extra to append to filename
        function dlm(this, c)
                        
            x = this.dVx / this.uieVoltsScale.get(); % values in [-1 : 1]
            y = this.dVy / this.uieVoltsScale.get(); % values in [-1 : 1]
            
            x = x * 3;
            y = y * 3;
            
            %{
            x = double(this.i32X)'/(2^20/2) * 3;
            y = double(this.i32Y)'/(2^20/2) * 3;
            %}
            
            % figure
            % plot(x, y)
            
            dlmwrite(sprintf('x-%s.txt', c), x, 'precision', 5);
            dlmwrite(sprintf('y-%s.txt', c), y, 'precision', 5);
        end
        
        function build(this)
        % BUILD Builds the UI element controls in a separate window
        %   PupilFill.Build()
        %
        % See also PUPILFILL, INIT, DELETE
            
            % Figure
            
            if ishghandle(this.hFigure)
                % Bring to front
                figure(this.hFigure);
                return
            end
            
            dScreenSize = get(0, 'ScreenSize');
        
            this.hFigure = figure( ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'Name',  sprintf('Scanner Control (%s)', this.cDevice), ...
                'Position', [ ...
                    (dScreenSize(3) - this.dWidth)/2 ...
                    (dScreenSize(4) - this.dHeight)/2 ...
                    this.dWidth ...
                    this.dHeight ...
                 ],... % left bottom width height
                'Resize', 'off', ...
                'HandleVisibility', 'on', ... % lets close all close the figure
                'Visible', 'on', ...
                'CloseRequestFcn', @this.onCloseRequest ...
                );
            
            drawnow;
            
            if this.lSerpentineDebug
                figure
                this.hSerpentineKernelAxes = subplot(141);
                this.hSerpentineWaveformAxes = subplot(142);
                this.hSerpentineConvAxes = subplot(143);
                this.hSerpentineConvOutputAxes = subplot(144);
                drawnow;
                
                figure
                this.hSerpentineCurrentAxes = axes();
                drawnow;
                
                
            end
            
            this.buildWaveformPanel();
            this.buildSavedWaveformsPanel();
            this.buildPlotPanel();
            % this.buildCameraPanel();
            % this.buildDevicePanel();
            % this.np.build(this.hFigure, 750 + 160, this.dYOffset);
            this.uilSaved.refresh();
            this.onLC400Connect()
        end
        
        function delete(this)
           
            this.msg('delete');
            % Delete the figure
            
            % Get properties:
            ceProperties = properties(this);
            
            % Loop through properties:
            for k = 1:length(ceProperties)
                if  isobject(this.(ceProperties{k}))  && ... 
                    ishandle(this.(ceProperties{k}))
                delete(this.(ceProperties{k}));
                end
            end
                        
            
            
        end
        
        function load(this, st)
           
             this.uipType.load(st.uipType);
             this.uipPlotType.load(st.uipPlotType);

             this.uieMultiPoleNum.load(st.uieMultiPoleNum);
             this.uieMultiSigMin.load(st.uieMultiSigMin);
             this.uieMultiSigMax.load(st.uieMultiSigMax);
             this.uieMultiCirclesPerPole.load(st.uieMultiCirclesPerPole);
             this.uieMultiDwell.load(st.uieMultiDwell);  
             this.uieMultiOffset.load(st.uieMultiOffset);
             this.uieMultiRot.load(st.uieMultiRot);
             this.uieMultiXOffset.load(st.uieMultiXOffset);
             this.uieMultiYOffset.load(st.uieMultiYOffset);
             this.uieMultiTransitTime.load(st.uieMultiTransitTime);
             this.uieTimeStep.load(st.uieTimeStep);
             this.uipMultiTimeType.load(st.uipMultiTimeType);
             this.uieMultiHz.load(st.uieMultiHz);
             this.uieMultiPeriod.load(st.uieMultiPeriod);
 
             this.uieSawSigX.load(st.uieSawSigX);
             this.uieSawPhaseX.load(st.uieSawPhaseX);
             this.uieSawOffsetX.load(st.uieSawOffsetX);
             this.uieSawSigY.load(st.uieSawSigY);
             this.uieSawPhaseY.load(st.uieSawPhaseY);
             this.uieSawOffsetY.load(st.uieSawOffsetY);
             this.uipSawTimeType.load(st.uipSawTimeType);
             this.uieSawHz.load(st.uieSawHz);
             this.uieSawPeriod.load(st.uieSawPeriod);

             this.uieSerpSigX.load(st.uieSerpSigX);
             this.uieSerpSigY.load(st.uieSerpSigY);
             this.uieSerpNumX.load(st.uieSerpNumX);
             this.uieSerpNumY.load(st.uieSerpNumY);
             this.uieSerpOffsetX.load(st.uieSerpOffsetX);
             this.uieSerpOffsetY.load(st.uieSerpOffsetY);
             this.uieSerpPeriod.load(st.uieSerpPeriod);

             this.uieDCx.load(st.uieDCx);
             this.uieDCy.load(st.uieDCy);

             this.uieRastorData.load(st.uieRastorData);
             this.uieRastorTransitTime.load(st.uieRastorTransitTime);

             this.uieFilterHz.load(st.uieFilterHz);
             this.uieVoltsScale.load(st.uieVoltsScale);
             this.uieConvKernelSig.load(st.uieConvKernelSig);
            
        end
        
        function st = save(this)
            
            st = struct();
            
            st.uipType = this.uipType.save();
            st.uipPlotType = this.uipPlotType.save();

            st.uieMultiPoleNum = this.uieMultiPoleNum.save();
            st.uieMultiSigMin = this.uieMultiSigMin.save();
            st.uieMultiSigMax = this.uieMultiSigMax.save();
            st.uieMultiCirclesPerPole = this.uieMultiCirclesPerPole.save();
            st.uieMultiDwell = this.uieMultiDwell.save();  
            st.uieMultiOffset = this.uieMultiOffset.save();
            st.uieMultiRot = this.uieMultiRot.save();
            st.uieMultiXOffset = this.uieMultiXOffset.save();
            st.uieMultiYOffset =  this.uieMultiYOffset.save();
            st.uieMultiTransitTime = this.uieMultiTransitTime.save();
            st.uieTimeStep = this.uieTimeStep.save();
            st.uipMultiTimeType = this.uipMultiTimeType.save();
            st.uieMultiHz = this.uieMultiHz.save();
            st.uieMultiPeriod = this.uieMultiPeriod.save();
 
            st.uieSawSigX = this.uieSawSigX.save();
            st.uieSawPhaseX = this.uieSawPhaseX.save();
            st.uieSawOffsetX = this.uieSawOffsetX.save();
            st.uieSawSigY = this.uieSawSigY.save();
            st.uieSawPhaseY = this.uieSawPhaseY.save();
            st.uieSawOffsetY = this.uieSawOffsetY.save();
            st.uipSawTimeType = this.uipSawTimeType.save();
            st.uieSawHz = this.uieSawHz.save();
            st.uieSawPeriod = this.uieSawPeriod.save();

            st.uieSerpSigX = this.uieSerpSigX.save();
            st.uieSerpSigY = this.uieSerpSigY.save();
            st.uieSerpNumX = this.uieSerpNumX.save();
            st.uieSerpNumY = this.uieSerpNumY.save();
            st.uieSerpOffsetX = this.uieSerpOffsetX.save();
            st.uieSerpOffsetY = this.uieSerpOffsetY.save();
            st.uieSerpPeriod = this.uieSerpPeriod.save();

            st.uieDCx = this.uieDCx.save();
            st.uieDCy = this.uieDCy.save();

            st.uieRastorData = this.uieRastorData.save();
            st.uieRastorTransitTime = this.uieRastorTransitTime.save();

            st.uieFilterHz = this.uieFilterHz.save();
            st.uieVoltsScale = this.uieVoltsScale.save();
            st.uieConvKernelSig = this.uieConvKernelSig.save();

        end

    end
    
    methods (Access = private)
        
        function initPlotMonitorPanel(this)
            
        end
        
        function initPlotPanel(this)
            
            this.uipPlotType = mic.ui.common.Popup(...
                'ceOptions', {'Preview', 'nPoint Monitor'}, ...
                'cLabel', 'Select Plot Source');
            addlistener(this.uipPlotType, 'eChange', @this.onPlotTypeChange);
                        
            this.initPlotRecordPanel();
        end
        
        function initPlotPreviewPanel(this)
            
        end
        
        function initPlotRecordPanel(this)
            
            this.uibRecord = mic.ui.common.Button('cText', 'Record');
            this.uieRecordTime = mic.ui.common.Edit(...
                'cLabel', 'Time (ms)', ...
                'cType', 'd', ...
                'lShowLabel', false);
            
             % Default values
            this.uieRecordTime.setMax(2000);
            this.uieRecordTime.setMin(0);
            this.uieRecordTime.set(100);
            
            addlistener(this.uibRecord, 'eChange', @this.onRecordClick);
            
        end
        
        function initWaveformSerpPanel(this)
            
            this.uieSerpSigX = mic.ui.common.Edit(...
                'cLabel', 'Sig X', ...
                'cType', 'd'); 
            this.uieSerpSigX.setMin(0);
            this.uieSerpSigX.setMax(1);
            this.uieSerpSigX.set(0.5);
            
            this.uieSerpNumX = mic.ui.common.Edit(...
                'cLabel', 'Num X (odd)', ...
                'cType', 'u8');
            this.uieSerpNumX.set(uint8(7));
            this.uieSerpNumX.setMin( uint8(4));
            this.uieSerpNumX.setMax( uint8(51));
            
            this.uieSerpOffsetX = mic.ui.common.Edit(...
                'cLabel', 'Offset X', ...
                'cType', 'd');
            this.uieSerpOffsetX.setMin(-1);
            this.uieSerpOffsetX.setMax(1);
            
            this.uieSerpSigY = mic.ui.common.Edit(...
                'cLabel', 'Sig Y', ...
                'cType', 'd'); 
            this.uieSerpSigY.setMin(0);
            this.uieSerpSigY.setMax(1);
            this.uieSerpSigY.set(0.5);            
            
            this.uieSerpNumY = mic.ui.common.Edit(...
                'cLabel', 'Num Y (odd)', ...
                'cType', 'u8');
            this.uieSerpNumY.set(uint8(7));
            this.uieSerpNumY.setMin( uint8(4));
            this.uieSerpNumY.setMax( uint8(51));
            
            this.uieSerpOffsetY = mic.ui.common.Edit(...
                'cLabel', 'Offset Y', ...
                'cType', 'd');
            this.uieSerpOffsetY.setMin(-1);
            this.uieSerpOffsetY.setMax(1);
            
            this.uieSerpPeriod = mic.ui.common.Edit(...
                'cLabel', 'Period (ms)', ...
                'cType', 'd');
            this.uieSerpPeriod.set(100); 
            this.uieSerpPeriod.setMin( 1);
            this.uieSerpPeriod.setMax( 10000);
            
        end
        
        function initWaveformSawPanel(this)
            
            this.uieSawSigX = mic.ui.common.Edit(...
                'cLabel', 'Sig X', ...
                'cType', 'd'); 
            this.uieSawSigX.setMin(0);
            this.uieSawSigX.setMax(1);
            this.uieSawSigX.set(0.5);
            
            this.uieSawPhaseX = mic.ui.common.Edit(...
                'cLabel', 'Phase X (pi)', ...
                'cType',  'd');
            this.uieSawPhaseX.setMin(-2);
            this.uieSawPhaseX.setMax(2);
                        
            this.uieSawOffsetX = mic.ui.common.Edit(...
                'cLabel', 'Offset X', ...
                'cType',  'd');
            this.uieSawOffsetX.setMin(-1);
            this.uieSawOffsetX.setMax(1);
            
            this.uieSawSigY = mic.ui.common.Edit(...
                'cLabel', 'Sig Y', ...
                'cType',  'd'); 
            this.uieSawSigY.setMin(0);
            this.uieSawSigY.setMax(1);
            this.uieSawSigY.set(0.5);            
            
            this.uieSawPhaseY = mic.ui.common.Edit(...
                'cLabel', 'Phase Y (pi)', ...
                'cType',  'd');
            this.uieSawPhaseY.setMin(-2);
            this.uieSawPhaseY.setMax(2);
                        
            this.uieSawOffsetY = mic.ui.common.Edit(...
                'cLabel', 'Offset Y', ...
                'cType',  'd');
            this.uieSawOffsetY.setMin(-1);
            this.uieSawOffsetY.setMax(1);
                                    
            this.uipSawTimeType = mic.ui.common.Popup(...
                'ceOptions', {'Period (ms)', 'Hz (avg)'}, ...
                'cLabel', 'Select Time Type');
            addlistener(this.uipSawTimeType, 'eChange', @this.onSawTimeTypeChange);            
            
            this.uieSawHz = mic.ui.common.Edit(...
                'cLabel', 'Hz (avg)', ...
                'cType',  'd');
            this.uieSawHz.setMin(0);
            this.uieSawHz.setMax(1000);
            this.uieSawHz.set(200);
            
            this.uieSawPeriod = mic.ui.common.Edit(...
                'cLabel', 'Period (ms)', ...
                'cType',  'd');
            this.uieSawPeriod.set(100); 
            this.uieSawPeriod.setMin(1);
            this.uieSawPeriod.setMax(10000);
            
        end
        
        function initWaveformRastorPanel(this)
            
             
            this.uieRastorData = mic.ui.common.Edit(...
                'cLabel', '(sig_x,sig_y,ms),(sig_x,sig_y,ms),...', ...
                'cType', 'c');
            this.uieRastorTransitTime =     mic.ui.common.Edit(...
                'cLabel', 'Transit Time (s)', ...
                'cType', 'd');
            
            this.uieRastorData.set('(0.3,0.3,5),(0.5,0.5,10),(0.4,0.4,4)');

           
            
        end
        
        function initWaveformDCPanel(this)
           
            this.uieDCx = mic.ui.common.Edit(...
                'cLabel', 'X offset', ...
                'cType', 'd');
            this.uieDCy = mic.ui.common.Edit(...
                'cLabel', 'Y offset', ...
                'cType', 'd');
            
            this.uieDCx.set(0.5);
            this.uieDCy.set(0.3);
        end
        
        function initWaveformMultiPanel(this)
            
            this.uieMultiPoleNum =          mic.ui.common.Edit(...
                'cLabel', 'Poles', ...
                'cType', 'u8');
            this.uieMultiSigMin =           mic.ui.common.Edit(...
                'cLabel', 'Sig min', ...
                'cType',  'd');
            this.uieMultiSigMax =           mic.ui.common.Edit(...
                'cLabel', 'Sig max', ...
                'cType',  'd');
            this.uieMultiCirclesPerPole =   mic.ui.common.Edit(...
                'cLabel', 'Circles/pole', ...
                'cType',  'u8');
            this.uieMultiDwell =            mic.ui.common.Edit(...
                'cLabel', 'Dwell', ...
                'cType',  'u8');
            this.uieMultiOffset =           mic.ui.common.Edit(...
                'cLabel', 'Pole Offset', ...
                'cType',  'd');
            this.uieMultiRot =              mic.ui.common.Edit(...
                'cLabel', 'Rot', ...
                'cType',  'd');
            this.uieMultiXOffset =          mic.ui.common.Edit(...
                'cLabel', 'X Global Offset', ...
                'cType',  'd');
            this.uieMultiYOffset =          mic.ui.common.Edit(...
                'cLabel', 'Y Global Offset', ...
                'cType',  'd');

            this.uieMultiTransitTime =      mic.ui.common.Edit(...
                'cLabel', 'Transit Frac', ...
                'cType',  'd');
            
            this.uipMultiTimeType =         mic.ui.common.Popup(...
                'ceOptions', {'Period (ms)', 'Hz (avg)'}, ...
                'cLabel', 'Select Time Type');
            addlistener(this.uipMultiTimeType, 'eChange', @this.onMultiTimeTypeChange);            
            
            this.uieMultiPeriod =           mic.ui.common.Edit(...
                'cLabel', 'Period (ms)', ...
                'cType',  'd');
            this.uieMultiHz =               mic.ui.common.Edit(...
                'cLabel', 'Hz (avg)', ...
                'cType',  'd');
            this.uitMultiFreqRange =        mic.ui.common.Text('cVal', '');
            
            % Defaults
            this.uieMultiPoleNum.set(uint8(4));
            this.uieMultiSigMin.set(0.2);
            this.uieMultiSigMax.set(0.3);
            this.uieMultiCirclesPerPole.set(uint8(2));
            this.uieMultiDwell.set(uint8(2));
            this.uieMultiOffset.set(0.6);
            this.uieMultiTransitTime.set(0.08);
            this.uieMultiHz.set(200);
            this.uieMultiPeriod.set(100);
            
            
        end
        
        function initWaveformGeneralPanel(this)
            
            % *********** General waveform panel
            
            this.uieFilterHz = mic.ui.common.Edit(...
                'cLabel', 'Filter Hz', ...
                'cType', 'd');
            this.uieFilterHz.set(400);
            this.uieFilterHz.setMin(1);
            this.uieFilterHz.setMax(10000);
            
            this.uieVoltsScale = mic.ui.common.Edit(...
                'cLabel', 'Volts scale', ...
                'cType', 'd');
            this.uieVoltsScale.set(29);
            this.uieVoltsScale.setMin(0);
            this.uieVoltsScale.setMax(100);
            
            this.uieTimeStep = mic.ui.common.Edit(...
                'cLabel', 'Time step (us)', ...
                'cType', 'd');
            this.uieTimeStep.set(24);    % nPoint has a 24 us control loop
            
            
            this.uieConvKernelSig = mic.ui.common.Edit(...
                'cLabel', 'Conv. kernel sig', ...
                'cType', 'd');
            this.uieConvKernelSig.set(0.05);
            this.uieConvKernelSig.setMin(0.01);
            this.uieConvKernelSig.setMax(1);
            
        end
        
        function initWaveformPanel(this)
            
            this.uipType = mic.ui.common.Popup(...
                'ceOptions', {'Multipole', 'DC', 'Rastor', 'Saw', 'Serpentine'}, ...
                'cLabel', 'Select Waveform Type');
            addlistener(this.uipType, 'eChange', @this.onTypeChange);
            
            
            this.initWaveformGeneralPanel();
            this.initWaveformMultiPanel();
            this.initWaveformDCPanel();
            this.initWaveformRastorPanel();
            this.initWaveformSawPanel();
            this.initWaveformSerpPanel();
            
            this.uibPreview = mic.ui.common.Button(...
                'cText', 'Preview');
            this.uibSave = mic.ui.common.Button(...
                'cText', 'Save');
            
            addlistener(this.uibPreview, 'eChange', @this.onPreview);
            addlistener(this.uibSave, 'eChange', @this.onSave);
            
        end
        
        function initSavedWaveformsPanel(this)
            
            this.uilSaved = mic.ui.common.List(...
                'ceOptions', cell(1,0), ...
                'cLabel', '', ...
                'lShowDelete', true, ...
                'lShowMove', true, ...
                'lShowLabel', false, ...
                'lShowRefresh', true);
            this.uilSaved.setRefreshFcn(@this.onListRefresh);
            
            addlistener(this.uilSaved, 'eChange', @this.onListChange);
            addlistener(this.uilSaved, 'eDelete', @this.onListChangeDelete);
            
            
            this.uibWriteWaveform = mic.ui.common.Button('cText', 'Write nPoint');
            addlistener(this.uibWriteWaveform, 'eChange', @this.onWriteClick);
            
            
            this.uibStartWaveform = mic.ui.common.Button('cText', 'Start nPoint');
            addlistener(this.uibStartWaveform, 'eChange', @this.onStartClick);
            
            this.uibStopWaveform = mic.ui.common.Button('cText', 'Stop nPoint');
            addlistener(this.uibStopWaveform, 'eChange', @this.onStopClick);
            
        end
        
        function init(this)
        %INIT Initializes the PupilFill class
        %   PupilFill.init()
        %
        % See also PUPILFILL, BUILD, DELETE
            
            % 2012.04.16 C. Cork instructed me to use double for all raw
            % values
            
            
            this.initWaveformPanel();
            this.initPlotPanel();
            this.initSavedWaveformsPanel();
            
            % ************ nPoint
            
            % 2014.02.11 CNA
            % I decided that we will build two PupilFill instances, one for
            % the field scanner and one for the pupil scanner.  We will
            % need to pass in information about the nPoint we want to
            % connect to.  I'm assuming I will eventually build in a second
            % parameter to nPoint that can specify which hardware it is
            % connected to.  This, in turn will be passed to the 
            % APIHardwareIOnPoint instances within the nPoint 
            
            % 2017.02.02 
            % This is creating the UI instance, which is also a wrapper
            % around the Java.  For now, I'm going to try and override this
            % with the new npoint.lc400.LC400 available at 
            % https://github.com/cnanders/matlab-npoint-lc400
            
            % this.np = nPoint(this.cl, this.cDevice);
            
            if this.lUseNPoint
                this.np = npoint.lc400.LC400('cPort', this.cPortNPoint);
                this.np.init();
                this.np.connect();
            end
            
            
            % addlistener(this.np, 'eConnect', @this.handleConnect);
            % addlistener(this.np, 'eDisconnect', @this.handleDisconnect);
                        
                        
        end
        
        function loadState(this)
                        
            %{
            % ceSelected is a cell of selected options - use the first
            % one.  Populates a structure named s in the local
            % workspace of this method

            cFile = fullfile(this.cDir, '..', this.cSaveDir, this.cName);
            
            if exist(cFile, 'file') ~= 0

                load(cFile); % populates s in local workspace

                this.loadClassInstance(s);
                % this.updateAxes();
                % this.updatePupilImg('preview');
            
            end
            %}
        end
        
       
        
        function saveState(this)
            
            
            %{
            cPath = fullfile(this.cDir, '..', this.cSaveDir, 'saved-state.mat');
            
            % Create a nested recursive structure of all public properties
            s = this.saveClassInstance();
                        
            % Save
            save(cPath, 's');  
            %}
            
        end
       
        function onLC400Connect(this)
            this.lConnected = true;
            
            if this.uipPlotType.getSelectedIndex() == uint8(2)
                % nPoint Monitor
                if ishandle(this.hPlotRecordPanel)
                    set(this.hPlotRecordPanel, 'Visible', 'on');
                end
            end
             
            % Show "set waveform" button
            % Show "record" button
            % Show "set" button
            
            % this.uibRecord.show();
            % this.uieRecordTime.show();
            
            this.uibWriteWaveform.show();
            this.uibStartWaveform.show(); 
            this.uibStopWaveform.show();
            
            
        end
        
        function onLC400Disconnect(this)
            
            this.lConnected = false;
            
            if ishandle(this.hPlotRecordPanel)
                set(this.hPlotRecordPanel, 'Visible', 'off');
            end
                
            % this.uibRecord.hide();
            % this.uieRecordTime.hide();
            
            this.uibWriteWaveform.hide();
            this.uibStartWaveform.hide();
            this.uibStopWaveform.hide();
            
        end
        
        function handleConnect(this, src, evt)
            this.onLC400Connect();   
        end
        
        
        function handleDisconnect(this, src, evt)
            this.onLC400Disconnect();
        end
        
                
        function onMultiTimeTypeChange(this, src, evt)
            
                                                
            % Show the UIEdit based on popup type 
            switch this.uipMultiTimeType.getSelectedIndex()
                case uint8(1)
                    % Period
                    if this.uieMultiHz.isVisible()
                        this.uieMultiHz.hide();
                    end
                    
                    if ~this.uieMultiPeriod.isVisible()
                        this.uieMultiPeriod.show();
                    end
                    
                case uint8(2)
                    % Hz
                    if this.uieMultiPeriod.isVisible()
                        this.uieMultiPeriod.hide();
                    end
                    
                    if ~this.uieMultiHz.isVisible()
                        this.uieMultiHz.show();
                    end
            end    
        end

        
        function onSawTimeTypeChange(this, src, evt)
            
            
            % Show the UIEdit based on popup type
            
            switch this.uipSawTimeType.getSelectedIndex()
                case uint8(1)
                    % Period
                    if this.uieSawHz.isVisible()
                        this.uieSawHz.hide();
                    end
                    
                    if ~this.uieSawPeriod.isVisible()
                        this.uieSawPeriod.show();
                    end
                    
                case uint8(2)
                    % Hz
                    if this.uieSawPeriod.isVisible()
                        this.uieSawPeriod.hide();
                    end
                    
                    if ~this.uieSawHz.isVisible()
                        this.uieSawHz.show();
                    end
            end
            
            
        end
        
        function onTypeChange(this, src, evt)
            
            
            % Build the sub-panel based on popup type 
            switch this.uipType.getSelectedIndex()
                case uint8(1)
                    % Multi
                    this.hideOtherWaveformPanels(this.hWaveformMultiPanel);
                    if ishandle(this.hWaveformMultiPanel)
                        set(this.hWaveformMultiPanel, 'Visible', 'on');
                    else
                        this.buildWaveformMultiPanel();
                    end
                    
                case uint8(2)
                    % DC offset
                    this.hideOtherWaveformPanels(this.hWaveformDCPanel);
                    if ishandle(this.hWaveformDCPanel)
                        set(this.hWaveformDCPanel, 'Visible', 'on');
                    else
                        this.buildWaveformDCPanel();
                    end
                case uint8(3)
                    % Rastor
                    this.hideOtherWaveformPanels(this.hWaveformRastorPanel);
                    if ishandle(this.hWaveformRastorPanel)
                        set(this.hWaveformRastorPanel, 'Visible', 'on');
                    else
                        this.buildWaveformRastorPanel();
                    end
                case uint8(4)
                    % Triangle
                    this.hideOtherWaveformPanels(this.hWaveformSawPanel);
                    if ishandle(this.hWaveformSawPanel)
                        set(this.hWaveformSawPanel, 'Visible', 'on');
                    else
                        this.buildWaveformSawPanel();
                    end
                case uint8(5)
                    % Serpentine
                    this.hideOtherWaveformPanels(this.hWaveformSerpPanel);
                    if ishandle(this.hWaveformSerpPanel)
                        set(this.hWaveformSerpPanel, 'Visible', 'on');
                    else
                        this.buildWaveformSerpPanel();
                    end
            end
            
            
        end
        
        
        function hideOtherWaveformPanels(this, h)
            
            % @parameter h
            %   type: handle
            %   desc: handle of the panel that you don't want to hide
            
            % USE CAUTION!  h may be empty when we pass it in
            
            %{
            this.msg( ...
                sprintf( ...
                    'PupilFill.hideOtherWaveformPanels() \n\t %1.0f', ...
                    h ...
                ) ...
            );
            %}
            
            % cell of handles of each waveform panel
            ceh = { ...
                this.hWaveformMultiPanel, ...
                this.hWaveformDCPanel, ...
                this.hWaveformRastorPanel, ...
                this.hWaveformSawPanel, ...
                this.hWaveformSerpPanel ...
            };
            
            % loop through all panels
            for n = 1:length(ceh)            
                
                ceOptions = this.uipType.getOptions();
                %{
                this.msg( ...
                    sprintf( ...
                        'PupilFill.hideOtherWaveformPanels() \n\t panel: %s \n\t ishandle: %1.0f \n\t handleval: %1.0f \n\t visible: %s \n\t isequal: %1.0f ', ...
                        ceOptions{uint8(n)}, ...
                        +ishandle(ceh{n}), ...
                        ceh{n}, ...
                        get(ceh{n}, 'Visible'), ...
                        +(ceh{n} ~= h) ...
                    ) ...
                );
                %}
                
                if ishandle(ceh{n}) & ...
                   strcmp(get(ceh{n}, 'Visible'), 'on') & ...
                   (isempty(h) | ceh{n} ~= h)
                    ceOptions = this.uipType.getOptions();
                    this.msg(sprintf('PupilFill.hideOtherWaveformPanels() hiding %s panel', ceOptions{uint8(n)}));
                    set(ceh{n}, 'Visible', 'off');
                    
                end
            end
            
        end
        
        function hideWaveformPanels(this)
                           
            if ishandle(this.hWaveformMultiPanel)
                set(this.hWaveformMultiPanel, 'Visible', 'off');
            end
            
            if ishandle(this.hWaveformDCPanel)
                set(this.hWaveformDCPanel, 'Visible', 'off');
            end
            
            if ishandle(this.hWaveformRastorPanel)
                set(this.hWaveformRastorPanel, 'Visible', 'off');
            end
            
            if ishandle(this.hWaveformSawPanel)
                set(this.hWaveformSawPanel, 'Visible', 'off');
            end
            
            drawnow;
            
        end
        
        
        function onPlotTypeChange(this, src, evt)
            
            
            % Debug: echo visibility of record button
            
            % this.uibRecord.isVisible()
            % this.uieRecordTime.isVisible();
            
            
            % Hide all other panels
            this.hidePlotPanels();
                        
            % Build the sub-panel based on popup type 
            switch this.uipPlotType.getSelectedIndex()
                case uint8(1)
                    % Preview
                    if ishandle(this.hPlotPreviewPanel)
                        set(this.hPlotPreviewPanel, 'Visible', 'on');
                    else
                        this.buildPlotPreviewPanel();
                    end
                case uint8(2)
                    % nPoint Monitor
                    if ishandle(this.hPlotMonitorPanel)
                        set(this.hPlotMonitorPanel, 'Visible', 'on');
                    else
                        this.buildPlotMonitorPanel();
                    end
                    
                    % Show the record panel when the device is connected
                    if this.lConnected
                        if ishandle(this.hPlotRecordPanel)
                            set(this.hPlotRecordPanel, 'Visible', 'on');
                        else
                            this.buildPlotRecordPanel();
                        end
                    end
                    
            end                
            
        end
        
        function hidePlotPanels(this)
                           
            if ishandle(this.hPlotPreviewPanel)
                set(this.hPlotPreviewPanel, 'Visible', 'off');
            end
            
            if ishandle(this.hPlotMonitorPanel)
                set(this.hPlotMonitorPanel, 'Visible', 'off');
            end
            
            if ishandle(this.hPlotRecordPanel)
                set(this.hPlotRecordPanel, 'Visible', 'off');
            end
                                                
        end
        
        function onPreview(this, src, evt)
            
            % Change plot type to preview
            this.uipPlotType.setSelectedIndex(uint8(1));
            
            
            this.updateWaveforms();
            this.updateAxes();
            this.updatePupilImg('preview');
            
            if this.uipType.getSelectedIndex == uint8(1)
                
                % Update multi range
                
                % The piezos have a voltage range between -30V and 150V
                % 180V is the full swing to achieve 6 mrad
                % +/- 90V = +/- sig = 1.
                % The current across a capacitor is: I = C*dV/dt 
                % The "small signal" capacitance of the piezo stack is about 2e-6 F (C/V).  
                % Source http://trs-new.jpl.nasa.gov/dspace/bitstream/2014/41642/1/08-0299.pdf
                % At full range, the voltage signal is: V(t) = 90*sin(2*pi*f*t)
                % dV/dt = 90*2*pi*f*cos(2*pi*f*t) which has a max of 180*pi*f V/s   
                % At 100 Hz, this is 180*100*pi V/s * 2e-6 (C/V) = 113 mA.  
                % It is believed that capacitance increases to 2.5e-6 F bit
                % for large signal which brings current up to 140 mA
         
    
                % Min frequency occurs at max sig and visa versa
                dC = 2e-6; % advertised
                dC_scale_factor = 300/113;
                
                dVdt_sig_max = 2*pi*90*this.uieMultiSigMax.get()*this.dFreqMin;
                dVdt_sig_min = 2*pi*90*this.uieMultiSigMin.get()*this.dFreqMax;
                dI_sig_max = dC*dC_scale_factor*dVdt_sig_max*1000; % mA
                dI_sig_min = dC*dC_scale_factor*dVdt_sig_min*1000; % mA
                
                cMsg = sprintf('Freq: %1.0f Hz - %1.0f Hz.\nI: %1.0f mA - %1.0f mA', ...
                    this.dFreqMin, ...
                    this.dFreqMax, ...
                    dI_sig_min, ...
                    dI_sig_max ...
                    );
             
                this.uitMultiFreqRange.set(cMsg);
            end
            
        end
        
        function updateWaveforms(this)
            
            % Update:
            % 
            %   dVx, 
            %   dVy, 
            %   dVxCorrected, 
            %   dVyCorrected, 
            %   dTime 

            %
            % and update plot preview
            
            switch this.uipType.getSelectedIndex()
                case uint8(1)
                    % Multi
                    
                    % Figure type
                    
                    % Show the UIEdit based on popup type 
                    switch this.uipMultiTimeType.getSelectedIndex()
                        case uint8(1)
                            % Period
                            lPeriod = true;

                        case uint8(2)
                            % Hz
                            lPeriod = false;
                    end
                    
                    
                    [this.dVx, ...
                     this.dVy, ...
                     this.dVxCorrected, ...
                     this.dVyCorrected, ...
                     this.dTime, ...
                     this.dFreqMin, ...
                     this.dFreqMax] = ScannerCore.getMulti( ...
                        double(this.uieMultiPoleNum.get()), ...
                        this.uieMultiSigMin.get(), ...
                        this.uieMultiSigMax.get(), ...
                        double(this.uieMultiCirclesPerPole.get()), ...
                        double(this.uieMultiDwell.get()), ...
                        this.uieMultiTransitTime.get(), ...
                        this.uieMultiOffset.get(), ...
                        this.uieMultiRot.get(), ...
                        this.uieMultiXOffset.get(), ...
                        this.uieMultiYOffset.get(), ...
                        this.uieMultiHz.get(), ...
                        this.uieVoltsScale.get(), ...
                        this.uieTimeStep.get()*1e-6, ...         
                        this.uieFilterHz.get(), ... 
                        this.uieMultiPeriod.get()/1000, ...
                        lPeriod ...
                        );
                    
                case uint8(2)
                    % DC offset
                    [this.dVx, this.dVy, this.dVxCorrected, this.dVyCorrected, this.dTime] = ScannerCore.getDC( ...
                        this.uieDCx.get(), ...
                        this.uieDCy.get(),...
                        this.uieVoltsScale.get(), ...
                        this.uieTimeStep.get()*1e-6 ...         
                        );
                    
                case uint8(3)
                    % Rastor
                    [this.dVx, this.dVy, this.dVxCorrected, this.dVyCorrected, this.dTime] = ScannerCore.getRastor( ...
                        this.uieRastorData.get(), ...
                        this.uieRastorTransitTime.get(), ...
                        this.uieTimeStep.get(), ... % send in us, not s
                        this.uieVoltsScale.get(), ...
                        this.uieFilterHz.get() ...
                        );
                    
                case uint8(4)
                    % Saw
                    
                    if this.uipSawTimeType.getSelectedIndex() == uint8(1)
                        % Period (ms)
                        dHz = 1/(this.uieSawPeriod.get()/1e3);
                    else
                        % Hz
                        dHz = this.uieSawHz.get();
                    end
                    
                    st = ScannerCore.getSaw( ...
                        this.uieSawSigX.get(), ...
                        this.uieSawPhaseX.get(), ...
                        this.uieSawOffsetX.get(), ...
                        this.uieSawSigY.get(), ...
                        this.uieSawPhaseY.get(), ...
                        this.uieSawOffsetY.get(), ...
                        this.uieVoltsScale.get(), ...
                        dHz, ...
                        this.uieFilterHz.get(), ...
                        this.uieTimeStep.get()*1e-6 ...
                        );
                    
                    this.dVx = st.dX;
                    this.dVy = st.dY;
                    this.dTime = st.dT;
                    
                case uint8(5)
                    % Serpentine
                                        
                    st = ScannerCore.getSerpentine2( ...
                        this.uieSerpSigX.get(), ...
                        this.uieSerpSigY.get(), ...
                        this.uieSerpNumX.get(), ...
                        this.uieSerpNumY.get(), ...
                        this.uieSerpOffsetX.get(), ...
                        this.uieSerpOffsetY.get(), ...
                        this.uieSerpPeriod.get()*1e-3, ...
                        this.uieVoltsScale.get(), ...
                        this.uieFilterHz.get(), ...
                        this.uieTimeStep.get()*1e-6 ...
                        );
                    
                    this.dVx = st.dX;
                    this.dVy = st.dY;
                    this.dTime = st.dT;
                                        
            end
            
            
            
            
                        
        end
        
        function updateAxes(this)
            
            % NEED TO FIX!!
            
            if ishandle(this.hFigure) & ... 
               ishandle(this.hPreviewAxis2D) & ...
               ishandle(this.hPreviewAxis1D)

                % set(this.hFigure, 'CurrentAxes', this.hPreviewAxis2D)
                plot(...
                    this.hPreviewAxis2D, ...
                    this.dVx, this.dVy, 'b' ...
                );
                xlim(this.hPreviewAxis2D, [-this.uieVoltsScale.get() this.uieVoltsScale.get()])
                ylim(this.hPreviewAxis2D, [-this.uieVoltsScale.get() this.uieVoltsScale.get()])

                % set(this.hFigure, 'CurrentAxes', this.hPreviewAxis1D)
                plot(...
                    this.hPreviewAxis1D, ...
                    this.dTime*1000, this.dVx, 'r', ...
                    this.dTime*1000, this.dVy,'b' ...
                );
                xlabel(this.hPreviewAxis1D, 'Time [ms]')
                ylabel(this.hPreviewAxis1D, 'Volts')
                legend(this.hPreviewAxis1D, 'vx','vy')
                xlim(this.hPreviewAxis1D, [0 max(this.dTime*1000)])
                ylim(this.hPreviewAxis1D, [-this.uieVoltsScale.get() this.uieVoltsScale.get()])
            end
            
        end
        
        function updateRecordAxes(this)
            
            if ishandle(this.hFigure) & ... 
               ishandle(this.hMonitorAxis2D) & ...
               ishandle(this.hMonitorAxis1D)

%                 set(this.hFigure, 'CurrentAxes', this.hMonitorAxis2D)
%                 cla;
%                 hold on


                delete(this.hLinesSensorVxVsVy)
                delete(this.hLinesCommandVxVsVy)
                
                this.hLinesSensorVxVsVy = plot(...
                    this.hMonitorAxis2D, ...
                    this.dRVxSensor, this.dRVySensor, 'b', ...
                    'LineWidth', 2 ...
                );
                hold(this.hMonitorAxis2D, 'on')
                this.hLinesCommandVxVsVy =  plot(...
                    this.hMonitorAxis2D, ...
                    this.dRVxCommand, this.dRVyCommand, 'b' ...
                );
                xlim(this.hMonitorAxis2D, [-this.uieVoltsScale.get() this.uieVoltsScale.get()])
                ylim(this.hMonitorAxis2D, [-this.uieVoltsScale.get() this.uieVoltsScale.get()])
                legend(this.hMonitorAxis2D, 'sensor', 'command');

%                 set(this.hFigure, 'CurrentAxes', this.hMonitorAxis1D)
%                 cla;
%                 hold on

                delete(this.hLinesVxSensor1D)
                delete(this.hLinesVySensor1D)
                delete(this.hLinesVxCommand1D)
                delete(this.hLinesVyCommand1D)
                
                this.hLinesVxSensor1D = plot(...
                    this.hMonitorAxis1D, ...
                    this.dRTime*1000, this.dRVxSensor, 'r', ...
                    'LineWidth', 2);
                
                hold(this.hMonitorAxis1D, 'on')
                
                this.hLinesVySensor1D = plot(...
                    this.hMonitorAxis1D, ...
                    this.dRTime*1000, this.dRVySensor,'b', ...
                    'LineWidth', 2);
                
                this.hLinesVxCommand1D = plot(...
                    this.hMonitorAxis1D, ...
                    this.dRTime*1000, this.dRVxCommand,'r');
                
                this.hLinesVyCommand1D = plot(...
                    this.hMonitorAxis1D, ...
                    this.dRTime*1000, this.dRVyCommand,'b');

                xlabel(this.hMonitorAxis1D, 'Time [ms]')
                ylabel(this.hMonitorAxis1D, 'Volts')
                legend(this.hMonitorAxis1D, 'vx sensor','vy sensor', 'vx command', 'vy command');
                xlim(this.hMonitorAxis1D, [0 max(this.dRTime*1000)])
                ylim(this.hMonitorAxis1D, [-this.uieVoltsScale.get() this.uieVoltsScale.get()])

                this.updatePupilImg('device');
                
            end
            
        end
        
        
        
        function onSave(this, src, evt)
            
            
            % Generate a suggested name for save structure.  
            
            switch this.uipType.getSelectedIndex()
                case uint8(1)
                    
                    % Multi
                    
                    switch this.uipMultiTimeType.getSelectedIndex()
                        case uint8(1)
                            % Period
                            cName = sprintf('%1.0fPole_off%1.0f_rot%1.0f_min%1.0f_max%1.0f_num%1.0f_dwell%1.0f_xoff%1.0f_yoff%1.0f_per%1.0f_filthz%1.0f_dt%1.0f',...
                                this.uieMultiPoleNum.get(), ...
                                this.uieMultiOffset.get()*100, ...
                                this.uieMultiRot.get(), ...
                                this.uieMultiSigMin.get()*100, ...
                                this.uieMultiSigMax.get()*100, ...
                                this.uieMultiCirclesPerPole.get(), ...
                                this.uieMultiDwell.get(), ...
                                this.uieMultiXOffset.get()*100, ...
                                this.uieMultiYOffset.get()*100, ...
                                this.uieMultiPeriod.get(), ...
                                this.uieFilterHz.get(), ...
                                this.uieTimeStep.get() ...
                            );
                        case uint8(2)
                            % Freq
                            cName = sprintf('%1.0fPole_off%1.0f_rot%1.0f_min%1.0f_max%1.0f_num%1.0f_dwell%1.0f_xoff%1.0f_yoff%1.0f_hz%1.0f_filthz%1.0f_dt%1.0f',...
                                this.uieMultiPoleNum.get(), ...
                                this.uieMultiOffset.get()*100, ...
                                this.uieMultiRot.get(), ...
                                this.uieMultiSigMin.get()*100, ...
                                this.uieMultiSigMax.get()*100, ...
                                this.uieMultiCirclesPerPole.get(), ...
                                this.uieMultiDwell.get(), ...
                                this.uieMultiXOffset.get()*100, ...
                                this.uieMultiYOffset.get()*100, ...
                                this.uieMultiHz.get(), ...
                                this.uieFilterHz.get(), ...
                                this.uieTimeStep.get() ...
                            ); 
                    end
                    
                case uint8(2)
                    
                    % DC offset
                    cName = sprintf('DC_x%1.0f_y%1.0f_dt%1.0f', ...
                        this.uieDCx.get()*100, ...
                        this.uieDCy.get()*100, ...
                        this.uieTimeStep.get() ...
                    );
                
                case uint8(3)
                    
                    % Rastor
                    cName = sprintf('Rastor_%s_ramp%1.0f_dt%1.0f', ...
                        this.uieRastorData.get(), ...
                        this.uieRastorTransitTime.get(), ...
                        this.uieTimeStep.get() ...
                    );
                
                case uint8(4)
                    % Saw
                    switch this.uipSawTimeType.getSelectedIndex()
                        case uint8(1)
                            % Period
                            cName = sprintf('Saw_sigx%1.0f_phasex%1.0f_offx%1.0f_sigy%1.0f_phasey%1.0f_offy%1.0f_scale%1.0f_per%1.0f_filthz%1.0f_dt%1.0f',...
                                this.uieSawSigX.get()*100, ...
                                this.uieSawPhaseX.get(), ...
                                this.uieSawOffsetX.get()*100, ...
                                this.uieSawSigY.get()*100, ...
                                this.uieSawPhaseY.get(), ...
                                this.uieSawOffsetY.get()*100, ...
                                this.uieVoltsScale.get(), ...
                                this.uieSawPeriod.get(), ...
                                this.uieFilterHz.get(), ...
                                this.uieTimeStep.get() ...
                            );                           
                    
                        
                        case uint8(2)
                            % Period
                            cName = sprintf('Saw_sigx%1.0f_phasex%1.0f_offx%1.0f_sigy%1.0f_phasey%1.0f_offy%1.0f_scale%1.0f_hz%1.0f_filthz%1.0f_dt%1.0f',...
                                this.uieSawSigX.get()*100, ...
                                this.uieSawPhaseX.get(), ...
                                this.uieSawOffsetX.get()*100, ...
                                this.uieSawSigY.get()*100, ...
                                this.uieSawPhaseY.get(), ...
                                this.uieSawOffsetY.get()*100, ...
                                this.uieVoltsScale.get(), ...
                                this.uieSawHz.get(), ...
                                this.uieFilterHz.get(), ...
                                this.uieTimeStep.get() ...
                            );   
                    end
                    
                case uint8(5)
                    
                    % Serpentine
                    cName = sprintf('Serpentine_sigx%1.0f_numx%1.0f_offx%1.0f_sigy%1.0f_numy%1.0f_offy%1.0f_scale%1.0f_per%1.0f_filthz%1.0f_dt%1.0f',...
                        this.uieSerpSigX.get()*100, ...
                        this.uieSerpNumX.get(), ...
                        this.uieSerpOffsetX.get()*100, ...
                        this.uieSerpSigY.get()*100, ...
                        this.uieSerpNumY.get(), ...
                        this.uieSerpOffsetY.get()*100, ...
                        this.uieVoltsScale.get(), ...
                        this.uieSerpPeriod.get(), ...
                        this.uieFilterHz.get(), ...
                        this.uieTimeStep.get() ...
                    );  
                     
            end
            
                        
            % NEW 2017.02.02
            % Allow the user to change the filename, if desired but do not
            % allow them to select a different directory.
            
            cePrompt = {'Save As:'};
            cTitle = '';
            dLines = 1;
            ceDefaultAns = {cName};
            ceAnswer = inputdlg(...
                cePrompt,...
                cTitle,...
                dLines,...
                ceDefaultAns ...
            );
            
            if isempty(ceAnswer)
                return
            end
            
            this.savePupilFill([ceAnswer{1}, '.mat']);
           
            
            % OLD < 2017.02.02
            % Allowed the user to select a different directory.  Don't do
            % this because the list always shows only one directory.
           
            %{
            [cFileName, cPathName, cFilterIndex] = uiputfile('*.mat', 'Save As:', cName);
            
            % uiputfile returns 0 when the user hits cancel
            if cFileName ~= 0
                this.savePupilFill(cFileName, cPathName)
            end
            %}
                                                    
        end
        
        % @param {char 1xm} cFileName name of file with '.mat' extension
        function savePupilFill(this, cFileName)
                                    
            % Create a nested recursive structure of all public properties
            
            s = this.save();
            
            save(fullfile(this.cDirWaveforms, cFileName), 's');
            
            % If the name is not already on the list, append it
            if isempty(strmatch(cFileName, this.uilSaved.getOptions(), 'exact'))
                this.uilSaved.append(cFileName);
            end
            
            notify(this, 'eNew');
            
            % this.saveAsciiFiles(cFileName)            
           
        end
        
        function saveAsciiFiles(this)
            
            % Save ascii files for nPoint software.  Make sure the time
            % step is 24 us.  This is the control loop clock so it will
            % read a data point from the file once every 24 us.  If your
            % samples are not separated by 24 us, the process of reading
            % the txt file will change the effective frequency
            
            % Signal levels need to be in mrad.  +/- 10 V == +/- 3 mrad.
            % Also, the vector needs to be a column vector before it is
            % written to ascii so each value goes on a new line.
            
            vx = this.dVx*3/10;
            vy = this.dVy*3/10;
            
            vx = vx';
            vy = vy';
            
            % Build the pupilfill_ascii directory if it does not exist
            
            cDirSaveAscii = fullfile( ...
                this.cDirApp, ...
                'pupilfill_ascii' ...
            );
        
            mic.Utils.checkDir(cDirSaveAscii);
                        
            % Save
            
            cPathX = fullfile( ...
                cDirSaveAscii, ...
                [cName, '_x.txt'] ...
            );
            cPathY = fullfile( ...
                cDirSaveAscii, ...
                [cName, '_y.txt'] ...
            );
            
            save(cPathX, 'vx', '-ascii');
            save(cPathY, 'vy', '-ascii');
                        
        end
        
        function buildWaveformPanel(this)
                        
            if ~ishandle(this.hFigure)
                return;
            end

            dLeftCol1 = 10;
            dLeftCol2 = 100;
            dEditWidth = 80;
            dTop = 20;
            dSep = 55;

            % Panel
            this.hWaveformPanel = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'Build Waveform',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([10 10 210 700], this.hFigure) ...
            );
            drawnow;


            % Popup (to select type)
            this.uipType.build(this.hWaveformPanel, dLeftCol1, dTop, 190, this.dHeightEdit);

            % Build the sub-panel based on popup type 
            switch this.uipType.getSelectedIndex()
                case uint8(1)
                    % Multi
                    this.buildWaveformMultiPanel();
                case uint8(2)
                    % DC offset
                    this.buildWaveformDCPanel();
                case uint8(3)
                    % Rastor
                    this.buildWaveformRastorPanel();
                case uint8(4)
                    % Triangle
                    this.buildWaveformSawPanel();
                case uint8(5)
                    % Serpentine
                    this.buildWaveformSerpPanel();
            end


            % Build sub-panel for parameters that apply to all waveform
            this.buildWaveformGeneralPanel();


            % Preview and save buttons
            dTop = 630;
            this.uibPreview.build(this.hWaveformPanel, dLeftCol1, dTop, 190, this.dHeightEdit);
            dTop = dTop + 30;

            this.uibSave.build(this.hWaveformPanel, dLeftCol1, dTop, 190, this.dHeightEdit);
            dTop = dTop + dSep;
                
            
        end
        
        function buildWaveformGeneralPanel(this)
            
            if ~ishandle(this.hWaveformPanel)
                return
            end

            dLeftCol1 = 10;
            dLeftCol2 = 100;
            dEditWidth = 80;
            dTop = 20;
            dSep = 55;

            % Panel

            this.hWaveformGeneralPanel = uipanel(...
                'Parent', this.hWaveformPanel,...
                'Units', 'pixels',...
                'Title', 'General',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([10 490 190 130], this.hWaveformPanel) ...
            );
            drawnow;

            % Build filter Hz, Volts scale and time step

            this.uieFilterHz.build(this.hWaveformGeneralPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);            
            this.uieVoltsScale.build(this.hWaveformGeneralPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            this.uieTimeStep.build(this.hWaveformGeneralPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieConvKernelSig.build(this.hWaveformGeneralPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);

            dTop = dTop + dSep; 
                            
        end
        
        
        function buildWaveformMultiPanel(this)
            
            if ~ishandle(this.hWaveformPanel)
                return
            end
            
            dLeftCol1 = 10;
            dLeftCol2 = 100;
            dEditWidth = 80;
            dTop = 20;
            dSep = 40;

            % Panel
            this.hWaveformMultiPanel = uipanel(...
                'Parent', this.hWaveformPanel,...
                'Units', 'pixels',...
                'Title', 'Multipole configuration',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([10 65 190 420], this.hWaveformPanel) ...
            );
            drawnow;

            this.uieMultiPoleNum.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieMultiTransitTime.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uieMultiSigMin.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieMultiSigMax.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            this.uieMultiCirclesPerPole.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieMultiDwell.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            this.uieMultiOffset.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieMultiRot.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            this.uieMultiXOffset.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieMultiYOffset.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            % Popup (to select type)
            this.uipMultiTimeType.build(this.hWaveformMultiPanel, dLeftCol1, dTop, 170, this.dHeightEdit);
            dTop = dTop + 45;

            this.uieMultiPeriod.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieMultiHz.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);                

            % Call handler for multitimetype to make active type visible
            this.onMultiTimeTypeChange();
            dTop = dTop + 45;

            this.uitMultiFreqRange.build(this.hWaveformMultiPanel, dLeftCol1, dTop, 170, 30);

            drawnow;
                
            
        end
        
        function buildWaveformDCPanel(this)
            
            if ~ishandle(this.hWaveformPanel)
                return
            end

            dLeftCol1 = 10;
            dLeftCol2 = 100;
            dEditWidth = 80;
            dTop = 20;
            dSep = 55;

            % Panel

            this.hWaveformDCPanel = uipanel(...
                'Parent', this.hWaveformPanel,...
                'Units', 'pixels',...
                'Title', 'DC configuration',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([10 65 190 80], this.hWaveformPanel) ...
            );
            drawnow;


            this.uieDCx.build(this.hWaveformDCPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);            
            this.uieDCy.build(this.hWaveformDCPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);

            drawnow;

        end
        
        function buildWaveformRastorPanel(this)
            
            if ~ishandle(this.hWaveformPanel)
                return
            end
            

            dLeftCol1 = 10;
            dLeftCol2 = 100;
            dEditWidth = 80;
            dTop = 20;
            dSep = 55;

            % Panel
            this.hWaveformRastorPanel = uipanel(...
                'Parent', this.hWaveformPanel,...
                'Units', 'pixels',...
                'Title', 'Rastor configuration',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([10 65 190 130], this.hWaveformPanel) ...
            );
            drawnow;


            this.uieRastorData.build(this.hWaveformRastorPanel, dLeftCol1, dTop, 170, this.dHeightEdit); 
            dTop = dTop + dSep;     

            this.uieRastorTransitTime.build(this.hWaveformRastorPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);

            drawnow;
                        
        end
        
        function buildWaveformSawPanel(this)
            
            if ~ishandle(this.hWaveformPanel)
                return
            end

            dLeftCol1 = 10;
            dLeftCol2 = 100;
            dEditWidth = 80;
            dTop = 20;
            dSep = 55;

            this.hWaveformSawPanel = uipanel(...
                'Parent', this.hWaveformPanel,...
                'Units', 'pixels',...
                'Title', 'Triangle configuration',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([10 65 190 300], this.hWaveformPanel) ...
            );
            drawnow;

            this.uieSawSigX.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieSawSigY.build(this.hWaveformSawPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uieSawPhaseX.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieSawPhaseY.build(this.hWaveformSawPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uieSawOffsetX.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieSawOffsetY.build(this.hWaveformSawPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uipSawTimeType.build(this.hWaveformSawPanel, dLeftCol1, dTop, 170, this.dHeightEdit);

            dTop = dTop + 45;

            this.uieSawPeriod.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieSawHz.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);                
            this.onSawTimeTypeChange(); % Call handler for multitimetype to make active type visible

            drawnow;
            
        end
        
        
        function buildWaveformSerpPanel(this)
            
            if ~ishandle(this.hWaveformPanel)
                return
            end

            dLeftCol1 = 10;
            dLeftCol2 = 100;
            dEditWidth = 80;
            dTop = 20;
            dSep = 40;

            this.hWaveformSerpPanel = uipanel(...
                'Parent', this.hWaveformPanel,...
                'Units', 'pixels',...
                'Title', 'Serpentine config',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([10 65 190 300], this.hWaveformPanel) ...
            );
            drawnow;

            this.uieSerpSigX.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieSerpSigY.build(this.hWaveformSerpPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uieSerpNumX.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieSerpNumY.build(this.hWaveformSerpPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uieSerpOffsetX.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uieSerpOffsetY.build(this.hWaveformSerpPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uieSerpPeriod.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);

            drawnow;
            
        end
        
        function buildSavedWaveformsPanel(this)
            
            if ~ishandle(this.hFigure)
                return;
            end
            

            dWidth = this.dWidthSavedWaveformsPanel;

            hPanel = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'Saved Waveforms',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([230 this.dYOffset dWidth 350], this.hFigure) ...
            );
            drawnow;

            dButtonWidth = 100;
            this.uilSaved.build(hPanel, 10, 20, dWidth-20, 290);
            
            dTop = 315;
            dLeft = 10;
            
            this.uibWriteWaveform.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            this.uibStartWaveform.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            
            this.uibStopWaveform.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            this.uibWriteWaveform.setTooltip('Write the waveform data to the LC400 controller.  This can take several seconds');
            this.uibStartWaveform.setTooltip('Start scanning');
            this.uibStopWaveform.setTooltip('Stop scanning');
            
            this.uibWriteWaveform.hide();
            this.uibStartWaveform.hide();
            this.uibStopWaveform.hide();
                
            
        end
        
        function buildPlotPanel(this)
            
            if ~ishandle(this.hFigure)
                return
            end

            this.hPlotPanel = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'Plot',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([230 10 this.dWidthPlotPanel 340], this.hFigure) ...
            );
            drawnow; 

            % Popup (to select type)
            this.uipPlotType.build(this.hPlotPanel, 10, 20, 190, this.dHeightEdit);

            % Call handler for popup to build type
            this.onPlotTypeChange();
            
        end
        
        function buildPlotPreviewPanel(this)
            
            if ~ishandle(this.hPlotPanel)
                return
            end

            dSize = 220;
            dPad = 30;

            this.hPlotPreviewPanel = uipanel(...
                'Parent', this.hPlotPanel,...
                'Units', 'pixels',...
                'Title', '',...
                'Clipping', 'on',...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([2 65 990-6 280], this.hPlotPanel) ...
            );
            drawnow;            

            this.hPreviewAxis1D = axes(...
                'Parent', this.hPlotPreviewPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([dPad 5 dSize*2 dSize], this.hPlotPreviewPanel),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'HandleVisibility','on'...
                );

            this.hPreviewAxis2D = axes(...
                'Parent', this.hPlotPreviewPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([2*(dPad+dSize) 5 dSize dSize], this.hPlotPreviewPanel),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'DataAspectRatio',[1 1 1],...
                'HandleVisibility','on'...
                );

            this.hPreviewAxis2DSim = axes(...
                'Parent', this.hPlotPreviewPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([3*(dSize+dPad) 5 dSize dSize], this.hPlotPreviewPanel),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'DataAspectRatio',[1 1 1],...
                'HandleVisibility','on'...
                );

                % 'PlotBoxAspectRatio',[obj.xpix obj.ypix 1],...
                % 'XTick',[],...
                % 'YTick',[],...
                % 'Xlim',[obj.stagexminCAL obj.stagexmaxCAL] ...
                % 'Color',[0.3,0.3,0.3],...
                                
        end
        

        function buildPlotMonitorPanel(this)
            
            if ~ishandle(this.hPlotPanel)
                return 
            end

            dSize = 220;
            dPad = 30;

            this.hPlotMonitorPanel = uipanel(...
                'Parent', this.hPlotPanel,...
                'Units', 'pixels',...
                'Title', '',...
                'Clipping', 'on',...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([2 65 990-6 280], this.hPlotPanel) ...
            );
            drawnow;


            this.hMonitorAxis1D = axes(...
                'Parent', this.hPlotMonitorPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([dPad 5 dSize*2 dSize], this.hPlotMonitorPanel),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'HandleVisibility','on'...
                );

            this.hMonitorAxis2D = axes(...
                'Parent', this.hPlotMonitorPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([2*(dPad+dSize) 5 dSize dSize], this.hPlotMonitorPanel),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'DataAspectRatio',[1 1 1],...
                'HandleVisibility','on'...
                );

            this.hMonitorAxis2DSim = axes(...
                'Parent', this.hPlotMonitorPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([3*(dSize+dPad) 5 dSize dSize], this.hPlotMonitorPanel),...
                'XColor', [0 0 0],...
                'YColor', [0 0 0],...
                'DataAspectRatio',[1 1 1],...
                'HandleVisibility','on'...
                );

                % 'PlotBoxAspectRatio',[obj.xpix obj.ypix 1],...
                % 'XTick',[],...
                % 'YTick',[],...
                % 'Xlim',[obj.stagexminCAL obj.stagexmaxCAL] ...
                % 'Color',[0.3,0.3,0.3],...
                                
            
        end
        
        
        function buildPlotRecordPanel(this)
            
            if ~ishandle(this.hPlotPanel)
                return
                
            end

            this.hPlotRecordPanel = uipanel(...
                'Parent', this.hPlotPanel,...
                'Units', 'pixels',...
                'Title', '',...
                'Clipping', 'on',...
                'BorderType', 'none', ...
                'Position', mic.Utils.lt2lb([210 25 200 40], this.hPlotPanel) ...
            );
            drawnow;

            % Button
            this.uibRecord.build(this.hPlotRecordPanel, 0, 0, 100, this.dHeightEdit);

            % Time
            this.uieRecordTime.build(this.hPlotRecordPanel, 105, 0, 40, this.dHeightEdit);

            % "ms"
            uitLabel = mic.ui.common.Text('cVal', 'ms');
            uitLabel.build(this.hPlotRecordPanel, 150, 8, 30, this.dHeightEdit);

            % this.uibRecord.hide();
            % this.uieRecordTime.hide();
            
        end
                
        
        
        
        
        
        function onCloseRequest(this, src, evt)
            delete(this.hFigure);
            this.saveState(); 
        end
        
        
        
        function updatePupilImg(this, cType)

            % Return if the handles don't exist
            
            switch (cType)
                case 'preview'
                    if  ishandle(this.hFigure) & ...
                        ishandle(this.hPreviewAxis2DSim)
                        % Proceed
                    else
                        return;
                    end
                case 'device'
                    if ishandle(this.hFigure) & ...
                       ishandle(this.hMonitorAxis2DSim)
                        % Proceed
                    else
                        return;
                    end
            end
            

            % 2013.08.19 CNA
            % Passing in Vx and Vy now so it is easy to do with the sensor
            % data and not just the preview waveform data

           
            % Create empty pupil fill matrices

            int = zeros(this.dPreviewPixels,this.dPreviewPixels);

            % Map each (vx,vy) pair to its corresponding pixel in the pupil
            % fill matrices.  For vy, need to flip its sign before
            % computing the pixel because of the way matlab does y
            % coordinates in an image plot

            dVoltsAtEdge = this.dPupilScale*this.uieVoltsScale.get();

            
            % dVxPixel {double 1 x length(dVx)}
            % dVyPixel {double 1 x length(dVy)}
            % 
            switch (cType)
                case 'preview'
                    dVxPixel = ceil(this.dVx/dVoltsAtEdge*(this.dPupilPixels/2)) + floor(this.dPupilPixels/2);
                    dVyPixel = ceil(-this.dVy/dVoltsAtEdge*(this.dPupilPixels/2)) + floor(this.dPupilPixels/2);                    
                case 'device'
                    dVxPixel = ceil(this.dRVxSensor/dVoltsAtEdge*(this.dPupilPixels/2)) + floor(this.dPupilPixels/2);
                    dVyPixel = ceil(-this.dRVySensor/dVoltsAtEdge*(this.dPupilPixels/2)) + floor(this.dPupilPixels/2);
            end

            % If any of the pixels lie outside the matrix, discard them

            dIndex = find(  dVxPixel <= this.dPupilPixels & ...
                            dVxPixel > 0 & ...
                            dVyPixel <= this.dPupilPixels & ...
                            dVyPixel > 0 ...
                            );

            dVxPixel = dVxPixel(dIndex);
            dVyPixel = dVyPixel(dIndex);

            % Add a "1" at each pixel where (vx,vy) pairs reside.  We may end up adding
            % "1" to a given pixel a few times - especially if the dwell is set to more
            % than 1.

            for n = 1:length(dVxPixel)
                int(dVyPixel(n), dVxPixel(n)) = int(dVyPixel(n), dVxPixel(n)) + 1;
            end

%             for n = 1:length(x_gc)
%                 int_gc(y_gc(n),x_gc(n)) = int_gc(y_gc(n),x_gc(n)) + 1;
%             end

            % Get the convolution kernel and convolve the pseudo-intensity
            % map with kernel and normalize


            [dX, dY, dKernelInt] = this.getKernel();            

            int = conv2(int,dKernelInt.^2,'same');
            int = int./max(max(int));
            % int = imrotate(int, 90);


            % Fill simulated with gain plot.  Old way to activate the axes we want:
            % axes(handles.pupil_axes), however this way sucks because it actually
            % creates a new

            switch (cType)
                case 'preview'
                    % set(this.hFigure, 'CurrentAxes', this.hPreviewAxis2DSim);
                    hParent = this.hPreviewAxis2DSim;
                case 'device'
                    % set(this.hFigure, 'CurrentAxes', this.hMonitorAxis2DSim);
                    hParent = this.hMonitorAxis2DSim;
            end

            imagesc(int, 'Parent', hParent)
            axis(hParent, 'image')
            colormap(hParent, 'jet');
            
            if this.lSerpentineDebug
                
                % Propagate 4 m with an angle of 6 mrad gives 24 mm of
                % displacement at the wafer at +10 volts (sig = 1) and - 24 mm at -
                % 10 volts.  
                
                dMmPerSig = 24;
                dMmPerVolts = 24/10;
                
                
                % Kernel
                imagesc(dX(:, 1)*dMmPerSig, dY(1, :)*dMmPerSig, dKernelInt, ...
                    'Parent', this.hSerpentineKernelAxes ...
                )
                axis(this.hSerpentineKernelAxes, 'image')
                colormap(this.hSerpentineKernelAxes, 'jet');
                xlabel(this.hSerpentineKernelAxes, 'x (mm)');
                ylabel(this.hSerpentineKernelAxes, 'y (mm)');
                
                % Waveform
                plot(this.dVx*dMmPerVolts, this.dVy*dMmPerVolts, 'b', ...
                    'Parent', this.hSerpentineWaveformAxes ...
                );
                axis(this.hSerpentineWaveformAxes, 'image')
                xlim(this.hSerpentineWaveformAxes, [-this.uieVoltsScale.get() this.uieVoltsScale.get()]*dMmPerVolts)
                ylim(this.hSerpentineWaveformAxes, [-this.uieVoltsScale.get() this.uieVoltsScale.get()]*dMmPerVolts)
                xlabel(this.hSerpentineWaveformAxes, 'x (mm)');
                ylabel(this.hSerpentineWaveformAxes, 'y (mm)');
                
                
                % Convolution
                imagesc(dX(:, 1)*dMmPerSig, dY(1, :)*dMmPerSig, int, ...
                    'Parent', this.hSerpentineConvAxes ...
                )
                axis(this.hSerpentineConvAxes, 'image')
                colormap(this.hSerpentineConvAxes, 'jet');
                xlabel(this.hSerpentineConvAxes, 'x (mm)');
                ylabel(this.hSerpentineConvAxes, 'y (mm)');
                
                % Apertured convolution
                
                % Box half width and half height in mm
                dBoxXLim = 5;
                dBoxYLim = 5;
                
                % Box sigma
                dSigXLim = dBoxXLim/dMmPerSig;
                dSigYLim = dBoxYLim/dMmPerSig;
               
                dIndex = abs(dX) > dSigXLim | abs(dY) > dSigYLim;
                
                intCrop = int;
                dXCrop = dX;
                dYCrop = dY;
                
                intCrop(dIndex) = 0;
                intCropCalc = intCrop;
                intCropCalc(dIndex) = [];
                
                
                
                imagesc(dXCrop(:, 1)*dMmPerSig, dYCrop(1, :)*dMmPerSig, intCrop, ...
                    'Parent', this.hSerpentineConvOutputAxes ...
                );
                %{
                imagesc(intCrop, ...
                    'Parent', this.hSerpentineConvOutputAxes ...
                )
                %}
                axis(this.hSerpentineConvOutputAxes, 'image')
                colormap(this.hSerpentineConvOutputAxes, 'jet');
                xlabel(this.hSerpentineConvOutputAxes, 'x (mm)');
                ylabel(this.hSerpentineConvOutputAxes, 'y (mm)');
                xlim(this.hSerpentineConvOutputAxes, [-dSigXLim dSigXLim]*dMmPerSig);
                ylim(this.hSerpentineConvOutputAxes, [-dSigYLim dSigYLim]*dMmPerSig);
                
                title(this.hSerpentineKernelAxes, 'Unscanned beam');
                title(this.hSerpentineWaveformAxes, 'Scan path');
                title(this.hSerpentineConvAxes, 'Scanned beam');
                title(this.hSerpentineConvOutputAxes, ...
                    sprintf(...
                        'Central %1.0f mm x %1.0f mm RMS = %1.1f%%, PV = %1.1f%%', ...
                        dBoxXLim*2, ...
                        dBoxYLim*2, ...
                        std(intCropCalc)*100, ...
                        100*(max(intCropCalc) - min(intCropCalc)) ...
                    ) ...
                );
                
                
                % Draw border box
                
                dXBox = [-dSigXLim -dSigXLim dSigXLim dSigXLim -dSigXLim];
                dYBox = [-dSigYLim  dSigYLim dSigYLim -dSigYLim -dSigYLim];
                
                % When x/y are mm
                dXBox = dXBox*dMmPerSig;
                dYBox = dYBox*dMmPerSig;
                
                %{
                % When x/y is pixels
                dXBox = dXBox*this.dPupilPixels/this.dPupilScale/2 + this.dPupilPixels/2;
                dYBox = dYBox*this.dPupilPixels/this.dPupilScale/2 + this.dPupilPixels/2;
                %}
                                
                line( ...
                    dXBox, dYBox, ...
                    'color', [1 1 1], ...
                    'LineWidth', 1, ...
                    'Parent', this.hSerpentineConvAxes ...
                );
            
                % 2016.03.02 plot the derivative of the voltage w.r.t to
                % time and multiply by the capicatance to get the current
                
                ddVxdT = derivative(this.dVx, this.uieTimeStep.get()*1e-6);
                ddVydT = derivative(this.dVy, this.uieTimeStep.get()*1e-6);
                
                dC = 2e-6; % advertised
                dC_scale_factor = 300/113;
                
                dIx = ddVxdT*dC*dC_scale_factor;
                dIy = ddVydT*dC*dC_scale_factor;
                
                % hold(this.hSerpentineCurrentAxes);
                plot(this.dTime*1000, dIx*1000, 'r', ...
                    'Parent', this.hSerpentineCurrentAxes ...
                );
                plot(this.dTime*1000, dIy*1000, 'b', ...
                    'Parent', this.hSerpentineCurrentAxes ...
                );
                xlabel(this.hSerpentineCurrentAxes, 'Time (ms)');
                ylabel(this.hSerpentineCurrentAxes, 'Current (mA)');
                title(this.hSerpentineCurrentAxes, 'Scanner current (300 mA max)');
                xlim(this.hSerpentineCurrentAxes, [0 max(this.dTime)*1000]);
            
            end
            
        
               

            % Create plotting data for circles at sigma = 0.3 - 1.0

            dSig = [0.3:0.1:1.0];
            dPhase = linspace(0, 2*pi, this.dPupilPixels);

            for (k = 1:length(dSig))

                % set(this.hFigure, 'CurrentAxes', this.hPreviewAxis2DSim)
                x = dSig(k)*this.dPupilPixels/this.dPupilScale/2*cos(dPhase) + this.dPupilPixels/2;
                y = dSig(k)*this.dPupilPixels/this.dPupilScale/2*sin(dPhase) + this.dPupilPixels/2;
                line( ...
                    x, y, ...
                    'color', [0.3 0.3 0.3], ... % [0.3 0.1 0.4], ... % [1 1 0] == yellow
                    'LineWidth', 1, ...
                    'Parent', hParent ...
                    );

            end

        end
        
      
        
        function drawSigmaCircles(this)

            
            
        end
        
        
        function [X,Y] = getXY(this, Nx, Ny, Lx, Ly)

            % Sample spacing

            dx = Lx/Nx;
            dy = Ly/Ny;


            % Sampled simulation points 1D 

            x = -Lx/2:dx:Lx/2 - dx;
            y = -Ly/2:dy:Ly/2 - dy;
            % u = -1/2/dx: 1/Nx/dx: 1/2/dx - 1/Nx/dx;
            % v = -1/2/dy: 1/Ny/dy: 1/2/dy - 1/Ny/dy;

            [Y,X] = meshgrid(y,x);
            % [V,U] = meshgrid(v,u);
            
        end
        
        
        function [out] = gauss(this, x, sigx, y, sigy)

            if nargin == 5
                out = exp(-((x/sigx).^2/2+(y/sigy).^2/2)); 
            elseif nargin == 4;
                disp('Must input x,sigx,y,sigy in ''gauss'' function')
            elseif nargin == 3;
                out = exp(-x.^2/2/sigx^2);
            elseif nargin == 12;
                out = exp(-x.^2/2);
            end
            
        end
        
        function onListChangeDelete(this, src, evt)
           
            % In this case, evt is an instance of EventWithData (custom
            % class that extends event.EventData) that has a property
            % stData (a structure).  The structure has one property called
            % options which is a cell array of the items on the list that
            % were just deleted.
            % 
            % Need to loop through them and delete them from the directory.
            % The actual filenames are appended with .mat
            
            evt.stData.ceOptions
            
            for k = 1:length(evt.stData.ceOptions)
                
                cFile = fullfile( ...
                    this.cDirWaveforms, ...
                    evt.stData.ceOptions{k} ...
                );
            
                if exist(cFile, 'file') ~= 0
                    % File exists, delete it
                    delete(cFile);
                else
                    this.msg(sprintf('Cannot find file: %s; not deleting.', cFile));
                end
                
            end
            
            notify(this, 'eDelete')

        end
        
        function onListChange(this, src, evt)
            
                        
            % Make sure preview is showing
            
            if this.uipPlotType.getSelectedIndex() ~= uint8(1)
                this.uipPlotType.setSelectedIndex(uint8(1));
            end
            
            
            % Load the .mat file
            ceSelected = this.uilSaved.get();
            
            if ~isempty(ceSelected)
                
                % ceSelected is a cell of selected options - use the first
                % one.  Populates a structure named s in the local
                % workspace of this method
                
                cFile = fullfile( ...
                    this.cDirWaveforms, ...
                    ceSelected{1} ...
                );
            
                
                if exist(cFile, 'file') ~= 0
                
                    load(cFile); % populates structure s in local workspace

                    this.load(s);
                    
                    % When dVx, dVy, etc. are private
                    this.onPreview();  
                    
                    % When dVx, dVy, etc. are public
                    
                    %{
                    this.updateAxes();
                    this.updatePupilImg('preview');
                    %}
                    
                else
                    
                    % warning message box
                    
                    h = msgbox( ...
                        'This pupil file file cannot be found.  Click OK below to continue.', ...
                        'File does not exist', ...
                        'warn', ...
                        'modal' ...
                        );
                    
                    % wait for them to close the message
                    uiwait(h);
                    
                    
                end
                
                
            else
                
                % ceSelected is an empty [1x0] cell.  do nothing
                
            end
            
 
        end
        
        function buildCameraPanel(this)
            
            if ishandle(this.hFigure)

                % Panel
                this.hCameraPanel = uipanel(...
                    'Parent', this.hFigure,...
                    'Units', 'pixels',...
                    'Title', 'Camera overlay with sigma annular lines',...
                    'Clipping', 'on',...
                    'Position', mic.Utils.lt2lb([720 this.dYOffset 400 350], this.hFigure) ...
                );
                drawnow;
            end
            
        end        
        
        function onRecordClick(this, src, evt)
            
            % Compute number of samples from uieRecordTime
            
            dSeconds = this.uieRecordTime.get() * 1e-3; % s
            dClockPeriod = 24e-6;
            u32Num = uint32(round(dSeconds / dClockPeriod));
            
            cMsg = sprintf('Recording %1.0f samples from LC400', u32Num);
            this.msg(cMsg);
            
            dResult = this.np.record(u32Num);
            
            % Unpack
            
            dTime = double(1 : u32Num) * dClockPeriod;
            
            
            this.dRVxCommand =      dResult(1, :) * this.uieVoltsScale.get(); % * cos(this.dThetaX * pi / 180);
            this.dRVxSensor =       dResult(2, :) * this.uieVoltsScale.get(); % * cos(this.dThetaX * pi / 180);
            this.dRVyCommand =      dResult(3, :) * this.uieVoltsScale.get(); % * cos(this.dThetaY * pi / 180);
            this.dRVySensor =       dResult(4, :) * this.uieVoltsScale.get(); % * cos(this.dThetaY * pi / 180);
            this.dRTime =           dTime;
            
            
            % stReturn = this.np.record();
            
            % Unpack 
            %{
            this.dRVxCommand =      stReturn.dRVxCommand;
            this.dRVxSensor =       stReturn.dRVxSensor;
            this.dRVyCommand =      stReturn.dRVyCommand;   
            this.dRVySensor =       stReturn.dRVySensor;
            this.dRTime =           stReturn.dRTime;
            
            %}
            
            % Update the axes
            this.updateRecordAxes();
            
        end
        
        function [i32X, i32Y] = get20BitWaveforms(this)
            
            if isempty(this.dVx) || ...
               isempty(this.dVy)
                
                % Empty - did not type anything
                % Throw a warning box and recursively call

                h = msgbox( ...
                    'The signal has not been set, click preview first.', ...
                    'Empty name', ...
                    'warn', ...
                    'modal' ...
                    );

                % wait for them to close the message
                uiwait(h);
                return;
            end
            
            % Convert the voltages into ints between +/- (2^19 - 1) where
            % 2^19 - 1 is the max 
            
            % Step 1, get values in [-1 1]
            dVxRel = this.dVx / this.uieVoltsScale.get(); % values in [-1 : 1]
            dVyRel = this.dVy / this.uieVoltsScale.get(); % values in [-1 : 1]
            
            % 2017.02.02
            % Adding correction factor for AOI.  The x direction receives
            % cos(45) less displacement than y so need to increase it.
            
            dVxRelCor = dVxRel / cos(this.dThetaX * pi / 180);
            dVyRelCor = dVyRel / cos(this.dThetaY * pi / 180);
            
            % Convert to values between +/- (2^19 - 1) and cast as int32 as
            % this is needed for LC400 max value and min value
            
            i32X = int32(dVxRelCor * (2^19 - 1));
            i32Y = int32(dVyRelCor * (2^19 - 1));  
            
        end
        
        function onWriteClick(this, src, evt)
                                    
            [i32X, i32Y] = this.get20BitWaveforms();
            
            this.uibWriteWaveform.setText('Writing ...');
            drawnow;
            
            this.setWavetable(i32X, i32Y)  
            this.uibWriteWaveform.setText('Write nPoint')
            
            h = msgbox( ...
                'The waveform has been written.  Click "Start Scan" to start.', ...
                'Success!', ...
                'help', ...
                'modal' ...
            );
           
            
        end
        
        
        function onStopClick(this, src, evt)
            
            % Stop
            this.np.setTwoWavetablesActive(false);
            
            % Disable
            this.np.setWavetableEnable(uint8(1), false);
            this.np.setWavetableEnable(uint8(2), false);
            
        end
        
        function onStartClick(this, src, evt)
            
            % Enable
            this.np.setWavetableEnable(uint8(1), true);
            this.np.setWavetableEnable(uint8(2), true);
            
            % Start
            this.np.setTwoWavetablesActive(true);
            
        end
        
        function ceReturn = onListRefresh(this)
            
            % Get path to the save directory
            
            ceReturn = mic.Utils.dir2cell(this.cDirWaveforms, 'date', 'descend', '*.mat');
                        
        end
        
        % @return {double m x n} return a matrix that represents the
        % intensity distribution of the scan kernel (beam intensity). 
        
        function [dX, dY, dKernelInt] = getKernel(this)
            
            dKernelSig = 0.02; % Using uie now.
            
            dKernelSigPixels = this.uieConvKernelSig.get()*this.dPupilPixels/this.dPupilScale/2;
            dKernelPixels = floor(dKernelSigPixels*2*4); % the extra factor of 2 is for oversize padding
            [dX, dY] = this.getXY(dKernelPixels, dKernelPixels, dKernelPixels, dKernelPixels);
            dKernelInt = this.gauss(dX, dKernelSigPixels, dY, dKernelSigPixels);
                        
            [dX, dY] = this.getXY(this.dPreviewPixels, this.dPreviewPixels, 2*this.dPreviewScale, 2*this.dPreviewScale);
            dKernelInt = this.gauss(dX, this.uieConvKernelSig.get(), dY, this.uieConvKernelSig.get());
            
            
            if this.lSerpentineDebug
                            

                % Update.  Build an aberrated, lumpy footprint for developing
                % serpentine patterns

                dKernelInt = zeros(size(dY));
                dTrials = 12;
                dSpread = 0.15; % Use spread = 0.15 with sigma = 0.1 (in the GUI) to get lumpy sigma = 0.2 spots
                dMag = abs(randn(1, dTrials));
                dX0 = randn(1, dTrials)*dSpread*this.dPreviewScale;
                dY0 = randn(1, dTrials)*dSpread*this.dPreviewScale;

                for n = 1:dTrials
                    dKernelInt = dKernelInt + dMag(n)*this.gauss(...
                        dX - dX0(n), ...
                        this.uieConvKernelSig.get(), ...
                        dY - dY0(n), ...
                        this.uieConvKernelSig.get());
                end


                % Compute center of mass and circshift the matrix so the center
                % of mass is in the center

                dArea = sum(sum(dKernelInt));
                dMeanX = sum(sum(dKernelInt.*dX))/dArea*this.dPreviewPixels/2;
                dMeanY = sum(sum(dKernelInt.*dY))/dArea*this.dPreviewPixels/2;

                dKernelInt = circshift(dKernelInt, [-round(dMeanX), -round(dMeanY)]);
                               
           
            end
            
            
        end
        
        
        function l = setWavetable(this, i32Ch1, i32Ch2)
            
                        
            % Stop scanning
            this.np.setTwoWavetablesActive(false);
            
            % Disable
            this.np.setWavetableEnable(uint8(1), false);
            this.np.setWavetableEnable(uint8(2), false);
            
            % Write data
            this.np.setWavetable(uint8(1), i32Ch1');
            this.np.setWavetable(uint8(2), i32Ch2');
            
            figure
            h = plot(i32Ch1, i32Ch2);
            xlim([-2^19 2^19])
            ylim([-2^19 2^19])
            
            l = true;
            
            
        end
        
        %{
        function checkDir(this, cPath)
            if (exist(cPath, 'dir') ~= 7)
                cMsg = sprintf('checkDir() creating dir %s', cPath);
                disp(cMsg);
                mkdir(cPath);
            end
        end
        %}
    
        
    end

end
        
        
        