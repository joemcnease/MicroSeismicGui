classdef StationView < handle

  properties (Access = private)

    fig

    ax
    miniSeedData
    pickData

    eventListener
    eventTimeLimitsListener
    pickListener
    staltaListener

    pickLines = []

  end

  methods

    function obj = StationView(miniSeedData,pickData,fig)

      obj.fig = fig;

      obj.miniSeedData = miniSeedData;
      obj.pickData = pickData;

      obj.eventListener = addlistener(obj.miniSeedData,'eventDataChanged',@obj.onEventDataChanged);

      obj.eventTimeLimitsListener = addlistener(obj.miniSeedData,'eventTimeLimitsChanged',@obj.onEventTimeLimitsChanged);

      obj.pickListener = addlistener(obj.pickData,'pickDataChanged',@obj.onPickDataChanged);

      obj.staltaListener = addlistener(obj.miniSeedData,'plotStaLtaChanged',@obj.onPlotStaLtaChanged);

      obj.setup;

    end

  end

  methods(Access = protected)

    function setup(obj)
    
      % Figure position/dimensions
      pos = [0.235 0.075 0.495 0.17];

      obj.ax = axes(obj.fig,'Position',pos);
      yticks(obj.ax,[]);
      yticklabels(obj.ax,[]);
      fontsize(obj.ax,10,'points');
    
    end

  end

  methods (Access = private)

    function onEventDataChanged(obj,~,~)

      % Plot selected channel in lower plot
      idx = obj.miniSeedData.stationIdx;
  
      cla(obj.ax);
      wf = obj.miniSeedData.getWaveforms();
      d = wf(idx);
      t = (d.t - d.t(1))*86400;

      dlim = max(abs(d.d)) + max(abs(d.d))*0.05;

      %Fs = length(d)/t(end);
      % data = processPipeline(d,Fs);

      plot(obj.ax,t,d.d,'Color','k',...
           'ButtonDownFcn',@obj.onPickCallback);
      hold(obj.ax,'on');
  
      annText = ['Channel: ' d.name];
      text(obj.ax,0.66,0.87,annText,'Units','normalized','FontSize',15);
  
      xlabel(obj.ax,"Time [s]");
      xl = [obj.miniSeedData.tmin obj.miniSeedData.tmax];
      xlim(obj.ax,xl);
      ylim(obj.ax,[-dlim dlim]);

      obj.onPickDataChanged();
  
    end

    function onEventTimeLimitsChanged(obj,~,~)

      xlim(obj.ax,obj.miniSeedData.getEventTimeLimits());

    end

    function onPickDataChanged(obj,~,~)

      [pickTimes,pickColors] = obj.pickData.getPickTimesAndColors();
      nPicks = length(pickTimes);

      delete(obj.pickLines);
      if nPicks > 0
        for i=1:nPicks
          pickLine = xline(obj.ax,pickTimes(i),'Color',pickColors(i),'LineWidth',3);
          obj.pickLines = [obj.pickLines pickLine];
          
          hold(obj.ax,'on');
        end
      end

    end

    function onPickCallback(obj,src,event)

      cp = obj.ax.CurrentPoint(1,1:2);
      [pickTimes,~] = obj.pickData.getPickTimesAndColors();

      cmp = (pickTimes == cp(1));
      if sum(cmp) > 0
        return
      end

      wf = obj.miniSeedData.getWaveforms();
      stawf = wf(obj.miniSeedData.getStationIdx());
      evnm = stawf.event_name;
      nscCode = strsplit(stawf.name,'.');

      net = nscCode{1};
      sta = nscCode{2};
      cha = nscCode{3};
      loc = '-';
      trel = cp(1);
      tabs = '-';
      phse = char(obj.pickData.getPickPhase());
      pickId = strcat([phse '_' num2str(trel)]);
      
      newPick = {evnm,net,sta,cha,loc,trel,tabs,phse};

      obj.pickData.addPick(newPick,pickId);
      

    end

    function onPlotStaLtaChanged(obj,~,~)

      if obj.miniSeedData.isStaLtaOn()
        stationIdx = obj.miniSeedData.getStationIdx();
        wf = obj.miniSeedData.getWaveforms();
        data = wf(stationIdx);
        d = data.d;
        t = data.t;
        t = (t - t(1))*86400;
        fs = length(data.d)/t(end);
  
        nsta = 100;
        nlta = 1000;
  
        sta = cumsum(d.^2);
        lta = sta;
  
        sta(nsta:end) = sta(nsta:end) - sta(1:end-nsta+1);
        sta = sta/nsta;
  
        lta(nlta:end) = lta(nlta:end) - lta(1:end-nlta+1);
        lta = lta/nlta;
  
        sta(1:nlta) = 0;
  
        r = sta./lta;
  
        yyaxis(obj.ax,'right');
        cla(obj.ax);
        plot(obj.ax,t,r,'Color','r','LineWidth',2);
        yyaxis(obj.ax,'left');
      else
        yyaxis(obj.ax,'right');
        cla(obj.ax);
        yyaxis(obj.ax,'left');
      end

    end

  end

end