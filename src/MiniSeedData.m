classdef MiniSeedData < handle

  properties (SetAccess = private)

    dataPath

    eventWaveforms = []
    eventFolders = []
    eventFolder
    eventList = []
    eventIdx = 1

    stationList = []
    stationIdx = 1

    channelList = {'EHZ','EHN','EHE'}
    channelIdx = 1

    tRealMin
    tRealMax

    dmin
    dmax
    tmin
    tmax
    tdelta

    normalize = false
    plotStaLta = false

    samplingFrequency

    % Filtering --- poly detrend, n, bandpass, lowf, highf
    filterParams = {false,        0, false,    0,    300}

  end

  events (NotifyAccess = private)

    % Broadcast changes when data is altered
    eventDataChanged

    % Broadcast zoom mode toggle
    eventTimeLimitsChanged

    plotStaLtaChanged

  end

  methods

    function load(obj,path)

      try
        % Get all event folders
        d = dir(path);
        obj.dataPath = path;

        d = d([d(:).isdir]);
        obj.eventFolders = d(~ismember({d.name},{'.','..'}));
        
        obj.eventList = {obj.eventFolders.name};
        
        obj.eventFolder = obj.eventFolders(obj.eventIdx).name;
        
        e = dir(strcat(path,'/',obj.eventFolder,'/*.',...
                       obj.channelList{obj.channelIdx}));
        e = e(~ismember({e.name},{'.','..'}));

        % Get all station data for chose event and sort by max amplitude
        elen = length(e);
        elen = elen(1);
        mx = zeros(elen,1);
        mxt = zeros(elen,1);
        mnt = zeros(elen,1);

        obj.eventWaveforms = [];
        for i=1:elen
          dataFile = strcat(path,'/',obj.eventFolder,'/',e(i).name);
          raw = rdmseed(dataFile);
          raw_t = cat(1,raw.t);
          raw_d = cat(1,raw.d);
          rawData.t = raw_t;
          rawData.d = raw_d;
          rawData.name = strcat(...
            raw(1).NetworkCode,'.',...
            raw(1).StationIdentifierCode,'.',...
            raw(1).ChannelIdentifier...
          );
          rawData.event_name = obj.eventFolder;
          obj.eventWaveforms = [obj.eventWaveforms rawData];

          mx(i) = max(raw_d);

          t = (raw_t - raw_t(1)).*86400;
          mxt(i) = max(t);
          mnt(i) = min(t);
        end
       
        obj.dmax = max(mx);
        obj.tmax = max(mxt);
        obj.tmin = min(mnt);
        obj.tRealMin = obj.tmin;
        obj.tRealMax = obj.tmax;
        
        raw_t = obj.eventWaveforms(1).t;
        t = (raw_t - raw_t(1)).*86400;
        obj.tdelta = t(2) - t(1);
        
        % Sort based on amplitude
        [~,idx] = sort(mx);
        obj.eventWaveforms = obj.eventWaveforms(idx);
        
        obj.stationList = {e.name};
        obj.stationList = obj.stationList(idx);

        obj.samplingFrequency = length(obj.eventWaveforms(i).d)/obj.tmax;

        obj.ensureStationIdxInBounds();

      catch exception
        % Keep current data
        disp(exception)
        % for i=1:length(exception.stack)
        %   disp(exception.stack(i).file)
        %   disp(exception.stack(i).name)
        %   disp(exception.stack(i).line)
        % end
        msg = sprintf("Unable to read file %s!",path);
        msgbox(msg,'Warning','warn','modal');
      end

      notify(obj,'eventDataChanged');

    end

    function clear(obj)

      % Clear all data
      obj.dataPath = '';
      obj.eventWaveforms = [];
      obj.eventFolders = [];
      obj.eventFolder = '';
      obj.eventList = [];
      obj.eventIdx = 1;
      obj.stationList = [];
      obj.stationIdx = 1;
      obj.channelIdx = 1;
      obj.dmin = 0;
      obj.dmax = 0;
      obj.tmin = 0;
      obj.tmax = 0;
      obj.tRealMin = 0;
      obj.tRealMax = 0;

    end

    function triggerUpdate(obj)

      notify(obj,'eventDataChanged');

    end

    function ensureStationIdxInBounds(obj)

      lenStationList = length(obj.stationList);
      if obj.stationIdx > lenStationList
        obj.stationIdx = lenStationList;
      end

    end

    function setEventIdx(obj,eventIdx)

      obj.eventIdx = eventIdx;
      obj.load(obj.dataPath);
      notify(obj,'plotStaLtaChanged');

    end

    function setStationIdx(obj,stationIdx)

      obj.stationIdx = stationIdx;
      notify(obj,'eventDataChanged');
      notify(obj,'plotStaLtaChanged');

    end

    function setChannelIdx(obj,channelIdx)

      obj.channelIdx = channelIdx;
      obj.load(obj.dataPath);
      notify(obj,'eventDataChanged');
      notify(obj,'plotStaLtaChanged');

    end

    function setEventTimeLimits(obj,eventTimeLimits)

      obj.tmin = eventTimeLimits(1);
      obj.tmax = eventTimeLimits(2);
      notify(obj,'eventTimeLimitsChanged');

    end

    function setNormalizeWaveforms(obj,bool)

      obj.normalize = bool;
      notify(obj,'eventDataChanged');

    end

    function setPlotStaLta(obj,bool)

      obj.plotStaLta = bool;
      notify(obj,'plotStaLtaChanged');

    end

    function resetEventTimeLimits(obj)
    
      obj.tmin = obj.tRealMin;
      obj.tmax = obj.tRealMax;
      notify(obj,'eventTimeLimitsChanged');

    end

    function setFilterParameters(obj,paramIdx,param)
    % Check class properties for layout of filterParams
       obj.filterParams{paramIdx} = param;

    end

    function efld = getDataPath(obj)

      temp = obj.dataPath;
      temp(strfind(temp,'\')) = '/';
      split = strsplit(temp,'/');
      efld = split{end};

      efld = obj.dataPath;

    end

    function sidx = getStationIdx(obj)

      sidx = obj.stationIdx;

    end

    function eidx = getEventIdx(obj)

      eidx = obj.eventIdx;

    end

    function wvfs = getWaveforms(obj)

      wvfs = obj.eventWaveforms;
      
      % Polynomial detrend
      if obj.filterParams{1}
        for i=1:length(wvfs)
          wvfs(i).d = detrend(wvfs(i).d,obj.filterParams{2});
        end
      end

      % Bandpass filter
      if obj.filterParams{3} && obj.filterParams{4} > 0.001 % && ...
          % obj.filterParams{5} < obj.samplingFrequency/2
        fs = obj.samplingFrequency;
        lowf = obj.filterParams{4};
        highf = obj.filterParams{5};
        for i=1:length(wvfs)
          % wvfs(i).d = bandpass(wvfs(i).d,[lowf highf],fs);
          wvfs(i).d = filtering(wvfs(i).d,fs,lowf,highf);
        end
      end

    end

    function tlim = getEventTimeLimits(obj)

      tlim = [obj.tmin obj.tmax];

    end

    function tdel = getEventTimeDeltaT(obj)

      tdel = obj.tdelta;

    end

    function elst = getEventList(obj)
    
      elst = obj.eventList;
    
    end

    function slst = getStationList(obj)

      slst = obj.stationList;

    end

    function islo = isStaLtaOn(obj)

      islo = obj.plotStaLta;

    end

    function smfq = getSamplingFrequency(obj)

      smfq = obj.samplingFrequency;

    end

    function clst = getChannelList(obj)

      clst = obj.channelList;

    end

    function cidx = getChannelIdx(obj)

      cidx = obj.channelIdx;

    end

  end

end