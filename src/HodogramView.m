classdef HodogramView < handle

  properties (Access = private)

    fig

    hodoFigVisible = false
    hodoFig
    ax
    miniSeedData
    pickData

    hodogramDataE
    hodogramDataN
    hodogramDataZ

    timeBounds
    timeData
    timeBoundsInit = false

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

          obj.hodogramDataE = hodogramData(3).d;
          obj.hodogramDataN = hodogramData(2).d;
          obj.hodogramDataZ = hodogramData(1).d;

          temp = hodogramData(1).t;
          t = (temp - temp(1))*86400;
          obj.timeData = t;

          if obj.timeBoundsInit      
            obj.onUpdateTimeBounds();
            return;
          end

          temp = hodogramData(1).t;
          t = (temp - temp(1))*86400;
          obj.timeBounds = [t(1) t(end)];
          obj.timeData = t;

          plot3(obj.ax,hodogramData(3).d,hodogramData(2).d,hodogramData(1).d);
          xlabel(obj.ax,'EHE');
          ylabel(obj.ax,'EHN');
          zlabel(obj.ax,'EHZ');

          obj.timeBoundsInit = true;

        catch exception
          disp(['File ' e{i} ' does not exist! Will not plot hodogram.']); 

        end
  
      end

    end

    function onUpdateTimeBounds(obj)

      cla(obj.ax);

      t = obj.timeData;
      dE = obj.hodogramDataE;
      dN = obj.hodogramDataN;
      dZ = obj.hodogramDataZ;

      % Find idxs in time domain
      idx1 = find(t>obj.timeBounds(1));
      idx2 = find(t<obj.timeBounds(2));
      b1 = idx1(1);
      b2 = idx2(end);

      dE = dE(b1:b2);
      dN = dN(b1:b2);
      dZ = dZ(b1:b2);     

      plot3(obj.ax,dE,dN,dZ);
      xlabel(obj.ax,'EHE');
      ylabel(obj.ax,'EHN');
      zlabel(obj.ax,'EHZ');

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

    function setTimeBounds(obj,timeBounds)

      obj.timeBounds = timeBounds;
      obj.onUpdateTimeBounds();

    end

  end

end
