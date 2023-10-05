classdef HodogramView < handle

  properties (Access = private)

    fig

    hodoFigVisible = false
    hodoFig
    ax
    miniSeedData
    pickData

    eventListener

  end

  methods

    function obj = HodogramView(miniSeedData,pickData,fig)

      obj.fig = fig;

      obj.miniSeedData = miniSeedData;
      obj.pickData = pickData;

      obj.eventListener = addlistener(obj.miniSeedData,'eventDataChanged',@obj.onEventDataChanged);

      obj.setup;

    end

  end

  methods(Access = protected)

    function setup(obj)
    


    end

  end

  methods (Access = private)

    function onEventDataChanged(obj,~,~)

      if obj.hodoFigVisible
        cla(obj.ax);

          idx = obj.miniSeedData.getStationIdx();
          stationName = obj.miniSeedData.getStationList();
          stationName = stationName(idx);
          stationName = stationName{1};
          stationName = stationName(1:end-4);
      
          dataFolder = obj.miniSeedData.getDataPath();
      
          %lst = obj.miniSeedData.getChannelList();
          %val = obj.miniSeedData.getChannelIdx();
          %channelType = lst{val};
      
          l_eventNum = obj.miniSeedData.getEventIdx();
          l_eventFolders = obj.miniSeedData.getEventList();
          l_eventFolder = l_eventFolders{l_eventNum};
      
          % We want all components of station (.EHZ, .EHN, .EHE)
          eZ = strcat(dataFolder,'/',l_eventFolder,'/',stationName,'.EHZ');
          eN = strcat(dataFolder,'/',l_eventFolder,'/',stationName,'.EHN');
          eE = strcat(dataFolder,'/',l_eventFolder,'/',stationName,'.EHE');
          e = {eZ,eN,eE};
    
        try
          % Get all station data for chose event and sort by max amplitude
          hodogramData = [];
          mx = [];
          for i=1:length(e)
            dataFile = e{i};
            raw = rdmseed(dataFile);
            raw_t = cat(1,raw.t);
            raw_d = cat(1,raw.d);
            raw_data.t = raw_t;
            raw_data.d = raw_d;
            raw_data.name = strcat(...
              raw(1).NetworkCode,'.',...
              raw(1).StationIdentifierCode,'.',...
              raw(1).ChannelIdentifier...
            );
            raw_data.event_name = l_eventFolder;
            hodogramData = [hodogramData raw_data];
            mx = [mx max(raw_d)];
          end
      
          plot3(obj.ax,hodogramData(3).d,hodogramData(2).d,hodogramData(1).d);
          xlabel(obj.ax,'EHE');
          ylabel(obj.ax,'EHN');
          zlabel(obj.ax,'EHZ');

        catch exception
          disp(['File ' e{i} ' does not exist! Will not plot hodogram.']); 

        end
  
      end

    end

  end

  methods

    function createNewFigure(obj)

      obj.hodoFig = figure;
      obj.ax = axes(obj.hodoFig);
      obj.hodoFigVisible = true;

      obj.onEventDataChanged();

    end

    function deleteFigure(obj)

      close(obj.hodoFig);
      pause(0.01);
      obj.hodoFigVisible = false;

    end

  end

end