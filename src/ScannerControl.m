classdef ScannerControl < mic.Base
%PUPILFILL Class that allows to monitor and the control of the Pupil fill
%
%   See also ScannerCore, RETICLEPICK, HEIGHTSENSOR
    

% Currently, saving saves the state of every UI element
% Loading loads the state of every UI element and calls onPreview() to
% calculate the waveforms and plot them


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
        
        dThetaX = 0; % deg
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
        
        cDevice = 'M142'       % Name of nPoint device 'm142' (field), 'm143' (pupil)
        
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
        hPlotRecordPanel        % panel with the uiEdit time and record button
        
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
        
        uiEditMultiPoleNum
        uiEditMultiSigMin
        uiEditMultiSigMax
        uiEditMultiCirclesPerPole
        uiEditMultiDwell
        uiEditMultiOffset
        uiEditMultiRot
        uiEditMultiXOffset
        uiEditMultiYOffset
        uiEditMultiTransitTime
        uiEditTimeStep
        uipMultiTimeType
        uiEditMultiHz
        uiEditMultiPeriod
        uitMultiFreqRange

        uiEditSawSigX
        uiEditSawPhaseX
        uiEditSawOffsetX
        uiEditSawSigY
        uiEditSawPhaseY
        uiEditSawOffsetY
        uipSawTimeType
        uiEditSawHz
        uiEditSawPeriod
        
        uiEditSerpSigX
        uiEditSerpSigY
        uiEditSerpNumX
        uiEditSerpNumY
        uiEditSerpOffsetX
        uiEditSerpOffsetY
        uiEditSerpPeriod
        
        uiEditDCx
        uiEditDCy
        
        uiEditRastorData
        uiEditRastorTransitTime
        uildSaved
        
        uiEditFilterHz
        uiEditConvKernelSig
        
        uiButtonPreview
        uiButtonSave
        uiButtonRecord
        uiEditRecordTime
        
        uiButtonLC400Write
        uiButtonLC400Start
        uiButtonLC400Stop
        uiButtonLC400Connect
        uiButtonLC400Read
        uiButtonLC400Record
        uiEditLC400Time
        
        
        cLC400TcpipHost = '192.168.0.3'
        
        cLabelLC400Write = 'Write'
        cLabelLC400Start = 'Start'
        cLabelLC400Stop = 'Stop'
        cLabelLC400Read = 'Read & Plot'
        cLabelLC400Record = 'Record & Plot'
        
        
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
                        
            x = this.dVx ; % values in [-1 : 1]
            y = this.dVy ; % values in [-1 : 1]
            
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
                'Visible', 'on' ...
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
            this.buildLC400Panel();
            
            % this.buildCameraPanel();
            % this.buildDevicePanel();
            % this.np.build(this.hFigure, 750 + 160, this.dYOffset);
            this.uildSaved.refresh();
            this.onListChange();
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

             this.uiEditMultiPoleNum.load(st.uiEditMultiPoleNum);
             this.uiEditMultiSigMin.load(st.uiEditMultiSigMin);
             this.uiEditMultiSigMax.load(st.uiEditMultiSigMax);
             this.uiEditMultiCirclesPerPole.load(st.uiEditMultiCirclesPerPole);
             this.uiEditMultiDwell.load(st.uiEditMultiDwell);  
             this.uiEditMultiOffset.load(st.uiEditMultiOffset);
             this.uiEditMultiRot.load(st.uiEditMultiRot);
             this.uiEditMultiXOffset.load(st.uiEditMultiXOffset);
             this.uiEditMultiYOffset.load(st.uiEditMultiYOffset);
             this.uiEditMultiTransitTime.load(st.uiEditMultiTransitTime);
             this.uiEditTimeStep.load(st.uiEditTimeStep);
             this.uipMultiTimeType.load(st.uipMultiTimeType);
             this.uiEditMultiHz.load(st.uiEditMultiHz);
             this.uiEditMultiPeriod.load(st.uiEditMultiPeriod);
 
             this.uiEditSawSigX.load(st.uiEditSawSigX);
             this.uiEditSawPhaseX.load(st.uiEditSawPhaseX);
             this.uiEditSawOffsetX.load(st.uiEditSawOffsetX);
             this.uiEditSawSigY.load(st.uiEditSawSigY);
             this.uiEditSawPhaseY.load(st.uiEditSawPhaseY);
             this.uiEditSawOffsetY.load(st.uiEditSawOffsetY);
             this.uipSawTimeType.load(st.uipSawTimeType);
             this.uiEditSawHz.load(st.uiEditSawHz);
             this.uiEditSawPeriod.load(st.uiEditSawPeriod);

             this.uiEditSerpSigX.load(st.uiEditSerpSigX);
             this.uiEditSerpSigY.load(st.uiEditSerpSigY);
             this.uiEditSerpNumX.load(st.uiEditSerpNumX);
             this.uiEditSerpNumY.load(st.uiEditSerpNumY);
             this.uiEditSerpOffsetX.load(st.uiEditSerpOffsetX);
             this.uiEditSerpOffsetY.load(st.uiEditSerpOffsetY);
             this.uiEditSerpPeriod.load(st.uiEditSerpPeriod);

             this.uiEditDCx.load(st.uiEditDCx);
             this.uiEditDCy.load(st.uiEditDCy);

             this.uiEditRastorData.load(st.uiEditRastorData);
             this.uiEditRastorTransitTime.load(st.uiEditRastorTransitTime);

             this.uiEditFilterHz.load(st.uiEditFilterHz);
             this.uiEditConvKernelSig.load(st.uiEditConvKernelSig);
            
        end
        
        function st = save(this)
            
            st = struct();
            
            st.uipType = this.uipType.save();
            st.uipPlotType = this.uipPlotType.save();

            st.uiEditMultiPoleNum = this.uiEditMultiPoleNum.save();
            st.uiEditMultiSigMin = this.uiEditMultiSigMin.save();
            st.uiEditMultiSigMax = this.uiEditMultiSigMax.save();
            st.uiEditMultiCirclesPerPole = this.uiEditMultiCirclesPerPole.save();
            st.uiEditMultiDwell = this.uiEditMultiDwell.save();  
            st.uiEditMultiOffset = this.uiEditMultiOffset.save();
            st.uiEditMultiRot = this.uiEditMultiRot.save();
            st.uiEditMultiXOffset = this.uiEditMultiXOffset.save();
            st.uiEditMultiYOffset =  this.uiEditMultiYOffset.save();
            st.uiEditMultiTransitTime = this.uiEditMultiTransitTime.save();
            st.uiEditTimeStep = this.uiEditTimeStep.save();
            st.uipMultiTimeType = this.uipMultiTimeType.save();
            st.uiEditMultiHz = this.uiEditMultiHz.save();
            st.uiEditMultiPeriod = this.uiEditMultiPeriod.save();
 
            st.uiEditSawSigX = this.uiEditSawSigX.save();
            st.uiEditSawPhaseX = this.uiEditSawPhaseX.save();
            st.uiEditSawOffsetX = this.uiEditSawOffsetX.save();
            st.uiEditSawSigY = this.uiEditSawSigY.save();
            st.uiEditSawPhaseY = this.uiEditSawPhaseY.save();
            st.uiEditSawOffsetY = this.uiEditSawOffsetY.save();
            st.uipSawTimeType = this.uipSawTimeType.save();
            st.uiEditSawHz = this.uiEditSawHz.save();
            st.uiEditSawPeriod = this.uiEditSawPeriod.save();

            st.uiEditSerpSigX = this.uiEditSerpSigX.save();
            st.uiEditSerpSigY = this.uiEditSerpSigY.save();
            st.uiEditSerpNumX = this.uiEditSerpNumX.save();
            st.uiEditSerpNumY = this.uiEditSerpNumY.save();
            st.uiEditSerpOffsetX = this.uiEditSerpOffsetX.save();
            st.uiEditSerpOffsetY = this.uiEditSerpOffsetY.save();
            st.uiEditSerpPeriod = this.uiEditSerpPeriod.save();

            st.uiEditDCx = this.uiEditDCx.save();
            st.uiEditDCy = this.uiEditDCy.save();

            st.uiEditRastorData = this.uiEditRastorData.save();
            st.uiEditRastorTransitTime = this.uiEditRastorTransitTime.save();

            st.uiEditFilterHz = this.uiEditFilterHz.save();
            st.uiEditConvKernelSig = this.uiEditConvKernelSig.save();

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
            
            this.uiButtonRecord = mic.ui.common.Button('cText', 'Record');
            this.uiEditRecordTime = mic.ui.common.Edit(...
                'cLabel', 'Time (ms)', ...
                'cType', 'd', ...
                'lShowLabel', false);
            
             % Default values
            this.uiEditRecordTime.setMax(2000);
            this.uiEditRecordTime.setMin(0);
            this.uiEditRecordTime.set(100);
            
            addlistener(this.uiButtonRecord, 'eChange', @this.onRecordClick);
            
        end
        
        function initWaveformSerpPanel(this)
            
            this.uiEditSerpSigX = mic.ui.common.Edit(...
                'cLabel', 'Sig X', ...
                'cType', 'd'); 
            this.uiEditSerpSigX.setMin(0);
            this.uiEditSerpSigX.setMax(1);
            this.uiEditSerpSigX.set(0.5);
            
            this.uiEditSerpNumX = mic.ui.common.Edit(...
                'cLabel', 'Num X (odd)', ...
                'cType', 'u8');
            this.uiEditSerpNumX.set(uint8(7));
            this.uiEditSerpNumX.setMin( uint8(4));
            this.uiEditSerpNumX.setMax( uint8(51));
            
            this.uiEditSerpOffsetX = mic.ui.common.Edit(...
                'cLabel', 'Offset X', ...
                'cType', 'd');
            this.uiEditSerpOffsetX.setMin(-1);
            this.uiEditSerpOffsetX.setMax(1);
            
            this.uiEditSerpSigY = mic.ui.common.Edit(...
                'cLabel', 'Sig Y', ...
                'cType', 'd'); 
            this.uiEditSerpSigY.setMin(0);
            this.uiEditSerpSigY.setMax(1);
            this.uiEditSerpSigY.set(0.5);            
            
            this.uiEditSerpNumY = mic.ui.common.Edit(...
                'cLabel', 'Num Y (odd)', ...
                'cType', 'u8');
            this.uiEditSerpNumY.set(uint8(7));
            this.uiEditSerpNumY.setMin( uint8(4));
            this.uiEditSerpNumY.setMax( uint8(51));
            
            this.uiEditSerpOffsetY = mic.ui.common.Edit(...
                'cLabel', 'Offset Y', ...
                'cType', 'd');
            this.uiEditSerpOffsetY.setMin(-1);
            this.uiEditSerpOffsetY.setMax(1);
            
            this.uiEditSerpPeriod = mic.ui.common.Edit(...
                'cLabel', 'Period (ms)', ...
                'cType', 'd');
            this.uiEditSerpPeriod.set(100); 
            this.uiEditSerpPeriod.setMin( 1);
            this.uiEditSerpPeriod.setMax( 10000);
            
        end
        
        function initWaveformSawPanel(this)
            
            this.uiEditSawSigX = mic.ui.common.Edit(...
                'cLabel', 'Sig X', ...
                'cType', 'd'); 
            this.uiEditSawSigX.setMin(0);
            this.uiEditSawSigX.setMax(1);
            this.uiEditSawSigX.set(0.5);
            
            this.uiEditSawPhaseX = mic.ui.common.Edit(...
                'cLabel', 'Phase X (pi)', ...
                'cType',  'd');
            this.uiEditSawPhaseX.setMin(-2);
            this.uiEditSawPhaseX.setMax(2);
                        
            this.uiEditSawOffsetX = mic.ui.common.Edit(...
                'cLabel', 'Offset X', ...
                'cType',  'd');
            this.uiEditSawOffsetX.setMin(-1);
            this.uiEditSawOffsetX.setMax(1);
            
            this.uiEditSawSigY = mic.ui.common.Edit(...
                'cLabel', 'Sig Y', ...
                'cType',  'd'); 
            this.uiEditSawSigY.setMin(0);
            this.uiEditSawSigY.setMax(1);
            this.uiEditSawSigY.set(0.5);            
            
            this.uiEditSawPhaseY = mic.ui.common.Edit(...
                'cLabel', 'Phase Y (pi)', ...
                'cType',  'd');
            this.uiEditSawPhaseY.setMin(-2);
            this.uiEditSawPhaseY.setMax(2);
                        
            this.uiEditSawOffsetY = mic.ui.common.Edit(...
                'cLabel', 'Offset Y', ...
                'cType',  'd');
            this.uiEditSawOffsetY.setMin(-1);
            this.uiEditSawOffsetY.setMax(1);
                                    
            this.uipSawTimeType = mic.ui.common.Popup(...
                'ceOptions', {'Period (ms)', 'Hz (avg)'}, ...
                'cLabel', 'Select Time Type');
            addlistener(this.uipSawTimeType, 'eChange', @this.onSawTimeTypeChange);            
            
            this.uiEditSawHz = mic.ui.common.Edit(...
                'cLabel', 'Hz (avg)', ...
                'cType',  'd');
            this.uiEditSawHz.setMin(0);
            this.uiEditSawHz.setMax(1000);
            this.uiEditSawHz.set(200);
            
            this.uiEditSawPeriod = mic.ui.common.Edit(...
                'cLabel', 'Period (ms)', ...
                'cType',  'd');
            this.uiEditSawPeriod.set(100); 
            this.uiEditSawPeriod.setMin(1);
            this.uiEditSawPeriod.setMax(10000);
            
        end
        
        function initWaveformRastorPanel(this)
            
             
            this.uiEditRastorData = mic.ui.common.Edit(...
                'cLabel', '(sig_x,sig_y,ms),(sig_x,sig_y,ms),...', ...
                'cType', 'c');
            this.uiEditRastorTransitTime =     mic.ui.common.Edit(...
                'cLabel', 'Transit Time (s)', ...
                'cType', 'd');
            
            this.uiEditRastorData.set('(0.3,0.3,5),(0.5,0.5,10),(0.4,0.4,4)');

           
            
        end
        
        function initWaveformDCPanel(this)
           
            this.uiEditDCx = mic.ui.common.Edit(...
                'cLabel', 'X offset', ...
                'cType', 'd');
            this.uiEditDCy = mic.ui.common.Edit(...
                'cLabel', 'Y offset', ...
                'cType', 'd');
            
            this.uiEditDCx.set(0.5);
            this.uiEditDCy.set(0.3);
        end
        
        function initWaveformMultiPanel(this)
            
            this.uiEditMultiPoleNum =          mic.ui.common.Edit(...
                'cLabel', 'Poles', ...
                'cType', 'u8');
            this.uiEditMultiSigMin =           mic.ui.common.Edit(...
                'cLabel', 'Sig min', ...
                'cType',  'd');
            this.uiEditMultiSigMax =           mic.ui.common.Edit(...
                'cLabel', 'Sig max', ...
                'cType',  'd');
            this.uiEditMultiCirclesPerPole =   mic.ui.common.Edit(...
                'cLabel', 'Circles/pole', ...
                'cType',  'u8');
            this.uiEditMultiDwell =            mic.ui.common.Edit(...
                'cLabel', 'Dwell', ...
                'cType',  'u8');
            this.uiEditMultiOffset =           mic.ui.common.Edit(...
                'cLabel', 'Pole Offset', ...
                'cType',  'd');
            this.uiEditMultiRot =              mic.ui.common.Edit(...
                'cLabel', 'Rot', ...
                'cType',  'd');
            this.uiEditMultiXOffset =          mic.ui.common.Edit(...
                'cLabel', 'X Global Offset', ...
                'cType',  'd');
            this.uiEditMultiYOffset =          mic.ui.common.Edit(...
                'cLabel', 'Y Global Offset', ...
                'cType',  'd');

            this.uiEditMultiTransitTime =      mic.ui.common.Edit(...
                'cLabel', 'Transit Frac', ...
                'cType',  'd');
            
            this.uipMultiTimeType =         mic.ui.common.Popup(...
                'ceOptions', {'Period (ms)', 'Hz (avg)'}, ...
                'cLabel', 'Select Time Type');
            addlistener(this.uipMultiTimeType, 'eChange', @this.onMultiTimeTypeChange);            
            
            this.uiEditMultiPeriod =           mic.ui.common.Edit(...
                'cLabel', 'Period (ms)', ...
                'cType',  'd');
            this.uiEditMultiHz =               mic.ui.common.Edit(...
                'cLabel', 'Hz (avg)', ...
                'cType',  'd');
            this.uitMultiFreqRange =        mic.ui.common.Text('cVal', '');
            
            % Defaults
            this.uiEditMultiPoleNum.set(uint8(4));
            this.uiEditMultiSigMin.set(0.2);
            this.uiEditMultiSigMax.set(0.3);
            this.uiEditMultiCirclesPerPole.set(uint8(2));
            this.uiEditMultiDwell.set(uint8(2));
            this.uiEditMultiOffset.set(0.6);
            this.uiEditMultiTransitTime.set(0.08);
            this.uiEditMultiHz.set(200);
            this.uiEditMultiPeriod.set(100);
            
            
        end
        
        function initWaveformGeneralPanel(this)
            
            % *********** General waveform panel
            
            this.uiEditFilterHz = mic.ui.common.Edit(...
                'cLabel', 'Filter Hz', ...
                'cType', 'd');
            this.uiEditFilterHz.set(400);
            this.uiEditFilterHz.setMin(1);
            this.uiEditFilterHz.setMax(10000);
            
            
            this.uiEditTimeStep = mic.ui.common.Edit(...
                'cLabel', 'Time step (us)', ...
                'cType', 'd');
            this.uiEditTimeStep.set(24);    % nPoint has a 24 us control loop
            
            
            this.uiEditConvKernelSig = mic.ui.common.Edit(...
                'cLabel', 'Conv. kernel sig', ...
                'cType', 'd');
            this.uiEditConvKernelSig.set(0.05);
            this.uiEditConvKernelSig.setMin(0.01);
            this.uiEditConvKernelSig.setMax(1);
            
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
            
            this.uiButtonPreview = mic.ui.common.Button(...
                'cText', 'Preview');
            this.uiButtonSave = mic.ui.common.Button(...
                'cText', 'Save');
            
            addlistener(this.uiButtonPreview, 'eChange', @this.onPreview);
            addlistener(this.uiButtonSave, 'eChange', @this.onSave);
            
        end
        
        function initSavedWaveformsPanel(this)
                        
            this.uildSaved = mic.ui.common.ListDir(...
                'cDir', this.cDirWaveforms, ...
                'cFilter', '*.mat', ...
                'fhOnChange', @this.onListChange, ...
                'lShowDelete', true, ...
                'lShowMove', false, ...
                'lShowLabel', false ...
            );    
        end
        
        
        function initLC400Panel(this)
            
            this.uiButtonLC400Connect = mic.ui.common.Button(...
                'cText', 'Connect', ...
                'fhOnClick', @this.onLC400Connect ...
            );
            
            this.uiButtonLC400Write = mic.ui.common.Button(...
                'cText', this.cLabelLC400Write, ...
                'fhOnClick', @this.onLC400Write ...
            );
            
            this.uiButtonLC400Start = mic.ui.common.Button(...
                'cText', this.cLabelLC400Start, ...
                'fhOnClick', @this.onLC400Start ...
            );
            
            this.uiButtonLC400Stop = mic.ui.common.Button(...
                'cText', this.cLabelLC400Stop, ...
                'fhOnClick', @this.onLC400Stop ...
            );
        
            this.uiButtonLC400Read = mic.ui.common.Button(...
                'cText', this.cLabelLC400Read, ...
                'fhOnClick', @this.onLC400Read ...
            );
        
            this.uiButtonLC400Record = mic.ui.common.Button(...
                'cText', this.cLabelLC400Record, ...
                'fhOnClick', @this.onLC400Record ...
            );
        
            this.uiEditLC400Time = mic.ui.common.Edit(...
                'cLabel', 'Read Time (ms)', ...
                'cType', 'd', ...
                'lShowLabel', true);
            
             % Default values
            this.uiEditLC400Time.setMax(2000);
            this.uiEditLC400Time.setMin(0);
            this.uiEditLC400Time.set(300);
        end
        
        
        function init(this)
        %INIT Initializes the PupilFill class
        %   PupilFill.init()
        %
        % See also PUPILFILL, BUILD, DELETE
            
            % 2012.04.16 C. Cork instructed me to use double for all raw
            % values
            
            
            this.initWaveformPanel();
            this.initLC400Panel();
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
        
       
        function onLC400Connect(this)
            
            this.lConnected = true;
            
            this.np = npoint.lc400.LC400(...
                'cConnection', npoint.lc400.LC400.cCONNECTION_TCPIP, ...
                'cTcpipHost', this.cLC400TcpipHost, ...
                'u16TcpipPort', 23 ...
            );
            this.np.init();
            this.np.connect();
            
            if this.uipPlotType.getSelectedIndex() == uint8(2)
                % nPoint Monitor
                if ishandle(this.hPlotRecordPanel)
                    set(this.hPlotRecordPanel, 'Visible', 'on');
                end
            end
             
            % Show "set waveform" button
            % Show "record" button
            % Show "set" button
            
            % this.uiButtonRecord.show();
            % this.uiEditRecordTime.show();
            
            this.uiButtonLC400Write.enable();
            this.uiButtonLC400Start.enable(); 
            this.uiButtonLC400Stop.enable();
            this.uiButtonLC400Read.enable()
            this.uiButtonLC400Record.enable()
            this.uiEditLC400Time.enable();
                        
        end
        
        function onLC400Disconnect(this)
            
            this.lConnected = false;
            
            if ishandle(this.hPlotRecordPanel)
                set(this.hPlotRecordPanel, 'Visible', 'off');
            end
               
            this.np.disconnect();
            % this.uiButtonRecord.hide();
            % this.uiEditRecordTime.hide();
            
            this.uiButtonLC400Write.disable();
            this.uiButtonLC400Start.disable();
            this.uiButtonLC400Stop.disable();
            this.uiButtonLC400Read.disable();
            this.uiButtonLC400Record.disable();
            this.uiEditLC400Time.disable();
        end
        
        
        
                
        function onMultiTimeTypeChange(this, src, evt)
            
                                                
            % Show the UIEdit based on popup type 
            switch this.uipMultiTimeType.getSelectedIndex()
                case uint8(1)
                    % Period
                    if this.uiEditMultiHz.isVisible()
                        this.uiEditMultiHz.hide();
                    end
                    
                    if ~this.uiEditMultiPeriod.isVisible()
                        this.uiEditMultiPeriod.show();
                    end
                    
                case uint8(2)
                    % Hz
                    if this.uiEditMultiPeriod.isVisible()
                        this.uiEditMultiPeriod.hide();
                    end
                    
                    if ~this.uiEditMultiHz.isVisible()
                        this.uiEditMultiHz.show();
                    end
            end    
        end

        
        function onSawTimeTypeChange(this, src, evt)
            
            
            % Show the UIEdit based on popup type
            
            switch this.uipSawTimeType.getSelectedIndex()
                case uint8(1)
                    % Period
                    if this.uiEditSawHz.isVisible()
                        this.uiEditSawHz.hide();
                    end
                    
                    if ~this.uiEditSawPeriod.isVisible()
                        this.uiEditSawPeriod.show();
                    end
                    
                case uint8(2)
                    % Hz
                    if this.uiEditSawPeriod.isVisible()
                        this.uiEditSawPeriod.hide();
                    end
                    
                    if ~this.uiEditSawHz.isVisible()
                        this.uiEditSawHz.show();
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
            
            % this.uiButtonRecord.isVisible()
            % this.uiEditRecordTime.isVisible();
            
            
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
                
                dVdt_sig_max = 2*pi*90*this.uiEditMultiSigMax.get()*this.dFreqMin;
                dVdt_sig_min = 2*pi*90*this.uiEditMultiSigMin.get()*this.dFreqMax;
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
                        double(this.uiEditMultiPoleNum.get()), ...
                        this.uiEditMultiSigMin.get(), ...
                        this.uiEditMultiSigMax.get(), ...
                        double(this.uiEditMultiCirclesPerPole.get()), ...
                        double(this.uiEditMultiDwell.get()), ...
                        this.uiEditMultiTransitTime.get(), ...
                        this.uiEditMultiOffset.get(), ...
                        this.uiEditMultiRot.get(), ...
                        this.uiEditMultiXOffset.get(), ...
                        this.uiEditMultiYOffset.get(), ...
                        this.uiEditMultiHz.get(), ...
                        1, ...
                        this.uiEditTimeStep.get()*1e-6, ...         
                        this.uiEditFilterHz.get(), ... 
                        this.uiEditMultiPeriod.get()/1000, ...
                        lPeriod ...
                        );
                    
                case uint8(2)
                    % DC offset
                    [this.dVx, this.dVy, this.dVxCorrected, this.dVyCorrected, this.dTime] = ScannerCore.getDC( ...
                        this.uiEditDCx.get(), ...
                        this.uiEditDCy.get(),...
                        1, ...
                        this.uiEditTimeStep.get()*1e-6 ...         
                        );
                    
                case uint8(3)
                    % Rastor
                    [this.dVx, this.dVy, this.dVxCorrected, this.dVyCorrected, this.dTime] = ScannerCore.getRastor( ...
                        this.uiEditRastorData.get(), ...
                        this.uiEditRastorTransitTime.get(), ...
                        this.uiEditTimeStep.get(), ... % send in us, not s
                        1, ...
                        this.uiEditFilterHz.get() ...
                        );
                    
                case uint8(4)
                    % Saw
                    
                    if this.uipSawTimeType.getSelectedIndex() == uint8(1)
                        % Period (ms)
                        dHz = 1/(this.uiEditSawPeriod.get()/1e3);
                    else
                        % Hz
                        dHz = this.uiEditSawHz.get();
                    end
                    
                    st = ScannerCore.getSaw( ...
                        this.uiEditSawSigX.get(), ...
                        this.uiEditSawPhaseX.get(), ...
                        this.uiEditSawOffsetX.get(), ...
                        this.uiEditSawSigY.get(), ...
                        this.uiEditSawPhaseY.get(), ...
                        this.uiEditSawOffsetY.get(), ...
                        1, ...
                        dHz, ...
                        this.uiEditFilterHz.get(), ...
                        this.uiEditTimeStep.get()*1e-6 ...
                        );
                    
                    this.dVx = st.dX;
                    this.dVy = st.dY;
                    this.dTime = st.dT;
                    
                case uint8(5)
                    % Serpentine
                                        
                    st = ScannerCore.getSerpentine2( ...
                        this.uiEditSerpSigX.get(), ...
                        this.uiEditSerpSigY.get(), ...
                        this.uiEditSerpNumX.get(), ...
                        this.uiEditSerpNumY.get(), ...
                        this.uiEditSerpOffsetX.get(), ...
                        this.uiEditSerpOffsetY.get(), ...
                        this.uiEditSerpPeriod.get()*1e-3, ...
                        1, ...
                        this.uiEditFilterHz.get(), ...
                        this.uiEditTimeStep.get()*1e-6 ...
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
                xlim(this.hPreviewAxis2D, [-1 1])
                ylim(this.hPreviewAxis2D, [-1 1])

                % set(this.hFigure, 'CurrentAxes', this.hPreviewAxis1D)
                plot(...
                    this.hPreviewAxis1D, ...
                    this.dTime*1000, this.dVx, 'r', ...
                    this.dTime*1000, this.dVy,'b' ...
                );
                xlabel(this.hPreviewAxis1D, 'Time [ms]')
                ylabel(this.hPreviewAxis1D, 'Amplitude')
                legend(this.hPreviewAxis1D, 'ch1 (x)','ch2 (y)')
                xlim(this.hPreviewAxis1D, [0 max(this.dTime*1000)])
                ylim(this.hPreviewAxis1D, [-1 1])
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
                xlim(this.hMonitorAxis2D, [-1 1])
                ylim(this.hMonitorAxis2D, [-1 1])
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
                ylabel(this.hMonitorAxis1D, 'Amplitude')
                legend(this.hMonitorAxis1D, 'ch1 (x) sensor','ch2 (y)sensor', 'ch1 (x) command', 'ch2 (y) command');
                xlim(this.hMonitorAxis1D, [0 max(this.dRTime*1000)])
                ylim(this.hMonitorAxis1D, [-1 1])

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
                                this.uiEditMultiPoleNum.get(), ...
                                this.uiEditMultiOffset.get()*100, ...
                                this.uiEditMultiRot.get(), ...
                                this.uiEditMultiSigMin.get()*100, ...
                                this.uiEditMultiSigMax.get()*100, ...
                                this.uiEditMultiCirclesPerPole.get(), ...
                                this.uiEditMultiDwell.get(), ...
                                this.uiEditMultiXOffset.get()*100, ...
                                this.uiEditMultiYOffset.get()*100, ...
                                this.uiEditMultiPeriod.get(), ...
                                this.uiEditFilterHz.get(), ...
                                this.uiEditTimeStep.get() ...
                            );
                        case uint8(2)
                            % Freq
                            cName = sprintf('%1.0fPole_off%1.0f_rot%1.0f_min%1.0f_max%1.0f_num%1.0f_dwell%1.0f_xoff%1.0f_yoff%1.0f_hz%1.0f_filthz%1.0f_dt%1.0f',...
                                this.uiEditMultiPoleNum.get(), ...
                                this.uiEditMultiOffset.get()*100, ...
                                this.uiEditMultiRot.get(), ...
                                this.uiEditMultiSigMin.get()*100, ...
                                this.uiEditMultiSigMax.get()*100, ...
                                this.uiEditMultiCirclesPerPole.get(), ...
                                this.uiEditMultiDwell.get(), ...
                                this.uiEditMultiXOffset.get()*100, ...
                                this.uiEditMultiYOffset.get()*100, ...
                                this.uiEditMultiHz.get(), ...
                                this.uiEditFilterHz.get(), ...
                                this.uiEditTimeStep.get() ...
                            ); 
                    end
                    
                case uint8(2)
                    
                    % DC offset
                    cName = sprintf('DC_x%1.0f_y%1.0f_dt%1.0f', ...
                        this.uiEditDCx.get()*100, ...
                        this.uiEditDCy.get()*100, ...
                        this.uiEditTimeStep.get() ...
                    );
                
                case uint8(3)
                    
                    % Rastor
                    cName = sprintf('Rastor_%s_ramp%1.0f_dt%1.0f', ...
                        this.uiEditRastorData.get(), ...
                        this.uiEditRastorTransitTime.get(), ...
                        this.uiEditTimeStep.get() ...
                    );
                
                case uint8(4)
                    % Saw
                    switch this.uipSawTimeType.getSelectedIndex()
                        case uint8(1)
                            % Period
                            cName = sprintf('Saw_sigx%1.0f_phasex%1.0f_offx%1.0f_sigy%1.0f_phasey%1.0f_offy%1.0f_scale%1.0f_per%1.0f_filthz%1.0f_dt%1.0f',...
                                this.uiEditSawSigX.get()*100, ...
                                this.uiEditSawPhaseX.get(), ...
                                this.uiEditSawOffsetX.get()*100, ...
                                this.uiEditSawSigY.get()*100, ...
                                this.uiEditSawPhaseY.get(), ...
                                this.uiEditSawOffsetY.get()*100, ...
                                1, ...
                                this.uiEditSawPeriod.get(), ...
                                this.uiEditFilterHz.get(), ...
                                this.uiEditTimeStep.get() ...
                            );                           
                    
                        
                        case uint8(2)
                            % Period
                            cName = sprintf('Saw_sigx%1.0f_phasex%1.0f_offx%1.0f_sigy%1.0f_phasey%1.0f_offy%1.0f_scale%1.0f_hz%1.0f_filthz%1.0f_dt%1.0f',...
                                this.uiEditSawSigX.get()*100, ...
                                this.uiEditSawPhaseX.get(), ...
                                this.uiEditSawOffsetX.get()*100, ...
                                this.uiEditSawSigY.get()*100, ...
                                this.uiEditSawPhaseY.get(), ...
                                this.uiEditSawOffsetY.get()*100, ...
                                1, ...
                                this.uiEditSawHz.get(), ...
                                this.uiEditFilterHz.get(), ...
                                this.uiEditTimeStep.get() ...
                            );   
                    end
                    
                case uint8(5)
                    
                    % Serpentine
                    cName = sprintf('Serpentine_sigx%1.0f_numx%1.0f_offx%1.0f_sigy%1.0f_numy%1.0f_offy%1.0f_scale%1.0f_per%1.0f_filthz%1.0f_dt%1.0f',...
                        this.uiEditSerpSigX.get()*100, ...
                        this.uiEditSerpNumX.get(), ...
                        this.uiEditSerpOffsetX.get()*100, ...
                        this.uiEditSerpSigY.get()*100, ...
                        this.uiEditSerpNumY.get(), ...
                        this.uiEditSerpOffsetY.get()*100, ...
                        1, ...
                        this.uiEditSerpPeriod.get(), ...
                        this.uiEditFilterHz.get(), ...
                        this.uiEditTimeStep.get() ...
                    );  
                     
            end
            
                        
            % NEW 2017.02.02
            % Allow the user to change the filename, if desired but do not
            % allow them to select a different directory.
            
            cePrompt = {'Save As:'};
            cTitle = '';
            dLines = [1 130];
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
                                                
            s = this.save();
            save(fullfile(this.uildSaved.getDir(), cFileName), 's');
            
            % Update the mic.ui.common.ListDir
            this.uildSaved.refresh();
            
            %{
            % If the name is not already on the list, append it
            if isempty(strmatch(cFileName, this.uildSaved.getOptions(), 'exact'))
                this.uildSaved.append(cFileName);
            end
            
            notify(this, 'eNew');
            %}
            
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
            this.uiButtonPreview.build(this.hWaveformPanel, dLeftCol1, dTop, 190, this.dHeightEdit);
            dTop = dTop + 30;

            this.uiButtonSave.build(this.hWaveformPanel, dLeftCol1, dTop, 190, this.dHeightEdit);
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

            this.uiEditFilterHz.build(this.hWaveformGeneralPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);            
            dTop = dTop + dSep;

            this.uiEditTimeStep.build(this.hWaveformGeneralPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditConvKernelSig.build(this.hWaveformGeneralPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);

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

            this.uiEditMultiPoleNum.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditMultiTransitTime.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uiEditMultiSigMin.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditMultiSigMax.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            this.uiEditMultiCirclesPerPole.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditMultiDwell.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            this.uiEditMultiOffset.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditMultiRot.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            this.uiEditMultiXOffset.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditMultiYOffset.build(this.hWaveformMultiPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);
            dTop = dTop + dSep;

            % Popup (to select type)
            this.uipMultiTimeType.build(this.hWaveformMultiPanel, dLeftCol1, dTop, 170, this.dHeightEdit);
            dTop = dTop + 45;

            this.uiEditMultiPeriod.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditMultiHz.build(this.hWaveformMultiPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);                

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


            this.uiEditDCx.build(this.hWaveformDCPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);            
            this.uiEditDCy.build(this.hWaveformDCPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);

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


            this.uiEditRastorData.build(this.hWaveformRastorPanel, dLeftCol1, dTop, 170, this.dHeightEdit); 
            dTop = dTop + dSep;     

            this.uiEditRastorTransitTime.build(this.hWaveformRastorPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);

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

            this.uiEditSawSigX.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditSawSigY.build(this.hWaveformSawPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uiEditSawPhaseX.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditSawPhaseY.build(this.hWaveformSawPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uiEditSawOffsetX.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditSawOffsetY.build(this.hWaveformSawPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uipSawTimeType.build(this.hWaveformSawPanel, dLeftCol1, dTop, 170, this.dHeightEdit);

            dTop = dTop + 45;

            this.uiEditSawPeriod.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditSawHz.build(this.hWaveformSawPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);                
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

            this.uiEditSerpSigX.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditSerpSigY.build(this.hWaveformSerpPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uiEditSerpNumX.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditSerpNumY.build(this.hWaveformSerpPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uiEditSerpOffsetX.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);
            this.uiEditSerpOffsetY.build(this.hWaveformSerpPanel, dLeftCol2, dTop, dEditWidth, this.dHeightEdit);            

            dTop = dTop + dSep;

            this.uiEditSerpPeriod.build(this.hWaveformSerpPanel, dLeftCol1, dTop, dEditWidth, this.dHeightEdit);

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
                'Position', mic.Utils.lt2lb([230 this.dYOffset dWidth 290], this.hFigure) ...
            );
            drawnow;
            
            dButtonWidth = 100;
            this.uildSaved.build(...
                hPanel, ...
                10, ...
                20, ...
                dWidth-20, ...
                200 ...
            );
            
        end
        
        
        function buildLC400Panel(this)
            
            if ~ishandle(this.hFigure)
                return;
            end
            
            dWidth = this.dWidthSavedWaveformsPanel;

            hPanel = uipanel(...
                'Parent', this.hFigure,...
                'Units', 'pixels',...
                'Title', 'LC400 Comm',...
                'Clipping', 'on',...
                'Position', mic.Utils.lt2lb([230 660 dWidth 50], this.hFigure) ...
            );
            drawnow;
            
            dButtonWidth = 100;
            dTop = 15;
            dLeft = 10;
            
            
            this.uiButtonLC400Connect.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
        
            dLeft = dLeft + dButtonWidth + 10;
            
            this.uiButtonLC400Write.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
        
            dLeft = dLeft + dButtonWidth + 10;
            
            this.uiButtonLC400Start.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            
            this.uiButtonLC400Stop.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            
            this.uiButtonLC400Read.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            
            this.uiButtonLC400Record.build(hPanel, ...
                dLeft, ... % l
                dTop, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            this.uiEditLC400Time.build(hPanel, ...
                dLeft, ... % l
                dTop - 5, ... % t
                dButtonWidth, ... % w
                this.dHeightEdit - 5 ... % h
            );
            dLeft = dLeft + dButtonWidth + 10;
            
            this.uiButtonLC400Write.setTooltip('Write the waveform data to the LC400 controller.  This can take several seconds');
            this.uiButtonLC400Start.setTooltip('Start scanning');
            this.uiButtonLC400Stop.setTooltip('Stop scanning');
            this.uiButtonLC400Read.setTooltip('Read the LC400 wavetables (from memory) and plot');
            this.uiButtonLC400Record.setTooltip('Record the command + servo values and plot');
            this.uiEditLC400Time.setTooltip('The time window for read / record commands');
            
            this.uiButtonLC400Write.disable();
            this.uiButtonLC400Start.disable();
            this.uiButtonLC400Stop.disable();
            this.uiButtonLC400Read.disable();
            this.uiButtonLC400Record.disable();
            this.uiEditLC400Time.disable();
            
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
                'Position', mic.Utils.lt2lb([230 10 this.dWidthPlotPanel 300], this.hFigure) ...
            );
            drawnow; 

            % Popup (to select type)
            % this.uipPlotType.build(this.hPlotPanel, 10, 20, 190, this.dHeightEdit);

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
                'Position', mic.Utils.lt2lb([2 20 990-6 280], this.hPlotPanel) ...
            );
            drawnow;            

            this.hPreviewAxis1D = axes(...
                'Parent', this.hPlotPreviewPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([dPad + 15 5 dSize*2 - 15 dSize], this.hPlotPreviewPanel),...
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
                'Position', mic.Utils.lt2lb([2 20 990-6 280], this.hPlotPanel) ...
            );
            drawnow;


            this.hMonitorAxis1D = axes(...
                'Parent', this.hPlotMonitorPanel,...
                'Units', 'pixels',...
                'Position',mic.Utils.lt2lb([dPad + 15 5 dSize*2 - 15 dSize], this.hPlotMonitorPanel),...
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
            
            return
            
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
            this.uiButtonRecord.build(this.hPlotRecordPanel, 0, 0, 100, this.dHeightEdit);

            % Time
            this.uiEditRecordTime.build(this.hPlotRecordPanel, 105, 0, 40, this.dHeightEdit);

            % "ms"
            uitLabel = mic.ui.common.Text('cVal', 'ms');
            uitLabel.build(this.hPlotRecordPanel, 150, 8, 30, this.dHeightEdit);

            % this.uiButtonRecord.hide();
            % this.uiEditRecordTime.hide();
            
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

            dVoltsAtEdge = this.dPupilScale*1;

            
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
                xlim(this.hSerpentineWaveformAxes, [-1 1]*dMmPerVolts)
                ylim(this.hSerpentineWaveformAxes, [-1 1]*dMmPerVolts)
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
                
                ddVxdT = derivative(this.dVx, this.uiEditTimeStep.get()*1e-6);
                ddVydT = derivative(this.dVy, this.uiEditTimeStep.get()*1e-6);
                
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
        
        
        function onListChange(this, src, evt)
            
            this.msg('onListChange()');
            
            % Make sure preview is showing
            
            if this.uipPlotType.getSelectedIndex() ~= uint8(1)
                this.uipPlotType.setSelectedIndex(uint8(1));
            end
            
            
            % Load the .mat file
            ceSelected = this.uildSaved.get();
            
            if ~isempty(ceSelected)
                
                % ceSelected is a cell of selected options - use the first
                % one.  Populates a structure named s in the local
                % workspace of this method
                
                cFile = fullfile( ...
                    this.uildSaved.getDir(), ...
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
            
            % Compute number of samples from uiEditRecordTime
            
            dSeconds = this.uiEditRecordTime.get() * 1e-3; % s
            dClockPeriod = 24e-6;
            u32Num = uint32(round(dSeconds / dClockPeriod));
            
            cMsg = sprintf('Recording %1.0f samples from LC400', u32Num);
            this.msg(cMsg);
            
            dResult = this.np.record(u32Num);
            
            % Unpack
            
            dTime = double(1 : u32Num) * dClockPeriod;
            
            
            this.dRVxCommand =      dResult(1, :) * 1; % * cos(this.dThetaX * pi / 180);
            this.dRVxSensor =       dResult(2, :) * 1; % * cos(this.dThetaX * pi / 180);
            this.dRVyCommand =      dResult(3, :) * 1; % * cos(this.dThetaY * pi / 180);
            this.dRVySensor =       dResult(4, :) * 1; % * cos(this.dThetaY * pi / 180);
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
            dVxRel = this.dVx; % values in [-1 : 1]
            dVyRel = this.dVy; % values in [-1 : 1]
            
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
        
        function onLC400Write(this, src, evt)
                                    
            [i32X, i32Y] = this.get20BitWaveforms();
            
            this.uiButtonLC400Write.setText('Writing ...');
            drawnow;
            
            this.setWavetable(i32X, i32Y)  
            this.uiButtonLC400Write.setText(this.cLabelLC400Write)
            
            h = msgbox( ...
                'The waveform has been written.  Click "Start Scan" to start.', ...
                'Success!', ...
                'help', ...
                'modal' ...
            );            
        end
        
        
        function onLC400Stop(this, src, evt)
            
            % Stop
            this.np.setTwoWavetablesActive(false);
            
            % Disable
            this.np.setWavetableEnable(uint8(1), false);
            this.np.setWavetableEnable(uint8(2), false);
            
        end
        
        
        function onLC400Read(this, src, evt)
                        
            u32Samples = uint32(this.uiEditLC400Time.get() / 2000 * 83333);
            
            cLabel = sprintf('Reading %u ...', u32Samples);
            this.uiButtonLC400Read.setText(cLabel);
            drawnow;
            
            d = this.np.getWavetables(u32Samples);
            this.uiButtonLC400Read.setText(this.cLabelLC400Read);

            % Change plot type to preview
            this.uipPlotType.setSelectedIndex(uint8(1));
            
            this.dVx = d(1, :) / 2^19;
            this.dVy = d(2, :) / 2^19;
            this.dTime = 24e-6 * double([1 : u32Samples]);
            
            this.updateAxes();
            this.updatePupilImg('preview');
            
            %{
            figure
            hold on
            plot(d(1, :), 'r');
            plot(d(2, :), 'b');
            legend({'ch 1', 'ch 2'});
            ylim([-2^19 2^19])
            %}
            
        end
        
        
        function onLC400Record(this, src, evt)
                        
            u32Samples = uint32(this.uiEditLC400Time.get() / 2000 * 83333);
            
            cMsg = sprintf('Rec. %u ...', u32Samples);
            this.uiButtonLC400Record.setText(cMsg);
            drawnow;
            
            dResult = this.np.record(u32Samples);
            
            this.uiButtonLC400Record.setText(this.cLabelLC400Record);

            % Unpack
            
            dClockPeriod = 24e-6;
            dTime = double(1 : u32Samples) * dClockPeriod;
            
            this.dRVxCommand =      dResult(1, :) * 1; % * cos(this.dThetaX * pi / 180);
            this.dRVxSensor =       dResult(2, :) * 1; % * cos(this.dThetaX * pi / 180);
            this.dRVyCommand =      dResult(3, :) * 1; % * cos(this.dThetaY * pi / 180);
            this.dRVySensor =       dResult(4, :) * 1; % * cos(this.dThetaY * pi / 180);
            this.dRTime =           dTime;
                
            % Change plot type to the monitor
            this.uipPlotType.setSelectedIndex(uint8(2));
            
            % Update the axes
            this.updateRecordAxes();
            this.updatePupilImg('preview');
            
        end
        
        function onLC400Start(this, src, evt)
            
            % Enable
            this.np.setWavetableEnable(uint8(1), true);
            this.np.setWavetableEnable(uint8(2), true);
            
            % Start
            this.np.setTwoWavetablesActive(true);
            
        end
        
        
        
        % @return {double m x n} return a matrix that represents the
        % intensity distribution of the scan kernel (beam intensity). 
        
        function [dX, dY, dKernelInt] = getKernel(this)
            
            dKernelSig = 0.02; % Using uiEdit now.
            
            dKernelSigPixels = this.uiEditConvKernelSig.get()*this.dPupilPixels/this.dPupilScale/2;
            dKernelPixels = floor(dKernelSigPixels*2*4); % the extra factor of 2 is for oversize padding
            [dX, dY] = this.getXY(dKernelPixels, dKernelPixels, dKernelPixels, dKernelPixels);
            dKernelInt = this.gauss(dX, dKernelSigPixels, dY, dKernelSigPixels);
                        
            [dX, dY] = this.getXY(this.dPreviewPixels, this.dPreviewPixels, 2*this.dPreviewScale, 2*this.dPreviewScale);
            dKernelInt = this.gauss(dX, this.uiEditConvKernelSig.get(), dY, this.uiEditConvKernelSig.get());
            
            
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
                        this.uiEditConvKernelSig.get(), ...
                        dY - dY0(n), ...
                        this.uiEditConvKernelSig.get());
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
            
            %{
            figure
            h = plot(i32Ch1, i32Ch2);
            xlim([-2^19 2^19])
            ylim([-2^19 2^19])
            %}
            
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
        
        
        