% An object for storing picking information.
classdef PickData < handle

  properties (SetAccess = private)

    % Path to pick file
    filepath

    data = table()

    tableHeaders = ["Event" "Network" "Station" "Channel" "Location",...
                    "RelativeTime" "AbsoluteTime" "Phase"]

    % Default pick file location
    defaultFilepath = 'picks/picks.txt'

    % Format specifier for writing pick data
    writeFormatSpec = '%-15s %-15s %-15s %-15s %-15s %-15s %-15s %-15s'
    readFormatSpec = '%s %s %s %s %s %s %s %s'

    meta = {}

    % File read flag
    fileRead = false

    pickList = {}

    % Labels for active picks
    activePickLabels
    activeStationCode
    activeEvent

    activePickTimes = []
    resetPickColors = []
    activePickColors = []

    pickPhases = ["P" "S"] % Phase options
    pickColors = ["r" "b"] % Colors for each phase
    pickPhaseColorMap

    pickPhaseIdx = 1

    pickIdx = 1

    plotEventPicks = false

  end

  events (NotifyAccess = private)

    % Broadcast changes when data is altered
    pickDataChanged

    pickDataHighlightChanged

    showEventPicksChanged

  end

  methods (Access = private)

    % Check if path exists, create if it doesn't.
    function ensurePickFileExists(obj)

        splitPath = strsplit(obj.filepath,'/');
        tempPath = char(splitPath(1:end-1));

        if not(isfolder(tempPath))
          mkdir(tempPath);
        end
        if not(isfile(obj.filepath))
          obj.createNewFile(obj.filepath);
        end

        obj.readFile();
        notify(obj,'pickDataChanged');

    end

    % Create new pick file
    function createNewFile(obj,val)

      fid = fopen(val,'w');
      fprintf(fid,'Pick file created on %s\n',string(datetime('now')));
      fprintf(fid,'Pick file last modified on %s\n',string(datetime('now')));
      s1 = 'Event';
      s2 = 'Network';
      s3 = 'Station';
      s4 = 'Channel';
      s5 = 'Location';
      s6 = 'RelativeTime';
      s7 = 'AbsoluteTime';
      s8 = 'Phase';
      fprintf(fid,obj.writeFormatSpec,s1,s2,s3,s4,s5,s6,s7,s8);
      fclose(fid);

    end

    % Open and read file contents
    function readFile(obj)

      fid = fopen(obj.filepath,'r');  

      obj.meta{1} = fgetl(fid); % Date created
      obj.meta{2} = fgetl(fid); % Date last modified
      obj.meta{3} = fgetl(fid); % Column names
  
      % Get data in cell arrays
      raw = textscan(fid,obj.readFormatSpec);
      rawTable = reshape([raw{:}],length(raw{1}),length(raw));
      obj.data = cell2table(rawTable,'VariableNames',obj.tableHeaders);
      obj.data = varfun(@(x) string(x),obj.data);
      obj.data.Properties.VariableNames = obj.tableHeaders;
      obj.data.RelativeTime = str2double(obj.data.RelativeTime);

      obj.activePickLabels = strcat(raw{end},'_',raw{6});
      obj.activeStationCode = strcat(raw{2},'.',raw{3},'.',raw{4});
      obj.activeEvent = raw{1};

      fclose(fid);

    end

    function overwriteFile(obj,pick)
    % Overwriting the pick file with the current pick table
    % is the standard way of permanently saving progress.
    %
    % In the future we can either have a swap file that has
    % some previous version of the pick table or we can
    % save edits in a formatted way to 'undo' progress.
    %
    % Note: I am not writing the table directly to file here,
    % but this is because of how the 'legacy' I/O system was
    % working. I should probably just write the header and 
    % then write the table. On the other hand, this reduces
    % the readability of the text file.

      fid = fopen(obj.filepath,'w');

      % Write header (change date last modified)
      lastMod = sprintf('Pick file last modified on %s',string(datetime('now')));
      obj.meta{2} = lastMod;
      for i=1:length(obj.meta)
        fprintf(fid,'%s\n',obj.meta{i});
      end
      
      % Write table
      for i=1:height(obj.data)
        fprintf(fid,[obj.writeFormatSpec '\n'],obj.data(i,:).Variables);
      end

      fclose(fid);

    end

  end

  methods

    % Constructor
    function obj = PickData(filepath)

      obj.pickPhaseColorMap = dictionary(obj.pickPhases,obj.pickColors);

      if nargin == 0
        % Create default pick file
        obj.filepath = obj.defaultFilepath;
        obj.ensurePickFileExists();
      elseif nargin == 1
        obj.filepath = filepath;
        obj.ensurePickFileExists();
      end

    end

    function triggerUpdate(obj)

      notify(obj,'pickDataChanged');

    end

    function ensurePickIdxInBounds(obj)

      lenPickList = length(obj.pickList);
      if obj.pickIdx > lenPickList && lenPickList > 0
        obj.pickIdx = lenPickList;
      end

    end

    function addPick(obj,pick,pickId)

      obj.data = [obj.data;pick];
      obj.getPickList(pickId);
      notify(obj,'showEventPicksChanged');

    end

    function savePicks(obj,notifyChange)

        obj.overwriteFile();
        if notifyChange
          notify(obj,'pickDataChanged');
        end

    end

    function deletePick(obj,pickId)
      pIdx = obj.pickIdx;
      strarr = obj.data.Variables;
      for i=1:height(obj.data)
        pid = char(strjoin(strarr(i,[8 6]),'_'));
        es = strjoin(strarr(i,[1 2 3 4]),'.');
        espid = strjoin([es pid],'.');
        if strcmp(espid,pickId)
          disp(i)
          obj.data(i,:) = [];
          obj.activePickTimes(pIdx) = [];
          obj.activePickColors(pIdx) = [];
          break
        end
      end

      notify(obj,'pickDataChanged');
      notify(obj,'showEventPicksChanged');

    end

    function highlightPick(obj)

      obj.activePickColors = obj.resetPickColors;
      obj.activePickColors(obj.pickIdx) = "y";
      notify(obj,'pickDataChanged');

    end

    function setPickPhaseIdx(obj,pickPhaseIdx)

      obj.pickPhaseIdx = pickPhaseIdx;
     
    end

    function setPickIdx(obj,pickIdx)

      obj.pickIdx = pickIdx;
      notify(obj,'showEventPicksChanged');

    end

    function setPlotEventPicks(obj,bool)

      obj.plotEventPicks = bool;
      notify(obj,'showEventPicksChanged');

    end

    function val = getTable(obj)

      val = obj.data;

    end

    function plst = getPickList(obj,pickId)

      obj.pickList = {};
      obj.activePickTimes = [];
      obj.activePickColors = [];

      strarr = obj.data.Variables;
      for i=1:height(obj.data)
        id = strjoin(strarr(i,1:4),'.');
        if strcmp(id,pickId)
          obj.pickList{end+1} = char(strjoin(strarr(i,[8 6]),'_'));
          obj.activePickTimes = [obj.activePickTimes 
                                 obj.data.RelativeTime(i)];
          obj.activePickColors = [obj.activePickColors 
                                  obj.pickPhaseColorMap(strarr(i,8))];
        end
      end

      plst = obj.pickList;

      obj.resetPickColors = obj.activePickColors;
      obj.activePickColors(obj.pickIdx) = "y";

      notify(obj,'pickDataChanged');
      notify(obj,'showEventPicksChanged');
      
    end

    function [pktm, pkcl] = getPickTimesAndColors(obj)

      pktm = obj.activePickTimes;
      pkcl = obj.activePickColors;

    end

    function phse = getPickPhase(obj)

      phse = obj.pickPhases(obj.pickPhaseIdx);

    end

    function pidx = getPickIdx(obj)

      pidx = obj.pickIdx;

    end

    function ppcm = getPickPhaseColorMap(obj)

      ppcm = obj.pickPhaseColorMap;

    end

    function ippo = isPlotEventPicksOn(obj)

      ippo = obj.plotEventPicks;

    end

  end
  
end