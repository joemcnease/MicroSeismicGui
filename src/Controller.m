classdef Controller < handle

  properties

    fig

    miniSeedData
    pickData

    pickListener

    timeSlider
    staltaToggleButton
    dataFolderText
    eventListBox
    channelTypePopup
    stationListBox
    pickListBox
    pickDeleteButton
    pickPhaseBox
    spectrumToggleButton
    polynomialDetrendCheckbox
    polynomialDetrendPopup
    bandpassCheckbox
    bandpassStart
    bandpassEnd
    hodogramToggleButton
    zoomToggleButton
    autoSaveToggleButton
    savePicksButton
    normalizeWaveformsToggleButton
    plotEventPicksToggleButton
    hodogramTimeRangeStart
    hodogramTimeRangeEnd
    hodogramTimeRangeSubmitButton

    zoomWindowWidth = 5

    spectrumView
    hodogramView

  end

  methods

    function obj = Controller(miniSeedData,pickData,spectrumView,hodogramView,fig)

      obj.fig = fig;
      obj.miniSeedData = miniSeedData;
      obj.pickData = pickData;

      obj.spectrumView = spectrumView;
      obj.hodogramView = hodogramView;

      obj.pickListener = addlistener(obj.pickData,'pickDataChanged',@obj.updatePickList);

      obj.setup;

    end

  end

  methods (Access = protected)

    function setup(obj)

      % File dropdown
      m = uimenu('Label','&File');
      uimenu(m,'Label','New','Callback','MicroSeismic');
      uimenu(m,'Label','New Figure','Callback','figure');
      uimenu(m,'Label','Load','Callback',@obj.onLoadFile);
      uimenu(m,'Label','Quit','Callback','close',...
               'Separator','on','Accelerator','Q');
           
      % Edit dropdown
      m = uimenu('Label','&Edit');
      uimenu(m,'Label','&Undo');
      uimenu(m,'Label','&Redo');
      uimenu(m,'Label','&Find','Separator','on');
      uimenu(m,'Label','&Replace');
      
      % Help dropdown
      m = uimenu('Label','&Help');
      uimenu(m,'Label','About','Separator','on','Callback',@obj.onAbout);

      
      % Zoomed time stepping slider
      obj.timeSlider = uicontrol(obj.fig,...
        'Style','slider',...
        'Units','normalized',...
        'Position',[0.27 0.25 0.715 0.025],...
        'Callback',@obj.timeSliderChangedCallback...
      );
    
    
      % Picking tab
      uiPanelLeft = uitabgroup(obj.fig,'Position',[0.0075 0.01 0.21 0.98]);
      uiPickingTab = uitab(uiPanelLeft,'Title','Pick');
    

      obj.dataFolderText = uicontrol(uiPickingTab,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.01 0.88 0.9 0.1],...
        'String','Folder: ','HorizontalAlignment','left', ...
        'FontSize',10 ...
      );
      uicontrol(uiPickingTab,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.01 0.84 0.9 0.1],...
        'String','Events: ','HorizontalAlignment','left', ...
        'FontSize',10 ...
      );
      obj.eventListBox = uicontrol(uiPickingTab,...
        'Style','listbox',...
        'Units','normalized',...
        'Position',[0.01 0.77 0.98 0.15],...
        'Callback',@obj.onEventList...
      );
      uicontrol(uiPickingTab,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.01 0.65 0.9 0.1],...
        'String','Stations: ','HorizontalAlignment','left', ...
        'FontSize',10 ...
      );
      obj.stationListBox = uicontrol(uiPickingTab,...
        'Style','listbox',...
        'Units','normalized',...
        'Position',[0.01 0.58 0.98 0.15],...
        'Callback',@obj.onStationList...
      );
      uicontrol(uiPickingTab,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.01 0.46 0.9 0.1],...
        'String','Channel: ','HorizontalAlignment','left', ...
        'FontSize',10 ...
      );
      obj.channelTypePopup = uicontrol(uiPickingTab,...
        'Style','popupmenu',...
        'Units','normalized',...
        'Position',[0.22 0.5125 0.45 0.05],...
        'String',{'EHZ','EHN','EHE'},...
        'Callback',@obj.onChannelType...
      );
      uicontrol(uiPickingTab,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.01 0.41 0.9 0.1],...
        'String','Picks: ','HorizontalAlignment','left', ...
        'FontSize',10 ...
      );
      obj.pickListBox = uicontrol(uiPickingTab,...
        'Style','listbox',...
        'Units','normalized',...
        'Position',[0.01 0.34 0.98 0.15],...
        'Callback',@obj.onPickList...
      );
      obj.pickDeleteButton = uicontrol(uiPickingTab,...
        'Units','normalized',...
        'Position',[0.6225 0.30 0.37 0.03],...
        'String','Delete','Callback',@obj.onPickDelete...
      );
      uicontrol(uiPickingTab,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.01 0.18 0.9 0.1],...
        'String','Phase: ','HorizontalAlignment','left', ...
        'FontSize',10 ...
      );
      obj.pickPhaseBox = uicontrol(uiPickingTab,...
        'Style','listbox',...
        'Units','normalized',...
        'Position',[0.01 0.21 0.98 0.05],...
        'Callback',@obj.onPickPhase,...
        'String',{'P','S'}...
      );
      obj.zoomToggleButton = uicontrol(uiPickingTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.16 0.975 0.04],...
        'Value',0,...
        'String','Zoom Mode',...
        'Callback',@obj.onZoomToggle...
      );    
      obj.plotEventPicksToggleButton = uicontrol(uiPickingTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.5 0.16 0.475 0.04],...
        'Value',0,...
        'String','Display Picks on Event Plot',...
        'Callback',@obj.onPlotEventPicksToggle...
      );    
      obj.staltaToggleButton = uicontrol(uiPickingTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.125 0.975 0.04],...
        'Value',0,...
        'String','Compute STA/LTA',...
        'Callback',@obj.onStaLtaToggle...
      );
      obj.normalizeWaveformsToggleButton = uicontrol(uiPickingTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.092 0.975 0.04],...
        'Value',0,...
        'String','Normalize Waveforms',...
        'Callback',@obj.onNormalizeWaveformsToggle...
      );    
      obj.autoSaveToggleButton = uicontrol(uiPickingTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.06 0.975 0.04],...
        'Value',0,...
        'String','Autosave Picks',...
        'Callback',@obj.onAutoSaveToggle...
      );    
      obj.savePicksButton = uicontrol(uiPickingTab,...
        'Style','pushbutton',...
        'Units','normalized',...
        'Position',[0.01 0.01 0.975 0.04],...
        'String','SAVE PICKS',...
        'Callback',@obj.onSavePicks...
      );    
    
      
      % Filtering tab
      uiFilterTab = uitab(uiPanelLeft,'Title','Filter');
    
      obj.spectrumToggleButton = uicontrol(uiFilterTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.95 0.975 0.05],...
        'Value',0,...
        'String','Plot Spectrum',...
        'Callback',@obj.onSpectrumToggle...
      ); 
      obj.polynomialDetrendCheckbox = uicontrol(uiFilterTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.9125 0.975 0.05],...
        'Value',0,...
        'String','Polynomial Detrend',...
        'Callback',@obj.onPolynomialDetrendCheck...
      );
      obj.polynomialDetrendPopup = uicontrol(uiFilterTab,...
        'Style','popupmenu',...
        'Units','normalized',...
        'Position',[0.6 0.9 0.26 0.05],...
        'String',{'0','1','2','3'},...
        'Callback',@obj.onPolynomialDetrendPopup...
      );
      obj.bandpassCheckbox = uicontrol(uiFilterTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.88 0.975 0.04],...
        'Value',0,...
        'String','Bandpass Filter',...
        'Callback',@obj.onBandpass...
      );
      obj.bandpassStart = uicontrol(uiFilterTab,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.01 0.85 0.4 0.03],...
        'String','10'...
      );
      obj.bandpassEnd = uicontrol(uiFilterTab,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.45 0.85 0.4 0.03],...
        'String','30'...
      );
    
    
      % Polarization analysis tab
      uiPolarizationTab = uitab(uiPanelLeft,'Title','Polarization');
    
      obj.hodogramToggleButton = uicontrol(uiPolarizationTab,...
        'Style','checkbox',...
        'Units','normalized',...
        'Position',[0.01 0.95 0.975 0.05],...
        'Value',0,...
        'String','Plot Hodogram',...
        'Callback',@obj.onHodogramToggle...
      );

      uicontrol(uiPolarizationTab,...
        'Style','text',...
        'Units','normalized',...
        'Position',[0.01 0.85 0.9 0.1],...
        'String','Time Window: ','HorizontalAlignment','left', ...
        'FontSize',10 ...
      );
      obj.hodogramTimeRangeStart = uicontrol(uiPolarizationTab,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.01 0.9 0.4 0.03],...
        'String','10'...
      );
      obj.hodogramTimeRangeEnd = uicontrol(uiPolarizationTab,...
        'Style','edit',...
        'Units','normalized',...
        'Position',[0.45 0.9 0.4 0.03],...
        'String','30'...
      );
      obj.hodogramTimeRangeSubmitButton = uicontrol(uiPolarizationTab,...
        'Style','pushbutton',...
        'Units','normalized',...
        'Position',[0.01 0.87 0.848 0.03],...
        'String','Update Time Window',...
        'Callback',@obj.onHodogramTimeRangeSubmit...
      );

    end

  end

  methods (Access = private)

    function load(obj,folder)

        obj.miniSeedData.load(folder);

        obj.dataFolderText.String = ['Folder: ' ...
                                     obj.miniSeedData.getDataPath()];

        % Update slider
        tlim = obj.miniSeedData.getEventTimeLimits();
        obj.timeSlider.Min = tlim(1);
        obj.timeSlider.Max = tlim(2);
          
        tdel = obj.miniSeedData.getEventTimeDeltaT();
        obj.timeSlider.SliderStep = [tdel tdel*10];

        % Update event list box
        obj.eventListBox.String = obj.miniSeedData.getEventList();

        % Update station list box
        obj.stationListBox.String = obj.miniSeedData.getStationList();

        % Update pick list box
        obj.updatePickList();

        % ...
    end

    function updateStationList(obj)

      obj.stationListBox.String = obj.miniSeedData.getStationList();

    end

    function updatePickList(obj,~,~)

      obj.miniSeedData.ensureStationIdxInBounds();

      eventIdx = obj.miniSeedData.getEventIdx();
      stationIdx = obj.miniSeedData.getStationIdx();

      if obj.stationListBox.Value > length(obj.stationListBox.String)
        obj.stationListBox.Value = stationIdx;
      end

      obj.pickData.ensurePickIdxInBounds();

      pickIdx = obj.pickData.getPickIdx();

      if obj.pickListBox.Value > pickIdx
       obj.pickListBox.Value = pickIdx;
      end

      elst = obj.miniSeedData.getWaveforms();
      enam = {elst.name};
      eval = enam{stationIdx};
      eval = strjoin({obj.eventListBox.String{eventIdx},eval},'.');
      obj.pickListBox.String = obj.pickData.getPickList(eval);

      if obj.autoSaveToggleButton.Value == 1
        obj.pickData.savePicks(false);
      end

    end

    function onLoadFile(obj,~,~)

      obj.miniSeedData.clear();

      folder = uigetdir();
      if isequal(folder,0)
        % msgbox("No file selected!",'Warning','warn','modal');
      else
        obj.load(folder);
      end

    end

    function onAbout(obj,~,~)

      msg = 'This is an application for loading and analyzing microseismic data.';
      msgbox(msg,'About','help','modal');

    end

    function onStaLtaToggle(obj,~,~)

      if obj.staltaToggleButton.Value == 1
        obj.miniSeedData.setPlotStaLta(true);
      else
        obj.miniSeedData.setPlotStaLta(false);
      end

    end

    function onZoomToggle(obj,~,~)
      
      if obj.zoomToggleButton.Value == 1
        tidx = obj.timeSlider.Value;
        obj.miniSeedData.setEventTimeLimits([tidx tidx+obj.zoomWindowWidth]);
      else
        obj.miniSeedData.resetEventTimeLimits();
      end

    end

    function timeSliderChangedCallback(obj,~,~)

      if obj.zoomToggleButton.Value == 1
        tidx = obj.timeSlider.Value;
        obj.miniSeedData.setEventTimeLimits([tidx tidx+obj.zoomWindowWidth]);
      else
        obj.miniSeedData.resetEventTimeLimits();
      end

    end

    function onEventList(obj,~,~)

      obj.miniSeedData.setEventIdx(obj.eventListBox.Value);
      obj.miniSeedData.resetEventTimeLimits();
      obj.zoomToggleButton.Value = 0;
      obj.updateStationList();
      obj.updatePickList();

    end

    function onStationList(obj,~,~)

      obj.miniSeedData.setStationIdx(obj.stationListBox.Value);
      obj.updatePickList();

    end

    function onChannelType(obj,~,~)

      val = obj.channelTypePopup.Value;
      obj.miniSeedData.setChannelIdx(val);
      obj.updateStationList();
      obj.updatePickList();

    end

    function onPickList(obj,~,~)

      obj.pickData.setPickIdx(obj.pickListBox.Value);
      obj.pickData.highlightPick();

    end

    function onPickDelete(obj,~,~)

      if length(obj.pickListBox.String) < 1
        return
      end

      str = obj.pickListBox.String;
      val = obj.pickListBox.Value;  
      pickId = str{val};

      evn = obj.eventListBox.String{obj.eventListBox.Value};
      sta = obj.stationListBox.String{obj.stationListBox.Value};
      espid = strjoin({evn,sta,pickId},'.');

      answer = questdlg(['Are you sure you want to delete ' pickId '?'],...
                        'Confirm action', 'Yes', 'No', 'No');
      if strcmpi(answer, 'Yes')
        obj.pickData.deletePick(espid);
      else
          % Just do nothing
      end

      if obj.autoSaveToggleButton == 1
        obj.pickData.savePicks(true);
      end

      obj.updatePickList();

    end

    function onPickPhase(obj,~,~)

      obj.pickData.setPickPhaseIdx(obj.pickPhaseBox.Value);

    end

    function onAutoSaveToggle(~,~,~) %(obj,~,~)

      % Toggle  autosave feature.
      %
      % Since this saves after every add/delete pick operation
      % it could be slow depending on the size of the pick list.

    end

    function onSavePicks(obj,~,~)

      obj.pickData.savePicks(true);

    end

    function onNormalizeWaveformsToggle(obj,~,~)

      if obj.normalizeWaveformsToggleButton.Value == 1
        obj.miniSeedData.setNormalizeWaveforms(true);
      else
        obj.miniSeedData.setNormalizeWaveforms(false);
      end

    end

    function onPlotEventPicksToggle(obj,~,~)

      if obj.plotEventPicksToggleButton.Value == 1
        obj.pickData.setPlotEventPicks(true);
      else
        obj.pickData.setPlotEventPicks(false);
      end

    end

    function onSpectrumToggle(obj,~,~)

      if obj.spectrumToggleButton.Value == 1
        obj.spectrumView.createNewFigure();
      else
        obj.spectrumView.deleteFigure();
      end

    end

    function onPolynomialDetrendCheck(obj,~,~)

      if obj.polynomialDetrendCheckbox.Value == 1
        obj.miniSeedData.setFilterParameters(1,true);
      else
        obj.miniSeedData.setFilterParameters(1,false);
      end
      
      obj.miniSeedData.triggerUpdate();

    end

    function onPolynomialDetrendPopup(obj,~,~)

      lst = obj.polynomialDetrendPopup.String;
      val = obj.polynomialDetrendPopup.Value;
      n = int32(lst{val});

      obj.miniSeedData.setFilterParameters(2,n);

      if obj.polynomialDetrendCheckbox.Value == 1
        obj.miniSeedData.triggerUpdate();
      end

    end

    function onBandpass(obj,~,~)

      lowf = double(string(obj.bandpassStart.String));
      highf = double(string(obj.bandpassEnd.String));

      obj.miniSeedData.setFilterParameters(4,lowf);
      obj.miniSeedData.setFilterParameters(5,highf);

      if obj.bandpassCheckbox.Value == 1
        obj.miniSeedData.setFilterParameters(3,true);
      else
        obj.miniSeedData.setFilterParameters(3,false);
      end
      
      obj.miniSeedData.triggerUpdate(); 

    end    

    function onHodogramToggle(obj,~,~)

      if obj.hodogramToggleButton.Value == 1
        obj.hodogramView.createNewFigure();
      else
        obj.hodogramView.deleteFigure();
      end

    end

    function onHodogramTimeRangeSubmit(obj,~,~)

      stmin = double(string(obj.hodogramTimeRangeStart.String));
      stmax = double(string(obj.hodogramTimeRangeEnd.String));

      tlim = obj.miniSeedData.getEventTimeLimits();

      if stmin >= tlim(1) && stmin < stmax && stmax <= tlim(2)
        obj.hodogramView.setTimeBounds([stmin stmax]);
      end
  
    end

  end

end