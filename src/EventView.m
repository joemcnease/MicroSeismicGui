classdef EventView < handle

  properties (Access = private)

    fig

    ax
    miniSeedData
    pickData

    eventListener
    eventTimeLimitsListener

    showEventPicksListener

    wfLines = []
    pickLines = []
    selectedLines = []

    lastEvent

  end

  methods

    function obj = EventView(miniSeedData,pickData,fig)

      obj.fig = fig;

      obj.miniSeedData = miniSeedData;
      obj.pickData = pickData;

      obj.eventListener = addlistener(obj.miniSeedData,'eventDataChanged',@obj.onEventDataChanged);

      obj.eventTimeLimitsListener = addlistener(obj.miniSeedData,'eventTimeLimitsChanged',@obj.onEventTimeLimitsChanged);

      obj.showEventPicksListener = addlistener(obj.pickData,'showEventPicksChanged',@obj.onShowEventPicksChanged);

      obj.setup;

    end

  end

  methods(Access = protected)

    function setup(obj)
    
      % Figure position/dimensions
      pos = [0.235 0.31 0.495 0.65];

      obj.ax = axes(obj.fig,'Position',pos);
      yticks(obj.ax,[]);
      yticklabels(obj.ax,[]);
      fontsize(obj.ax,10,'points');
    
    end

  end

  methods (Access = private)

    function onEventDataChanged(obj,~,~)

      obj.wfLines = [];

      thisEvent = obj.miniSeedData.getEventList();
      thisEvent = thisEvent{obj.miniSeedData.getEventIdx()};
      disp(thisEvent);

      cla(obj.ax);
      d = obj.miniSeedData.getWaveforms();
      elen = length(d);
      offsets = zeros(1,elen);
      labels = {d.name};
      offset = 0;
      doff = 500;

      if not(strcmp(thisEvent,obj.lastEvent))
        obj.selectedLines = false(1,elen);
      end

      for i=1:elen
        data = d(i).d;
        if obj.miniSeedData.normalize
          data = rescale(data,-1,1).*(doff/2);
          data = data * obj.miniSeedData.getAmpFactor();
        end
        t = (d(i).t - d(i).t(1))*86400;
        wfLine = plot(obj.ax,t,data+offset);%,'ButtonDownFcn',@obj.onLineSelection);
        if obj.selectedLines(i)
          wfLine.Visible = 'off';
        end
        obj.wfLines = [obj.wfLines wfLine];
        offsets(i) = offset;
        offset=offset+doff;     
        hold(obj.ax,'on');
      end

      obj.ax.ButtonDownFcn = @obj.onLineSelection;

      annText = ['Event: ' d(1).event_name];
      text(obj.ax,0.73,0.96,annText,'Units','normalized','FontSize',15);

      xlm = obj.miniSeedData.getEventTimeLimits();
  
      % xlabel(obj.ax,"Time [s]"); % Can't see label because of timeSlider
      xlim(obj.ax,xlm);
      ylim(obj.ax,[-2*doff offset+doff]);
      yticks(obj.ax,offsets);
      yticklabels(obj.ax,labels);
      obj.ax.YAxis.FontSize = 9;
      ytickangle(obj.ax,45)

      obj.lastEvent = thisEvent;

      if obj.pickData.isPlotEventPicksOn()
        obj.onShowEventPicksChanged();
      end

    end

    function onShowEventPicksChanged(obj,~,~)

      hold(obj.ax,'on');

      delete(obj.pickLines);
      if ~obj.pickData.isPlotEventPicksOn()
        return
      end

      offset = 0;
      doff = 500;

      % Event
      wf = obj.miniSeedData.getWaveforms();
      evnt = wf(obj.miniSeedData.getEventIdx()).event_name;

      % Stations
      stlst = obj.miniSeedData.getStationList();
        
      pckdat = obj.pickData.getTable();
      strarr = pckdat.Variables;

      clrmap = obj.pickData.getPickPhaseColorMap();

      pidx = obj.pickData.getPickIdx();
      [activePickTimes,~] = obj.pickData.getPickTimesAndColors();

      % Plot picks for station
      for i=1:length(stlst)
        st = stlst(i);
        for j=1:height(pckdat)
          evstCode = strjoin([evnt st],'.');
          es = strjoin(strarr(j,1:4),'.');
          if strcmp(es,evstCode)
            time = pckdat.RelativeTime(j);
            color = clrmap(strarr(j,8));
            if ~isempty(activePickTimes) && ...
                strcmp(stlst{i},stlst{obj.miniSeedData.getStationIdx()}) && ...
                time == activePickTimes(pidx)
              color = "y";
            end
            pickLine = line(obj.ax,[time time],...
                          [(offset-doff/2) (offset+doff/2)],...
                          'Color',color,'LineWidth',3);
            obj.pickLines = [obj.pickLines pickLine];

            hold(obj.ax,'on');
          end
        end
        offset = offset + doff;
      end
    end

    function onEventTimeLimitsChanged(obj,~,~)

      xlim(obj.ax,obj.miniSeedData.getEventTimeLimits());

    end

    function onLineSelection(obj,ax,event)

      [~,tickIdx] = min(abs(ax.YTick - event.IntersectionPoint(2)));
      tickSelected = ax.YTick(tickIdx);

      idx = tickIdx;
      
      if obj.selectedLines(idx)
        obj.wfLines(idx).Visible = 'on';
        obj.selectedLines(idx) = false;
        return
      end

      obj.wfLines(idx).Visible = 'off';
      obj.selectedLines(idx) = true;

    end

  end

end