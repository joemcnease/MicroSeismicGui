classdef SpectrumView < handle

  properties (Access = private)

    fig

    specFigVisible = false
    specFig
    ax
    miniSeedData
    pickData

    eventListener

  end

  methods

    function obj = SpectrumView(miniSeedData,pickData,fig)

      obj.fig = fig;

      obj.miniSeedData = miniSeedData;
      obj.pickData = pickData;

      obj.eventListener = addlistener(obj.miniSeedData,'eventDataChanged',@obj.onEventDataChanged);

      obj.setup;

    end

  end

  methods(Access = protected)

    function setup(obj)

      pos = [0.79 0.075 0.18 0.4];
      obj.ax = axes(obj.fig,'Position',pos);
      yticks(obj.ax,[]);
      yticklabels(obj.ax,[]);
      xticks(obj.ax,[]);
      xticklabels(obj.ax,[]);
      fontsize(obj.ax,10,'points');

      obj.specFigVisible = true;
    
    end

  end

  methods (Access = private)

    function onEventDataChanged(obj,~,~)

      if obj.specFigVisible
        cla(obj.ax);
  
        % Plot selected channel in lower plot
        idx = obj.miniSeedData.stationIdx;
    
        wf = obj.miniSeedData.getWaveforms();
        data = wf(idx);
        d = data.d;
        t = (data.t - data.t(1))*86400;
  
        Fs = length(d)/t(end);
  
        L = length(d);
        Y = fft(d);
        P2 = abs(Y/L);
        P1 = P2(1:floor(L/2+1));
        P1(2:end-1) = 2*P1(2:end-1);
        f = Fs*(0:(L/2))/L;
  
        plot(obj.ax,f,P1);
        xlim(obj.ax,[0 f(end)]);
        ylabel(obj.ax,'Amplitude Spectrum'); % |P1(f)|');
        xlabel(obj.ax,'Frequency [Hz]');
  
      end

    end

  end

  methods

    function createNewFigure(obj)

      % obj.specFig = figure;
      % obj.ax = axes(obj.specFig);

      %pos = [0.8 0.075 0.175 0.4];
      %obj.ax = axes(obj.fig,'Position',pos);
      obj.specFigVisible = true;

      obj.onEventDataChanged();

    end

    function deleteFigure(obj)

      %close(obj.specFig);
      %pause(0.01);
      %obj.specFigVisible = false;

    end

  end

end